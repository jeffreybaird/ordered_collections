current_file = Path.relative_to_cwd(__ENV__.file)

IO.puts("Current file: #{current_file}")

Path.wildcard("bench/sorted_collections/set/**/*.exs")
|> Enum.reject(&(&1 == current_file))
|> Enum.each(&Code.require_file/1)
