defmodule OrderedCollections.Collectable.SortedSetTest do
  use ExUnit.Case, async: true
  alias OrderedCollections.SortedSet
  doctest Collectable.OrderedCollections.SortedSet

  describe "into/1" do
    test "collects elements into a SortedSet" do
      sorted_set = Enum.into([3, 1, 2], SortedSet.new()) |> SortedSet.to_list()
      assert sorted_set == [1, 2, 3]
    end

    test "collects elements into a SortedSet with a custom initial value" do
      sorted_set = Enum.into([3, 1, 2], SortedSet.new([4])) |> SortedSet.to_list()
      assert sorted_set == [1, 2, 3, 4]
    end

    test "handles suspend in collection" do
      {initial, collector} = Collectable.into(SortedSet.new())

      # Start collection with first element
      acc = collector.(initial, {:cont, 1})

      # Resume collection with more elements
      final_acc = collector.(acc, {:cont, 2})
      final_acc = collector.(final_acc, {:cont, 3})

      # Complete collection
      result = collector.(final_acc, :done)

      assert SortedSet.to_list(result) == [1, 2, 3]
    end

    test "handles halt in collection" do
      {initial, collector} = Collectable.into(SortedSet.new())

      # Start collection with first element
      acc = collector.(initial, {:cont, 1})

      # Add more elements
      acc = collector.(acc, {:cont, 2})
      acc = collector.(acc, {:cont, 3})

      # Halt collection
      result = collector.(acc, :halt)

      # Should return :ok as per the implementation
      assert result == :ok
    end

    test "handles empty collection" do
      {initial, collector} = Collectable.into(SortedSet.new())
      result = collector.(initial, :done)
      assert SortedSet.to_list(result) == []
    end

    test "maintains uniqueness during collection" do
      sorted_set = Enum.into([3, 1, 2, 3, 1], SortedSet.new()) |> SortedSet.to_list()
      assert sorted_set == [1, 2, 3]
    end
  end
end
