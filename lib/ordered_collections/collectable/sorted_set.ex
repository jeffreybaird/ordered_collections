defimpl Collectable, for: OrderedCollections.SortedSet do
  alias OrderedCollections.SortedSet

  @doc """
  Implements the `into` function for the `Collectable` protocol.
  This function is used to collect elements into a SortedSet.

  ## Examples

      iex> Enum.into([3, 1, 2], SortedSet.new()) |> SortedSet.to_list()
      [1, 2, 3]

      iex> Enum.into([3, 1, 2], SortedSet.new([3,5,9,-1])) |> SortedSet.to_list()
      [-1, 1, 2, 3, 5, 9]
  """
  @spec into(OrderedCollections.SortedSet.t()) ::
          {any(), (any(), :done | :halt | {any(), any()} -> any())}
  def into(sorted_set) do
    collected_fun = fn
      sorted_set_acc, {:cont, elm} ->
        SortedSet.add(sorted_set_acc, elm)

      sorted_set_acc, :done ->
        sorted_set_acc

      _sorted_set_acc, :halt ->
        :ok
    end

    initial_acc = sorted_set

    {initial_acc, collected_fun}
  end
end
