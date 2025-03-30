Mix.Task.run("app.start")
Code.require_file("bench/sorted_collections/test_data.ex")
alias OrderedCollections.SortedMap
alias OrderedCollections
alias TestData

# Benchmark functions for SortedMap (core)
sorted_map_insert = fn ->
  Enum.reduce(TestData.values(), SortedMap.new(), fn {k, v}, acc ->
    SortedMap.put(acc, k, v)
  end)
end

# Benchmark functions for SortedMap (convenience)
map_insert = fn ->
  Enum.reduce(TestData.values(), OrderedCollections.new_map(), fn {k, v}, acc ->
    OrderedCollections.map_put(acc, k, v)
  end)
end

# Benchmark functions for gb_trees directly
gb_tree_insert = fn ->
  Enum.reduce(TestData.values(), :gb_trees.empty(), fn {k, v}, acc ->
    :gb_trees.insert(k, v, acc)
  end)
end

IO.puts("=== Map Insert Operations ===")

Benchee.run(%{
  "Insert - SortedMap (Core)" => sorted_map_insert,
  "Insert - SortedMap (Convenience)" => map_insert,
  "Insert - gb_trees" => gb_tree_insert
})
