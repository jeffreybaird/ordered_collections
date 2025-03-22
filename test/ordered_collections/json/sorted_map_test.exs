defmodule OrderedCollections.JSON.SortedMapTest do
  use ExUnit.Case, async: true

  # This will run the doctests for your SortedMap JSON encoder.
  doctest JSON.Encoder.OrderedCollections.SortedMap

  alias OrderedCollections.SortedMap

  test "JSON encoding of a non-empty SortedMap" do
    map = SortedMap.new(%{a: 1, b: 2})
    # Since SortedMap stores keys in sorted order (alphabetically), we expect:
    # {"a":1,"b":2}
    assert JSON.encode!(map) == "{\"a\":1,\"b\":2}"
  end

  test "JSON encoding of an empty SortedMap" do
    map = SortedMap.new()
    # An empty map should be encoded as "{}"
    assert JSON.encode!(map) == "{}"
  end
end
