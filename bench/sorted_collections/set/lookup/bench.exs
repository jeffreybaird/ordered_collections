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
sorted_set_lookup = fn ->
  Enum.each(TestData.set_values(), fn k ->
    SortedSet.member?(sorted_set, k)
  end)
end

# Convenience Set operations
set_lookup = fn ->
  Enum.each(TestData.set_values(), fn k ->
    OrderedCollections.set_member?(convenience_set, k)
  end)
end

gb_set_lookup = fn ->
  Enum.each(TestData.set_values(), fn k ->
    :gb_sets.is_member(k, gb_set)
  end)
end

IO.puts("=== Set Lookup Operations ===")

Benchee.run(%{
  "SortedSet Lookup (Core)" => sorted_set_lookup,
  "SortedSet Lookup (Convenience)" => set_lookup,
  ":gb_sets Lookup" => gb_set_lookup
})
