#!/usr/bin/env bash
# Baseline source is isolated; dependency sources are shared and builds separate.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
baseline=${BASELINE_REVISION:-61ca0f5c50dbdbc8db78b09c9f0dc32006fb9b49}
output=${1:-$(mktemp -d /tmp/ordered-collections-bench.XXXXXX)}
mkdir -p "$output/baseline"
output=$(cd "$output" && pwd)
git archive "$baseline" | tar -x -C "$output/baseline"
ln -s "$root/deps" "$output/baseline/deps"
cp "$root/bench/comparison.exs" "$output/comparison.exs"
(
  cd "$output/baseline"
  BENCH_LABEL=baseline BENCH_REVISION="$baseline" BENCH_OUTPUT="$output/baseline.json" MIX_BUILD_PATH="$output/build-baseline" mix run "$output/comparison.exs"
) > "$output/baseline.log" 2>&1
(
  cd "$root"
  BENCH_LABEL=current BENCH_OUTPUT="$output/current.json" mix run "$output/comparison.exs"
) > "$output/current.log" 2>&1
printf 'Benchmark evidence: %s\n' "$output"
