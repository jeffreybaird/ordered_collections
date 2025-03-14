# OrderedCollections

[![Hex.pm version](https://img.shields.io/hex/v/ordered_collections.svg)](https://hex.pm/packages/ordered_collections)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
For detailed usage see our [docs](https://hexdocs.pm/ordered_collections/api-reference.html)

**OrderedCollections** is a library for Elixir that provides efficient, sorted data structures:

## Why Use `SortedMap` and `SortedSet`?

By default, Elixir provides powerful data structures like `Map` and `MapSet`—both of which rely on hashing and do not store their elements in any particular order. In many use-cases, that’s sufficient. However, there are scenarios where **ordering** is essential:

1. **Range Queries and Ordered Iteration**
   If you need to iterate elements in ascending or descending order, or retrieve all items that fall within a given key or value range, a hash-based structure like `Map` or `MapSet` requires a full sort after-the-fact. In contrast, `SortedMap` and `SortedSet` store data in a balanced tree (via Erlang’s `:gb_trees` or `:gb_sets`) so that retrieving elements in sorted order is quick and efficient (O(n) to walk the tree, with O(log n) operations to find the start).

2. **Consistent Performance for Insert, Update, and Lookup**
   While Elixir’s `Map` and `MapSet` already provide close to O(1) average performance for membership and insertion, using a balanced tree ensures O(log n) in the worst case for many operations, with the additional benefit of the data remaining in sorted order at all times. That means tasks like “find the minimum key” or “find all elements after X” become straightforward and efficient without extra sorting overhead.

3. **Integration with Erlang Data Structures**
   Both `SortedMap` and `SortedSet` wrap Erlang’s battle-tested `:gb_trees` and `:gb_sets`. These are well-optimized data structures that have been part of the Erlang standard library for years. By exposing a more Elixir-friendly API on top of these, you get a seamless experience in Elixir while reaping the benefits of Erlang’s robust implementation.

4. **Balance Between Ease of Use and Power**
   `SortedMap` and `SortedSet` provide functions that mirror typical Elixir data-structure patterns (e.g., `put`, `delete`, `get`, etc.), as well as specialized calls like `range/3` for retrieving subranges of elements or keys. This bridges the gap between the built-in `Map`/`MapSet` and more advanced, tree-based containers—giving you a clean, readable syntax plus ordering guarantees.

In short, if you need a data structure that’s **ordered**, allows **fast range queries**, and can handle **logarithmic** insert/lookups/deletions in a straightforward way, `SortedMap` and `SortedSet` may be exactly what you’re looking for.

## Features

- **SortedMap**
  - Insert, update, and delete key-value pairs while preserving sorted order.
  - Fast lookups using `:gb_trees` (O(log n) performance).
  - Range queries over keys.
  - Conversion to standard Elixir `Map` or list.

- **SortedSet**
  - Maintain a set of unique elements in sorted order.
  - Fast membership checks using `:gb_sets` (O(log n) performance).
  - Union, intersection, and difference operations.
  - Range queries over elements.
  - Conversion to a standard Elixir `MapSet` or list.

## Installation

Add `ordered_collections` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ordered_collections, "~> 0.1.1"}
  ]
end
```

## Benchmarks

Run on my local machine:

Operating System: macOS
CPU Information: Apple M3
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.18.3
Erlang 27.2.4
JIT enabled: true

| **Operation**    | **Structure** | **IPS**   | **Avg (ms)** | **Comparison**                           |
|------------------|---------------|-----------|--------------|------------------------------------------|
| **Map Delete**   | gb_trees      | 262.38    | 3.81         | –                                        |
|                  | SortedMap     | 226.38    | 4.42         | 1.16× slower, +0.61 ms                   |
| **Map Insert**   | gb_trees      | 342.90    | 2.92         | –                                        |
|                  | SortedMap     | 293.90    | 3.40         | 1.17× slower, +0.49 ms                   |
| **Map Lookup**   | gb_trees      | 308.63    | 3.24         | –                                        |
|                  | SortedMap     | 257.60    | 3.88         | 1.20× slower, +0.64 ms                   |
| **Set Delete**   | :gb_sets      | 300.08    | 3.33         | –                                        |
|                  | SortedSet     | 298.92    | 3.35         | 1.00× slower, +0.013 ms                  |
| **Set Insert**   | :gb_sets      | 520.44    | 1.92         | –                                        |
|                  | SortedSet     | 516.41    | 1.94         | 1.01× slower, +0.015 ms                  |
| **Set Lookup**   | :gb_sets      | 407.20    | 2.46         | –                                        |
|                  | SortedSet     | 373.51    | 2.68         | 1.09× slower, +0.22 ms                   |
