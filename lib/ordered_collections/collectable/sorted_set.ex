defimpl Collectable, for: OrderedCollections.SortedSet do
  alias OrderedCollections.SortedSet

  @typedoc "Opaque collector state. Pass it only to the collector returned by `into/1`."
  @opaque accumulator() :: :gb_sets.set()

  @doc """
  Implements the `into` function for the `Collectable` protocol.
  This function is used to collect elements into a SortedSet.

  The initial and intermediate accumulators are opaque implementation state,
  not SortedSets. Pass them unchanged to the returned collector; only `:done`
  returns the completed SortedSet.

  The function handles all standard Collectable protocol signals:
  - `{:cont, element}`: Adds the element to the set
  - `:done`: Returns the final set
  - `:halt`: Returns `:ok`

  ## Examples

      iex> Enum.into([3, 1, 2], SortedSet.new()) |> SortedSet.to_list()
      [1, 2, 3]

      iex> Enum.into([3, 1, 2], SortedSet.new([3,5,9,-1])) |> SortedSet.to_list()
      [-1, 1, 2, 3, 5, 9]

      iex> {initial, collector} = Collectable.into(SortedSet.new())
      iex> acc = collector.(initial, {:cont, 1})
      iex> acc = collector.(acc, {:cont, 2})
      iex> result = collector.(acc, :done)
      iex> SortedSet.to_list(result)
      [1, 2]
  """
  @spec into(OrderedCollections.SortedSet.t()) ::
          {accumulator(),
           (accumulator(),
            :done
            | :halt
            | {:cont, any()} ->
              accumulator() | OrderedCollections.SortedSet.t() | :ok)}
  def into(%SortedSet{set: set}) do
    collected_fun = fn
      set_acc, {:cont, elm} ->
        :gb_sets.add(elm, set_acc)

      set_acc, :done ->
        %SortedSet{set: set_acc}

      _set_acc, :halt ->
        :ok
    end

    {set, collected_fun}
  end
end
