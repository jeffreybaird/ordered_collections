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

## Benchmark Results

The table below summarizes performance benchmarks comparing operations on different data structures. These benchmarks were run on macOS (Apple M3, 8 cores, 16 GB memory) using Elixir 1.18.3 and Erlang 27.2.4 with JIT enabled. The measurements show IPS (Iterations Per Second), average execution times, and a comparison between implementations.

### Delete Operations (Key-Value Stores)

| **Operation**    | **Structure**    | **IPS** | **Average Time** | **Deviation** | **Median**   | **99th Percentile** | **Comparison**                |
|------------------|------------------|---------|------------------|---------------|--------------|---------------------|-------------------------------|
| Delete           | gb_trees         | 1.11 K  | 901.71 μs        | ±7.36%       | 885.04 μs    | 1129.99 μs          | —                             |
| Delete           | SortedMap        | 1.02 K  | 985.20 μs        | ±4.89%       | 972.92 μs    | 1198.37 μs          | 1.09× slower (+83.48 μs)       |

### Insert Operations (Key-Value Stores)

| **Operation**    | **Structure**    | **IPS** | **Average Time** | **Deviation** | **Median**   | **99th Percentile** | **Comparison**                |
|------------------|------------------|---------|------------------|---------------|--------------|---------------------|-------------------------------|
| Insert           | gb_trees         | 348.54  | 2.87 ms          | ±12.31%      | 2.85 ms      | 3.71 ms             | —                             |
| Insert           | SortedMap        | 298.88  | 3.35 ms          | ±9.82%       | 3.38 ms      | 4.21 ms             | 1.17× slower (+0.48 ms)       |

### Lookup Operations (Key-Value Stores)

| **Operation**    | **Structure**    | **IPS** | **Average Time** | **Deviation** | **Median**   | **99th Percentile** | **Comparison**                |
|------------------|------------------|---------|------------------|---------------|--------------|---------------------|-------------------------------|
| Lookup           | gb_trees         | 2.73 K  | 366.81 μs        | ±9.90%       | 361.96 μs    | 446.20 μs           | —                             |
| Lookup           | SortedMap        | 2.35 K  | 425.65 μs        | ±18.01%      | 415.50 μs    | 508.36 μs           | 1.16× slower (+58.84 μs)       |

### Range Operations (Key-Value Stores)

| **Operation**    | **Structure**    | **IPS** | **Average Time** | **Deviation** | **Median**   | **99th Percentile** | **Comparison**                |
|------------------|------------------|---------|------------------|---------------|--------------|---------------------|-------------------------------|
| Range            | SortedMap        | 8.85 K  | 113.04 μs        | ±3.73%       | 112.21 μs    | 130.50 μs           | —                             |
| Range            | gb_trees         | 8.39 K  | 119.25 μs        | ±32.45%      | 118.08 μs    | 136.58 μs           | 1.05× slower (+6.20 μs)        |
| Range            | Elixir (naive)   | 5.67 K  | 176.34 μs        | ±12.57%      | 173.63 μs    | 220.07 μs           | 1.56× slower (+63.29 μs)       |

### SET (Unique Elements) Delete Operations

| **Operation**    | **Structure**    | **IPS** | **Average Time** | **Deviation** | **Median**   | **99th Percentile** | **Comparison**                |
|------------------|------------------|---------|------------------|---------------|--------------|---------------------|-------------------------------|
| Delete           | SortedSet        | 684.77  | 1.46 ms          | ±4.06%       | 1.45 ms      | 1.67 ms             | —                             |
| Delete           | :gb_sets         | 684.39  | 1.46 ms          | ±4.65%       | 1.46 ms      | 1.68 ms             | ~Same performance             |

### SET (Unique Elements) Insert Operations

| **Operation**    | **Structure**    | **IPS** | **Average Time** | **Deviation** | **Median**   | **99th Percentile** | **Comparison**                |
|------------------|------------------|---------|------------------|---------------|--------------|---------------------|-------------------------------|
| Insert           | :gb_sets         | 554.92  | 1.80 ms          | ±7.06%       | 1.80 ms      | 2.15 ms             | —                             |
| Insert           | SortedSet        | 511.32  | 1.96 ms          | ±10.78%      | 1.92 ms      | 2.46 ms             | 1.09× slower (+0.154 ms)       |

### SET (Unique Elements) Lookup Operations

| **Operation**    | **Structure**    | **IPS** | **Average Time** | **Deviation** | **Median**   | **99th Percentile** | **Comparison**                |
|------------------|------------------|---------|------------------|---------------|--------------|---------------------|-------------------------------|
| Lookup           | :gb_sets         | 1.68 K  | 593.48 μs        | ±5.98%       | 586.30 μs    | 708.54 μs           | —                             |
| Lookup           | SortedSet        | 1.62 K  | 617.83 μs        | ±4.29%       | 614.80 μs    | 742.15 μs           | 1.04× slower (+24.36 μs)       |
