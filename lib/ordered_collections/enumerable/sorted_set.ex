defimpl Enumerable, for: OrderedCollections.SortedSet do
  alias OrderedCollections.SortedSet

  @type element() :: any()

  @doc """
  Reduces the SortedSet in sorted order using Erlang's public fold operation.

  Supports continuation and early halt. After suspension, a public Erlang iterator
  resumes immediately after the consumed element. Exhaustion returns
  `{:done, accumulator}`.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> Enum.reduce(set, 0, fn x, acc -> x + acc end)
      6
  """
  @spec reduce(SortedSet.t(), Enumerable.acc(), Enumerable.reducer()) :: Enumerable.result()
  def reduce(%SortedSet{set: set}, acc, fun), do: reduce_set(set, acc, fun)

  defp reduce_set(_set, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_set(set, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce_set(set, &1, fun)}

  defp reduce_set(set, {:cont, acc}, fun) do
    # Only our private throws interrupt the fold; callback exceptions, exits,
    # and arbitrary throws must propagate unchanged.
    tag = make_ref()

    try do
      result =
        :gb_sets.fold(
          fn element, acc ->
            case fun.(element, acc) do
              {:cont, next_acc} -> next_acc
              {:halt, next_acc} -> throw({tag, :halt, next_acc})
              {:suspend, next_acc} -> throw({tag, :suspend, element, next_acc})
            end
          end,
          acc,
          set
        )

      {:done, result}
    catch
      {^tag, :halt, halted_acc} ->
        {:halted, halted_acc}

      {^tag, :suspend, element, suspended_acc} ->
        {_stored, iterator} = :gb_sets.next(:gb_sets.iterator_from(element, set))
        {:suspended, suspended_acc, &reduce_iterator(iterator, &1, fun)}
    end
  end

  def count(%SortedSet{set: set}) do
    {:ok, :gb_sets.size(set)}
  end

  @doc """
  Checks membership with strict equality (`===`). Unlike `SortedSet.member?/2`,
  numeric equivalents must match the stored representation.

  ## Examples

      iex> set = SortedSet.new([3, 1, 2])
      iex> Enum.member?(set, 1)
      true
      iex> Enum.member?(set, 4)
      false
      iex> Enum.member?(set, 1.0)
      false
  """
  @spec member?(OrderedCollections.SortedSet.t(), any()) :: {:ok, boolean()}
  def member?(%SortedSet{set: set}, value) do
    case :gb_sets.next(:gb_sets.iterator_from(value, set)) do
      {stored, _iterator} -> {:ok, stored === value}
      :none -> {:ok, false}
    end
  end

  @doc """
  Returns a bounded iterator slicer supporting start, length, and step.

  ## Examples

      iex> set = SortedSet.new([3, 1, 2])
      iex> Enum.slice(set,0,1)
      [1]

  """
  def slice(%SortedSet{set: set}) do
    slicer = fn
      _start, 0, _step ->
        []

      start, length, step ->
        set
        |> :gb_sets.iterator()
        |> skip(start)
        |> take_slice(length, step, [])
    end

    {:ok, :gb_sets.size(set), slicer}
  end

  defp reduce_iterator(_iterator, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_iterator(iterator, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce_iterator(iterator, &1, fun)}

  defp reduce_iterator(iterator, {:cont, acc}, fun) do
    case :gb_sets.next(iterator) do
      :none -> {:done, acc}
      {element, next} -> reduce_iterator(next, fun.(element, acc), fun)
    end
  end

  defp skip(iterator, 0), do: iterator

  defp skip(iterator, count) do
    case :gb_sets.next(iterator) do
      :none -> iterator
      {_, next} -> skip(next, count - 1)
    end
  end

  defp take_slice(_iterator, 0, _step, acc), do: Enum.reverse(acc)

  defp take_slice(iterator, length, step, acc) do
    case :gb_sets.next(iterator) do
      :none -> Enum.reverse(acc)
      {element, _next} when length == 1 -> Enum.reverse([element | acc])
      {element, next} -> take_slice(skip(next, step - 1), length - 1, step, [element | acc])
    end
  end
end
