defimpl Collectable, for: OrderedCollections.SortedSet do
  alias OrderedCollections.SortedSet

  @doc """
  Implements the `into` function for the `Collectable` protocol.
  This function is used to collect elements into a SortedSet.

  The function handles all standard Collectable protocol signals:
  - `{:cont, element}`: Adds the element to the set
  - `:done`: Returns the final set
  - `:halt`: Returns `:ok`
  - `{:suspend, _}`: Returns the current set unchanged

  ## Examples

      iex> Enum.into([3, 1, 2], SortedSet.new()) |> SortedSet.to_list()
      [1, 2, 3]

      iex> Enum.into([3, 1, 2], SortedSet.new([3,5,9,-1])) |> SortedSet.to_list()
      [-1, 1, 2, 3, 5, 9]

      iex> {initial, collector} = Collectable.into(SortedSet.new())
      iex> acc = collector.(initial, {:cont, 1})
      iex> acc = collector.(acc, {:suspend, []})
      iex> acc = collector.(acc, {:cont, 2})
      iex> result = collector.(acc, :done)
      iex> SortedSet.to_list(result)
      [1, 2]
  """
  @spec into(OrderedCollections.SortedSet.t()) ::
          {OrderedCollections.SortedSet.t(),
           (OrderedCollections.SortedSet.t(),
            :done
            | :halt
            | {:cont, any()}
            | {:suspend, any()} ->
              OrderedCollections.SortedSet.t() | :ok)}
  def into(sorted_set) do
    collected_fun = fn
      sorted_set_acc, {:cont, elm} ->
        SortedSet.add(sorted_set_acc, elm)

      sorted_set_acc, :done ->
        sorted_set_acc

      _sorted_set_acc, :halt ->
        :ok

      sorted_set_acc, {:suspend, _} ->
        sorted_set_acc
    end

    {sorted_set, collected_fun}
  end
end
