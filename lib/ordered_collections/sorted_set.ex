defmodule OrderedCollections.SortedSet do
  @moduledoc """
  A sorted set implemented using Erlang's `:gb_sets`.

  This module provides a sorted set data structure that stores unique elements in sorted order.
  Internally, it wraps Erlang's `:gb_sets` to provide efficient operations (insertion, deletion, and
  membership checking). SortedSet is designed to integrate seamlessly with Elixir’s core protocols,
  making it behave like a first-class Elixir collection.

  ### Protocol Support

  - **Enumerable:**
    SortedSet implements the Enumerable protocol. This means you can traverse the set using functions
    like `Enum.map/2`, `Enum.reduce/3`, and `Enum.slice/2`, all while preserving the sorted order of elements.

    **Example:**
        iex> set = SortedSet.new([3, 1, 2])
        iex> Enum.map(set, &(&1 * 2))
        [2, 4, 6]

  - **Collectable:**
    SortedSet implements the Collectable protocol, allowing you to build a SortedSet from any enumerable
    using `Enum.into/2`.

    **Example:**
        iex> set = Enum.into([3, 1, 2], SortedSet.new())
        iex> SortedSet.to_list(set)
        [1, 2, 3]

  - **Inspect:**
    SortedSet implements the Inspect protocol, providing a clean and readable output when you use
    `IO.inspect/1`.

    **Example:**
        iex> set = SortedSet.new([3, 1, 2])
        iex> captured = ExUnit.CaptureIO.capture_io(fn -> IO.inspect(set) end)
        iex> captured
        ~s(#SortedSet<[1, 2, 3]>\\n)

  - **JSON Encoding:**
    SortedSet implements the JSON.Encoder protocol (using Elixir 1.18's native JSON support) so that
    when you encode a SortedSet to JSON, it is represented as an array with the elements in sorted order.

    **Example:**
        iex> set = SortedSet.new([3, 1, 2])
        iex> JSON.encode!(set)
        "[1,2,3]"

  ### Implementation Details

  Internally, SortedSet leverages Erlang's `:gb_sets` to maintain a sorted collection of unique elements.
  By integrating with Enumerable, Collectable, Inspect, and JSON.Encoder, SortedSet provides a natural,
  idiomatic API that behaves just like other Elixir collections while preserving the sorted order of its elements.
  """

  alias __MODULE__, as: SortedSet

  @opaque t :: %SortedSet{set: element()}
  defstruct set: :gb_sets.empty()

  @type non_empty_t() :: %__MODULE__{
          set: non_empty_set()
        }

  @type non_empty_set() :: :gb_sets.set()

  @type element() :: any()

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

  Returns the set unchanged if the item already exists in the set

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([2, 3])
      iex> set = OrderedCollections.SortedSet.add(set, 1)
      iex> set = OrderedCollections.SortedSet.add(set, 3)
      iex> OrderedCollections.SortedSet.to_list(set)
      [1, 2, 3]
  """
  @spec add(SortedSet.t(), element()) :: SortedSet.t()
  def add(%SortedSet{set: set}, value) do
    case SortedSet.member?(%SortedSet{set: set}, value) do
      true -> %SortedSet{set: set}
      false -> %SortedSet{set: :gb_sets.insert(value, set)}
    end
  end

  @doc """
  Deletes a value from the SortedSet.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([1, 2, 3])
      iex> set = OrderedCollections.SortedSet.delete(set, 2)
      iex> OrderedCollections.SortedSet.to_list(set)
      [1, 3]
  """
  @spec delete(SortedSet.t(), element()) :: SortedSet.t()
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
  @spec member?(SortedSet.t(), element()) :: boolean()
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
  @spec min(non_empty_t()) :: element()
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
  @spec max(non_empty_t()) :: element()
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
  @spec range(SortedSet.t(), element(), element()) :: list()
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

  @doc """
  Returns a new SortedSet that contains elements present in both sets.

  ## Examples

      iex> set1 = SortedSet.new([1, 2, 3])
      iex> set2 = SortedSet.new([2, 3, 4])
      iex> SortedSet.intersection(set1, set2) |> SortedSet.to_list()
      [2, 3]
  """
  @spec intersection(SortedSet.t(), SortedSet.t()) :: SortedSet.t()
  def intersection(%SortedSet{set: s1}, %SortedSet{set: s2}) do
    %SortedSet{set: :gb_sets.intersection(s1, s2)}
  end
end
