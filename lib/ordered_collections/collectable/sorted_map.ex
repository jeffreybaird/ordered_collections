defimpl Collectable, for: OrderedCollections.SortedMap do
  alias OrderedCollections.SortedMap

  @doc """
  Implements the `into` function for the `Collectable` protocol.
  This function is used to collect elements into a SortedMap.

  ## Examples

      iex> Enum.into(%{a: 1, b: 3}, SortedMap.new()) |> SortedMap.to_list()
      [a: 1, b: 3]

      iex> Enum.into(%{a: 1, b: 3}, SortedMap.new(%{c: 2})) |> SortedMap.to_list()
      [a: 1, b: 3, c: 2]

      iex> Enum.into(%{a: 1, b: 3}, SortedMap.new(%{a: 2, b: 3})) |> SortedMap.to_list()
      [a: 1, b: 3]

      iex> SortedMap.new(%{a: 1, b: 3}) |> Enum.into(SortedMap.new(%{n: -1})) |> SortedMap.to_map()
      %{n: -1, a: 1, b: 3}
  """
  def into(sorted_map) do
    collected_fun = fn
      # On each element, insert it into the accumulating SortedMap.
      sorted_map_acc, {:cont, {key, value}} ->
        SortedMap.put(sorted_map_acc, key, value)

      # When done, return the final SortedMap.
      sorted_map_acc, :done ->
        sorted_map_acc

      # On halt, simply return :ok.
      _sorted_map_acc, :halt ->
        :ok

      # Handle suspend if needed.
      sorted_map_acc, {:suspend, _} ->
        sorted_map_acc
    end

    {sorted_map, collected_fun}
  end
end
