# bench/sorted_collections_bench.exs
defmodule TestModule do
  def range(tree, start, last) do
    tree
    |> Enum.filter(fn {n, _value} ->
      n >= start and n <= last
    end)
    |> Enum.sort_by(fn {n, _value} -> n end)
  end

  def gb_tree_range(map, min, max) do
    map
    |> :gb_trees.to_list()
    |> Enum.filter(fn {key, _} -> key >= min and key <= max end)
  end
end

Mix.Task.run("app.start")
alias OrderedCollections.SortedMap
alias OrderedCollections.SortedSet
alias OrderedCollections

# Prepare sample data for the benchmark
keys = Enum.to_list(1..10_000)
values = Enum.map(keys, fn k -> {k, k} end)

# Benchmark functions for SortedMap (core)
sorted_map_insert = fn ->
  Enum.reduce(values, SortedMap.new(), fn {k, v}, acc ->
    SortedMap.put(acc, k, v)
  end)
end

# Benchmark functions for SortedMap (convenience)
map_insert = fn ->
  Enum.reduce(values, OrderedCollections.new_map(), fn {k, v}, acc ->
    OrderedCollections.map_put(acc, k, v)
  end)
end

# Benchmark functions for gb_trees directly
gb_tree_insert = fn ->
  Enum.reduce(values, :gb_trees.empty(), fn {k, v}, acc ->
    :gb_trees.insert(k, v, acc)
  end)
end

unsorted_map_insert = fn ->
  Enum.reduce(values, %{}, fn {k, v}, acc ->
    Map.put(acc, k, v)
  end)
end

map = unsorted_map_insert.()
sorted_map = sorted_map_insert.()
convenience_map = map_insert.()
gb_list = gb_tree_insert.()

# Core SortedMap operations
sorted_map_lookup = fn map ->
  Enum.each(keys, fn k ->
    SortedMap.get(map, k)
  end)
end

sorted_map_delete = fn map ->
  Enum.each(keys, fn k ->
    _ = SortedMap.delete(map, k)
  end)
end

# Convenience Map operations
map_lookup = fn map ->
  Enum.each(keys, fn k ->
    OrderedCollections.map_get(map, k)
  end)
end

map_delete = fn map ->
  Enum.each(keys, fn k ->
    OrderedCollections.map_delete(map, k)
  end)
end

gb_tree_lookup = fn tree ->
  Enum.each(keys, fn k ->
    _ = :gb_trees.lookup(k, tree)
  end)
end

gb_tree_delete = fn tree ->
  Enum.each(keys, fn k ->
    _ = :gb_trees.delete_any(k, tree)
  end)
end

# Similarly for SortedSet vs :gb_sets:
# to simulate unsorted insertion
set_values = Enum.shuffle(keys)

# Core SortedSet operations
sorted_set_insert = fn ->
  Enum.reduce(set_values, SortedSet.new(), fn k, acc ->
    SortedSet.add(acc, k)
  end)
end

# Convenience Set operations
set_insert = fn ->
  Enum.reduce(set_values, OrderedCollections.new_set(), fn k, acc ->
    OrderedCollections.set_add_value(acc, k)
  end)
end

gb_set_insert = fn ->
  Enum.reduce(set_values, :gb_sets.empty(), fn k, acc ->
    :gb_sets.insert(k, acc)
  end)
end

sorted_set = sorted_set_insert.()
convenience_set = set_insert.()
gb_set = gb_set_insert.()

# Core SortedSet operations
sorted_set_lookup = fn set ->
  Enum.each(set_values, fn k ->
    SortedSet.member?(set, k)
  end)
end

sorted_set_delete = fn set ->
  Enum.each(set_values, fn k ->
    _ = SortedSet.delete(set, k)
  end)
end

# Convenience Set operations
set_lookup = fn set ->
  Enum.each(set_values, fn k ->
    OrderedCollections.set_member?(set, k)
  end)
end

set_delete = fn set ->
  Enum.each(set_values, fn k ->
    OrderedCollections.set_delete_value(set, k)
  end)
end

gb_set_lookup = fn set ->
  Enum.each(set_values, fn k ->
    :gb_sets.is_member(k, set)
  end)
end

gb_set_delete = fn set ->
  Enum.each(set_values, fn k ->
    _ = :gb_sets.delete_any(k, set)
  end)
end

# Run benchmarks using Benchee
IO.puts("=== Map Delete Operations ===")

Benchee.run(%{
  "Delete - SortedMap (Core)" => fn -> sorted_map_delete.(sorted_map) end,
  "Delete - SortedMap (Convenience)" => fn -> map_delete.(convenience_map) end,
  "Delete - gb_trees" => fn -> gb_tree_delete.(gb_list) end
})

IO.puts("=== Map Insert Operations ===")

Benchee.run(%{
  "Insert - SortedMap (Core)" => sorted_map_insert,
  "Insert - SortedMap (Convenience)" => map_insert,
  "Insert - gb_trees" => gb_tree_insert
})

IO.puts("=== Map Lookup Operations ===")

Benchee.run(%{
  "SortedMap Lookup (Core)" => fn -> sorted_map_lookup.(sorted_map) end,
  "SortedMap Lookup (Convenience)" => fn -> map_lookup.(convenience_map) end,
  "gb_trees Lookup" => fn -> gb_tree_lookup.(gb_list) end
})

IO.puts("=== Map Range Operations ===")

Benchee.run(%{
  "SortedMap Range (Core)" => fn ->
    SortedMap.range(sorted_map, 1000, 2000)
  end,
  "SortedMap Range (Convenience)" => fn ->
    OrderedCollections.map_range(convenience_map, 1000, 2000)
  end,
  "gb_trees Range" => fn -> TestModule.gb_tree_range(gb_list, 1000, 2000) end,
  "Elixir Range" => fn -> TestModule.range(map, 1000, 2000) end
})

IO.puts("=== Set Delete Operations ===")

Benchee.run(%{
  "Delete - SortedSet (Core)" => fn -> sorted_set_delete.(sorted_set) end,
  "Delete - SortedSet (Convenience)" => fn -> set_delete.(convenience_set) end,
  "Delete - :gb_sets" => fn -> gb_set_delete.(gb_set) end
})

IO.puts("=== Set Insert Operations ===")

Benchee.run(%{
  "Insert - SortedSet (Core)" => sorted_set_insert,
  "Insert - SortedSet (Convenience)" => set_insert,
  "Insert - :gb_sets" => gb_set_insert
})

IO.puts("=== Set Lookup Operations ===")

Benchee.run(%{
  "SortedSet Lookup (Core)" => fn -> sorted_set_lookup.(sorted_set) end,
  "SortedSet Lookup (Convenience)" => fn -> set_lookup.(convenience_set) end,
  ":gb_sets Lookup" => fn -> gb_set_lookup.(gb_set) end
})

IO.puts("=== Set Range Operations ===")

Benchee.run(%{
  "SortedSet Range (Core)" => fn ->
    SortedSet.range(sorted_set, 1000, 2000)
  end,
  "SortedSet Range (Convenience)" => fn ->
    OrderedCollections.set_range(convenience_set, 1000, 2000)
  end
})
