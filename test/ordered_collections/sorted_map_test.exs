defmodule SortedMapTest do
  use ExUnit.Case
  alias OrderedCollections.SortedMap
  doctest SortedMap

  test "creates an empty map" do
    assert SortedMap.new() |> SortedMap.to_list() == []
  end

  test "creates a new sorted map from a map" do
    assert SortedMap.new(%{b: 2, a: 1}) |> SortedMap.to_map() == %{a: 1, b: 2}
  end

  test "inserts and retrieves values" do
    map = SortedMap.new() |> SortedMap.put(:a, 10) |> SortedMap.put(:b, 20)
    assert SortedMap.get(map, :a) == 10
    assert SortedMap.get(map, :b) == 20
    assert SortedMap.get(map, :c, "default") == "default"
  end

  test "updates a value in a sorted map" do
    map = SortedMap.new(%{a: 1, b: 2}) |> SortedMap.update_with_value(:a, 10)
    assert SortedMap.get(map, :a) == 10
  end

  test "updates a value with a function" do
    map = SortedMap.new(%{a: 1, b: 2}) |> SortedMap.update(:a, &(&1 + 10))
    assert SortedMap.get(map, :a) == 11
  end

  test "updates a value with a function that returns nil" do
    map = SortedMap.new(%{a: 1, b: 2}) |> SortedMap.update(:a, &(&1 + 10))
    assert SortedMap.get(map, :b) == 2
  end

  test "updates a value with a default" do
    map = SortedMap.new(%{a: 1, b: 2}) |> SortedMap.update(:c, &(&1 + 10), 10)
    assert SortedMap.get(map, :c) == 10
  end

  test "checks if a key exists" do
    map = SortedMap.new(%{a: 1, b: 2})
    assert SortedMap.has_key?(map, :a) == true
    assert SortedMap.has_key?(map, :c) == false
  end

  test "deletes keys" do
    map = SortedMap.new(%{a: 1, b: 2}) |> SortedMap.delete(:b)
    assert SortedMap.get(map, :b) == nil
  end

  test "delete a key that is not in the map" do
    map = SortedMap.new(%{a: 1, b: 2})
    assert SortedMap.delete(map, :c) == map
  end

  test "returns the smallest key" do
    map = SortedMap.new(%{a: 1, b: 2})
    assert SortedMap.min_key(map) == :a
  end

  test "returns the largest key" do
    map = SortedMap.new(%{a: 1, b: 2})
    assert SortedMap.max_key(map) == :b
  end

  test "returns a list sorted by keys" do
    map = SortedMap.new(%{b: 2, a: 1})
    assert SortedMap.to_list(map) == [{:a, 1}, {:b, 2}]
  end

  test "returns a map sorted by keys" do
    map = SortedMap.new(%{b: 2, a: 1})
    assert SortedMap.to_map(map) == %{a: 1, b: 2}
  end

  test "range queries work" do
    map = SortedMap.new(%{a: 1, b: 2, c: 3, d: 4})
    assert SortedMap.range(map, :b, :d) == [b: 2, c: 3, d: 4]
  end

  test "range query on an empty map" do
    map = SortedMap.new()
    assert SortedMap.range(map, :a, :z) == []
  end
end
