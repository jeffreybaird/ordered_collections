defmodule SortedMapTest do
  use ExUnit.Case
  doctest SortedMap

  test "creates an empty map" do
    assert SortedMap.new() |> SortedMap.to_list() == []
  end

  test "inserts and retrieves values" do
    map = SortedMap.new() |> SortedMap.put(:a, 10) |> SortedMap.put(:b, 20)
    assert SortedMap.get(map, :a) == 10
    assert SortedMap.get(map, :b) == 20
    assert SortedMap.get(map, :c, "default") == "default"
  end

  test "deletes keys" do
    map = SortedMap.new(%{a: 1, b: 2}) |> SortedMap.delete(:b)
    assert SortedMap.get(map, :b) == nil
  end

  test "range queries work" do
    map = SortedMap.new(%{a: 1, b: 2, c: 3, d: 4})
    assert SortedMap.range(map, :b, :d) == [b: 2, c: 3, d: 4]
  end
end
