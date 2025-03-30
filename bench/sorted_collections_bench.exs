# Run all benchmarks
Code.require_file("bench/sorted_collections/test_data.ex")

current_file = Path.relative_to_cwd(__ENV__.file)

IO.puts("Current file: #{current_file}")

Path.wildcard("bench/sorted_collections/**/bench.exs")
|> Enum.reject(&(&1 == current_file))
|> Enum.each(&Code.require_file/1)
