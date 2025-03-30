defmodule TestData do
  @moduledoc """
  Shared test data and helper functions for benchmarks.
  """

  def keys, do: Enum.to_list(1..10_000)

  def values do
    keys()
    |> Enum.map(fn k -> {k, k} end)
  end

  def set_values do
    keys()
    |> Enum.shuffle()
  end

  def range(tree, start, last) do
    tree
    |> Enum.filter(fn {n, _value} ->
      n >= start and n <= last
    end)
    |> Enum.sort_by(fn {n, _value} -> n end)
  end

  def gb_tree_range(map, min, max) do
    map
    |> :gb_trees.to_list()
    |> Enum.filter(fn {key, _} -> key >= min and key <= max end)
  end
end
