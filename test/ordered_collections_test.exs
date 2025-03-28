defmodule OrderedCollectionsTest do
  use ExUnit.Case
  doctest OrderedCollections

  import DialyzerHelper

  describe "OrderedCollections" do
    test "get a nonexistant key from a SortedMap" do
      sm = OrderedCollections.new_map(%{b: 2, a: 1})
      assert OrderedCollections.get_map(sm, :c) == nil
    end

    test "raises an error when trying to create a new map with a non-map" do
      assert_raise FunctionClauseError, fn ->
        OrderedCollections.new_map(1)
      end
    end

    test "transforms a SortedMap into a map" do
      sm = OrderedCollections.new_map(%{b: 2, a: 1})
      assert OrderedCollections.to_map(sm) == %{a: 1, b: 2}
    end

    test "raises an error with a non sorted map argument" do
      assert_raise FunctionClauseError, fn ->
        # wrapping this in a helper function to avoid dialyzer warnings
        (&OrderedCollections.to_map/1)
        |> dialyzer_warning_ignore(%{b: 2, a: 1})
      end
    end

    test "puts a key-value pair into a SortedMap" do
      sm = OrderedCollections.new_map()
      sm = OrderedCollections.put_map(sm, :a, 1)
      assert OrderedCollections.get_map(sm, :a) == 1
    end

    test "raises an error when trying to put a key-value pair into a non-sorted-map" do
      assert_raise FunctionClauseError, fn ->
        (&OrderedCollections.put_map/3)
        |> dialyzer_warning_ignore([%{}, :a, 1])
      end
    end

    test "retrieves the value for the given key from a SortedMap, returning a default if the key is missing" do
      sm = OrderedCollections.new_map(%{a: 1})
      assert OrderedCollections.get_map(sm, :a) == 1
      assert OrderedCollections.get_map(sm, :b, 2) == 2
      assert OrderedCollections.get_map(sm, :c) == nil
    end

    test "raises an error when trying to get a key from a non-sorted-map" do
      assert_raise FunctionClauseError, fn ->
        (&OrderedCollections.get_map/3)
        |> dialyzer_warning_ignore([%{}, :a, 1])
      end
    end

    test "creates a new empty SortedSet" do
      ss = OrderedCollections.new_set()
      assert OrderedCollections.SortedSet.to_list(ss) == []
    end

    test "creates a new SortedSet from a list" do
      ss = OrderedCollections.new_set([3, 1, 2])
      assert OrderedCollections.SortedSet.to_list(ss) == [1, 2, 3]
    end

    test "raises an error when trying to create a new set with a non-set" do
      assert_raise FunctionClauseError, fn ->
        OrderedCollections.new_set(1)
      end
    end

    test "adds an element to a SortedSet" do
      ss = OrderedCollections.new_set([3, 1, 2])
      ss = OrderedCollections.add_set_value(ss, 4)
      assert OrderedCollections.SortedSet.to_list(ss) == [1, 2, 3, 4]
    end

    test "raises an error when trying to add an element to a non-sorted-set" do
      assert_raise FunctionClauseError, fn ->
        (&OrderedCollections.add_set_value/2)
        |> dialyzer_warning_ignore([[], 1])
      end
    end

    test "checks if an element is a member of a SortedSet" do
      ss = OrderedCollections.new_set([3, 1, 2])
      assert OrderedCollections.SortedSet.member?(ss, 2) == true
      assert OrderedCollections.SortedSet.member?(ss, 4) == false
    end

    test "raises an error when trying to check if an element is a member of a non-sorted-set" do
      assert_raise FunctionClauseError, fn ->
        (&OrderedCollections.SortedSet.member?/2)
        |> dialyzer_warning_ignore([[2, 3], 1])
      end
    end
  end
end
