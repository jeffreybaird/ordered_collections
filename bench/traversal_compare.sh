#!/usr/bin/env bash
# Compare the preserved, correct iterator implementation with the working tree.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
original=61ca0f5c50dbdbc8db78b09c9f0dc32006fb9b49
output=${1:-$(mktemp -d /tmp/ordered-traversal-bench.XXXXXX)}
mkdir -p "$output"
output=$(cd "$output" && pwd)
if [ -e "$output/baseline" ]; then
  printf 'Refusing to overwrite existing baseline: %s\n' "$output/baseline" >&2
  exit 1
fi
mkdir "$output/baseline"
git archive "$original" | tar -x -C "$output/baseline"
git -C "$output/baseline" apply "$root/.docs/traversal-baseline.patch"
ln -s "$root/deps" "$output/baseline/deps"
cp "$root/bench/traversal.exs" "$output/traversal.exs"
shasum -a 256 "$root/.docs/traversal-baseline.patch" "$output/traversal.exs" > "$output/inputs.sha256"
(
  cd "$output/baseline"
  BENCH_LABEL=fixed-iterator-baseline BENCH_FILTER="${BENCH_FILTER:-/(library|raw|raw_to_list)$}" BENCH_OUTPUT="$output/baseline.json" MIX_BUILD_PATH="$output/build-baseline" mix run "$output/traversal.exs"
) > "$output/baseline.log" 2>&1
(
  cd "$root"
  BENCH_LABEL=optimized-working-tree BENCH_FILTER="${BENCH_FILTER:-/(library|raw|raw_to_list)$}" BENCH_OUTPUT="$output/current.json" mix run "$output/traversal.exs"
) > "$output/current.log" 2>&1
printf 'Traversal comparison evidence: %s\n' "$output"
