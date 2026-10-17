defimpl Enumerable, for: OrderedCollections.SortedMap do
  alias OrderedCollections.SortedMap

  @doc """
  Reduces the SortedMap by traversing its underlying tree in sorted order.

  This function is used by `Enum.reduce/3` to iterate over the map’s key–value pairs.
  It handles the control signals `:cont`, `:halt`, and `:suspend` as required by the
  `Enumerable` protocol.

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2, c: 3})
      iex> Enum.reduce(map, [], fn {k, _v}, acc -> [k | acc] end)
      [:c, :b, :a]
      iex> Enum.reduce(map, [], fn {k, _v}, acc -> [k | acc] end) |> Enum.reverse()
      [:a, :b, :c]
  """
  @spec reduce(SortedMap.t(), Enumerable.acc(), Enumerable.reducer()) :: Enumerable.result()
  def reduce(%SortedMap{tree: tree}, acc, fun) do
    reduce_iterator(:gb_trees.iterator(tree), acc, fun)
  end

  @doc """
  Returns the total number of elements in the SortedMap.

  This function is used by `Enum.count/1` and returns `{:ok, count}`,
  where the count is determined by the underlying `:gb_trees.size/1`.

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2, c: 3})
      iex> Enum.count(map)
      3
  """
  @spec count(OrderedCollections.SortedMap.t()) :: {:ok, non_neg_integer()}
  def count(%SortedMap{tree: tree}) do
    {:ok, :gb_trees.size(tree)}
  end

  @doc """
  Checks for membership of a given key–value pair in the SortedMap.

  This function is invoked by `Enum.member?/2`. It returns `{:ok, true}` if the key exists
  and both the stored key and value match strictly (`===`), otherwise `{:ok, false}`.

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2})
      iex> Enum.member?(map, {:a, 1})
      true
      iex> Enum.member?(map, {:c, 3})
      false
      iex> Enum.member?(map, {:a, 1.0})
      false
  """
  @spec member?(OrderedCollections.SortedMap.t(), any()) :: {:ok, boolean()}
  def member?(%SortedMap{tree: tree}, {key, _value} = pair) do
    case :gb_trees.next(:gb_trees.iterator_from(key, tree)) do
      {stored_key, stored_value, _iterator} -> {:ok, {stored_key, stored_value} === pair}
      :none -> {:ok, false}
    end
  end

  def member?(%SortedMap{}, _other), do: {:ok, false}

  @doc """
  Implements index-based slicing for the SortedMap.

  This function is used by `Enum.slice/2` to extract a subrange from the SortedMap.
  It returns a tuple `{:ok, count, slicer_fun}` where `count` is the total number of elements,
  and `slicer_fun` accepts `(start, length, step)` and returns the requested
  key–value pairs without traversing the remainder of the map.

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2, c: 3, d: 4})
      iex> Enum.slice(map, 1, 2)
      [b: 2, c: 3]
      iex> Enum.slice(map, 0, 3)
      [a: 1, b: 2, c: 3]
  """
  @spec slice(OrderedCollections.SortedMap.t()) :: {:ok, any(), (any(), any(), any() -> list())}
  def slice(%SortedMap{tree: tree}) do
    slicer = fn
      _start, 0, _step ->
        []

      start, length, step ->
        tree
        |> :gb_trees.iterator()
        |> skip(start)
        |> take_slice(length, step, [])
    end

    {:ok, :gb_trees.size(tree), slicer}
  end

  defp reduce_iterator(_iterator, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_iterator(iterator, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce_iterator(iterator, &1, fun)}

  defp reduce_iterator(iterator, {:cont, acc}, fun) do
    reduce_cont(iterator, acc, fun)
  end

  defp reduce_cont(iterator, acc, fun) do
    case :gb_trees.next(iterator) do
      :none ->
        {:done, acc}

      {key, value, next} ->
        case fun.({key, value}, acc) do
          {:cont, next_acc} -> reduce_cont(next, next_acc, fun)
          signal -> reduce_iterator(next, signal, fun)
        end
    end
  end

  defp skip(iterator, 0), do: iterator

  defp skip(iterator, count) do
    case :gb_trees.next(iterator) do
      :none -> iterator
      {_, _, next} -> skip(next, count - 1)
    end
  end

  defp take_slice(_iterator, 0, _step, acc), do: Enum.reverse(acc)

  defp take_slice(iterator, length, step, acc) do
    case :gb_trees.next(iterator) do
      :none ->
        Enum.reverse(acc)

      {key, value, _next} when length == 1 ->
        Enum.reverse([{key, value} | acc])

      {key, value, next} ->
        take_slice(skip(next, step - 1), length - 1, step, [{key, value} | acc])
    end
  end
end
