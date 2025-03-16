defmodule OrderedCollections do
  @moduledoc """
  OrderedCollections provides sorted data structures for Elixir,
  including a `SortedMap` and (eventually) a `SortedSet`.

  ## Modules

    - `OrderedCollections.SortedMap` - A sorted key-value store implemented using Erlang's `:gb_trees`.
    - `OrderedCollections.SortedSet` - A sorted set implemented using Erlang's `:gb_sets`.

  ## Examples

      iex> sm = OrderedCollections.SortedMap.new(%{b: 2, a: 1})
      iex> OrderedCollections.SortedMap.get(sm, :a)
      1

  You can also use convenience functions:

      iex> sm = OrderedCollections.new_map(%{x: 10})
      iex> sm = OrderedCollections.put_map(sm, :y, 20)
      iex> OrderedCollections.get_map(sm, :y)
      20
  """

  # Alias the submodules for easy access.
  alias OrderedCollections.SortedMap

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
    tree = Enum.reduce(map, :gb_trees.empty(), fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end)
    %SortedMap{tree: tree}
  end

  @doc """
  Creates a map from a SortedMap.

  ## Examples

    iex> sm = OrderedCollections.new_map(%{b: 2, a: 1})
    iex> OrderedCollections.to_map(sm)
    %{a: 1, b: 2}
  """
  @spec to_map(SortedMap.t()) :: map()
  def to_map(map) when is_map(map), do: SortedMap.to_map(map)

  @doc """
  Inserts a key-value pair into a SortedMap.
  """
  @spec put_map(SortedMap.t(), any(), any()) :: SortedMap.t()
  def put_map(sorted_map, key, value), do: SortedMap.put(sorted_map, key, value)

  @doc """
  Retrieves the value for the given key from a SortedMap, returning a default if the key is missing.
  """
  @spec get_map(SortedMap.t(), any(), any()) :: any()
  def get_map(sorted_map, key, default \\ nil), do: SortedMap.get(sorted_map, key, default)
end
