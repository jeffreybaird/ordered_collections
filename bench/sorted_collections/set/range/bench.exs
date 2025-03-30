Mix.Task.run("app.start")
Code.require_file("bench/sorted_collections/test_data.ex")
alias OrderedCollections.SortedSet
alias OrderedCollections
alias TestData

# Prepare test data
sorted_set =
  Enum.reduce(TestData.set_values(), SortedSet.new(), fn k, acc ->
    SortedSet.add(acc, k)
  end)

convenience_set =
  Enum.reduce(TestData.set_values(), OrderedCollections.new_set(), fn k, acc ->
    OrderedCollections.set_add_value(acc, k)
  end)

IO.puts("=== Set Range Operations ===")

Benchee.run(%{
  "SortedSet Range (Core)" => fn ->
    SortedSet.range(sorted_set, 1000, 2000)
  end,
  "SortedSet Range (Convenience)" => fn ->
    OrderedCollections.set_range(convenience_set, 1000, 2000)
  end
})
