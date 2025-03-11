defmodule SortedMap do
  @moduledoc """
  A sorted key-value store implemented using Erlang's `:gb_trees` (Red-Black Trees).

  This module stores items in sorted order by their keys.
  """

  @opaque t :: %SortedMap{tree: :gb_trees.tree()}
  defstruct tree: :gb_trees.empty()

  @doc """
  Creates a new empty sorted map.

  ## Examples

      iex> sm = SortedMap.new()
      iex> SortedMap.to_map(sm)
      %{}
  """
  @spec new() :: SortedMap.t()
  def new(), do: %SortedMap{}

  @doc """
  Creates a new sorted map from a standard map.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1, b: 2})
      iex> SortedMap.get(sm, :a)
      1
      iex> SortedMap.get(sm, :b)
      2
  """
  @spec new(map()) :: SortedMap.t()
  def new(map) when is_map(map) do
    tree = Enum.reduce(map, :gb_trees.empty(), fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end)
    %SortedMap{tree: tree}
  end

  @doc """
  Inserts a key-value pair, maintaining order.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1})
      iex> sm = SortedMap.put(sm, :b, 2)
      iex> SortedMap.get(sm, :b)
      2
  """
  @spec put(SortedMap.t(), any(), any()) :: SortedMap.t()
  def put(%SortedMap{tree: tree} = map, key, value) do
    %SortedMap{map | tree: :gb_trees.enter(key, value, tree)}
  end

  @doc """
  Updates a key if it exists, otherwise sets a default value.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1})
      iex> SortedMap.update(sm, :a, fn val -> val + 1 end) |> SortedMap.get(:a)
      2

      iex> SortedMap.new(%{a: 1}) |> SortedMap.update(:b, fn val -> val + 1 end, 10) |> SortedMap.get(:b)
      10
  """
  @spec update(SortedMap.t(), any(), (any() -> any()), any()) :: SortedMap.t()
  def update(%SortedMap{} = map, key, fun, default \\ nil) do
    case get(map, key) do
      nil -> put(map, key, default)
      val -> put(map, key, fun.(val))
    end
  end

  @doc """
  Retrieves a value by key, returning a default if missing.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1})
      iex> SortedMap.get(sm, :a)
      1
      iex> SortedMap.get(sm, :b, :default)
      :default
  """
  @spec get(SortedMap.t(), any(), any()) :: any()
  def get(%SortedMap{tree: tree}, key, default \\ nil) do
    case :gb_trees.lookup(key, tree) do
      {:value, val} -> val
      :none -> default
    end
  end

  @doc """
  Checks if a key exists.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1, b: 2})
      iex> SortedMap.has_key?(sm, :a)
      true
      iex> SortedMap.has_key?(sm, :c)
      false
  """
  @spec has_key?(SortedMap.t(), any()) :: boolean()
  def has_key?(%SortedMap{tree: tree}, key), do: :gb_trees.is_defined(key, tree)

  @doc """
  Deletes a key.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1, b: 2})
      iex> sm2 = SortedMap.delete(sm, :b)
      iex> SortedMap.has_key?(sm2, :b)
      false
  """
  @spec delete(SortedMap.t(), any()) :: SortedMap.t()
  def delete(%SortedMap{tree: tree} = map, key) do
    %SortedMap{map | tree: :gb_trees.delete_any(key, tree)}
  end

  @doc """
  Returns the smallest key. Returns `:none` if the map is empty.

  ## Examples

      iex> sm = SortedMap.new(%{b: 2, a: 1, c: 3})
      iex> SortedMap.min_key(sm)
      :a

      iex> sm_empty = SortedMap.new()
      iex> SortedMap.min_key(sm_empty)
      :none
  """
  @spec min_key(SortedMap.t()) :: any()
  def min_key(%SortedMap{tree: tree}) do
    if :gb_trees.is_empty(tree) do
      :none
    else
      {key, _val} = :gb_trees.smallest(tree)
      key
    end
  end

  @doc """
  Returns the largest key. Returns `:none` if the map is empty.

  ## Examples

      iex> sm = SortedMap.new(%{b: 2, a: 1, c: 3})
      iex> SortedMap.max_key(sm)
      :c

      iex> sm_empty = SortedMap.new()
      iex> SortedMap.max_key(sm_empty)
      :none
  """
  @spec max_key(SortedMap.t()) :: any()
  def max_key(%SortedMap{tree: tree}) do
    if :gb_trees.is_empty(tree) do
      :none
    else
      case :gb_trees.largest(tree) do
        {key, _val} -> key
        _ -> nil
      end
    end
  end

  @doc """
  Returns all key-value pairs in sorted order.

  ## Examples

      iex> sm = SortedMap.new(%{b: 2, a: 1})
      iex> SortedMap.to_list(sm)
      [{:a, 1}, {:b, 2}]
  """
  @spec to_list(SortedMap.t()) :: [{any(), any()}]
  def to_list(%SortedMap{tree: tree}), do: :gb_trees.to_list(tree)

  @doc """
  Converts the `SortedMap` into a standard `Map`, losing the sorted property.

  ## Examples

      iex> sm = SortedMap.new(%{b: 2, a: 1})
      iex> SortedMap.to_map(sm)
      %{a: 1, b: 2}
  """
  @spec to_map(SortedMap.t()) :: map()
  def to_map(%SortedMap{tree: tree}), do: Enum.into(:gb_trees.to_list(tree), %{})

  @doc """
  Iterates over a range of keys, returning key-value pairs
  whose keys are between `min` and `max` (inclusive).

  ## Examples

      iex> sm = SortedMap.new(%{a: 1, b: 2, c: 3, d: 4})
      iex> SortedMap.range(sm, :b, :c)
      [{:b, 2}, {:c, 3}]
  """
  @spec range(SortedMap.t(), any(), any()) :: [{any(), any()}]
  def range(%SortedMap{tree: tree}, min, max) do
    tree
    |> :gb_trees.to_list()
    |> Enum.reduce([], fn {key, value}, acc ->
      if key >= min and key <= max, do: [{key, value} | acc], else: acc
    end)
    |> Enum.reverse()
  end
end
