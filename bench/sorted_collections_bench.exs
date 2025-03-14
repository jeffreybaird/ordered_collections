# bench/sorted_collections_bench.exs
Mix.Task.run("app.start")
alias OrderedCollections.SortedMap

# Prepare sample data for the benchmark
keys = Enum.to_list(1..10_000)
values = Enum.map(keys, fn k -> {k, k} end)

# Benchmark functions for SortedMap
sorted_map_insert = fn ->
  Enum.reduce(values, SortedMap.new(), fn {k, v}, acc ->
    SortedMap.put(acc, k, v)
  end)
end

sorted_map_lookup = fn ->
  map = sorted_map_insert.()
  Enum.each(keys, fn k ->
    SortedMap.get(map, k)
  end)
end

sorted_map_delete = fn ->
  map = sorted_map_insert.()
  Enum.each(keys, fn k ->
    _ = SortedMap.delete(map, k)
  end)
end

# Benchmark functions for gb_trees directly
gb_tree_insert = fn ->
  Enum.reduce(values, :gb_trees.empty(), fn {k, v}, acc ->
    :gb_trees.insert(k, v, acc)
  end)
end

gb_tree_lookup = fn ->
  tree = gb_tree_insert.()
  Enum.each(keys, fn k ->
    _ = :gb_trees.lookup(k, tree)
  end)
end

gb_tree_delete = fn ->
  tree = gb_tree_insert.()
  Enum.each(keys, fn k ->
    _ = :gb_trees.delete_any(k, tree)
  end)
end

# Similarly for SortedSet vs :gb_sets:
set_values = Enum.shuffle(keys)  # to simulate unsorted insertion

sorted_set_insert = fn ->
  Enum.reduce(set_values, SortedSet.new(), fn k, acc ->
    SortedSet.add(acc, k)
  end)
end

sorted_set_lookup = fn ->
  set = sorted_set_insert.()
  Enum.each(set_values, fn k ->
    SortedSet.member?(set, k)
  end)
end

sorted_set_delete = fn ->
  set = sorted_set_insert.()
  Enum.each(set_values, fn k ->
    _ = SortedSet.delete(set, k)
  end)
end

gb_set_insert = fn ->
  Enum.reduce(set_values, :gb_sets.empty(), fn k, acc ->
    :gb_sets.insert(k, acc)
  end)
end

gb_set_lookup = fn ->
  set = gb_set_insert.()
  Enum.each(set_values, fn k ->
    :gb_sets.is_member(k, set)
  end)
end

gb_set_delete = fn ->
  set = gb_set_insert.()
  Enum.each(set_values, fn k ->
    _ = :gb_sets.delete_any(k, set)
  end)
end

# Run benchmarks using Benchee
IO.puts("=== Delete Operations ===")
Benchee.run(%{
  "Delete - SortedMap" => sorted_map_delete,
  "Delete - gb_trees" => gb_tree_delete
})

IO.puts("=== Insert Operations ===")
Benchee.run(%{
  "Insert - SortedMap" => sorted_map_insert,
  "Insert - gb_trees" => gb_tree_insert
})

IO.puts("=== Lookup Operations ===")
Benchee.run(%{
  "SortedMap Lookup" => sorted_map_lookup,
  "gb_trees Lookup" => gb_tree_lookup,
})
