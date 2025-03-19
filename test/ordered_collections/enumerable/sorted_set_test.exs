defmodule OrderedCollections.Enumerable.SortedSetTest do
  use ExUnit.Case, async: true
  alias OrderedCollections.SortedSet
  doctest Enumerable.OrderedCollections.SortedSet

  describe "Enumerable implementation for SortedSet" do
    test "Enum.count/1 returns the number of elements" do
      set = SortedSet.new([3, 1, 2])
      assert Enum.count(set) == 3
    end

    test "Handles and empty set" do
      set = SortedSet.new([])
      assert Enum.count(set) == 0
    end

    test "Enum.member?/2 checks for key presence" do
      set = SortedSet.new([3, 1, 2])
      assert Enum.member?(set, 1)
      refute Enum.member?(set, 4)
    end

    test "Enum.reduce/3 iterates over elements" do
      set = SortedSet.new([3, 1, 2])

      result = Enum.reduce(set, 0, fn x, acc -> x + acc end)

      assert result == 6
    end

    test "reduces a set of sets" do
      set = SortedSet.new([SortedSet.new([3, 1, 2]), SortedSet.new([4, 5, 6])])

      result = Enum.reduce(set, 0, fn x, acc -> Enum.reduce(x, acc, &+/2) end)

      assert result == 21
    end
  end
end
