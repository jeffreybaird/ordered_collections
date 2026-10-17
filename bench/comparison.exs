# Run in each checkout with the same script and BENCH_* settings. See comparison.sh.
defmodule OrderedCollections.Comparison do
  alias OrderedCollections.{SortedMap, SortedSet}

  def run do
    sizes =
      System.get_env("BENCH_SIZES", "32,1000,20000")
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    config = [
      warmup: seconds("BENCH_WARMUP", "0.1"),
      time: seconds("BENCH_TIME", "0.4"),
      memory_time: seconds("BENCH_MEMORY", "0.1"),
      parallel: 1,
      formatters: [],
      print: [benchmarking: false, configuration: false, fast_warning: false]
    ]

    {rows, failures} =
      Enum.reduce(sizes, {[], []}, fn size, {rows, failures} ->
        input = input(size)
        all_jobs = jobs(input)
        filter = System.get_env("BENCH_FILTER", ".*") |> Regex.compile!()
        selected_jobs = Enum.filter(all_jobs, fn {name, _} -> Regex.match?(filter, name) end)

        {jobs, failed} =
          Enum.reduce(selected_jobs, {%{}, []}, fn {name, function}, {jobs, failed} ->
            try do
              result = function.()
              verify!(name, result, all_jobs)
              {Map.put(jobs, name, function), failed}
            rescue
              error ->
                {jobs,
                 [
                   %{
                     size: size,
                     job: name,
                     error: Exception.format(:error, error, __STACKTRACE__)
                   }
                   | failed
                 ]}
            end
          end)

        IO.puts(
          "Benchmarking #{size} elements: #{map_size(jobs)} jobs; #{length(failed)} preflight failures"
        )

        suite = Benchee.run(jobs, config)

        results =
          Enum.map(suite.scenarios, fn scenario ->
            %{
              size: size,
              job: scenario.name,
              runtime_ns: stats(scenario.run_time_data.statistics),
              memory_bytes: stats(scenario.memory_usage_data.statistics)
            }
          end)

        {rows ++ results, failures ++ failed}
      end)

    report = %{metadata: metadata(config, sizes), results: rows, correctness_failures: failures}
    output = System.get_env("BENCH_OUTPUT", "/tmp/ordered-collections-benchmark.json")
    File.write!(output, JSON.encode!(report))
    IO.puts("Saved #{output}")
  end

  defp seconds(key, default), do: key |> System.get_env(default) |> String.to_float()

  defp verify!(name, result, jobs) do
    if String.ends_with?(name, "/library") do
      reference = Map.fetch!(jobs, String.replace_suffix(name, "/library", "/raw")).()

      unless normalize(name, result) === normalize(name, reference),
        do: raise("Result differs from raw reference")
    end
  end

  defp normalize("set/" <> operation, value) do
    if String.starts_with?(operation, ["new", "insert", "range", "collect"]) do
      case value do
        %SortedSet{set: set} -> :gb_sets.to_list(set)
        set -> :gb_sets.to_list(set)
      end
    else
      value
    end
  end

  defp normalize("map/" <> operation, value) do
    if String.starts_with?(operation, ["new", "insert", "collect"]) do
      case value do
        %SortedMap{tree: tree} -> :gb_trees.to_list(tree)
        tree -> :gb_trees.to_list(tree)
      end
    else
      value
    end
  end

  defp stats(nil), do: nil
  defp stats(value), do: Map.take(value, [:average, :median, :std_dev_ratio, :sample_size])

  defp metadata(config, sizes) do
    {revision, _} = System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true)
    {machine, _} = System.cmd("uname", ["-a"])

    cpu =
      case :os.type() do
        {:unix, :darwin} ->
          elem(System.cmd("sysctl", ["-n", "machdep.cpu.brand_string", "hw.memsize"]), 0)

        _ ->
          "See machine and scheduler metadata"
      end

    %{
      label: System.get_env("BENCH_LABEL", "current"),
      revision: System.get_env("BENCH_REVISION", String.trim(revision)),
      source_sha256: Map.new(Path.wildcard("lib/**/*.ex") ++ ["mix.exs"], &{&1, hash(&1)}),
      harness_sha256: hash(__ENV__.file),
      filter: System.get_env("BENCH_FILTER", ".*"),
      elixir: System.version(),
      otp: List.to_string(:erlang.system_info(:otp_release)),
      erts: List.to_string(:erlang.system_info(:version)),
      system: List.to_string(:erlang.system_info(:system_version)),
      schedulers: :erlang.system_info(:schedulers_online),
      machine: String.trim(machine),
      cpu_memory: String.trim(cpu),
      sizes: sizes,
      config: config |> Keyword.take([:warmup, :time, :memory_time, :parallel]) |> Map.new(),
      recorded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      memory_method:
        "Benchee per-operation process allocation measurement; includes garbage-collected allocations, not retained heap or RSS",
      runtime_unit: "nanoseconds"
    }
  end

  defp hash(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)

  defp input(size) do
    # Deterministic permutation; setup is outside timed closures.
    values = Enum.sort_by(1..size, &:erlang.phash2({&1, 4242}))
    pairs = Enum.map(values, &{&1, &1 * 2})
    source = Map.new(pairs)

    %{
      size: size,
      values: values,
      missing_values: Enum.map(values, &(&1 + size)),
      duplicates: values ++ values,
      pairs: pairs,
      duplicate_pairs: pairs ++ Enum.map(pairs, fn {k, v} -> {k, -v} end),
      source: source,
      set: SortedSet.new(values),
      map: SortedMap.new(source),
      raw_set: :gb_sets.from_list(values),
      raw_map:
        Enum.reduce(source, :gb_trees.empty(), fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end),
      low: div(size, 2),
      high: min(div(size, 2) + 9, size)
    }
  end

  defp jobs(i) do
    %{
      "set/new/library" => fn -> SortedSet.new(i.values) end,
      "set/new/raw" => fn -> :gb_sets.from_list(i.values) end,
      "set/new_duplicates/library" => fn -> SortedSet.new(i.duplicates) end,
      "set/new_duplicates/raw" => fn -> :gb_sets.from_list(i.duplicates) end,
      "map/new/library" => fn -> SortedMap.new(i.source) end,
      "map/new/raw" => fn ->
        Enum.reduce(i.source, :gb_trees.empty(), fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end)
      end,
      "set/insert_hit/library" => fn -> SortedSet.add(i.set, i.low) end,
      "set/insert_hit/raw" => fn -> :gb_sets.add(i.low, i.raw_set) end,
      "set/insert_miss/library" => fn -> SortedSet.add(i.set, i.size + 1) end,
      "set/insert_miss/raw" => fn -> :gb_sets.add(i.size + 1, i.raw_set) end,
      "map/insert_hit/library" => fn -> SortedMap.put(i.map, i.low, :updated) end,
      "map/insert_hit/raw" => fn -> :gb_trees.enter(i.low, :updated, i.raw_map) end,
      "map/insert_miss/library" => fn -> SortedMap.put(i.map, i.size + 1, :updated) end,
      "map/insert_miss/raw" => fn -> :gb_trees.enter(i.size + 1, :updated, i.raw_map) end,
      "set/to_list/library" => fn -> SortedSet.to_list(i.set) end,
      "set/to_list/raw" => fn -> :gb_sets.to_list(i.raw_set) end,
      "map/to_list/library" => fn -> SortedMap.to_list(i.map) end,
      "map/to_list/raw" => fn -> :gb_trees.to_list(i.raw_map) end,
      "map/to_map/library" => fn -> SortedMap.to_map(i.map) end,
      "map/to_map/raw" => fn -> Map.new(:gb_trees.to_list(i.raw_map)) end,
      "map/values/library" => fn -> SortedMap.values(i.map) end,
      "map/values/raw" => fn -> :gb_trees.values(i.raw_map) end,
      "set/range_narrow/library" => fn -> SortedSet.range(i.set, i.low, i.high) end,
      "set/range_narrow/raw" => fn -> set_range(i.raw_set, i.low, i.high) end,
      "set/range_full/library" => fn -> SortedSet.range(i.set, 1, i.size) end,
      "set/range_full/raw" => fn -> set_range(i.raw_set, 1, i.size) end,
      "map/range_narrow/library" => fn -> SortedMap.range(i.map, i.low, i.high) end,
      "map/range_narrow/raw" => fn -> map_range(i.raw_map, i.low, i.high) end,
      "map/range_full/library" => fn -> SortedMap.range(i.map, 1, i.size) end,
      "map/range_full/raw" => fn -> map_range(i.raw_map, 1, i.size) end,
      "set/enumerate/library" => fn -> Enum.reduce(i.set, 0, &+/2) end,
      "set/enumerate/raw" => fn -> sum_set(:gb_sets.iterator(i.raw_set), 0) end,
      "map/enumerate/library" => fn -> Enum.reduce(i.map, 0, fn {_, v}, acc -> v + acc end) end,
      "map/enumerate/raw" => fn -> sum_map(:gb_trees.iterator(i.raw_map), 0) end,
      "set/take_5/library" => fn -> Enum.take(i.set, 5) end,
      "set/take_5/raw" => fn -> take(:gb_sets, :gb_sets.iterator(i.raw_set), 5, []) end,
      "map/take_5/library" => fn -> Enum.take(i.map, 5) end,
      "map/take_5/raw" => fn -> take(:gb_trees, :gb_trees.iterator(i.raw_map), 5, []) end,
      "set/slice_prefix/library" => fn -> Enum.slice(i.set, 0, 5) end,
      "set/slice_prefix/raw" => fn -> take(:gb_sets, :gb_sets.iterator(i.raw_set), 5, []) end,
      "map/slice_prefix/library" => fn -> Enum.slice(i.map, 0, 5) end,
      "map/slice_prefix/raw" => fn -> take(:gb_trees, :gb_trees.iterator(i.raw_map), 5, []) end,
      "set/slice_stepped/library" => fn -> Enum.slice(i.set, 0..8//2) end,
      "set/slice_stepped/raw" => fn -> stepped(:gb_sets, :gb_sets.iterator(i.raw_set), 5, []) end,
      "map/slice_stepped/library" => fn -> Enum.slice(i.map, 0..8//2) end,
      "map/slice_stepped/raw" => fn ->
        stepped(:gb_trees, :gb_trees.iterator(i.raw_map), 5, [])
      end,
      "set/collect_duplicates/library" => fn -> Enum.into(i.duplicates, i.set) end,
      "set/collect_duplicates/raw" => fn ->
        Enum.reduce(i.duplicates, i.raw_set, &:gb_sets.add/2)
      end,
      "map/collect_duplicates/library" => fn -> Enum.into(i.duplicate_pairs, i.map) end,
      "map/collect_duplicates/raw" => fn ->
        Enum.reduce(i.duplicate_pairs, i.raw_map, fn {k, v}, acc -> :gb_trees.enter(k, v, acc) end)
      end,
      "set/collector_struct/candidate" => fn ->
        collect(i.values, i.set, fn value, acc ->
          %SortedSet{set: :gb_sets.add(value, acc.set)}
        end)
      end,
      "set/collector_raw/candidate" => fn ->
        %SortedSet{set: collect(i.values, i.raw_set, &:gb_sets.add/2)}
      end,
      "set/collector_miss_struct/candidate" => fn ->
        collect(i.missing_values, i.set, fn value, acc ->
          %SortedSet{set: :gb_sets.add(value, acc.set)}
        end)
      end,
      "set/collector_miss_raw/candidate" => fn ->
        %SortedSet{set: collect(i.missing_values, i.raw_set, &:gb_sets.add/2)}
      end,
      "map/collector_struct/candidate" => fn ->
        collect(i.pairs, i.map, fn {k, v}, acc ->
          %SortedMap{tree: :gb_trees.enter(k, v, acc.tree)}
        end)
      end,
      "map/collector_raw/candidate" => fn ->
        %SortedMap{
          tree: collect(i.pairs, i.raw_map, fn {k, v}, acc -> :gb_trees.enter(k, v, acc) end)
        }
      end
    }
  end

  defp collect(values, initial, callback), do: Enum.reduce(values, initial, callback)

  defp set_range(set, low, high),
    do: :gb_sets.from_ordset(range(:gb_sets, :gb_sets.iterator_from(low, set), high, []))

  defp map_range(tree, low, high),
    do: range(:gb_trees, :gb_trees.iterator_from(low, tree), high, [])

  defp range(module, iterator, high, acc) do
    case module.next(iterator) do
      {key, next} when key <= high -> range(module, next, high, [key | acc])
      {key, value, next} when key <= high -> range(module, next, high, [{key, value} | acc])
      _ -> Enum.reverse(acc)
    end
  end

  defp sum_set(iterator, acc) do
    case :gb_sets.next(iterator) do
      :none -> acc
      {value, next} -> sum_set(next, value + acc)
    end
  end

  defp sum_map(iterator, acc) do
    case :gb_trees.next(iterator) do
      :none -> acc
      {_, value, next} -> sum_map(next, value + acc)
    end
  end

  defp take(_, _, 0, acc), do: Enum.reverse(acc)

  defp take(module, iterator, count, acc) do
    case module.next(iterator) do
      :none -> Enum.reverse(acc)
      {key, next} -> take(module, next, count - 1, [key | acc])
      {key, value, next} -> take(module, next, count - 1, [{key, value} | acc])
    end
  end

  defp stepped(_, _, 0, acc), do: Enum.reverse(acc)

  defp stepped(module, iterator, count, acc) do
    case module.next(iterator) do
      :none ->
        Enum.reverse(acc)

      {key, next} ->
        stepped(module, skip_one(module, next), count - 1, [key | acc])

      {key, value, next} ->
        stepped(module, skip_one(module, next), count - 1, [{key, value} | acc])
    end
  end

  defp skip_one(module, iterator) do
    case module.next(iterator) do
      :none -> iterator
      {_, next} -> next
      {_, _, next} -> next
    end
  end
end

OrderedCollections.Comparison.run()
