defmodule OrderedCollections.SortedMap do
  alias __MODULE__, as: SortedMap
  alias OrderedCollections.SortedSet

  @moduledoc """
  A sorted key-value store implemented using Erlang's `:gb_trees` (Red-Black Trees).

  This module stores items in sorted order by their keys and offers a rich set of features that allow it to integrate seamlessly with Elixir’s core protocols:

  - **Enumerable:**
    SortedMap implements the Enumerable protocol. This means you can use all the standard functions in the `Enum` module (like `Enum.map/2`, `Enum.reduce/3`, and `Enum.slice/2`) directly on a SortedMap.

    **Example:**

        iex> map = SortedMap.new(%{b: 2, a: 1, c: 3})
        iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
        [a: 2, b: 4, c: 6]

  - **Collectable:**
    SortedMap implements the Collectable protocol, allowing you to build a SortedMap from any enumerable using `Enum.into/2`.

    **Example:**

        iex> map = Enum.into([{:a, 1}, {:b, 2}], SortedMap.new())
        iex> SortedMap.to_list(map)
        [a: 1, b: 2]

  - **Inspect:**
    SortedMap implements the Inspect protocol, providing a clean and concise representation when you use `IO.inspect/1`.

    **Example:**
        iex> map = SortedMap.new(%{b: 2, a: 1})
        iex> captured = ExUnit.CaptureIO.capture_io(fn -> IO.inspect(map) end)
        iex> captured
        ~s(#SortedMap<%{a: 1, b: 2}>\\n)


  - **JSON Encoding:**
    SortedMap implements the JSON.Encoder protocol (using the native JSON support in Elixir 1.18 and later). This ensures that when you encode a SortedMap to JSON, the keys appear in sorted order.

    **Example:**

        iex> map = SortedMap.new(%{a: 1, b: 2})
        iex> JSON.encode!(map)
        ~s({"a":1,"b":2})

  ## Implementation Details

  Internally, SortedMap wraps Erlang's `:gb_trees` to achieve efficient insertion, lookup, and deletion operations while automatically maintaining the order of keys. By leveraging the power of Erlang's native data structures and integrating with protocols like Enumerable, Collectable, Inspect, and JSON.Encoder, SortedMap behaves like a first-class Elixir collection with a familiar API.

  """

  @type t :: %SortedMap{tree: :gb_trees.tree()}
  defstruct tree: :gb_trees.empty()

  @type non_empty_t() :: %__MODULE__{tree: non_empty_tree()}
  @type non_empty_tree() :: :gb_trees.tree()

  @doc """
  Creates a new empty sorted map.

  ## Examples

      iex> sm = SortedMap.new()
      iex> SortedMap.to_map(sm)
      %{}
  """
  @spec new() :: SortedMap.t()
  def new(), do: %__MODULE__{}

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
  def new(map = %{}) do
    tree = Enum.reduce(map, :gb_trees.empty(), fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end)
    %SortedMap{tree: tree}
  end

  @doc """
  Returns the keys of the SortedMap in sorted order.

  ## Examples

      iex> sm = SortedMap.new(%{b: 2, a: 1, c: 3})
      iex> SortedMap.keys(sm)
      [:a, :b, :c]
  """
  @spec keys(SortedMap.t()) :: list()
  def keys(%SortedMap{tree: tree}) do
    :gb_trees.keys(tree)
  end

  @doc """
  Returns the values of the SortedMap in the order corresponding to the sorted keys.

  ## Examples

      iex> sm = SortedMap.new(%{b: 2, a: 1, c: 3})
      iex> SortedMap.values(sm)
      [1, 2, 3]
  """
  @spec values(SortedMap.t()) :: list()
  def values(sorted_map = %__MODULE__{}) do
    sorted_map |> Enum.map(fn {_, v} -> v end)
  end

  @doc """
  Merges two SortedMaps. In case of duplicate keys, values from the second map override those from the first.

  ## Examples

      iex> sm1 = SortedMap.new(%{a: 1, b: 2})
      iex> sm2 = SortedMap.new(%{b: 3, c: 4})
      iex> SortedMap.merge(sm1, sm2) |> SortedMap.to_list()
      [{:a, 1}, {:b, 3}, {:c, 4}]
  """
  @spec merge(OrderedCollections.SortedMap.t(), OrderedCollections.SortedMap.t()) :: any()
  def merge(sorted_map1 = %__MODULE__{}, sorted_map2 = %__MODULE__{}) do
    sorted_map2 |> Enum.into(sorted_map1)
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
  Updates a key with a function. If the key doesn’t exist,
  it is set to `nil`.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1})
      iex> sm = SortedMap.update(sm, :a, &(&1 + 1))
      iex> SortedMap.get(sm, :a)
      2

      iex> SortedMap.new(%{a: 1}) |> SortedMap.update(:b, &(&1 + 1)) |> SortedMap.get(:b)
      nil
  """

  @spec update(SortedMap.t(), any(), (any() -> any())) :: t()
  def update(%__MODULE__{} = map, key, fun) do
    # Get the current value for the key
    case get(map, key) do
      # If the key doesn't exist, set it to nil
      nil -> put(map, key, nil)
      # Otherwise, update the value with the function
      val -> put(map, key, fun.(val))
    end
  end

  @doc """
  Updates a key with a function. If the key doesn’t exist,
  it sets it to `default`.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1})
      iex> sm = SortedMap.update(sm, :a, &(&1 + 5), 0)
      iex> SortedMap.get(sm, :a)
      6

      iex> SortedMap.new(%{a: 1}) |> SortedMap.update(:b, &(&1 + 1), 10) |> SortedMap.get(:b)
      10
  """
  @spec update(SortedMap.t(), any(), (any() -> any()), any()) :: t()
  def update(%__MODULE__{} = map, key, fun, default) do
    case get(map, key) do
      nil -> put(map, key, default)
      val -> put(map, key, fun.(val))
    end
  end

  @doc """
  Replaces the value for `key` with `new_value` if the key exists.
  If `key` does not exist, the map remains unchanged.

  ## Examples

      iex> sm = SortedMap.new(%{a: 1, b: 2})
      iex> sm = SortedMap.update_with_value(sm, :a, 100)
      iex> SortedMap.get(sm, :a)
      100
      iex> SortedMap.update_with_value(sm, :c, 300)
      iex> SortedMap.get(sm, :c)
      nil
  """
  @spec update_with_value(SortedMap.t(), any(), any()) :: t()
  def update_with_value(%__MODULE__{} = map, key, new_value) do
    if has_key?(map, key) do
      put(map, key, new_value)
    else
      map
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

      iex> sm = SortedMap.new(%{b: 10, a: 99, c: 3})
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
      {key, _val} = :gb_trees.largest(tree)
      key
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

      iex> sm = SortedMap.new(%{a: 2, b: 1})
      iex> captured = ExUnit.CaptureIO.capture_io(fn -> IO.inspect(sm) end)
      iex> captured
      ~s(#SortedMap<%{a: 2, b: 1}>\\n)
      iex> SortedMap.to_map(sm)
      %{a: 2, b: 1}
  """
  @spec to_map(SortedMap.t()) :: map()
  def to_map(sorted_map) do
    SortedMap.to_list(sorted_map)
    |> SortedSet.new()
    |> Enum.into(Map.new())
  end

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

  @doc """
  Rebalances the tree.

  ## Examples

  iex> sm = SortedMap.new(%{a: 1, b: 2, c: 3})
  iex> smi = SortedMap.new() |> SortedMap.put(:a, 1) |> SortedMap.put(:b, 2) |> SortedMap.put(:c, 3)
  iex> sm == smi
  false
  iex> sm |> SortedMap.rebalance() == smi |> SortedMap.rebalance()
  true
  """
  @spec rebalance(OrderedCollections.SortedMap.t()) :: OrderedCollections.SortedMap.t()
  def rebalance(%SortedMap{tree: tree}) do
    tree = :gb_trees.balance(tree)
    %SortedMap{tree: tree}
  end
end
