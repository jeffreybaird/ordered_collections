# OrderedCollections
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
For detailed usage see our [docs](https://hexdocs.pm/ordered_collections/api-reference.html)

**OrderedCollections** is a library for Elixir that provides efficient, sorted data structures:

`SortedMap` and `SortedSet` wrap Erlang’s `:gb_trees` and `:gb_sets` for easy use in Elixir.

## Features

- **SortedMap**
  - Insert, update, and delete key-value pairs while preserving sorted order.
  - Fast lookups using `:gb_trees`
  - Range queries over keys.
  - Conversion to standard Elixir `Map` or list.
  - Implements `Enum` and `Collectable`

- **SortedSet**
  - Maintain a set of unique elements in sorted order.
  - Fast membership checks using `:gb_sets`
  - Union, intersection, and difference operations.
  - Range queries over elements.
  - Conversion to a standard Elixir `MapSet` or list.
  - Implements `Enum` and `Collectable`

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

Tested with a `SortedSet` with 10_000 integers and a `SortedMap` with 10_000 elements

Run on my local machine:

- Operating System: macOS
- CPU Information: Apple M3
- Number of Available Cores: 8
- Available memory: 16 GB
- Elixir 1.18.3
- Erlang 27.2.4
- JIT enabled: true

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
