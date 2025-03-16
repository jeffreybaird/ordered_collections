defmodule SortedSetTest do
  use ExUnit.Case
  alias OrderedCollections.SortedSet
  doctest SortedSet

  test "creates an empty set" do
    assert SortedSet.new() |> SortedSet.to_list() == []
  end

  test "creates a new set from a list" do
    assert SortedSet.new([3, 1, 2]) |> SortedSet.to_list() == [1, 2, 3]
  end

  test "fails if the argument is not a list" do
    assert_raise FunctionClauseError, fn ->
      SortedSet.new(1)
    end
  end

  test "adds a value to the set" do
    set = SortedSet.new([2, 3])
    set = SortedSet.add(set, 1)
    assert SortedSet.to_list(set) == [1, 2, 3]
  end

  test "adds a value of a different type - float" do
    set = SortedSet.new([2, 3])
    set = SortedSet.add(set, 1.0)
    assert SortedSet.to_list(set) == [1.0, 2, 3]
  end

  test "adds a value of a different type - atom" do
    set = SortedSet.new([2, 3])
    set = SortedSet.add(set, :a)
    assert SortedSet.to_list(set) == [2, 3, :a]
  end

  test "deletes a value from the set" do
    set = SortedSet.new([1, 2, 3])
    set = SortedSet.delete(set, 2)
    assert SortedSet.to_list(set) == [1, 3]
  end

  test "delete a value that is not in the set" do
    set = SortedSet.new([1, 2, 3])
    set = SortedSet.delete(set, 4)
    assert SortedSet.to_list(set) == [1, 2, 3]
  end

  test "checks if a value is in the set" do
    set = SortedSet.new([1, 2, 3])
    assert SortedSet.member?(set, 2) == true
  end

  test "checks if a value is not in the set" do
    set = SortedSet.new([1, 2, 3])
    assert SortedSet.member?(set, 4) == false
  end

  test "return the minimum element of the set" do
    set = SortedSet.new([3, 1, 2])
    assert SortedSet.min(set) == 1
  end

  test "looks for the minimum element in an empty set" do
    set = SortedSet.new()

    assert_raise FunctionClauseError, fn ->
      SortedSet.min(set)
    end
  end

  test "return the maximum element of the set" do
    set = SortedSet.new([3, 1, 2])
    assert SortedSet.max(set) == 3
  end

  test "looks for the maximum element in an empty set" do
    set = SortedSet.new()

    assert_raise FunctionClauseError, fn ->
      SortedSet.max(set)
    end
  end

  test "returns all the elements of a set as a list in sorted order" do
    set = SortedSet.new([3, 1, 2])
    assert SortedSet.to_list(set) == [1, 2, 3]
  end

  test "returns an empty list for an empty set" do
    set = SortedSet.new()
    assert SortedSet.to_list(set) == []
  end

  test "returns all the string elements within a range" do
    set = SortedSet.new(["d", "a", "c", "b"])
    assert SortedSet.range(set, "b", "d") == ["b", "c", "d"]
  end

  test "returns the list inclusive of the boundary elements" do
    set = SortedSet.new([2, 10, 5, 1])
    assert SortedSet.range(set, 1, 5) == [1, 2, 5]
  end

  test "range returns an empty list for an empty set" do
    set = SortedSet.new()
    assert SortedSet.range(set, 1, 5) == []
  end

  test "combines two sets" do
    set1 = SortedSet.new([1, 2, 3])
    set2 = SortedSet.new([3, 4, 5])
    assert SortedSet.union(set1, set2) |> SortedSet.to_list() == [1, 2, 3, 4, 5]
  end

  test "combines two empty sets" do
    set1 = SortedSet.new()
    set2 = SortedSet.new()
    assert SortedSet.union(set1, set2) |> SortedSet.to_list() == []
  end

  test "one set is empty" do
    set1 = SortedSet.new([1, 2, 3])
    set2 = SortedSet.new()
    assert SortedSet.union(set1, set2) |> SortedSet.to_list() == [1, 2, 3]
  end

  test "difference between two sets" do
    set1 = SortedSet.new([1, 2, 3])
    set2 = SortedSet.new([3, 4, 5])
    assert SortedSet.difference(set1, set2) |> SortedSet.to_list() == [1, 2]
  end

  test "difference between two empty sets" do
    set1 = SortedSet.new()
    set2 = SortedSet.new()
    assert SortedSet.difference(set1, set2) |> SortedSet.to_list() == []
  end

  test "difference between a set and an empty set" do
    set1 = SortedSet.new([1, 2, 3])
    set2 = SortedSet.new()
    assert SortedSet.difference(set1, set2) |> SortedSet.to_list() == [1, 2, 3]
  end
end
