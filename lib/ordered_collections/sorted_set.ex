defmodule OrderedCollections.SortedSet do
  @moduledoc """
  A sorted set implemented using Erlang's `:gb_sets`.

  This module provides a sorted set data structure with efficient insertions,
  deletions, and membership checks. Internally it wraps Erlang's `:gb_sets`
  to maintain elements in sorted order.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new()
      iex> OrderedCollections.SortedSet.to_list(set)
      []

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> OrderedCollections.SortedSet.to_list(set)
      [1, 2, 3]
  """

  alias __MODULE__, as: SortedSet

  @opaque t :: %SortedSet{set: any()}
  defstruct set: :gb_sets.empty()

  @type non_empty_t() :: %__MODULE__{
          set: non_empty_set()
        }

  @type non_empty_set() :: :gb_sets.set()

  @doc """
  Creates a new empty SortedSet.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new()
      iex> OrderedCollections.SortedSet.to_list(set)
      []
  """
  @spec new() :: SortedSet.t()
  def new(), do: %SortedSet{set: :gb_sets.empty()}

  @doc """
  Creates a new SortedSet from a list.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> OrderedCollections.SortedSet.to_list(set)
      [1, 2, 3]
  """
  @spec new(list()) :: SortedSet.t()
  def new(list) when is_list(list) do
    %SortedSet{set: Enum.reduce(list, :gb_sets.empty(), &:gb_sets.insert/2)}
  end

  @doc """
  Adds a value to the SortedSet.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([2, 3])
      iex> set = OrderedCollections.SortedSet.add(set, 1)
      iex> OrderedCollections.SortedSet.to_list(set)
      [1, 2, 3]
  """
  @spec add(SortedSet.t(), any()) :: SortedSet.t()
  def add(%SortedSet{set: set}, value) do
    %SortedSet{set: :gb_sets.insert(value, set)}
  end

  @doc """
  Deletes a value from the SortedSet.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([1, 2, 3])
      iex> set = OrderedCollections.SortedSet.delete(set, 2)
      iex> OrderedCollections.SortedSet.to_list(set)
      [1, 3]
  """
  @spec delete(SortedSet.t(), any()) :: SortedSet.t()
  def delete(%SortedSet{set: set}, value) do
    %SortedSet{set: :gb_sets.delete_any(value, set)}
  end

  @doc """
  Checks if a value is a member of the SortedSet.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([1, 2, 3])
      iex> OrderedCollections.SortedSet.member?(set, 2)
      true
      iex> OrderedCollections.SortedSet.member?(set, 4)
      false
  """
  @spec member?(SortedSet.t(), any()) :: boolean()
  def member?(%SortedSet{set: set}, value) do
    :gb_sets.is_member(value, set)
  end

  @doc """
  Returns the minimum element of the SortedSet.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> OrderedCollections.SortedSet.min(set)
      1
  """
  @spec min(non_empty_t()) :: any()
  def min(%SortedSet{set: set}) do
    :gb_sets.smallest(set)
  end

  @doc """
  Returns the maximum element of the SortedSet.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> OrderedCollections.SortedSet.max(set)
      3
  """
  @spec max(non_empty_t()) :: any()
  def max(%SortedSet{set: set}) do
    :gb_sets.largest(set)
  end

  @doc """
  Converts the SortedSet into a list of elements in sorted order.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> OrderedCollections.SortedSet.to_list(set)
      [1, 2, 3]
  """
  @spec to_list(SortedSet.t()) :: list()
  def to_list(%SortedSet{set: set}) do
    :gb_sets.to_list(set)
  end

  @doc """
  Returns a list of elements in the SortedSet that fall within the given range (inclusive).

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([1, 2, 3, 4, 5])
      iex> OrderedCollections.SortedSet.range(set, 2, 4)
      [2, 3, 4]
  """
  @spec range(SortedSet.t(), any(), any()) :: list()
  def range(%SortedSet{set: set}, min, max) do
    set
    |> :gb_sets.to_list()
    |> Enum.reduce([], fn elem, acc ->
      if elem >= min and elem <= max, do: [elem | acc], else: acc
    end)
    |> Enum.reverse()
  end

  @doc """
  Returns a new SortedSet that is the union of two SortedSets.

  ## Examples

      iex> set1 = OrderedCollections.SortedSet.new([1, 3, 5])
      iex> set2 = OrderedCollections.SortedSet.new([2, 3, 4])
      iex> OrderedCollections.SortedSet.union(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [1, 2, 3, 4, 5]
  """
  @spec union(SortedSet.t(), SortedSet.t()) :: SortedSet.t()
  def union(%SortedSet{set: s1}, %SortedSet{set: s2}) do
    %SortedSet{set: :gb_sets.union(s1, s2)}
  end

  @doc """
  Returns a new SortedSet that contains elements in the first set that are not present in the second.

  ## Examples

      iex> set1 = OrderedCollections.SortedSet.new([1, 2, 3, 4, 5])
      iex> set2 = OrderedCollections.SortedSet.new([2, 4])
      iex> OrderedCollections.SortedSet.difference(set1, set2) |> OrderedCollections.SortedSet.to_list()
      [1, 3, 5]
  """
  @spec difference(SortedSet.t(), SortedSet.t()) :: SortedSet.t()
  def difference(%SortedSet{set: s1}, %SortedSet{set: s2}) do
    %SortedSet{set: :gb_sets.subtract(s1, s2)}
  end
end
