defmodule OrderedCollections.Enumerable.MembershipTest do
  use ExUnit.Case, async: true

  alias OrderedCollections.{SortedMap, SortedSet}

  test "map membership requires the entire stored pair" do
    map = SortedMap.new(%{a: 1, b: nil})
    assert Enum.member?(map, {:a, 1})
    assert Enum.member?(map, {:b, nil})
    refute Enum.member?(map, {:a, :different})
    refute Enum.member?(map, {:missing, nil})
    refute Enum.member?(SortedMap.new(), {:a, 1})
  end

  test "map membership returns false for non-pairs" do
    map = SortedMap.new(%{a: 1})

    for candidate <- [:a, nil, 1, {:a}, {:a, 1, :extra}, [:a, 1], %{a: 1}] do
      refute Enum.member?(map, candidate)
      refute Enum.member?(SortedMap.new(), candidate)
    end
  end

  test "map membership uses strict equality for numeric keys" do
    map = SortedMap.new(%{1 => :one, 2.0 => :two})
    assert SortedMap.has_key?(map, 1.0)
    assert SortedMap.get(map, 2) == :two
    assert Enum.member?(map, {1, :one})
    assert Enum.member?(map, {2.0, :two})
    refute Enum.member?(map, {1.0, :one})
    refute Enum.member?(map, {2, :two})
  end

  test "map membership uses strict equality for numeric values" do
    map = SortedMap.new(%{a: 1, b: 2.0})
    assert Enum.member?(map, {:a, 1})
    assert Enum.member?(map, {:b, 2.0})
    refute Enum.member?(map, {:a, 1.0})
    refute Enum.member?(map, {:b, 2})
  end

  test "map membership uses strict equality for nested numeric keys and values" do
    map = SortedMap.new(%{{:key, [1]} => %{value: [2]}, :nested => {:value, 3.0}})
    assert Enum.member?(map, {{:key, [1]}, %{value: [2]}})
    assert Enum.member?(map, {:nested, {:value, 3.0}})
    refute Enum.member?(map, {{:key, [1.0]}, %{value: [2]}})
    refute Enum.member?(map, {{:key, [1]}, %{value: [2.0]}})
    refute Enum.member?(map, {:nested, {:value, 3}})
  end

  test "set collection membership retains Erlang equality while Enum membership is strict" do
    set = SortedSet.new([1, 2.0])
    assert SortedSet.member?(set, 1.0)
    assert SortedSet.member?(set, 2)
    assert Enum.member?(set, 1)
    assert Enum.member?(set, 2.0)
    refute Enum.member?(set, 1.0)
    refute Enum.member?(set, 2)
    refute Enum.member?(set, :missing)
    refute Enum.member?(SortedSet.new(), 1)
  end

  test "set Enum membership is strict inside compound terms" do
    for {stored, equivalent} <- [
          {{:id, 1}, {:id, 1.0}},
          {[2], [2.0]},
          {%{value: 3}, %{value: 3.0}}
        ] do
      set = SortedSet.new([stored])
      assert SortedSet.member?(set, equivalent)
      assert Enum.member?(set, stored)
      refute Enum.member?(set, equivalent)
    end
  end
end
