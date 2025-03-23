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
  checks if a value is a member of the SortedSet.

  ## Examples

      iex> ss = OrderedCollections.new_set([1, 2, 3])
      iex> OrderedCollections.set_member?(ss, 2)
      true
  """
  @spec set_member?(OrderedCollections.SortedSet.t(), any()) :: boolean()
  def set_member?(sorted_set, value), do: SortedSet.member?(sorted_set, value)
end
