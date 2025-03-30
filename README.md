# OrderedCollections
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
For detailed usage see our [docs](https://hexdocs.pm/ordered_collections/api-reference.html)

**OrderedCollections** is a library for Elixir that provides efficient, sorted data structures:

`SortedMap` and `SortedSet` wrap Erlang's `:gb_trees` and `:gb_sets` for easy use in Elixir.

## Features

- **SortedMap**
  - Insert, update, and delete key-value pairs while preserving sorted order.
  - Fast lookups using `:gb_trees`
  - Range queries over keys.
  - Conversion to standard Elixir `Map` or list.
  - Implements `Enum`, `Collectable`, `Inspect` and the new `JSON` protocol introduced in Elixir 1.18

- **SortedSet**
  - Maintain a set of unique elements in sorted order.
  - Fast membership checks using `:gb_sets`
  - Union, intersection, and difference operations.
  - Range queries over elements.
  - Conversion to a standard Elixir `MapSet` or list.
  - Implements `Enum`, `Collectable`, `Inspect` and the new `JSON` protocol introduced in Elixir 1.18

## Installation

Add `ordered_collections` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ordered_collections, "~> 0.3.2"}
  ]
end
```

## Benchmarks
### Running Benchmarks

To run the benchmarks for OrderedCollections, follow these steps:

1. Ensure your dependencies are up-to-date by running:
   mix deps.get

2. Compile the project:
   mix compile

3. Execute the benchmark suite:
   mix run bench/sorted_collections_bench.exs

This command will automatically locate and run all benchmark files under the "bench/sorted_collections/" directory. You can also run individual benchmark files if desired, for example:
   mix run bench/sorted_collections/<set|map>/bench.exs
or
  mix run bench/sorted_collections/<set|map>/<delete|insert|lookup|range>/bench.exs

Benchmarks are configured using [Benchee](https://github.com/bencheeorg/benchee). Feel free to modify the benchmark settings in the respective files as needed.

### Pre-executed Benchmarks
Below are the benchmark results for various map and set operations. Each section details the environment, benchmark configuration, results, and comparisons.

> **Note:** All benchmarks were executed on macOS using an Apple M3 CPU with 8 cores, 16 GB of memory, Elixir 1.18.3, Erlang 27.2.4, and JIT enabled.

### Environment
- **Operating System:** macOS
- **CPU:** Apple M3 (8 cores)
- **Memory:** 16 GB
- **Elixir:** 1.18.3
- **Erlang:** 27.2.4
- **JIT Enabled:** true

## Map Delete Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 21 s

### Results

| Test                             | ips     | Average  | Deviation | Median  | 99th %  |
|----------------------------------|---------|----------|-----------|---------|---------|
| Delete - gb_trees                | 1084.28 | 0.92 ms  | ±6.34%    | 0.91 ms | 1.10 ms |
| Delete - SortedMap (Core)        | 989.02  | 1.01 ms  | ±5.58%    | 1.00 ms | 1.23 ms |
| Delete - SortedMap (Convenience) | 986.13  | 1.01 ms  | ±4.84%    | 1.00 ms | 1.23 ms |

### Comparison
- **Delete - gb_trees:** 1084.28 ips
- **Delete - SortedMap (Core):** 989.02 ips (1.10× slower, +0.0888 ms)
- **Delete - SortedMap (Convenience):** 986.13 ips (1.10× slower, +0.0918 ms)

## Map Insert Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 21 s

### Results

| Test                                | ips     | Average  | Deviation  | Median  | 99th %  |
|-------------------------------------|---------|----------|------------|---------|---------|
| Insert - gb_trees                   | 329.53  | 3.03 ms  | ±38.68%    | 2.94 ms | 4.05 ms |
| Insert - SortedMap (Convenience)    | 334.44  | 3.99 ms  | ±16.76%   | 3.01 ms | 3.75 ms |
| Insert - SortedMap (Core)           | 329.17  | 3.04 ms  | ±23.13%    | 3.07 ms | 3.91 ms |

### Comparison
- **Insert - SortedMap (Convenience):**        334.44
- **Insert - gb_trees:**                       329.53 - 1.01x slower +0.0445 ms
- **Insert - SortedMap (Core):**               329.17 - 1.02x slower +0.0479 ms

## Map Lookup Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 21 s

### Results

| Test                           | ips   | Average    | Deviation | Median    | 99th %    |
|--------------------------------|-------|------------|-----------|-----------|-----------|
| gb_trees Lookup                | 2.69K | 371.12 μs  | ±6.40%    | 367.88 μs | 449.14 μs |
| SortedMap Lookup (Core)        | 2.28K | 437.72 μs  | ±13.92%   | 434.04 μs | 517.95 μs |
| SortedMap Lookup (Convenience) | 2.11K | 474.03 μs  | ±5.68%    | 473.25 μs | 562.01 μs |

### Comparison
- **gb_trees Lookup:** 2.69K ips
- **SortedMap Lookup (Core):** 2.28K ips (1.18× slower, +66.60 μs)
- **SortedMap Lookup (Convenience):** 2.11K ips (1.28× slower, +102.91 μs)

## Map Range Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 28 s

### Results

| Test                               | ips   | Average    | Deviation | Median    | 99th %    |
|------------------------------------|-------|------------|-----------|-----------|-----------|
| SortedMap Range (Convenience)      | 8.89K | 112.49 μs  | ±6.17%    | 111.58 μs | 127.67 μs |
| SortedMap Range (Core)             | 8.79K | 113.80 μs  | ±7.02%    | 112.92 μs | 132.33 μs |
| gb_trees Range                     | 8.42K | 118.71 μs  | ±6.46%    | 117.83 μs | 135.66 μs |
| Elixir Range                       | 5.43K | 184.15 μs  | ±101.67%  | 176.79 μs | 272.26 μs |

### Comparison
- **SortedMap Range (Convenience):** 8.89K ips
- **SortedMap Range (Core):** 8.79K ips (1.01× slower, +1.30 μs)
- **gb_trees Range:** 8.42K ips (1.06× slower, +6.22 μs)
- **Elixir Range:** 5.43K ips (1.64× slower, +71.66 μs)

## Set Delete Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 21 s

### Results

| Test                             | ips     | Average  | Deviation | Median  | 99th %  |
|----------------------------------|---------|----------|-----------|---------|---------|
| Delete - SortedSet (Core)        | 686.83  | 1.46 ms  | ±4.46%    | 1.46 ms | 1.67 ms |
| Delete - SortedSet (Convenience) | 675.48  | 1.48 ms  | ±9.15%    | 1.47 ms | 1.76 ms |
| Delete - :gb_sets                | 631.20  | 1.58 ms  | ±33.92%   | 1.47 ms | 2.35 ms |

### Comparison
- **Delete - SortedSet (Core):** 686.83 ips
- **Delete - SortedSet (Convenience):** 675.48 ips (1.02× slower, +0.0245 ms)
- **Delete - :gb_sets:** 631.20 ips (1.09× slower, +0.128 ms)

## Set Insert Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 21 s

### Results

| Test                                | ips     | Average  | Deviation | Median  | 99th %  |
|-------------------------------------|---------|----------|-----------|---------|---------|
| Insert - :gb_sets                   | 554.73  | 1.80 ms  | ±8.50%    | 1.79 ms | 2.26 ms |
| Insert - SortedSet (Convenience)    | 383.41  | 2.61 ms  | ±6.95%    | 2.60 ms | 3.19 ms |
| Insert - SortedSet (Core)           | 381.61  | 2.62 ms  | ±6.84%    | 2.62 ms | 3.15 ms |

### Comparison
- **Insert - :gb_sets:** 554.73 ips
- **Insert - SortedSet (Convenience):** 383.41 ips (1.45× slower, +0.81 ms)
- **Insert - SortedSet (Core):** 381.61 ips (1.45× slower, +0.82 ms)

## Set Lookup Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 21 s

### Results

| Test                               | ips    | Average    | Deviation | Median    | 99th %    |
|------------------------------------|--------|------------|-----------|-----------|-----------|
| :gb_sets Lookup                    | 1.68K  | 595.51 μs  | ±15.03%   | 586.25 μs | 716.88 μs |
| SortedSet Lookup (Core)            | 1.63K  | 615.22 μs  | ±9.16%    | 605.98 μs | 768.99 μs |
| SortedSet Lookup (Convenience)     | 1.60K  | 626.72 μs  | ±4.67%    | 627.91 μs | 738.40 μs |

### Comparison
- **:gb_sets Lookup:** 1.68K ips
- **SortedSet Lookup (Core):** 1.63K ips (1.03× slower, +19.70 μs)
- **SortedSet Lookup (Convenience):** 1.60K ips (1.05× slower, +31.21 μs)

## Set Range Operations

### Benchmark Configuration
- **Warmup:** 2 s
- **Time:** 5 s
- **Memory Time:** 0 ns
- **Reduction Time:** 0 ns
- **Parallel:** 1
- **Inputs:** none specified
- **Estimated Run Time:** 14 s

### Results

| Test                              | ips   | Average    | Deviation | Median    | 99th %    |
|-----------------------------------|-------|------------|-----------|-----------|-----------|
| SortedSet Range (Convenience)     | 3.28K | 305.11 μs  | ±36.98%   | 259.12 μs | 651.30 μs |
| SortedSet Range (Core)            | 2.27K | 441.03 μs  | ±11.94%   | 430.75 μs | 759.20 μs |

### Comparison
- **SortedSet Range (Convenience):** 3.28K ips
- **SortedSet Range (Core):** 2.27K ips (1.45× slower, +135.92 μs)
