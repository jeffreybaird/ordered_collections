# Usage: elixir bench/summarize.exs baseline.json current.json > comparison.tsv
[baseline_path, current_path] = System.argv()
baseline = baseline_path |> File.read!() |> JSON.decode!()
current = current_path |> File.read!() |> JSON.decode!()
index = fn report -> Map.new(report["results"], &{{&1["size"], &1["job"]}, &1}) end
old = index.(baseline)
new = index.(current)
metric = fn row, kind -> if row, do: get_in(row, [kind, "average"]) end

ratio = fn numerator, denominator ->
  if is_number(numerator) and is_number(denominator) and denominator > 0,
    do: Float.round(numerator / denominator, 3)
end

cell = fn
  nil -> "NA"
  number when is_float(number) -> :erlang.float_to_binary(number, decimals: 3)
  other -> to_string(other)
end

IO.puts(
  "size\tjob\tbaseline_ns\tcurrent_ns\traw_ns\tbaseline_over_current\tcurrent_over_raw\tbaseline_bytes\tcurrent_bytes\traw_bytes"
)

current["results"]
|> Enum.filter(&String.ends_with?(&1["job"], "/library"))
|> Enum.sort_by(&{&1["job"], &1["size"]})
|> Enum.each(fn row ->
  size = row["size"]
  name = row["job"]
  previous = old[{size, name}]
  raw = new[{size, String.replace_suffix(name, "/library", "/raw")}]
  before_ns = metric.(previous, "runtime_ns")
  now_ns = metric.(row, "runtime_ns")
  raw_ns = metric.(raw, "runtime_ns")

  [
    size,
    name,
    before_ns,
    now_ns,
    raw_ns,
    ratio.(before_ns, now_ns),
    ratio.(now_ns, raw_ns),
    metric.(previous, "memory_bytes"),
    metric.(row, "memory_bytes"),
    metric.(raw, "memory_bytes")
  ]
  |> Enum.map_join("\t", cell)
  |> IO.puts()
end)

for {label, report} <- [{"baseline", baseline}, {"current", current}] do
  for failure <- report["correctness_failures"] do
    IO.puts(
      :stderr,
      "#{label} correctness failure: #{failure["size"]} #{failure["job"]}: #{failure["error"]}"
    )
  end
end
