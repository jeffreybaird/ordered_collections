defmodule SortedMapTest do
  use ExUnit.Case
  alias OrderedCollections.SortedMap
  doctest SortedMap

  import DialyzerHelper

  test "creates an empty map" do
    assert SortedMap.new() |> SortedMap.to_list() == []
  end

  test "creates a new sorted map from a map" do
    assert SortedMap.new(%{b: 2, a: 1}) |> SortedMap.to_map() == %{a: 1, b: 2}
  end

  test "raises a FunctionClauseError when put is given a non-map" do
    assert_raise FunctionClauseError, fn ->
      dialyzer_warning_ignore(&SortedMap.new/1, 1)
    end
  end

  test "returns the keys for a map" do
    map = SortedMap.new(%{b: 2, a: 1})
    assert SortedMap.keys(map) == [:a, :b]
  end

  test "handles an empty map" do
    map = SortedMap.new()
    assert SortedMap.keys(map) == []
  end

  test "raises a FunctionClauseError when keys is given a non-map" do
    assert_raise FunctionClauseError, fn ->
      dialyzer_warning_ignore(&SortedMap.keys/1, 1)
    end
  end

  test "raises an error when get is given a non-map" do
    assert_raise FunctionClauseError, fn ->
      l = [a: 1]
      dialyzer_warning_ignore(&SortedMap.get/3, [l, :a, 1])
    end
  end

  test "returns values for a map" do
    map = SortedMap.new(%{b: 2, a: 1})
    assert SortedMap.values(map) == [1, 2]
  end

  test "handles an empty map valuex" do
    map = SortedMap.new()
    assert SortedMap.values(map) == []
  end

  test "raises a FunctionClauseError when values is given a non-map" do
    assert_raise FunctionClauseError, fn ->
      dialyzer_warning_ignore(&SortedMap.values/1, 1)
    end
  end

  test "merges two maps" do
    map1 = SortedMap.new(%{a: 1, b: 2})
    map2 = SortedMap.new(%{b: 3, c: 4})
    merged_map = SortedMap.merge(map1, map2) |> SortedMap.to_list()
    expected = SortedMap.new(%{a: 1, b: 3, c: 4}) |> SortedMap.to_list()
    assert merged_map == expected
  end

  test "merges with an empty map" do
    map1 = SortedMap.new(%{a: 1, b: 2})
    map2 = SortedMap.new()
    assert SortedMap.merge(map1, map2) == SortedMap.new(%{a: 1, b: 2})
  end

  test "raises a FunctionClauseError when merge is given a non-map" do
    assert_raise FunctionClauseError, fn ->
      dialyzer_warning_ignore(&SortedMap.merge/2, [%{}, 1])
    end
  end

  test "inserts and retrieves values" do
    map = SortedMap.new() |> SortedMap.put(:a, 10) |> SortedMap.put(:b, 20)
    assert SortedMap.get(map, :a) == 10
    assert SortedMap.get(map, :b) == 20
    assert SortedMap.get(map, :c, "default") == "default"
  end

  test "inserts a nil value" do
    map = SortedMap.new() |> SortedMap.put(:a, nil)
    assert SortedMap.get(map, :a) == nil
  end

  test "raises a FunctionClauseError when given a non-map" do
    assert_raise FunctionClauseError, fn ->
      dialyzer_warning_ignore(&SortedMap.put/3, [%{}, :a, 1])
    end
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
