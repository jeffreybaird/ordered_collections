defmodule OrderedCollections.CollectionRegressionTest do
  use ExUnit.Case, async: true

  alias OrderedCollections.{SortedMap, SortedSet}

  test "set construction accepts repeated elements from a list" do
    set = SortedSet.new([3, 1, 3, 2, 1])
    assert SortedSet.to_list(set) === [1, 2, 3]
    assert Enum.count(set) == 3
  end

  test "set construction accepts repeated elements from a non-list enumerable" do
    set = [3, 1, 3, 2, 1] |> Stream.map(& &1) |> SortedSet.new()
    assert SortedSet.to_list(set) === [1, 2, 3]
    assert Enum.count(set) == 3
  end

  test "list construction retains the stored numeric representative for either input order" do
    assert SortedSet.new([1, 1.0]) |> SortedSet.to_list() === [1]
    assert SortedSet.new([1.0, 1]) |> SortedSet.to_list() === [1.0]
  end

  test "enumerable construction retains the stored numeric representative for either input order" do
    assert [1, 1.0] |> Stream.map(& &1) |> SortedSet.new() |> SortedSet.to_list() === [1]
    assert [1.0, 1] |> Stream.map(& &1) |> SortedSet.new() |> SortedSet.to_list() === [1.0]
  end

  test "set construction maintains strict representatives and uniqueness among mixed nested terms" do
    input = ["z", [3], {:id, 2}, :a, 1.0, 1, {:id, 2.0}, [3.0], :a]

    for {items, expected} <- [
          {input, [1.0, :a, {:id, 2}, [3], "z"]},
          {Enum.reverse(input), [1, :a, {:id, 2.0}, [3.0], "z"]}
        ],
        source <- [items, Stream.map(items, & &1)] do
      set = SortedSet.new(source)
      assert SortedSet.to_list(set) === expected
      assert Enum.count(set) == 5
      for item <- items, do: assert(SortedSet.member?(set, item))
    end
  end

  test "set insertion preserves stored representatives on numeric hits and adds misses" do
    set = SortedSet.new([1.0, {:id, 2}, [3]])
    updated = set |> SortedSet.add(1) |> SortedSet.add({:id, 2.0}) |> SortedSet.add([3.0])
    assert SortedSet.to_list(updated) === [1.0, {:id, 2}, [3]]
    assert SortedSet.to_list(SortedSet.add(updated, :new)) === [1.0, :new, {:id, 2}, [3]]
    assert SortedSet.to_list(set) === [1.0, {:id, 2}, [3]]
  end

  test "update/3 invokes the callback on an existing nil value" do
    map = SortedMap.new(%{a: nil, untouched: 5})

    updated =
      SortedMap.update(map, :a, fn value ->
        send(self(), {:updated, value})
        {:was, value}
      end)

    assert SortedMap.to_map(updated) === %{a: {:was, nil}, untouched: 5}
    assert_received {:updated, nil}
    refute_received {:updated, _}
    assert SortedMap.get(map, :a) == nil
  end

  test "update/4 invokes the callback on an existing nil value instead of using the default" do
    map = SortedMap.new(%{1 => nil})

    updated =
      SortedMap.update(
        map,
        1.0,
        fn value ->
          send(self(), {:updated, value})
          {:was, value}
        end,
        :default
      )

    assert SortedMap.get(updated, 1) === {:was, nil}
    assert Enum.count(updated) == 1
    assert_received {:updated, nil}
    refute_received {:updated, _}
  end

  test "missing map updates insert their documented defaults without invoking the callback" do
    map = SortedMap.new(%{a: 1})
    callback = fn _ -> flunk("missing-key update invoked the callback") end
    assert SortedMap.to_map(SortedMap.update(map, :missing, callback)) === %{a: 1, missing: nil}

    assert SortedMap.to_map(SortedMap.update(map, :missing, callback, 42)) === %{
             a: 1,
             missing: 42
           }

    assert SortedMap.to_map(map) === %{a: 1}
  end

  test "map conversions retain keys, nil values, and values in key order" do
    pairs = [{1.0, :number}, {:a, nil}, {{:key, 2}, [3]}, {"z", %{nested: 4.0}}]
    map = SortedMap.new(Map.new(pairs))
    assert SortedMap.to_list(map) === pairs
    assert SortedMap.keys(map) === Enum.map(pairs, &elem(&1, 0))
    assert SortedMap.values(map) === [:number, nil, [3], %{nested: 4.0}]
    assert SortedMap.to_map(map) === Map.new(pairs)
    assert SortedMap.to_map(SortedMap.new()) === %{}
    assert SortedMap.values(SortedMap.new()) === []
  end

  test "map ranges are inclusive sorted lists across boundaries and mixed term bounds" do
    pairs = [{1, :one}, {2.0, nil}, {:a, :atom}, {{:key, 3}, :tuple}, {"z", :binary}]
    map = SortedMap.new(Map.new(pairs))

    for {lower, upper, expected} <- [
          {1.0, 2, Enum.take(pairs, 2)},
          {2, 2.0, [{2.0, nil}]},
          {:a, {:key, 3}, [{:a, :atom}, {{:key, 3}, :tuple}]},
          {0, "zz", pairs},
          {1.0, "z", pairs},
          {2, "zz", Enum.drop(pairs, 1)},
          {0, {:key, 3}, Enum.drop(pairs, -1)},
          {2.5, 3, []},
          {"zz", "zzz", []},
          {"z", 1, []}
        ] do
      result = SortedMap.range(map, lower, upper)
      assert is_list(result)
      assert result === expected
    end

    assert SortedMap.range(SortedMap.new(), 1, 2) === []
  end

  test "map ranges distinguish full bounds from ranges excluding an endpoint after many inserts" do
    keys = [1.0 | Enum.to_list(2..256)] ++ [257.0]
    pairs = Enum.map(keys, &{&1, {:value, &1}})

    inserted =
      Enum.reduce(pairs, SortedMap.new(), fn {key, value}, acc ->
        SortedMap.put(acc, key, value)
      end)

    for map <- [inserted, SortedMap.rebalance(inserted)] do
      for {lower, upper, expected} <- [
            {1, 257, pairs},
            {0, 258, pairs},
            {2, 258, Enum.drop(pairs, 1)},
            {0, 256, Enum.drop(pairs, -1)},
            {128, 130, Enum.slice(pairs, 127, 3)},
            {257, 1, []},
            {258, 300, []},
            {-10, 0, []}
          ] do
        assert SortedMap.range(map, lower, upper) === expected
      end
    end
  end

  test "map range extrema handle singleton and empty maps with strict numeric representatives" do
    singleton = SortedMap.new(%{1.0 => nil})

    for {lower, upper} <- [{1, 1}, {0, 2}, {1.0, 2}, {0, 1.0}] do
      assert SortedMap.range(singleton, lower, upper) === [{1.0, nil}]
      assert SortedMap.range(SortedMap.new(), lower, upper) === []
    end

    for {lower, upper} <- [{2, 1}, {2, 3}, {-1, 0}] do
      assert SortedMap.range(singleton, lower, upper) === []
      assert SortedMap.range(SortedMap.new(), lower, upper) === []
    end
  end

  test "set ranges return sets and retain stored representatives at inclusive bounds" do
    items = [1, 2.0, :a, {:key, 3}, "z"]
    set = SortedSet.new(items)

    for {lower, upper, expected} <- [
          {1.0, 2, [1, 2.0]},
          {2, 2.0, [2.0]},
          {:a, {:key, 3}, [:a, {:key, 3}]},
          {0, "zz", items},
          {2.5, 3, []},
          {"zz", "zzz", []},
          {"z", 1, []}
        ] do
      assert %SortedSet{} = result = SortedSet.range(set, lower, upper)
      assert SortedSet.to_list(result) === expected
    end

    assert %SortedSet{} = empty = SortedSet.range(SortedSet.new(), 1, 2)
    assert SortedSet.to_list(empty) === []
  end

  test "set collection preserves initial representatives and deduplicates incoming values" do
    initial = SortedSet.new([1.0, :keep])
    result = Enum.into([1, 2, 2.0, 1.0, :keep], initial)
    assert SortedSet.to_list(result) === [1.0, 2, :keep]
    assert SortedSet.to_list(initial) === [1.0, :keep]
    assert Enum.into([], initial) === initial
  end

  test "map collection preserves initial entries and the last value for equivalent keys wins" do
    initial = SortedMap.new(%{1 => :initial, :keep => nil})
    result = Enum.into([{1.0, :first}, {:new, 2}, {1, :second}, {:new, 3}, {1.0, :last}], initial)
    assert SortedMap.to_list(result) === [{1.0, :last}, {:keep, nil}, {:new, 3}]
    assert SortedMap.get(result, 1) === :last
    assert SortedMap.to_map(initial) === %{1 => :initial, :keep => nil}
    assert Enum.into([], initial) === initial
  end
end
