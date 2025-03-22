defmodule OrderedCollections.Inspectable.SortedMapTest do
  use ExUnit.Case, async: true
  alias OrderedCollections.SortedMap
  import ExUnit.CaptureIO

  doctest Inspect.OrderedCollections.SortedMap

  test "SortedMap inspect output" do
    map = SortedMap.new(%{b: 2, a: 1})
    # Capture the output of IO.inspect/1
    output = capture_io(fn -> IO.inspect(map) end)
    # Expect the output to be followed by a newline
    assert output == "#SortedMap<%{a: 1, b: 2}>\n"
  end
end
