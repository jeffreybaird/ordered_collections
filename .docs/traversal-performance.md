# Traversal performance follow-up

This follow-up compares against the **corrected iterator implementation** from
the [initial review](review-results.md), rather than against the buggy published
implementation. Public collection APIs, Erlang ordering, strict Enumerable
membership, and the underlying trees remain unchanged.

## Implementation choices

- Set enumeration starts with public `:gb_sets.fold/3`, avoiding per-element
  iterator allocation on a full traversal. A fresh private reference identifies
  internal halt/suspend throws; unrelated callback throws, errors, and exits
  propagate. Suspension reconstructs a public iterator at the consumed element,
  discards that one element, and captures the remaining iterator for resumption.
  Initial halt and suspension do not invoke the callback.
- Map enumeration keeps its public iterator. The continuing path recurses with
  the unwrapped accumulator; halt and suspend dispatch separately.
- Map range queries that cover both extrema use public `:gb_trees.to_list/1`.
  Other ranges retain the bounded `iterator_from/2` traversal. Reversed and empty
  ranges return immediately. Extrema comparisons use Erlang ordering, including
  equivalent numeric keys.

The initial candidates are recorded in [reducer](traversal-benchmarks/candidate-reduce.json),
[range](traversal-benchmarks/candidate-ranges.json), and
[set-fold](traversal-benchmarks/fold-candidates.json) results. Forward recursive
range construction, which avoids the final list reversal, was rejected: it was
inconsistent across sizes, slower at 20,000 elements, and adds recursion-stack
cost. The full-coverage fast path provides a larger benefit with a simpler
implementation. The set-fold path trades higher fixed early-halt overhead for
lower full-traversal time and allocation; it is not a universal speedup.

## Measured results

The paired run contains 92 measurements per version, all with successful result
checks. The following are medians from the actual `Enum.reduce/3` and range
workloads. Allocation columns are median bytes per call.

| Operation | Elements | Before, µs | After, µs | Time reduction | Allocation before → after |
|---|---:|---:|---:|---:|---:|
| Set `Enum.reduce` | 32 | 0.459 | 0.400 | 12.9% | 2,912 → 896 B |
| Set `Enum.reduce` | 1,000 | 14.250 | 12.292 | 13.7% | 88,096 → 24,128 B |
| Set `Enum.reduce` | 20,000 | 289.791 | 242.125 | 16.4% | 1,760,096 → 480,128 B |
| Set `Enum.reduce` | 100,000 | 1,418.563 | 1,192.647 | 15.9% | 8,800,096 → 2,400,128 B |
| Full map range | 32 | 0.333 | 0.125 | 62.5% | 4,120 → 1,328 B |
| Full map range | 1,000 | 13.667 | 3.375 | 75.3% | 128,024 → 40,048 B |
| Full map range | 20,000 | 581.770 | 125.208 | 78.5% | 2,366,648 → 800,048 B |
| Full map range | 100,000 | 3,280.417 | 1,253.938 | 61.8% | 12,781,936 → 3,999,928 B |

Set allocation fell approximately 73% at 1,000 elements and above; full map
range allocation fell 66–69% across the measured sizes. Direct protocol
`Enumerable.reduce/3` set workloads improved 26–31% in the final pair. The initial
fold experiment showed larger gains, but those are not the actual `Enum.reduce`
results and should not be substituted for the table above.

At 20,000 elements, raw `:gb_sets.fold/3` took 157.958 µs with no measured heap
allocation for its arithmetic callback, versus 242.125 µs / 480,128 B for the
library's `Enum.reduce`. Raw `:gb_trees.to_list/1` took 128.500 µs / 800,000 B,
close to the full-range fast path's 125.208 µs / 800,048 B. The small timing
difference does not imply that the wrapper is inherently faster. Raw bounded
map iteration remains a separate reference in the complete results.

### Map enumeration uncertainty

Map enumeration allocation is unchanged. Timing was inconsistent, including a
77% regression at 20,000 elements in the first actual `Enum.reduce` pair. A
reverse-order repeat ran the optimized version first, with 2 seconds timing,
0.5 seconds warmup, and 0.2 seconds memory measurement per job:

| Elements | Initial before → after, µs | Repeat before → after, µs |
|---|---:|---:|
| 1,000 | 13.958 → 13.834 | 14.041 → 13.541 |
| 20,000 | 296.458 → 525.063 | 315.958 → 284.458 |
| 100,000 | 1,723.313 → 1,504.917 | 2,818.000 → 1,674.333 |

The 20,000-element regression did not repeat. The candidate comparisons and
repeat support a modest benefit from the small continuing-loop change, which
was retained after independent review. However, the 100,000-element baseline
moved substantially between runs, and direct protocol timings also swung in
both directions, including a 63% regression at 100,000 in the initial pair.
There is no stable general percentage improvement to claim for map enumeration.
The raw map reference also varies; the repeat's apparent 3.6% improvement at
1,000 elements is only about 1.2% after normalizing by that reference.

### Tradeoffs

- Halting set reduction after five elements costs another 58–158 ns in the final
  pair (roughly 1.7–2.7× total time). Allocation drops from 696–872 B to 408–504 B.
- Suspending after every set element is about 13% slower at size 32 and 4–6%
  faster at larger sizes in this run. The first suspension adds a seek; later
  resumptions use the iterator. The separate singleton experiment showed a
  suspension cost of 125 ns versus 42 ns. These fixed costs matter for short work.
- Ten-element map ranges add 0–42 ns in the final pair, and 24 B of allocation,
  for the coverage check. The candidate run showed up to 58 ns additional time.
  Nearly full ranges remain on the iterator path and changed approximately
  −4% to +2% in the final pair; they do not receive the full-coverage speedup.
- Empty and reversed ranges remain covered by tests and timing workloads.
  Construction, insertion, conversion, and set range code did not change in this
  follow-up; their broader measurements remain in the initial review.

Complete evidence: [paired baseline](traversal-benchmarks/paired-baseline.json),
[paired optimized version](traversal-benchmarks/paired-current.json),
[mean/median comparison](traversal-benchmarks/final-comparison.csv),
[repeat baseline](traversal-benchmarks/map-repeat-baseline.json),
[repeat optimized version](traversal-benchmarks/map-repeat-current.json), and
[source/harness integrity](traversal-benchmarks/final-evidence-integrity.json).
The JSON includes every selected measurement, including regressions and raw
references. These workload-specific observations do not establish a universal
speedup or predict other hardware, runtimes, callbacks, or data distributions.

## Reproduction and baseline

The corrected baseline was saved before the performance edits. The
[baseline patch](traversal-baseline.patch), applied to commit
`61ca0f5c50dbdbc8db78b09c9f0dc32006fb9b49`, reconstructs its production code and
build configuration. The reconstructed files were checked byte-for-byte against
that saved baseline. The comparison script uses separate build directories and
runs the same harness against baseline and working-tree versions sequentially.
Before committing, blank context lines in the saved patch and CSV line endings
were normalized for Git's whitespace checks. The patch still reconstructs all
12 recorded source hashes exactly; historical checksum files retain the original
patch checksum.

```sh
BENCH_TIME=1.0 BENCH_WARMUP=0.3 BENCH_MEMORY=0.2 \
  bash bench/traversal_compare.sh /tmp/ordered-traversal-comparison
```

Use a fresh output directory. Dependencies must already be available in `deps/`.
`BENCH_SIZES` and `BENCH_FILTER` select sizes and jobs. JSON files record source
and harness hashes, runtime details, sample counts, averages, medians, variation,
and correctness preflight results. Setup is excluded from operation timings.
The reverse-order repeat's exact working directories, environment variables, and
commands are retained in its [optimized-run log](traversal-benchmarks/map-repeat-current.log)
and [baseline-run log](traversal-benchmarks/map-repeat-baseline.log); substitute
the output directory created by the comparison script for the recorded temporary
directory when reproducing those commands.

Measurements use an Apple M3, 16 GiB RAM, Elixir 1.19.5, Erlang/OTP 29.0.1
(ERTS 17.0.1), eight schedulers, and Benchee with parallelism 1. Each job has
0.3 seconds warmup, 1 second timing, and 0.2 seconds memory measurement at
32, 1,000, 20,000, and 100,000 elements. Memory figures are Benchee's per-call
allocation measurements, not retained memory or peak resident size. Submicrosecond
jobs have substantial timing noise; small percentage differences are not reliable
evidence of a general speedup. Raw Erlang references omit protocol overhead.

## Correctness safeguards

Fourteen additional tests passed against the unchanged corrected implementation
before optimization. They exercise long traversals followed by halt or suspension,
replacement accumulators, nested reductions, callback throws/errors/exits, and
full, nearly full, narrow, mixed-term, and numeric-equivalent range boundaries.
The existing tests cover initial signals, repeated resumption, exhaustion, and
empty collections. Accepted test hashes are checked after implementation.

Final validation passed:

- `mix test`: 110 doctests, 169 tests, zero failures.
- Focused protocol and regression trace: 14 doctests, 80 tests, zero failures.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`,
  `mix dialyzer`, and `mix docs`.
- All 17 accepted test-file hashes remain unchanged; `git diff --check` passes.

Evidence: [full tests](traversal-benchmarks/final-full-test.log),
[focused trace](traversal-benchmarks/final-focused-trace.log),
[format](traversal-benchmarks/final-format.log),
[compile](traversal-benchmarks/final-compile.log),
[Dialyzer](traversal-benchmarks/final-dialyzer.log),
[docs](traversal-benchmarks/final-docs.log), and
[test hashes](traversal-benchmarks/final-test-hash-check.json).
The Dialyzer log retains an intermediate opaque-type warning and the subsequent
passing run. A private dispatcher fixed the continuation's type inference;
no warning suppression was added.

The project now requires Elixir 1.19.5 or later in the 1.x series. This requirement
was raised after these measurements; all measurements already used 1.19.5.
The library source, tests, benchmark scripts, and dependencies are unchanged by
the version-requirement update. Recorded benchmark hashes retain the original
`mix.exs` requirement rather than rewriting historical evidence. Fresh validation
of the upgraded requirement is recorded in
[the upgrade validation log](elixir-upgrade-validation.log).
