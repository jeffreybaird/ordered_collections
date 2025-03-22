defimpl JSON.Encoder, for: OrderedCollections.SortedSet do
  @doc """
  Encodes the SortedSet as a JSON array, preserving the sorted order of its elements.

  The SortedSet is converted to a list (using `:gb_sets.to_list/1`), each element is encoded
  using the native JSON.Encoder protocol, and the results are joined into a JSON array string.

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> JSON.encode!(set)
      "[1,2,3]"
  """
  def encode(set, opts) do
    encoded_values =
      set
      |> Enum.map(fn value -> JSON.Encoder.encode(value, opts) end)

    doc = ["[", intersperse(encoded_values, ","), "]"]
    IO.iodata_to_binary(doc)
  end

  defp intersperse(list, sep) do
    list
    |> Enum.intersperse(sep)
    |> List.flatten()
  end
end
