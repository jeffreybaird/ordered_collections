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

unsorted_map =
  Enum.reduce(TestData.values(), %{}, fn {k, v}, acc ->
    Map.put(acc, k, v)
  end)

IO.puts("=== Map Range Operations ===")

Benchee.run(%{
  "SortedMap Range (Core)" => fn ->
    SortedMap.range(sorted_map, 1000, 2000)
  end,
  "SortedMap Range (Convenience)" => fn ->
    OrderedCollections.map_range(convenience_map, 1000, 2000)
  end,
  "gb_trees Range" => fn -> TestData.gb_tree_range(gb_list, 1000, 2000) end,
  "Elixir Range" => fn -> TestData.range(unsorted_map, 1000, 2000) end
})
