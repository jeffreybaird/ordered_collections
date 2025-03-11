defmodule SortedMap do
  @moduledoc """
  A sorted key-value store implemented using Erlang's `:gb_trees` (Red-Black Trees).
  """

  @opaque t :: %SortedMap{tree: :gb_trees.tree()}
  defstruct tree: :gb_trees.empty()

  @spec new() :: SortedMap.t()
  @doc "Creates a new empty sorted map."
  def new(), do: %SortedMap{}

  @spec new(map()) :: SortedMap.t()
  @doc "Creates a new sorted map from a standard map."
  def new(map) when is_map(map) do
    tree = Enum.reduce(map, :gb_trees.empty(), fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end)
    %SortedMap{tree: tree}
  end

  @spec put(SortedMap.t(), any(), any()) :: SortedMap.t()
  @doc "Inserts a key-value pair, maintaining order."
  def put(%SortedMap{tree: tree} = map, key, value) do
    %SortedMap{map | tree: :gb_trees.insert(key, value, tree)}
  end

  @spec update(SortedMap.t(), any(), any()) :: SortedMap.t()
  @doc "Updates a key if it exists, otherwise sets a default value."
  def update(%SortedMap{} = map, key, fun, default \\ nil) do
    case get(map, key) do
      nil -> put(map, key, default)
      val -> put(map, key, fun.(val))
    end
  end

  @doc "Retrieves a value by key, returning a default if missing."
  @spec get(SortedMap.t(), any(), any()) :: any()
  def get(%SortedMap{tree: tree}, key, default \\ nil) do
    case :gb_trees.lookup(key, tree) do
      {:value, val} -> val
      :none -> default
    end
  end

  @doc "Checks if a key exists."
  @spec has_key?(SortedMap.t(), any()) :: boolean()
  def has_key?(%SortedMap{tree: tree}, key), do: :gb_trees.is_defined(key, tree)

  @spec delete(SortedMap.t(), any()) :: SortedMap.t()
  @doc "Deletes a key."
  def delete(%SortedMap{tree: tree} = map, key) do
    %SortedMap{map | tree: :gb_trees.delete_any(key, tree)}
  end

  @spec min_key(SortedMap.t()) :: any()
  @doc "Returns the smallest key."
  def min_key(%SortedMap{tree: tree}) do
    case :gb_trees.smallest(tree) do
      {key, _val} -> key
      _ -> nil
    end
  end

  @spec max_key(SortedMap.t()) :: any()
  @doc "Returns the largest key."
  def max_key(%SortedMap{tree: tree}) do
    case :gb_trees.largest(tree) do
      {key, _val} -> key
      _ -> nil
    end
  end

  @spec to_list(SortedMap.t()) :: [{any(), any()}]
  @doc "Returns all key-value pairs in sorted order."
  def to_list(%SortedMap{tree: tree}), do: :gb_trees.to_list(tree)

  @spec to_map(SortedMap.t()) :: any()
  @doc "Converts the SortedMap into a standard Map (losing order)."
  def to_map(%SortedMap{tree: tree}), do: Enum.into(:gb_trees.to_list(tree), %{})

  @spec range(SortedMap.t(), any(), any()) :: list()
  @doc "Iterates over a range of keys."
  def range(%SortedMap{tree: tree}, min, max) do
    tree
    |> :gb_trees.to_list()
    |> Enum.reduce([], fn {key, value}, acc ->
      if key >= min and key <= max, do: [{key, value} | acc], else: acc
    end)
    |> Enum.reverse()
  end
end
