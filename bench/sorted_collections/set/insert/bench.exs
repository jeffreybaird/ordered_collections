Mix.Task.run("app.start")
Code.require_file("bench/sorted_collections/test_data.ex")
alias OrderedCollections.SortedSet
alias OrderedCollections
alias TestData

# Core SortedSet operations
sorted_set_insert = fn ->
  Enum.reduce(TestData.set_values(), SortedSet.new(), fn k, acc ->
    SortedSet.add(acc, k)
  end)
end

# Convenience Set operations
set_insert = fn ->
  Enum.reduce(TestData.set_values(), OrderedCollections.new_set(), fn k, acc ->
    OrderedCollections.set_add_value(acc, k)
  end)
end

gb_set_insert = fn ->
  Enum.reduce(TestData.set_values(), :gb_sets.empty(), fn k, acc ->
    :gb_sets.insert(k, acc)
  end)
end

IO.puts("=== Set Insert Operations ===")

Benchee.run(%{
  "Insert - SortedSet (Core)" => sorted_set_insert,
  "Insert - SortedSet (Convenience)" => set_insert,
  "Insert - :gb_sets" => gb_set_insert
})
