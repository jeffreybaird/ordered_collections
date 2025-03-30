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
sorted_map_delete = fn ->
  Enum.each(TestData.keys(), fn k ->
    _ = SortedMap.delete(sorted_map, k)
  end)
end

# Convenience Map operations
map_delete = fn ->
  Enum.each(TestData.keys(), fn k ->
    OrderedCollections.map_delete(convenience_map, k)
  end)
end

gb_tree_delete = fn ->
  Enum.each(TestData.keys(), fn k ->
    _ = :gb_trees.delete_any(k, gb_list)
  end)
end

IO.puts("=== Map Delete Operations ===")

Benchee.run(%{
  "Delete - SortedMap (Core)" => sorted_map_delete,
  "Delete - SortedMap (Convenience)" => map_delete,
  "Delete - gb_trees" => gb_tree_delete
})
