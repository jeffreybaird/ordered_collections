# Changelog

## Unreleased

### Compatibility

- Require Elixir 1.19.5 or later in the 1.x series. Elixir 1.18 and earlier
  1.19 patch releases are no longer supported. This is an intentional project
  baseline change, not a requirement introduced by the collection algorithms.
- `Enumerable.member?/2` compares stored elements and complete map pairs with
  strict Elixir equality. Collection operations retain Erlang numeric equality.
- Treat the accumulator returned by `Collectable.into/1` as opaque and pass it
  only to its collector function. Only completion with `:done` returns the final
  collection. SortedSet collection now uses a raw Erlang set while accumulating.

### Fixed

- Correct Enumerable exhaustion, early halt, suspension, and repeated resumption.
- Honor stepped slices and support duplicate set construction.
- Pass stored `nil` values to map update callbacks.
- Preserve existing collection contents and map last-write-wins behavior during
  collection.

### Performance

- Reduce conversion and bounded-range work, and optimize full map ranges and
  full set traversal using public Erlang APIs.
- Full set traversal uses less allocation at the cost of higher early-halt and
  first-suspension overhead. See the [measured tradeoffs](.docs/traversal-performance.md)
  and [broader comparison](.docs/review-results.md).

These changes are not published. The package version remains unchanged until a
release is prepared; that release must identify the raised Elixir requirement.
