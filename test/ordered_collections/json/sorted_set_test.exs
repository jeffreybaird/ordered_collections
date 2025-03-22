defmodule OrderedCollections.JSON.SortedSetTest do
  use ExUnit.Case, async: true
  doctest JSON.Encoder.OrderedCollections.SortedSet

  alias OrderedCollections.SortedSet

  test "JSON encoding of an empty SortedSet" do
    set = SortedSet.new()
    assert JSON.encode!(set) == "[]"
  end

  test "JSON encoding of a SortedSet with numbers" do
    set = SortedSet.new([3, 1, 2])
    assert JSON.encode!(set) == "[1,2,3]"
  end

  test "JSON encoding of a SortedSet with atoms" do
    set = SortedSet.new([:b, :a, :c])
    assert JSON.encode!(set) == ~s(["a","b","c"])
  end
end
