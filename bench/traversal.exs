# Candidate experiments use the exact same prepared structures and callbacks.
# BENCH_FILTER selects jobs; BENCH_* settings match comparison.exs.
defmodule OrderedCollections.TraversalBench do
  alias OrderedCollections.{SortedMap, SortedSet}

  def run do
    sizes =
      System.get_env("BENCH_SIZES", "32,1000,20000,100000")
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    filter = System.get_env("BENCH_FILTER", ".*") |> Regex.compile!()

    config = [
      warmup: seconds("BENCH_WARMUP", "0.1"),
      time: seconds("BENCH_TIME", "0.4"),
      memory_time: seconds("BENCH_MEMORY", "0.1"),
      parallel: 1,
      formatters: [],
      print: [benchmarking: false, configuration: false, fast_warning: false]
    ]

    rows =
      Enum.flat_map(sizes, fn size ->
        values = Enum.to_list(1..size)
        set = SortedSet.new(values)
        map = SortedMap.new(Map.new(values, &{&1, &1 * 2}))
        jobs = jobs(set, map, size)
        selected = Enum.filter(jobs, fn {name, _} -> Regex.match?(filter, name) end)

        functions =
          Map.new(selected, fn {name, {function, expected}} ->
            result = function.()

            unless result === expected,
              do: raise("#{name} failed correctness preflight: #{inspect(result, limit: 5)}")

            {name, function}
          end)

        IO.puts("Traversal candidates: #{size} elements, #{map_size(functions)} jobs")
        suite = Benchee.run(functions, config)

        Enum.map(suite.scenarios, fn scenario ->
          %{
            size: size,
            job: scenario.name,
            runtime_ns: stats(scenario.run_time_data.statistics),
            memory_bytes: stats(scenario.memory_usage_data.statistics)
          }
        end)
      end)

    {machine, _} = System.cmd("uname", ["-a"])

    report = %{
      metadata: %{
        label: System.get_env("BENCH_LABEL", "fixed-baseline-candidates"),
        elixir: System.version(),
        otp: List.to_string(:erlang.system_info(:otp_release)),
        system: List.to_string(:erlang.system_info(:system_version)),
        machine: String.trim(machine),
        schedulers: :erlang.system_info(:schedulers_online),
        sizes: sizes,
        config: config |> Keyword.take([:warmup, :time, :memory_time, :parallel]) |> Map.new(),
        source_sha256: Map.new(Path.wildcard("lib/**/*.ex") ++ ["mix.exs"], &{&1, hash(&1)}),
        harness_sha256: hash(__ENV__.file),
        filter: Regex.source(filter),
        recorded_at: DateTime.utc_now() |> DateTime.to_iso8601()
      },
      results: rows,
      correctness_failures: []
    }

    output = System.get_env("BENCH_OUTPUT", "/tmp/ordered-traversal-candidates.json")
    File.write!(output, JSON.encode!(report))
    IO.puts("Saved #{output}")
  end

  defp seconds(key, default), do: key |> System.get_env(default) |> String.to_float()
  defp stats(nil), do: nil
  defp stats(value), do: Map.take(value, [:average, :median, :std_dev_ratio, :sample_size])
  defp hash(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)

  defp jobs(set, map, size) do
    reductions =
      for {kind, collection, factor} <- [{"set", set, 1}, {"map", map, 2}],
          {variant, reduce} <- [{"library", &Enumerable.reduce/3}, {"hot_loop", &hot_reduce/3}],
          {operation, callback, initial, finish, expected} <- [
            {"full", fn item, acc -> {:cont, value(item) + acc} end, 0, & &1,
             {:done, div(size * (size + 1), 2) * factor}},
            {"early",
             fn item, {count, sum} ->
               {if(count == 4, do: :halt, else: :cont), {count + 1, sum + value(item)}}
             end, {0, 0}, & &1, {:halted, {5, 15 * factor}}},
            {"suspend", fn item, acc -> {:suspend, value(item) + acc} end, 0, &resume_all/1,
             {:done, div(size * (size + 1), 2) * factor}}
          ],
          into: %{} do
        {"#{kind}/#{operation}/#{variant}",
         {fn -> finish.(reduce.(collection, {:cont, initial}, callback)) end, expected}}
      end

    raw = %{
      "map/range_full/raw_to_list" =>
        {fn -> :gb_trees.to_list(map.tree) end, SortedMap.to_list(map)},
      "set/enum_reduce/library" =>
        {fn -> Enum.reduce(set, 0, &+/2) end, div(size * (size + 1), 2)},
      "set/enum_reduce/raw" =>
        {fn -> :gb_sets.fold(&+/2, 0, set.set) end, div(size * (size + 1), 2)},
      "map/enum_reduce/library" =>
        {fn -> Enum.reduce(map, 0, fn {_, value}, acc -> value + acc end) end, size * (size + 1)},
      "map/enum_reduce/raw" =>
        {fn -> raw_map_sum(:gb_trees.iterator(map.tree), 0) end, size * (size + 1)},
      "set/full/raw" =>
        {fn -> {:done, :gb_sets.fold(&+/2, 0, set.set)} end, {:done, div(size * (size + 1), 2)}},
      "map/full/raw" =>
        {fn -> {:done, raw_map_sum(:gb_trees.iterator(map.tree), 0)} end,
         {:done, size * (size + 1)}}
    }

    ranges =
      for {label, collection, lower, upper} <- [
            {"full", map, 0, size + 1},
            {"narrow", map, div(size, 2), div(size, 2) + 9},
            {"nearly_full", map, 2, size - 1},
            {"reversed", map, size, 1},
            {"empty", SortedMap.new(), 0, size}
          ],
          {variant, function} <- [
            {"library", &SortedMap.range/3},
            {"full_fast", &full_fast/3},
            {"body", &body_range/3},
            {"fast_body", &fast_body/3},
            {"raw", &raw_range/3}
          ],
          into: %{} do
        expected =
          collection
          |> SortedMap.to_list()
          |> Enum.filter(fn {key, _} -> key >= lower and key <= upper end)

        {"map/range_#{label}/#{variant}",
         {fn -> function.(collection, lower, upper) end, expected}}
      end

    reductions |> Map.merge(raw) |> Map.merge(ranges)
  end

  defp value({_, value}), do: value
  defp value(value), do: value
  defp resume_all({:suspended, acc, continuation}), do: resume_all(continuation.({:cont, acc}))
  defp resume_all(result), do: result

  def hot_reduce(%SortedSet{set: set}, acc, fun), do: set_signal(:gb_sets.iterator(set), acc, fun)

  def hot_reduce(%SortedMap{tree: tree}, acc, fun),
    do: map_signal(:gb_trees.iterator(tree), acc, fun)

  defp set_signal(_iterator, {:halt, acc}, _fun), do: {:halted, acc}

  defp set_signal(iterator, {:suspend, acc}, fun),
    do: {:suspended, acc, &set_signal(iterator, &1, fun)}

  defp set_signal(iterator, {:cont, acc}, fun), do: set_loop(iterator, acc, fun)

  defp set_loop(iterator, acc, fun) do
    case :gb_sets.next(iterator) do
      :none ->
        {:done, acc}

      {item, next} ->
        case fun.(item, acc) do
          {:cont, acc} -> set_loop(next, acc, fun)
          other -> set_signal(next, other, fun)
        end
    end
  end

  defp map_signal(_iterator, {:halt, acc}, _fun), do: {:halted, acc}

  defp map_signal(iterator, {:suspend, acc}, fun),
    do: {:suspended, acc, &map_signal(iterator, &1, fun)}

  defp map_signal(iterator, {:cont, acc}, fun), do: map_loop(iterator, acc, fun)

  defp map_loop(iterator, acc, fun) do
    case :gb_trees.next(iterator) do
      :none ->
        {:done, acc}

      {key, value, next} ->
        case fun.({key, value}, acc) do
          {:cont, acc} -> map_loop(next, acc, fun)
          other -> map_signal(next, other, fun)
        end
    end
  end

  def full_fast(%SortedMap{tree: tree} = map, lower, upper) do
    cond do
      lower > upper or :gb_trees.is_empty(tree) ->
        []

      lower <= elem(:gb_trees.smallest(tree), 0) and upper >= elem(:gb_trees.largest(tree), 0) ->
        :gb_trees.to_list(tree)

      true ->
        SortedMap.range(map, lower, upper)
    end
  end

  def fast_body(%SortedMap{tree: tree} = map, lower, upper) do
    cond do
      lower > upper or :gb_trees.is_empty(tree) ->
        []

      lower <= elem(:gb_trees.smallest(tree), 0) and upper >= elem(:gb_trees.largest(tree), 0) ->
        :gb_trees.to_list(tree)

      true ->
        body_range(map, lower, upper)
    end
  end

  def body_range(%SortedMap{tree: tree}, lower, upper),
    do: body(:gb_trees.iterator_from(lower, tree), upper)

  defp body(iterator, upper) do
    case :gb_trees.next(iterator) do
      {key, value, next} when key <= upper -> [{key, value} | body(next, upper)]
      _ -> []
    end
  end

  def raw_range(%SortedMap{tree: tree}, lower, upper),
    do: tail(:gb_trees.iterator_from(lower, tree), upper, [])

  defp tail(iterator, upper, acc) do
    case :gb_trees.next(iterator) do
      {key, value, next} when key <= upper -> tail(next, upper, [{key, value} | acc])
      _ -> Enum.reverse(acc)
    end
  end

  defp raw_map_sum(iterator, acc) do
    case :gb_trees.next(iterator) do
      :none -> acc
      {_, value, next} -> raw_map_sum(next, value + acc)
    end
  end
end

OrderedCollections.TraversalBench.run()
