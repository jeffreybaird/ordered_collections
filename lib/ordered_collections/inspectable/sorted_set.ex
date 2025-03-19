defimpl Inspect, for: OrderedCollections.SortedSet do
  import Inspect.Algebra

  @doc """
  Returns a formatted representation of the SortedSet.

  The output is in the form:

      #SortedSet<[1, 2, 3]>

  ## Examples

      iex> set = OrderedCollections.SortedSet.new([3, 1, 2])
      iex> Inspect.inspect(set, [])
      "#SortedSet<[1, 2, 3]>"
  """
  def inspect(%OrderedCollections.SortedSet{set: set}, opts) do
    sorted_list = :gb_sets.to_list(set)
    opts = if is_list(opts), do: Inspect.Opts.new(opts), else: opts
    doc = concat(["#SortedSet<", to_doc(sorted_list, opts), ">"])
    formatted = Inspect.Algebra.format(doc, opts.width)
    IO.iodata_to_binary(formatted)
  end
end
