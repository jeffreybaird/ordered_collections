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
  @spec reduce(OrderedCollections.SortedMap.t(), {:cont, any()}, any()) ::
          {:cont, any()}
          | {:halted, any()}
          | {:suspended, any(), (any() -> {any(), any()} | {any(), any(), any()})}
  def reduce(%SortedMap{tree: {_, root_node}}, {:cont, acc}, fun) do
    traverse_tree(root_node, acc, fun)
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
  in the map (ignoring the value), otherwise `{:ok, false}`.

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2})
      iex> Enum.member?(map, {:a, 1})
      true
      iex> Enum.member?(map, {:c, 3})
      false
  """
  @spec member?(OrderedCollections.SortedMap.t(), {any(), any()}) :: {:ok, boolean()}
  def member?(%SortedMap{tree: tree}, {key, _value}) do
    {:ok, :gb_trees.is_defined(key, tree)}
  end

  @doc """
  Implements index-based slicing for the SortedMap.

  This function is used by `Enum.slice/2` to extract a subrange from the SortedMap.
  It returns a tuple `{:ok, count, slicer_fun}` where `count` is the total number of elements,
  and `slicer_fun` is a function that accepts `(start, length, step)` (with step ignored) and
  returns a list of key–value pairs starting at that index.

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2, c: 3, d: 4})
      iex> Enum.slice(map, 1, 2)
      [b: 2, c: 3]
      iex> Enum.slice(map, 0, 3)
      [a: 1, b: 2, c: 3]
  """
  @spec slice(OrderedCollections.SortedMap.t()) :: {:ok, any(), (any(), any(), any() -> list())}
  def slice(%SortedMap{tree: {size, root}}) do
    slicer = fn start, length, _step ->
      {_, acc, _remaining} = collect_slice(root, start, length, 0, [])
      Enum.reverse(acc)
    end

    {:ok, size, slicer}
  end

  defp traverse_tree(nil, acc, _fun), do: {:cont, acc}

  defp traverse_tree({key, value, left, right}, acc, fun) do
    case traverse_tree(left, acc, fun) do
      {:cont, acc} ->
        case fun.({key, value}, acc) do
          {:cont, new_acc} -> traverse_tree(right, new_acc, fun)
          {:halt, final_acc} -> {:halted, final_acc}
          {:suspend, suspended_acc} -> {:suspended, suspended_acc, &traverse_tree(right, &1, fun)}
        end

      other ->
        other
    end
  end

  # Base case: If we hit a nil node, return the current index, accumulator, and remaining length.
  defp collect_slice(nil, _start, length, index, acc) do
    {index, acc, length}
  end

  # In-order traversal: traverse left, process current node, then traverse right.
  defp collect_slice({key, value, left, right}, start, length, index, acc) do
    # Traverse the left subtree first.
    {index, acc, length} = collect_slice(left, start, length, index, acc)

    new_index = index + 1

    {acc, length} =
      if new_index > start and length > 0 do
        # We are past the start index and still need elements, so collect the current node.
        {[{key, value} | acc], length - 1}
      else
        # Otherwise, leave the accumulator and length unchanged.
        {acc, length}
      end

    # If we've collected the required number of elements, stop traversing further.
    if length == 0 do
      {new_index, acc, length}
    else
      # Otherwise, continue with the right subtree.
      collect_slice(right, start, length, new_index, acc)
    end
  end
end
