#!/usr/bin/env bash
# Compare the preserved, correct iterator implementation with the working tree.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
original=${BASELINE_REVISION:-61ca0f5c50dbdbc8db78b09c9f0dc32006fb9b49}
manifest="$root/.docs/traversal-baseline.sha256"
if ! baseline_commit=$(git rev-parse --verify --quiet --end-of-options "${original}^{commit}"); then
  printf 'Baseline revision is not available locally: %s\n' "$original" >&2
  printf 'This can happen in a shallow clone. Fetch the commit, then rerun:\n  git fetch origin %s\n' "$original" >&2
  exit 1
fi
output=${1:-$(mktemp -d /tmp/ordered-traversal-bench.XXXXXX)}
mkdir -p "$output"
output=$(cd "$output" && pwd)
if [ -e "$output/baseline" ]; then
  printf 'Refusing to overwrite existing baseline: %s\n' "$output/baseline" >&2
  exit 1
fi
mkdir "$output/baseline"
git archive "$baseline_commit" | tar -x -C "$output/baseline"
# The output may live inside a Git checkout. Prevent discovery of that parent
# repository, whose subdirectory filtering would otherwise skip patch paths.
if ! GIT_CEILING_DIRECTORIES="$output" git -C "$output/baseline" apply "$root/.docs/traversal-baseline.patch"; then
  printf 'Cannot reconstruct the preserved baseline from revision %s. Check BASELINE_REVISION and the baseline patch.\n' "$original" >&2
  exit 1
fi

# A revision override may change the archive source, but never the measured
# baseline. Verify both its complete source inventory and every expected byte.
awk '{print $2}' "$manifest" | LC_ALL=C sort > "$output/expected-baseline-files.txt"
(
  cd "$output/baseline"
  find lib -name '*.ex' ! -type d -print
  printf '%s\n' mix.exs
) | LC_ALL=C sort > "$output/actual-baseline-files.txt"
if ! diff -u "$output/expected-baseline-files.txt" "$output/actual-baseline-files.txt"; then
  printf 'Baseline source inventory does not match the checksum manifest. No benchmarks were run.\n' >&2
  exit 1
fi
if ! (cd "$output/baseline" && shasum -a 256 -c "$manifest") > "$output/baseline-verification.log" 2>&1; then
  cat "$output/baseline-verification.log" >&2
  printf 'Baseline checksum verification failed. No benchmarks were run.\n' >&2
  exit 1
fi
printf '%s\n' "$baseline_commit" > "$output/baseline-commit.txt"
ln -s "$root/deps" "$output/baseline/deps"
cp "$root/bench/traversal.exs" "$output/traversal.exs"
shasum -a 256 "$root/.docs/traversal-baseline.patch" "$manifest" "$output/traversal.exs" > "$output/inputs.sha256"
(
  cd "$output/baseline"
  BENCH_LABEL=fixed-iterator-baseline BENCH_FILTER="${BENCH_FILTER:-/(library|raw|raw_to_list)$}" BENCH_OUTPUT="$output/baseline.json" MIX_BUILD_PATH="$output/build-baseline" mix run "$output/traversal.exs"
) > "$output/baseline.log" 2>&1
(
  cd "$root"
  BENCH_LABEL=optimized-working-tree BENCH_FILTER="${BENCH_FILTER:-/(library|raw|raw_to_list)$}" BENCH_OUTPUT="$output/current.json" mix run "$output/traversal.exs"
) > "$output/current.log" 2>&1
printf 'Traversal comparison evidence: %s\n' "$output"
