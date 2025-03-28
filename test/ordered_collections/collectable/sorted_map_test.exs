defmodule OrderedCollections.Collectable.SortedMapTest do
  use ExUnit.Case, async: true
  alias OrderedCollections.SortedMap
  doctest Collectable.OrderedCollections.SortedMap

  describe "into/1" do
    test "collects elements into a SortedMap" do
      sorted_map = Enum.into([a: 1, b: 2, c: 3], SortedMap.new()) |> SortedMap.rebalance()
      expected = SortedMap.new(%{a: 1, b: 2, c: 3}) |> SortedMap.rebalance()
      assert sorted_map == expected
    end

    test "collects elements into a SortedMap with a custom initial value" do
      sorted_map = Enum.into([a: 1, b: 2, c: 3], SortedMap.new(%{d: 4})) |> SortedMap.rebalance()
      expected = SortedMap.new(%{a: 1, b: 2, c: 3, d: 4}) |> SortedMap.rebalance()
      assert sorted_map == expected
    end

    test "handles suspend in collection" do
      {initial, collector} = Collectable.into(SortedMap.new())

      # Start collection with first element
      acc = collector.(initial, {:cont, {:a, 1}})

      # Suspend collection
      suspended_acc = collector.(acc, {:suspend, []})

      # Resume collection with more elements
      final_acc = collector.(suspended_acc, {:cont, {:b, 2}})
      final_acc = collector.(final_acc, {:cont, {:c, 3}})

      # Complete collection
      result = collector.(final_acc, :done)

      expected = SortedMap.new(%{a: 1, b: 2, c: 3}) |> SortedMap.rebalance()
      assert result |> SortedMap.rebalance() == expected
    end

    test "handles halt in collection" do
      {initial, collector} = Collectable.into(SortedMap.new())

      # Start collection with first element
      acc = collector.(initial, {:cont, {:a, 1}})

      # Add more elements
      acc = collector.(acc, {:cont, {:b, 2}})
      acc = collector.(acc, {:cont, {:c, 3}})

      # Halt collection
      result = collector.(acc, :halt)

      # Should return :ok as per the implementation
      assert result == :ok
    end

    test "raises error when collecting non-key-value pairs" do
      {initial, collector} = Collectable.into(SortedMap.new())

      # Start collection with first element
      acc = collector.(initial, {:cont, {:a, 1}})

      # Try to collect a non-key-value pair
      assert_raise FunctionClauseError, fn ->
        collector.(acc, {:cont, 1})
      end
    end

    test "raises error when collecting invalid key-value pairs" do
      {initial, collector} = Collectable.into(SortedMap.new())

      # Start collection with first element
      acc = collector.(initial, {:cont, {:a, 1}})

      # Try to collect an invalid key-value pair (not a tuple)
      assert_raise FunctionClauseError, fn ->
        collector.(acc, {:cont, %{a: 1}})
      end
    end

    test "handles empty collection" do
      {initial, collector} = Collectable.into(SortedMap.new())
      result = collector.(initial, :done)
      assert result == SortedMap.new()
    end
  end
end
