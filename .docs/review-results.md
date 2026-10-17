# OrderedCollections correctness and performance review

This report records the initial correctness change. Its “current” measurements
refer to that implementation before the subsequent
[traversal performance follow-up](traversal-performance.md), which compares
against this corrected implementation and documents the final traversal choices.

## Scope and compatibility

Reviewed the current 0.3.3 checkout at
`61ca0f5c50dbdbc8db78b09c9f0dc32006fb9b49`, rather than assuming the findings from
the published 0.3.2 archive still applied. All reported correctness problems were
present. Public collection functions, argument order, return types, and underlying
Erlang trees are preserved; no dependencies or package version changed.

- Both Enumerable reducers use public Erlang iterators, return `{:done, acc}`
  on exhaustion, and preserve the remaining iterator across all halt/suspend/
  resume paths. Opaque-node traversal code was removed.
- Membership checks the actual stored element with strict `===`, including both
  parts of map pairs; non-pair map queries return false. Collection-level set
  membership and map key lookup retain Erlang equality. This distinction follows
  the [Elixir 1.18 Enumerable contract](https://hexdocs.pm/elixir/1.18.4/Enumerable.html#member?/2).
- Slices honor step and stop after the requested elements. Small prefixes no
  longer materialize an entire set. Negative indices are normalized by Enum.
- Set list construction uses `:gb_sets.from_list/1`; other enumerables and `add/2`
  use duplicate-safe `:gb_sets.add/2`. Numeric equivalents occupy one position.
- Both map update arities pass stored `nil` to the callback. Missing keys still
  insert the documented default without invoking the callback.
- Map conversion builds directly from pairs; values use `:gb_trees.values/1`.
  Inclusive ranges seek with `iterator_from/2` and stop above the upper bound;
  set ranges build from already ordered unique elements with `from_ordset/1`.
- Collectable implements only `{:cont, element}`, `:done`, and `:halt`, matching
  the [Elixir 1.18 contract](https://hexdocs.pm/elixir/1.18.4/Collectable.html#into/1).
  Set collection accumulates a raw tree and wraps on completion. Map collection
  keeps its existing struct accumulator. Existing contents, set equality, and
  map last-write-wins behavior are covered by tests.
- Map `put/3` uses `:gb_trees.enter/3` instead of insert plus a broad rescue.
  Empty-map construction now uses the public tree constructor, and invalid set
  input raises `FunctionClauseError` with valid exception options. These small
  corrections resolve the baseline Dialyzer findings without suppressions.

`SortedMap.new/1` still accepts a native map, not a pair list. Its existing error
when a native map contains both `1` and `1.0` as separate keys is unchanged.
For sequential equivalent-key writes, use `put/3` or Collectable. A float-key
overwrite preserves Erlang's stored-key replacement behavior. The internal
Collectable accumulator is protocol-private; callers must use the collector and
its completion result.

## Tests and checks

The unchanged baseline passed 106 doctests and 112 tests. Added regressions
produced 31 failures before production changes: membership, duplicate
construction, stored-nil updates, and Enumerable control/slice behavior. An
independent reviewer accepted that test contract before implementation.

The additions cover 43 regression tests, including repeated suspension through
pending ancestors, resumption after the last element, callback suppression on
halt, zip/take, contiguous and stepped slices, negative/out-of-range indices,
numeric equivalents (including nested terms), and empty/reversed/boundary/full
ranges. Existing invalid Collectable suspension examples were replaced with
valid collection coverage. All accepted test hashes remained unchanged during
implementation.

Two previously unregistered test-helper doctests referenced a nonexistent API.
They now demonstrate successful calls and run normally: test support is compiled
only in the test environment. All modules with `iex>` examples are registered.
Additional source doctests exercise duplicate construction and a stored-nil update.

Final frozen-source validation passed:

| Check | Result |
| --- | --- |
| Full `mix test` | 110 doctests, 155 tests, zero failures |
| Focused `mix test ... --trace` | 14 doctests, 66 tests, zero failures |
| `mix format --check-formatted` | Passed |
| `mix compile --warnings-as-errors` | Passed |
| `mix dialyzer` | Zero errors, no suppressions added |
| `mix docs` | Passed |

See the [original failing regressions](red-tests.log) and
[final command output](validation.log). Validation uses Elixir 1.19.5 and
Erlang/OTP 29.0.1; no Elixir 1.18 runtime was installed, so execution on the
then-declared minimum series was unverified. The project subsequently raised its
minimum to Elixir 1.19.5, the runtime already used for these measurements; see the
[upgrade validation log](elixir-upgrade-validation.log). The initial Dialyzer run reported
three pre-existing type warnings plus errors formatting those diagnostics on
OTP 29; the final run has no warnings to format and exits successfully.

## Measured results

The final sequential runs used an Apple M3, 8 schedulers, 16 GiB RAM, the runtime
above, deterministic inputs of 32, 1,000, and 20,000 elements, and Benchee with
0.1 seconds warmup, 0.4 seconds timing, 0.1 seconds memory measurement per job,
and `parallel: 1`. Setup is outside timed closures. Memory is total per-operation
process allocation, including garbage-collected allocations, not retained heap
or RSS. These short exploratory measurements have substantial variance in some
jobs; small differences should not be interpreted as reliable speedups.

The table uses **mean microseconds per operation** at 20,000 elements. Full
statistics include medians, dispersion, and sample counts. Raw columns use public
Erlang operations and iterator loops with equivalent results.

| Operation | Original µs | Updated µs | Raw µs |
| --- | ---: | ---: | ---: |
| Set construction | 2,497.69 | 1,248.78 | 1,227.72 |
| Map construction (unchanged) | 2,990.77 | 3,853.66 | 3,106.10 |
| Map insertion hit | 0.415 | 0.152 | 0.128 |
| Map insertion miss | 0.104 | 0.130 | 0.137 |
| Map conversion to native map | 17,519.48 | 1,919.49 | 1,870.00 |
| Map values | 408.63 | 101.10 | 102.04 |
| Set narrow range (10 elements) | 143.719 | 0.223 | 0.478 |
| Map narrow range (10 pairs) | 343.056 | 0.201 | 0.281 |
| Set full range | 5,878.84 | 335.63 | 511.83 |
| Map full range | 208.22 | 334.23 | 571.46 |
| Set full enumeration | 303.96 | 472.76 | 128.65 |
| Map full enumeration | 211.90 | 305.22 | 369.11 |
| Set prefix slice (5 elements) | 140.711 | 0.124 | 0.141 |
| Map early take (5 pairs) | 0.122 | 0.142 | 0.128 |
| Set early take (5 elements) | Failed | 0.163 | 0.160 |
| Set duplicate collection (40,000 inserts) | 3,346.86 | 3,848.75 | 2,805.42 |

At this size, mean set construction time approximately halved and map conversion
fell about ninefold. Bounded ranges and set prefix slicing show large gains.
These gains are not universal: map full-range traversal was about 61% slower,
full enumeration about 44% slower for maps and 56% for sets, map insertion misses
about 25% slower, and duplicate set collection about 15% slower. Correct reduction
control and bounded traversal take priority over the original traversal speed.
The `put/3` change trades improved existing-key writes for extra work on misses.

Allocation improvements are distinct from latency: map conversion fell from
44.77 MB to 0.85 MB, values from 2.08 MB to 0.32 MB, and set duplicate collection
from 4.16 MB to 0.96 MB per operation. The raw set collector was retained for its
measured allocation savings: isolated hit candidates at 20,000 inserts allocate
40 bytes instead of 800,000 bytes. The full collection workload also includes
protocol tuple allocations and does not show a universal latency improvement.
Miss candidates confirmed reduced allocation; timing varied between runs.
Raw map accumulation was deferred because its timing results were mixed,
including a 5.6% slowdown for the final 20,000-element candidate.

The unchanged map constructor also varied noticeably between runs, illustrating
benchmark noise and cross-run effects. Original sets were built by incremental
insertion while updated and raw sets use bulk construction; their tree shapes
differ. These comparisons include those layout effects and must not be presented
as isolated wrapper overhead. Direct `add/2` delegation simplifies the wrapper;
it does not imply that Erlang's `:gb_sets.add/2` performs a single tree search.

The baseline excluded 12 failed jobs across the three sizes: duplicate set
construction, early set termination, and both stepped slices. The updated run
completed all 168 jobs with zero correctness failures. Never compare the latency
of a crashing or incorrect baseline job with a successful implementation.

Saved evidence:

- [All 75 library comparisons, including raw timings and allocations](benchmarks/comparison.tsv)
- [Original full statistics and metadata](benchmarks/baseline-final.json)
- [Updated full statistics and metadata](benchmarks/current-final.json)
- [Collector candidates, including misses](benchmarks/collector-candidates-misses.json)
- [Longer 1,000-element miss repeat](benchmarks/collector-miss-1000-repeat.json)

The final source/harness hashes match the measured working tree and baseline
archive. The original and updated final runs used the identical harness.

## Reproduction

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix test test/ordered_collections/enumerable test/ordered_collections/collectable test/ordered_collections/collection_regression_test.exs test/support_test.exs --trace
mix dialyzer
mix docs
bash bench/comparison.sh /tmp/ordered-collections-comparison
elixir bench/summarize.exs /tmp/ordered-collections-comparison/baseline.json /tmp/ordered-collections-comparison/current.json > /tmp/ordered-collections-comparison/comparison.tsv
```

Use a fresh benchmark output directory. The script archives the recorded original
revision, shares dependency sources, uses separate baseline build output, and
runs both revisions sequentially with the same harness. It records source and
harness hashes because the updated implementation is an uncommitted working-tree
change over the original HEAD. Each library job must pass a comparison with its
raw equivalent before timing; failed jobs are reported without a timing result.

## Agent guidance adaptation

`AGENTS.md` and `CLAUDE.md` share library-specific project and workflow guidance.
Five matching native role definitions separate test writing, implementation,
execution, review, and coordination. Syntax, paired instructions, and local links
were checked. These are instruction files: no hooks, audit machinery, model
overrides, deployment infrastructure, or additional test frameworks were installed.
Native client discovery of the files has not been verified. This review used
native subagents with explicit role handoffs.

Dead-code review removed obsolete private traversal helpers and the redundant
conversion dependency. Public delegates remain available for external callers.
No live behavior tests were deleted to get a passing suite.
