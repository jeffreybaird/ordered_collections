defimpl Enumerable, for: OrderedCollections.SortedSet do
  alias OrderedCollections.SortedSet

  @type element() :: any()

  @doc """
  Reduces the SortedSet using :gb_sets.fold.

  This implementation unwraps the accumulator from the `{:cont, acc}` tuple,
  passes a plain accumulator to :gb_sets.fold/3, and then wraps the result back
  in `{:cont, result}`.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> Enum.reduce(set, 0, fn x, acc -> x + acc end)
      6
  """
  @spec reduce(OrderedCollections.SortedSet.t(), {:cont, any()}, any()) ::
          {:cont, any()}
          | {:halted, any()}
          | {:suspended, any(), (any() -> {any(), any()} | {any(), any(), any()})}
  def reduce(%SortedSet{set: set}, {:cont, acc}, fun) do
    result =
      :gb_sets.fold(
        fn element, acc ->
          case fun.(element, acc) do
            {:cont, new_acc} -> new_acc
          end
        end,
        acc,
        set
      )

    {:cont, result}
  end

  def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(set, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(set, &1, fun)}

  def count(%SortedSet{set: set}) do
    {:ok, :gb_sets.size(set)}
  end

  @spec member?(OrderedCollections.SortedSet.t(), any()) :: {:ok, boolean()}
  @doc """
  Implementation of member? for the Enumerable implementation of SortedSet.

  ## Examples

      iex> set = SortedSet.new([3, 1, 2])
      iex> Enum.member?(set, 1)
      true
      iex> Enum.member?(set, 4)
      false
  """
  @spec member?(OrderedCollections.SortedSet.t(), any()) :: {:ok, boolean()}
  def member?(%SortedSet{set: set}, value) do
    {:ok, :gb_sets.is_member(value, set)}
  end

  @doc """
  Implementation of slice for the Enumerable implementation of SortedSet.

  ## Examples

      iex> set = SortedSet.new([3, 1, 2])
      iex> Enum.slice(set,0,1)
      [1]

  """
  def slice(%SortedSet{set: set}) do
    sorted_list = :gb_sets.to_list(set)
    count = length(sorted_list)

    slicer = fn start, length, _step ->
      Enum.slice(sorted_list, start, length)
    end

    {:ok, count, slicer}
  end
end
