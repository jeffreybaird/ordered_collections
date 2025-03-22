defimpl Inspect, for: OrderedCollections.SortedMap do
  alias OrderedCollections.SortedMap
  import Inspect.Algebra

  @doc """
  Returns a formatted representation of the SortedMap.

  The output is in the form:

      #SortedMap<[a: 1, b: 2]>

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2})
      iex> Inspect.inspect(map, [])
      "#SortedMap<%{a: 1, b: 2}>"
  """
  def inspect(%SortedMap{tree: tree}, opts) do
    # Retrieve the sorted key-value pairs.
    kvs = :gb_trees.to_list(tree)
    # Ensure opts is an Inspect.Opts struct.
    opts = if is_list(opts), do: Inspect.Opts.new(opts), else: opts

    # Build documents for each key-value pair.
    pair_docs =
      Enum.map(kvs, fn {k, v} ->
        pair_doc(k, v, opts)
      end)

    # Intercalate commas between pairs.
    inner_doc =
      pair_docs
      |> Enum.intersperse(", ")
      |> concat()

    # Wrap with map literal and SortedMap marker.
    doc = concat(["#SortedMap<", "%{", inner_doc, "}>"])
    formatted = Inspect.Algebra.format(doc, opts.width)
    IO.iodata_to_binary(formatted)
  end

  # For atom keys, convert them using Inspect.inspect/2 and strip the leading colon.
  defp pair_doc(k, v, opts) when is_atom(k) do
    key_str =
      k
      |> Inspect.inspect(opts)
      |> String.trim_leading(":")

    value_doc = to_doc(v, opts)
    concat([key_str, ": ", value_doc])
  end

  # For non-atom keys, fall back to the default formatting.
  defp pair_doc(k, v, opts) do
    concat([to_doc(k, opts), " => ", to_doc(v, opts)])
  end
end
