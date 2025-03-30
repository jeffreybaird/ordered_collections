Mix.Task.run("app.start")
Code.require_file("bench/sorted_collections/test_data.ex")
alias OrderedCollections.SortedMap
alias OrderedCollections
alias TestData

# Prepare test data
sorted_map =
  Enum.reduce(TestData.values(), SortedMap.new(), fn {k, v}, acc ->
    SortedMap.put(acc, k, v)
  end)

convenience_map =
  Enum.reduce(TestData.values(), OrderedCollections.new_map(), fn {k, v}, acc ->
    OrderedCollections.map_put(acc, k, v)
  end)

gb_list =
  Enum.reduce(TestData.values(), :gb_trees.empty(), fn {k, v}, acc ->
    :gb_trees.insert(k, v, acc)
  end)

# Core SortedMap operations
sorted_map_lookup = fn ->
  Enum.each(TestData.keys(), fn k ->
    SortedMap.get(sorted_map, k)
  end)
end

# Convenience Map operations
map_lookup = fn ->
  Enum.each(TestData.keys(), fn k ->
    OrderedCollections.map_get(convenience_map, k)
  end)
end

gb_tree_lookup = fn ->
  Enum.each(TestData.keys(), fn k ->
    _ = :gb_trees.lookup(k, gb_list)
  end)
end

IO.puts("=== Map Lookup Operations ===")

Benchee.run(%{
  "SortedMap Lookup (Core)" => sorted_map_lookup,
  "SortedMap Lookup (Convenience)" => map_lookup,
  "gb_trees Lookup" => gb_tree_lookup
})
