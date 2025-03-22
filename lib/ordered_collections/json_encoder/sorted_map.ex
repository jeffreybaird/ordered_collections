defimpl JSON.Encoder, for: OrderedCollections.SortedMap do
  @doc """
  Encodes the SortedMap as a regular map for JSON encoding.

  ## Examples

      iex> OrderedCollections.SortedMap.new(%{a: 1, b: 2}) |>  JSON.encode!()
      ~s({"a":1,"b":2})
  """
  def encode(sorted_map, opts) do
    # Encode each pair as "encoded_key:encoded_value"
    encoded_pairs =
      sorted_map
      |> Enum.map(fn {k, v} ->
        key_encoded = JSON.Encoder.encode(k, opts)
        value_encoded = JSON.Encoder.encode(v, opts)
        [key_encoded, ":", value_encoded]
      end)

    # Intercalate commas between pairs and wrap with curly braces.
    doc = ["{", intersperse(encoded_pairs, ","), "}"]
    # Return iodata (the JSON protocol expects iodata, not necessarily a binary)
    doc
  end

  # Helper function that intersperses the given separator between elements,
  # then flattens the result.
  defp intersperse(list, sep) do
    list
    |> Enum.intersperse(sep)
    |> List.flatten()
  end
end
