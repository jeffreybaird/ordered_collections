defmodule OrderedCollections.SortedSetTest do
  use ExUnit.Case, async: true
  alias OrderedCollections.SortedSet

  import DialyzerHelper

  doctest SortedSet

  describe "SortedSet.new/0 and SortedSet.new/1" do
    test "creates an empty set" do
      assert SortedSet.new() |> SortedSet.to_list() == []
    end

    test "creates a new set from a list" do
      assert SortedSet.new([3, 1, 2]) |> SortedSet.to_list() == [1, 2, 3]
    end

    test "raises a FunctionClauseError when given a non-list" do
      assert_raise FunctionClauseError, fn ->
        SortedSet.new(1)
      end
    end
  end

  describe "SortedSet.add/2" do
    test "adds a value to the set" do
      set = SortedSet.new([2, 3])
      set = SortedSet.add(set, 1)
      assert SortedSet.to_list(set) == [1, 2, 3]
    end

    test "adding an existing value does not change the set" do
      set = SortedSet.new([2, 3])
      set = SortedSet.add(set, 3)
      assert SortedSet.to_list(set) == [2, 3]
    end

    test "adds a value of a different type - float" do
      set = SortedSet.new([2, 3])
      set = SortedSet.add(set, 1.0)
      # Note: In Erlang term order, numbers come before atoms.
      assert SortedSet.to_list(set) == [1.0, 2, 3]
    end

    test "adds a value of a different type - atom" do
      set = SortedSet.new([2, 3])
      set = SortedSet.add(set, :a)
      # In Erlang term order, numbers are less than atoms.
      assert SortedSet.to_list(set) == [2, 3, :a]
    end

    test "raises an error when trying to add to a non-set" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.add/2)
        |> dialyzer_warning_ignore([1, 1])
      end
    end
  end

  describe "SortedSet.delete/2" do
    test "deletes a value from the set" do
      set = SortedSet.new([1, 2, 3])
      set = SortedSet.delete(set, 2)
      assert SortedSet.to_list(set) == [1, 3]
    end

    test "deleting a value not in the set leaves it unchanged" do
      set = SortedSet.new([1, 2, 3])
      set = SortedSet.delete(set, 4)
      assert SortedSet.to_list(set) == [1, 2, 3]
    end

    test "raises an error when trying to delete from a non-set" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.delete/2)
        |> dialyzer_warning_ignore([1, 1])
      end
    end
  end

  describe "SortedSet.member?/2" do
    test "returns true for a member" do
      set = SortedSet.new([1, 2, 3])
      assert SortedSet.member?(set, 2) == true
    end

    test "returns false for a non-member" do
      set = SortedSet.new([1, 2, 3])
      assert SortedSet.member?(set, 4) == false
    end

    test "raises an error when trying to check membership in a non-set" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.member?/2)
        |> dialyzer_warning_ignore([1, 1])
      end
    end
  end

  describe "SortedSet.min/1 and SortedSet.max/1" do
    test "returns the minimum element" do
      set = SortedSet.new([3, 1, 2])
      assert SortedSet.min(set) == 1
    end

    test "raises an error when getting minimum from an empty set" do
      set = SortedSet.new()
      assert_raise FunctionClauseError, fn -> SortedSet.min(set) end
    end

    test "returns the maximum element" do
      set = SortedSet.new([3, 1, 2])
      assert SortedSet.max(set) == 3
    end

    test "raises an error when getting maximum from an empty set" do
      set = SortedSet.new()
      assert_raise FunctionClauseError, fn -> SortedSet.max(set) end
    end

    test "raises an error when getting maximum from a non-set" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.max/1)
        |> dialyzer_warning_ignore([1])
      end
    end
  end

  describe "SortedSet.to_list/1" do
    test "returns all elements as a sorted list" do
      set = SortedSet.new([3, 1, 2])
      assert SortedSet.to_list(set) == [1, 2, 3]
    end

    test "returns an empty list for an empty set" do
      set = SortedSet.new()
      assert SortedSet.to_list(set) == []
    end

    test "raises an error when converting a non-set to a list" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.to_list/1)
        |> dialyzer_warning_ignore([1])
      end
    end
  end

  describe "SortedSet.range/3" do
    test "returns elements within a given range for numbers" do
      set = SortedSet.new([2, 10, 5, 1])
      # Expected to return [1, 2, 5] when asked for range 1 to 5.
      assert SortedSet.range(set, 1, 5) |> SortedSet.to_list() == [1, 2, 5]
    end

    test "returns elements within a given range for strings" do
      set = SortedSet.new(["d", "a", "c", "b"])
      assert SortedSet.range(set, "b", "d") |> SortedSet.to_list() == ["b", "c", "d"]
    end

    test "returns an empty list for an empty set" do
      set = SortedSet.new()
      assert SortedSet.range(set, 1, 5) |> SortedSet.to_list() == []
    end

    test "raises an error when getting range from a non-set" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.range/3)
        |> dialyzer_warning_ignore([1, 1, 1])
      end
    end
  end

  describe "SortedSet.union/2" do
    test "combines two non-empty sets" do
      set1 = SortedSet.new([1, 2, 3])
      set2 = SortedSet.new([3, 4, 5])
      result = SortedSet.union(set1, set2) |> SortedSet.to_list()
      assert result == [1, 2, 3, 4, 5]
    end

    test "combines two empty sets" do
      set1 = SortedSet.new()
      set2 = SortedSet.new()
      assert SortedSet.union(set1, set2) |> SortedSet.to_list() == []
    end

    test "union with one empty set" do
      set1 = SortedSet.new([1, 2, 3])
      set2 = SortedSet.new()
      assert SortedSet.union(set1, set2) |> SortedSet.to_list() == [1, 2, 3]
    end

    test "raises an error when getting union of non-sets" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.union/2)
        |> dialyzer_warning_ignore([1, 1])
      end
    end
  end

  describe "SortedSet.difference/2" do
    test "returns the difference between two sets" do
      set1 = SortedSet.new([1, 2, 3])
      set2 = SortedSet.new([3, 4, 5])
      assert SortedSet.difference(set1, set2) |> SortedSet.to_list() == [1, 2]
    end

    test "difference between two empty sets returns an empty set" do
      set1 = SortedSet.new()
      set2 = SortedSet.new()
      assert SortedSet.difference(set1, set2) |> SortedSet.to_list() == []
    end

    test "difference when one set is empty returns the original set" do
      set1 = SortedSet.new([1, 2, 3])
      set2 = SortedSet.new()
      assert SortedSet.difference(set1, set2) |> SortedSet.to_list() == [1, 2, 3]
    end

    test "raises an error when getting difference of non-sets" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.difference/2)
        |> dialyzer_warning_ignore([1, 1])
      end
    end
  end

  describe "SortedSet.intersection/2" do
    test "returns a set with the shared elements of two sets" do
      set1 = SortedSet.new([1, 2, 3])
      set2 = SortedSet.new([3, 4, 5])
      assert SortedSet.intersection(set1, set2) |> SortedSet.to_list() == [3]
    end

    test "returns an empty set when one of the two is empty" do
      set1 = SortedSet.new([1, 2, 3])
      set2 = SortedSet.new()
      assert SortedSet.intersection(set1, set2) |> SortedSet.to_list() == []
    end

    test "returns an empty set when both sets are empty" do
      set1 = SortedSet.new()
      set2 = SortedSet.new()
      assert SortedSet.intersection(set1, set2) |> SortedSet.to_list() == []
    end

    test "returns an empty set when the two sets have no shared elements" do
      set1 = SortedSet.new([1, 2, 3])
      set2 = SortedSet.new([4, 5, 6])
      assert SortedSet.intersection(set1, set2) |> SortedSet.to_list() == []
    end

    test "raises an error when getting intersection of non-sets" do
      assert_raise FunctionClauseError, fn ->
        (&SortedSet.intersection/2)
        |> dialyzer_warning_ignore([1, 1])
      end
    end
  end
end
