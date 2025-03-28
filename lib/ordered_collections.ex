defmodule OrderedCollections do
  alias OrderedCollections.SortedMap
  alias OrderedCollections.SortedSet

  @moduledoc """
  OrderedCollections provides sorted data structures for Elixir,
  including a `SortedMap` and a `SortedSet`.

  For `SortedMap`, keys are maintained in a sorted order per Erlang's
  `:gb_trees` module.

  For `SortedSet`, elements are maintained in a sorted order per Erlang's
  `:gb_sets` module.


  ## Modules

    - `OrderedCollections.SortedMap` - A sorted key-value store implemented using Erlang's `:gb_trees`.
    - `OrderedCollections.SortedSet` - A sorted set implemented using Erlang's `:gb_sets`.

  ## Examples

      iex> sm = OrderedCollections.SortedMap.new(%{b: 2, a: 1})
      iex> OrderedCollections.SortedMap.get(sm, :a)
      1

      iex> ss = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> OrderedCollections.SortedSet.to_list(ss)
      [1, 2, 3]

  You can also use convenience functions:

      iex> sm = OrderedCollections.new_map(%{x: 10})
      iex> sm = OrderedCollections.put_map(sm, :y, 20)
      iex> OrderedCollections.get_map(sm, :y)
      20

      iex> sm = OrderedCollections.new_map()
      iex> sm = OrderedCollections.put_map(sm, :a, 1)
      iex> OrderedCollections.to_map(sm)
      %{a: 1}

      iex> ss = OrderedCollections.new_set([3, 1, 2])
      iex> ss = OrderedCollections.add_set_value(ss, 4)
      iex> OrderedCollections.set_member?(ss, 4)
      true

      iex> ss = OrderedCollections.new_set()
      iex> ss = OrderedCollections.add_set_value(ss, 1)
      iex> OrderedCollections.SortedSet.to_list(ss)
      [1]

  ## Map Operations

  The `SortedMap` module provides various operations:

      iex> sm = OrderedCollections.new_map(%{b: 2, a: 1, c: 3})
      iex> OrderedCollections.map_keys(sm)
      [:a, :b, :c]
      iex> OrderedCollections.map_values(sm)
      [1, 2, 3]
      iex> sm2 = OrderedCollections.new_map(%{b: 4, d: 5})
      iex> OrderedCollections.map_merge(sm, sm2) |> OrderedCollections.to_map()
      %{a: 1, b: 4, c: 3, d: 5}
      iex> OrderedCollections.map_range(sm, :a, :b)
      [a: 1, b: 2]
      iex> OrderedCollections.map_min_key(sm)
      :a
      iex> OrderedCollections.map_max_key(sm)
      :c

  ## Set Operations

  The `SortedSet` module also provides set operations:

      iex> set1 = OrderedCollections.new_set([1, 2, 3])
      iex> set2 = OrderedCollections.new_set([3, 4, 5])
      iex> OrderedCollections.set_union(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [1, 2, 3, 4, 5]
      iex> OrderedCollections.set_difference(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [1, 2]
      iex> OrderedCollections.set_intersection(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [3]

  ## Range Operations

  You can get elements within a specific range:

      iex> set = OrderedCollections.new_set([1, 2, 3, 4, 5])
      iex> OrderedCollections.set_range(set, 2, 4) |> OrderedCollections.SortedSet.to_list()
      [2, 3, 4]

  ## Min/Max Operations

  You can get the minimum and maximum elements:

      iex> set = OrderedCollections.new_set([3, 1, 2])
      iex> OrderedCollections.set_min(set)
      1
      iex> OrderedCollections.set_max(set)
      3
  """

  # Convenience functions re-exporting the SortedMap functionality.

  @doc """
  Creates a new empty SortedMap.

  ## Examples

    iex> sm = OrderedCollections.new_map()
    iex> OrderedCollections.to_map(sm)
    %{}
  """
  @spec new_map() :: SortedMap.t()
  def new_map, do: SortedMap.new()

  @doc """
  Creates a new SortedMap from a regular map.

  ## Examples

    iex> m = %{b: 2, a: 1}
    iex> sm = OrderedCollections.new_map(m)
    iex> OrderedCollections.get_map(sm, :a)
    1
  """
  @spec new_map(map()) :: SortedMap.t()
  def new_map(map) when is_map(map) do
    SortedMap.new(map)

    # tree = Enum.reduce(map, :gb_trees.empty(), fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end)
    # %SortedMap{tree: tree}
  end

  @doc """
  Creates a map from a SortedMap.

  ## Examples

    iex> sm = OrderedCollections.new_map(%{b: 2, a: 1})
    iex> OrderedCollections.to_map(sm)
    %{a: 1, b: 2}
  """
  @spec to_map(SortedMap.t()) :: map()
  def to_map(%OrderedCollections.SortedMap{} = sorted_map), do: SortedMap.to_map(sorted_map)

  @doc """
  Inserts a key-value pair into a SortedMap.

  ## Examples

    iex> sm = OrderedCollections.new_map()
    iex> sm = OrderedCollections.put_map(sm, :a, 1)
    iex> OrderedCollections.get_map(sm, :a)
    1
  """
  @spec put_map(SortedMap.t(), any(), any()) :: SortedMap.t()
  def put_map(%OrderedCollections.SortedMap{} = sorted_map, key, value),
    do: SortedMap.put(sorted_map, key, value)

  @doc """
  Retrieves the value for the given key from a SortedMap, returning a default if the key is missing.

  ## Examples

    iex> sm = OrderedCollections.new_map(%{a: 1})
    iex> OrderedCollections.get_map(sm, :a)
    1
    iex> OrderedCollections.get_map(sm, :b, 2)
    2
  """
  @spec get_map(SortedMap.t(), any(), any()) :: any()
  def get_map(%OrderedCollections.SortedMap{} = sorted_map, key, default \\ nil),
    do: SortedMap.get(sorted_map, key, default)

  @doc """
  Returns the keys of the SortedMap in sorted order.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{b: 2, a: 1, c: 3})
      iex> OrderedCollections.map_keys(sm)
      [:a, :b, :c]
  """
  @spec map_keys(SortedMap.t()) :: list()
  def map_keys(%OrderedCollections.SortedMap{} = sorted_map), do: SortedMap.keys(sorted_map)

  @doc """
  Returns the values of the SortedMap in the order corresponding to the sorted keys.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{b: 2, a: 1, c: 3})
      iex> OrderedCollections.map_values(sm)
      [1, 2, 3]
  """
  @spec map_values(SortedMap.t()) :: list()
  def map_values(%OrderedCollections.SortedMap{} = sorted_map), do: SortedMap.values(sorted_map)

  @doc """
  Merges two SortedMaps. In case of duplicate keys, values from the second map override those from the first.

  ## Examples

      iex> sm1 = OrderedCollections.new_map(%{a: 1, b: 2})
      iex> sm2 = OrderedCollections.new_map(%{b: 3, c: 4})
      iex> OrderedCollections.map_merge(sm1, sm2) |> OrderedCollections.to_map()
      %{a: 1, b: 3, c: 4}
  """
  @spec map_merge(SortedMap.t(), SortedMap.t()) :: SortedMap.t()
  def map_merge(%OrderedCollections.SortedMap{} = map1, %OrderedCollections.SortedMap{} = map2),
    do: SortedMap.merge(map1, map2)

  @doc """
  Updates a key with a function. If the key doesn't exist, it is set to `nil`.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{a: 1})
      iex> sm = OrderedCollections.map_update(sm, :a, &(&1 + 1))
      iex> OrderedCollections.get_map(sm, :a)
      2

      iex> OrderedCollections.new_map(%{a: 1}) |> OrderedCollections.map_update(:b, &(&1 + 1)) |> OrderedCollections.get_map(:b)
      nil
  """
  @spec map_update(SortedMap.t(), any(), (any() -> any())) :: SortedMap.t()
  def map_update(%OrderedCollections.SortedMap{} = map, key, fun),
    do: SortedMap.update(map, key, fun)

  @doc """
  Updates a key with a function. If the key doesn't exist, it sets it to `default`.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{a: 1})
      iex> sm = OrderedCollections.map_update(sm, :a, &(&1 + 5), 0)
      iex> OrderedCollections.get_map(sm, :a)
      6

      iex> OrderedCollections.new_map(%{a: 1}) |> OrderedCollections.map_update(:b, &(&1 + 1), 10) |> OrderedCollections.get_map(:b)
      10
  """
  @spec map_update(SortedMap.t(), any(), (any() -> any()), any()) :: SortedMap.t()
  def map_update(%OrderedCollections.SortedMap{} = map, key, fun, default),
    do: SortedMap.update(map, key, fun, default)

  @doc """
  Replaces the value for `key` with `new_value` if the key exists.
  If `key` does not exist, the map remains unchanged.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{a: 1, b: 2})
      iex> sm = OrderedCollections.map_update_with_value(sm, :a, 100)
      iex> OrderedCollections.get_map(sm, :a)
      100
      iex> OrderedCollections.map_update_with_value(sm, :c, 300)
      iex> OrderedCollections.get_map(sm, :c)
      nil
  """
  @spec map_update_with_value(SortedMap.t(), any(), any()) :: SortedMap.t()
  def map_update_with_value(%OrderedCollections.SortedMap{} = map, key, new_value),
    do: SortedMap.update_with_value(map, key, new_value)

  @doc """
  Checks if a key exists.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{a: 1, b: 2})
      iex> OrderedCollections.map_has_key?(sm, :a)
      true
      iex> OrderedCollections.map_has_key?(sm, :c)
      false
  """
  @spec map_has_key?(SortedMap.t(), any()) :: boolean()
  def map_has_key?(%OrderedCollections.SortedMap{} = map, key), do: SortedMap.has_key?(map, key)

  @doc """
  Deletes a key.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{a: 1, b: 2})
      iex> sm2 = OrderedCollections.map_delete(sm, :b)
      iex> OrderedCollections.map_has_key?(sm2, :b)
      false
  """
  @spec map_delete(SortedMap.t(), any()) :: SortedMap.t()
  def map_delete(%OrderedCollections.SortedMap{} = map, key), do: SortedMap.delete(map, key)

  @doc """
  Returns the smallest key. Returns `:none` if the map is empty.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{b: 2, a: 1, c: 3})
      iex> OrderedCollections.map_min_key(sm)
      :a

      iex> sm_empty = OrderedCollections.new_map()
      iex> OrderedCollections.map_min_key(sm_empty)
      :none
  """
  @spec map_min_key(SortedMap.t()) :: any()
  def map_min_key(%OrderedCollections.SortedMap{} = map), do: SortedMap.min_key(map)

  @doc """
  Returns the largest key. Returns `:none` if the map is empty.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{b: 2, a: 1, c: 3})
      iex> OrderedCollections.map_max_key(sm)
      :c

      iex> sm_empty = OrderedCollections.new_map()
      iex> OrderedCollections.map_max_key(sm_empty)
      :none
  """
  @spec map_max_key(SortedMap.t()) :: any()
  def map_max_key(%OrderedCollections.SortedMap{} = map), do: SortedMap.max_key(map)

  @doc """
  Iterates over a range of keys, returning key-value pairs
  whose keys are between `min` and `max` (inclusive).

  ## Examples

      iex> sm = OrderedCollections.new_map(%{a: 1, b: 2, c: 3, d: 4})
      iex> OrderedCollections.map_range(sm, :b, :c)
      [b: 2, c: 3]
  """
  @spec map_range(SortedMap.t(), any(), any()) :: [{any(), any()}]
  def map_range(%OrderedCollections.SortedMap{} = map, min, max),
    do: SortedMap.range(map, min, max)

  @doc """
  Rebalances the tree.

  ## Examples

      iex> sm = OrderedCollections.new_map(%{a: 1, b: 2, c: 3})
      iex> smi = OrderedCollections.new_map() |> OrderedCollections.put_map(:a, 1) |> OrderedCollections.put_map(:b, 2) |> OrderedCollections.put_map(:c, 3)
      iex> sm == smi
      false
      iex> OrderedCollections.map_rebalance(sm) == OrderedCollections.map_rebalance(smi)
      true
  """
  @spec map_rebalance(SortedMap.t()) :: SortedMap.t()
  def map_rebalance(%OrderedCollections.SortedMap{} = map), do: SortedMap.rebalance(map)

  # Convenience functions for SortedSet.

  @doc """
  Creates a new empty SortedSet.

  ## Examples

      iex> ss = OrderedCollections.new_set()
      iex> OrderedCollections.SortedSet.to_list(ss)
      []
  """
  @spec new_set() :: OrderedCollections.SortedSet.t()
  def new_set, do: SortedSet.new()

  @doc """
  Creates a new SortedSet from a list.

  ## Examples

      iex> ss = OrderedCollections.new_set([3, 1, 2])
      iex> OrderedCollections.SortedSet.to_list(ss)
      [1, 2, 3]
  """
  @spec new_set(list()) :: OrderedCollections.SortedSet.t()
  def new_set(list) when is_list(list), do: SortedSet.new(list)

  @doc """
  Adds a value to the SortedSet.

  ## Examples

      iex> ss = OrderedCollections.new_set([2, 3])
      iex> ss = OrderedCollections.add_set_value(ss, 1)
      iex> ss = OrderedCollections.add_set_value(ss, 3)
      iex> OrderedCollections.SortedSet.to_list(ss)
      [1, 2, 3]
  """
  @spec add_set_value(OrderedCollections.SortedSet.t(), any()) :: OrderedCollections.SortedSet.t()
  def add_set_value(sorted_set, value),
    do: SortedSet.add(sorted_set, value)

  @doc """
  Deletes a value from the SortedSet.

  ## Examples

      iex> ss = OrderedCollections.new_set([1, 2, 3])
      iex> ss = OrderedCollections.delete_set_value(ss, 2)
      iex> OrderedCollections.SortedSet.to_list(ss)
      [1, 3]
  """
  @spec delete_set_value(OrderedCollections.SortedSet.t(), any()) ::
          OrderedCollections.SortedSet.t()
  def delete_set_value(sorted_set, value),
    do: SortedSet.delete(sorted_set, value)

  @doc """
  Checks if a value is a member of the SortedSet.

  ## Examples

      iex> ss = OrderedCollections.new_set([1, 2, 3])
      iex> OrderedCollections.set_member?(ss, 2)
      true
  """
  @spec set_member?(OrderedCollections.SortedSet.t(), any()) :: boolean()
  def set_member?(sorted_set, value), do: SortedSet.member?(sorted_set, value)

  @doc """
  Returns the minimum element of the SortedSet.

  ## Examples

      iex> ss = OrderedCollections.new_set([3, 1, 2])
      iex> OrderedCollections.set_min(ss)
      1
  """
  @spec set_min(OrderedCollections.SortedSet.non_empty_t()) ::
          OrderedCollections.SortedSet.element()
  def set_min(sorted_set), do: SortedSet.min(sorted_set)

  @doc """
  Returns the maximum element of the SortedSet.

  ## Examples

      iex> ss = OrderedCollections.new_set([3, 1, 2])
      iex> OrderedCollections.set_max(ss)
      3
  """
  @spec set_max(OrderedCollections.SortedSet.non_empty_t()) ::
          OrderedCollections.SortedSet.element()
  def set_max(sorted_set), do: SortedSet.max(sorted_set)

  @doc """
  Returns elements within a given range (inclusive).

  ## Examples

      iex> ss = OrderedCollections.new_set([1, 2, 3, 4, 5])
      iex> OrderedCollections.set_range(ss, 2, 4) |> OrderedCollections.SortedSet.to_list()
      [2, 3, 4]
  """
  @spec set_range(OrderedCollections.SortedSet.t(), any(), any()) ::
          OrderedCollections.SortedSet.t()
  def set_range(sorted_set, min, max), do: SortedSet.range(sorted_set, min, max)

  @doc """
  Returns the union of two SortedSets.

  ## Examples

      iex> set1 = OrderedCollections.new_set([1, 2, 3])
      iex> set2 = OrderedCollections.new_set([3, 4, 5])
      iex> OrderedCollections.set_union(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [1, 2, 3, 4, 5]
  """
  @spec set_union(OrderedCollections.SortedSet.t(), OrderedCollections.SortedSet.t()) ::
          OrderedCollections.SortedSet.t()
  def set_union(set1, set2), do: SortedSet.union(set1, set2)

  @doc """
  Returns the difference between two SortedSets.

  ## Examples

      iex> set1 = OrderedCollections.new_set([1, 2, 3])
      iex> set2 = OrderedCollections.new_set([3, 4, 5])
      iex> OrderedCollections.set_difference(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [1, 2]
  """
  @spec set_difference(OrderedCollections.SortedSet.t(), OrderedCollections.SortedSet.t()) ::
          OrderedCollections.SortedSet.t()
  def set_difference(set1, set2), do: SortedSet.difference(set1, set2)

  @doc """
  Returns the intersection of two SortedSets.

  ## Examples

      iex> set1 = OrderedCollections.new_set([1, 2, 3])
      iex> set2 = OrderedCollections.new_set([3, 4, 5])
      iex> OrderedCollections.set_intersection(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [3]
  """
  @spec set_intersection(OrderedCollections.SortedSet.t(), OrderedCollections.SortedSet.t()) ::
          OrderedCollections.SortedSet.t()
  def set_intersection(set1, set2), do: SortedSet.intersection(set1, set2)
end
