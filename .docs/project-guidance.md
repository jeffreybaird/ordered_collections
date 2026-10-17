# OrderedCollections project guidance

## Scope and compatibility

This is an Elixir library providing `OrderedCollections.SortedSet` and
`OrderedCollections.SortedMap`, with delegates in `lib/ordered_collections.ex`.
Read the affected modules, tests, `mix.exs`, and relevant README sections before
editing. Verify reports from published archives against the current checkout.

- Preserve public function names, arities, argument order, return types, and
  documented missing-key behavior unless the user authorizes an API change.
- Keep `:gb_sets` and `:gb_trees` as the underlying structures. Prefer their public
  functions and iterators; do not pattern-match opaque tree nodes. Do not add Nx.
- Preserve Erlang term ordering and tree equality in collection operations.
  `Enumerable.member?/2` must separately honor Elixir's strict `===` contract,
  including complete map pairs and numeric equivalents such as `1` and `1.0`.
- Preserve immutable updates, set uniqueness, existing Collectable contents,
  and last-write-wins map collection. Stored `nil` is an existing value.
- The minimum Elixir version is specified in `mix.exs` (currently 1.19.5,
  with later 1.x releases allowed).
  Check protocol and Erlang API availability against supported versions; report
  the actual Elixir/OTP versions used for validation.
- Keep this a standalone library. Do not import deployment, database, Phoenix,
  Ruby, Cucumberex, or infrastructure requirements from reference repositories.

## Layout and changes

- `lib/ordered_collections/`: collections and protocol implementations.
- `test/`: ExUnit unit, protocol, and doctest coverage.
- `bench/`: Benchee scripts and reproducible comparison workloads.
- `mix.exs`, `mix.lock`, `.formatter.exs`: build, dependencies, formatting.
- Generated `_build/`, `deps/`, `doc/`, and package archives are not source.

Keep changes focused. Preserve unrelated user work. Do not bump the version,
publish a Hex package, or push a release as part of an ordinary fix. Write code,
documentation, commits, and PR descriptions normally; keep conversation concise.

## Tests and doctests

Add regression tests that fail for the reported reason before fixing a bug.
Exercise observable behavior rather than tree shape or private implementation.
Test both collections where a protocol contract applies. Relevant cases include
empty and populated inputs, early halt, initial and callback suspension, repeated
resumption, stepped and negative-index slices, numeric equivalents, duplicate
construction, stored `nil`, and inclusive range boundaries.

Every module with `iex>` examples must be registered with `doctest` in ExUnit and
executed by normal `mix test`. Demonstrate representative successful behavior;
fallback/error examples alone are insufficient. Predicates need a true example.
Keep useful edge cases in addition to successful examples. Empty constructors
should demonstrate their intended empty result. Review examples against an
implementation that always returns the fallback value. Use stable clocks or
generous relative offsets for any future time-dependent examples.

## Validation

Format changed Elixir files before final validation. Run and record:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix test <affected test paths> --trace
mix dialyzer
```

The focused trace supplies readable behavioral evidence; it does not replace the
full suite. Run `mix docs` when public documentation changes. Report pre-existing
failures separately. Never claim an unavailable tool, blocked download, missing
PLT, or unrun supported-version check passed. Do not weaken checks to get green.

Review dependency advisories with current data when dependencies change or a
security review is requested; use available Hex audit tooling and report coverage
limits. Avoid unrelated dependency upgrades during a collection bug fix.

## Performance evidence

Correctness comes first. Retain optional optimizations only when representative
measurements support them. Compare against a recorded original revision and
equivalent raw Erlang operations on the same runtime, inputs, and machine.
Cover construction, insertion hits/misses, conversion, narrow/full ranges, full
enumeration, and early termination at small, medium, and large sizes. Measure
memory where supported. Exclude setup from operation timing unless construction
is the operation being measured. Record sizes, durations, warmup, runtime,
hardware, commands, failures, and allocation methodology. A baseline operation
that crashes is a correctness failure, not a timing result. Report regressions
and workload-specific tradeoffs; do not claim universal speedups.

## Review and delivery

Review public delegates and protocol entry points before declaring code unused;
external library callers do not appear in repository searches. Remove confirmed
obsolete private code while retaining coverage for live behavior. Explain any
test replacement and its replacement coverage; never delete a failing test just
to pass. Make focused, complete commits only with green validation when commits
are requested or otherwise part of the agreed delivery.

Deliver a concise explanation of changed behavior, compatibility decisions,
actual validation, benchmark results, and remaining limitations. PR descriptions
should include focused ExUnit trace or representative scenario content and the
commands/results, with longer evidence linked or collapsed. Do not invent
acceptance tooling this repository does not use.
