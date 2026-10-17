# Experimental public-fold reducer. No production modules are redefined.
defmodule OrderedCollections.SetFoldCandidate do
  alias OrderedCollections.SortedSet

  def reduce(%SortedSet{}, {:halt, acc}, _fun), do: {:halted, acc}

  def reduce(%SortedSet{} = set, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(set, &1, fun)}

  def reduce(%SortedSet{set: set}, {:cont, acc}, fun) do
    tag = make_ref()

    try do
      result =
        :gb_sets.fold(
          fn element, acc ->
            case fun.(element, acc) do
              {:cont, next_acc} -> next_acc
              {:halt, next_acc} -> throw({tag, :halt, next_acc})
              {:suspend, next_acc} -> throw({tag, :suspend, element, next_acc})
            end
          end,
          acc,
          set
        )

      {:done, result}
    catch
      {^tag, :halt, halted_acc} ->
        {:halted, halted_acc}

      {^tag, :suspend, element, suspended_acc} ->
        {_stored, iterator} = :gb_sets.next(:gb_sets.iterator_from(element, set))
        {:suspended, suspended_acc, &iterator_reduce(iterator, &1, fun)}
    end
  end

  defp iterator_reduce(_iterator, {:halt, acc}, _fun), do: {:halted, acc}

  defp iterator_reduce(iterator, {:suspend, acc}, fun),
    do: {:suspended, acc, &iterator_reduce(iterator, &1, fun)}

  defp iterator_reduce(iterator, {:cont, acc}, fun) do
    case :gb_sets.next(iterator) do
      :none -> {:done, acc}
      {element, next} -> iterator_reduce(next, fun.(element, acc), fun)
    end
  end
end

defmodule OrderedCollections.SetFoldBench do
  alias OrderedCollections.{SortedSet, SetFoldCandidate}

  def run do
    sizes =
      System.get_env("BENCH_SIZES", "1,32,1000,20000,100000")
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    filter = System.get_env("BENCH_FILTER", ".*") |> Regex.compile!()

    config = [
      warmup: seconds("BENCH_WARMUP", "0.3"),
      time: seconds("BENCH_TIME", "1.0"),
      memory_time: seconds("BENCH_MEMORY", "0.2"),
      parallel: 1,
      formatters: [],
      print: [benchmarking: false, configuration: false, fast_warning: false]
    ]

    check_callback_signals!()

    rows =
      Enum.flat_map(sizes, fn size ->
        set = SortedSet.new(Enum.to_list(1..size))
        count = min(size, 5)

        jobs =
          for {variant, reduce} <- [
                {"baseline", &Enumerable.reduce/3},
                {"fold", &SetFoldCandidate.reduce/3}
              ],
              {operation, callback, initial, finish, expected} <- [
                {"full", fn item, acc -> {:cont, item + acc} end, 0, & &1,
                 {:done, div(size * (size + 1), 2)}},
                {"early",
                 fn item, {n, sum} ->
                   {if(n + 1 == count, do: :halt, else: :cont), {n + 1, sum + item}}
                 end, {0, 0}, & &1, {:halted, {count, div(count * (count + 1), 2)}}},
                {"suspend", fn item, acc -> {:suspend, item + acc} end, 0, &resume_all/1,
                 {:done, div(size * (size + 1), 2)}}
              ],
              Regex.match?(filter, "set/#{operation}/#{variant}"),
              into: %{} do
            function = fn -> finish.(reduce.(set, {:cont, initial}, callback)) end

            unless function.() === expected,
              do: raise("#{operation}/#{variant} failed correctness preflight")

            {"set/#{operation}/#{variant}", function}
          end

        IO.puts("Set fold candidates: #{size} elements, #{map_size(jobs)} jobs")
        suite = Benchee.run(jobs, config)

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
        label: System.get_env("BENCH_LABEL", "fixed-baseline-fold-candidate"),
        elixir: System.version(),
        otp: List.to_string(:erlang.system_info(:otp_release)),
        system: List.to_string(:erlang.system_info(:system_version)),
        machine: String.trim(machine),
        schedulers: :erlang.system_info(:schedulers_online),
        sizes: sizes,
        config: config |> Keyword.take([:warmup, :time, :memory_time, :parallel]) |> Map.new(),
        source_sha256: Map.new(Path.wildcard("lib/**/*.ex") ++ ["mix.exs"], &{&1, hash(&1)}),
        harness_sha256: hash(__ENV__.file),
        recorded_at: DateTime.utc_now() |> DateTime.to_iso8601()
      },
      results: rows,
      correctness_failures: []
    }

    output = System.get_env("BENCH_OUTPUT", "/tmp/ordered-set-fold-candidates.json")
    File.write!(output, JSON.encode!(report))
    IO.puts("Saved #{output}")
  end

  # Preflight must preserve callback exceptions, throws, and exits, including terms
  # resembling protocol control. The reducer may catch only its own private tag.
  defp check_callback_signals! do
    set = SortedSet.new([1, 2, 3])

    for reason <- [:halt, {:halt, 12}, {:suspend, 42}, {make_ref(), :halt, :user}] do
      try do
        SetFoldCandidate.reduce(set, {:cont, 0}, fn _, _ -> throw(reason) end)
        raise "Callback throw was swallowed"
      catch
        :throw, caught when caught === reason -> :ok
      end
    end

    try do
      SetFoldCandidate.reduce(set, {:cont, 0}, fn _, _ -> exit(:callback_exit) end)
      raise "Callback exit was swallowed"
    catch
      :exit, :callback_exit -> :ok
    end

    try do
      SetFoldCandidate.reduce(set, {:cont, 0}, fn _, _ ->
        raise ArgumentError, "callback error"
      end)

      raise "Callback error was swallowed"
    rescue
      error in ArgumentError ->
        if error.message != "callback error", do: reraise(error, __STACKTRACE__)
    end

    callback = fn item, acc -> {:suspend, [item | acc]} end
    {:suspended, [1], resume} = SetFoldCandidate.reduce(set, {:cont, []}, callback)
    {:suspended, :replacement, resume_again} = resume.({:suspend, :replacement})
    {:halted, :stop} = resume_again.({:halt, :stop})
    {:done, [3, 2, 1]} = resume_all(resume.({:cont, [1]}))
  end

  defp resume_all({:suspended, acc, continuation}), do: resume_all(continuation.({:cont, acc}))
  defp resume_all(result), do: result
  defp seconds(key, default), do: key |> System.get_env(default) |> String.to_float()
  defp stats(nil), do: nil
  defp stats(value), do: Map.take(value, [:average, :median, :std_dev_ratio, :sample_size])
  defp hash(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
end

OrderedCollections.SetFoldBench.run()
