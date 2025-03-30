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

gb_set =
  Enum.reduce(TestData.set_values(), :gb_sets.empty(), fn k, acc ->
    :gb_sets.insert(k, acc)
  end)

# Core SortedSet operations
sorted_set_delete = fn ->
  Enum.each(TestData.set_values(), fn k ->
    _ = SortedSet.delete(sorted_set, k)
  end)
end

# Convenience Set operations
set_delete = fn ->
  Enum.each(TestData.set_values(), fn k ->
    OrderedCollections.set_delete_value(convenience_set, k)
  end)
end

gb_set_delete = fn ->
  Enum.each(TestData.set_values(), fn k ->
    _ = :gb_sets.delete_any(k, gb_set)
  end)
end

IO.puts("=== Set Delete Operations ===")

Benchee.run(%{
  "Delete - SortedSet (Core)" => sorted_set_delete,
  "Delete - SortedSet (Convenience)" => set_delete,
  "Delete - :gb_sets" => gb_set_delete
})
