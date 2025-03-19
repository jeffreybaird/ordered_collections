defimpl Inspect, for: OrderedCollections.SortedMap do
  import Inspect.Algebra

  @doc """
  Returns a formatted representation of the SortedMap.

  The output is in the form:

      #SortedMap<[a: 1, b: 2]>

  ## Examples

      iex> map = OrderedCollections.SortedMap.new(%{a: 1, b: 2})
      iex> Inspect.inspect(map, [])
      "#SortedMap<[a: 1, b: 2]>"
  """
  def inspect(%OrderedCollections.SortedMap{tree: tree}, opts) do
    sorted_list = :gb_trees.to_list(tree)
    opts = if is_list(opts), do: Inspect.Opts.new(opts), else: opts
    doc = concat(["#SortedMap<", to_doc(sorted_list, opts), ">"])
    formatted = Inspect.Algebra.format(doc, opts.width)
    IO.iodata_to_binary(formatted)
  end
end
