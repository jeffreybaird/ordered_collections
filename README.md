# OrderedCollections

[![Hex.pm version](https://img.shields.io/hex/v/ordered_collections.svg)](https://hex.pm/packages/ordered_collections)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**OrderedCollections** is a library for Elixir that provides efficient, sorted data structures:
- **SortedMap:** A key-value store that maintains keys in sorted order, implemented as a thin wrapper around Erlang's `:gb_trees`.

## Features

- **SortedMap**
  - Insert, update, and delete key-value pairs while preserving sorted order.
  - Fast lookups using `:gb_trees` (O(log n) performance).
  - Range queries over keys.
  - Conversion to standard Elixir `Map` or list.

## Installation

Add `ordered_collections` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ordered_collections, "~> 0.1.1"}
  ]
end
```

For detailed usage see our [docs](https://hexdocs.pm/ordered_collections/api-reference.html)