defmodule OrderedCollections.Enumerable.SortedMapTest do
  use ExUnit.Case, async: true
  alias OrderedCollections.SortedMap
  doctest Enumerable.OrderedCollections.SortedMap

  describe "Enumerable implementation for SortedMap" do
    test "Enum.count/1 returns the number of elements" do
      map = SortedMap.new(%{a: 1, b: 2, c: 3})
      assert Enum.count(map) == 3
    end

    test "Enum.member?/2 checks for key presence" do
      map = SortedMap.new(%{a: 1, b: 2})
      assert Enum.member?(map, {:a, 1})
      refute Enum.member?(map, {:c, 3})
    end

    test "Enum.reduce/3 iterates over elements" do
      map = SortedMap.new(%{a: 1, c: 3, b: 2})

      result = Enum.reduce(map, [], fn {key, _val}, acc -> [key | acc] end)

      assert result |> Enum.reverse() == [:a, :b, :c]
    end

    test "Enum.slice/2 retrieves a subrange" do
      map = SortedMap.new(%{a: 1, b: 2, c: 3, d: 4})

      assert Enum.slice(map, 1, 2) == [b: 2, c: 3]
      assert Enum.slice(map, 0, 3) == [a: 1, b: 2, c: 3]
    end

    test "Enum.slice/2 retrieves a subrange even if key order is different than val order" do
      map = SortedMap.new(%{"2025-01-01": 5, "2025-02-02": 3, "2025-03-03": 1, "2025-04-04": 2})

      assert Enum.slice(map, 1, 2) == ["2025-02-02": 3, "2025-03-03": 1]
      assert Enum.slice(map, 0, 3) == ["2025-01-01": 5, "2025-02-02": 3, "2025-03-03": 1]
    end
  end
end
