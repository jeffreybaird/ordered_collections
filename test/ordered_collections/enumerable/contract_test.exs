defmodule OrderedCollections.Enumerable.ContractTest do
  use ExUnit.Case, async: true

  alias OrderedCollections.{SortedMap, SortedSet}

  for collection <- [SortedMap, SortedSet] do
    describe "#{inspect(collection)} protocol contract" do
      @collection collection

      test "exhaustion returns done for empty and populated inputs" do
        for input <- [[], Enum.to_list(1..15)] do
          {collection, expected} = fixture(@collection, input)

          assert Enumerable.reduce(collection, {:cont, []}, fn item, acc ->
                   {:cont, [item | acc]}
                 end) === {:done, Enum.reverse(expected)}
        end
      end

      test "initial halt skips callbacks, including on an empty collection" do
        for input <- [[], [1, 2, 3]] do
          {collection, _} = fixture(@collection, input)
          callback = fn _, _ -> flunk("initial halt invoked the callback") end
          assert Enumerable.reduce(collection, {:halt, :stopped}, callback) == {:halted, :stopped}
        end
      end

      test "initial suspension can suspend again, halt, or resume to exhaustion" do
        for input <- [[], [1, 2, 3]] do
          {collection, expected} = fixture(@collection, input)

          callback = fn item, acc ->
            send(self(), {:visited, item})
            {:cont, [item | acc]}
          end

          assert {:suspended, [], resume} =
                   Enumerable.reduce(collection, {:suspend, []}, callback)

          refute_received {:visited, _}
          assert {:suspended, [:seed], resume_again} = resume.({:suspend, [:seed]})
          refute_received {:visited, _}
          assert resume_again.({:halt, :stopped}) == {:halted, :stopped}
          refute_received {:visited, _}
          assert resume.({:cont, []}) === {:done, Enum.reverse(expected)}

          for item <- expected, do: assert_received({:visited, ^item})
          refute_received {:visited, _}
        end
      end

      test "callback halt stops at the requested element" do
        {collection, [first | _]} = fixture(@collection, Enum.to_list(1..15))

        callback = fn item, acc ->
          send(self(), {:visited, item})
          {:halt, [item | acc]}
        end

        assert Enumerable.reduce(collection, {:cont, []}, callback) === {:halted, [first]}
        assert_received {:visited, ^first}
        refute_received {:visited, _}
      end

      test "many continued callbacks can halt in the middle without visiting later elements" do
        input = Enum.to_list(1..257)

        for {collection, expected} <- [
              fixture(@collection, input),
              inserted_fixture(@collection, input)
            ] do
          callback = fn item, acc ->
            send(self(), {:visited, item})
            signal = if ordinal(item) == 129, do: :halt, else: :cont
            {signal, [item | acc]}
          end

          assert Enumerable.reduce(collection, {:cont, []}, callback) ===
                   {:halted, expected |> Enum.take(129) |> Enum.reverse()}

          for item <- Enum.take(expected, 129), do: assert_received({:visited, ^item})
          refute_received {:visited, _}
        end
      end

      test "middle suspensions resume long runs with replacement map accumulators" do
        input = Enum.to_list(1..257)

        for {collection, expected} <- [
              fixture(@collection, input),
              inserted_fixture(@collection, input)
            ] do
          callback = fn item, acc ->
            updated = %{acc | count: acc.count + 1, items: [item | acc.items]}
            signal = if ordinal(item) in [64, 192], do: :suspend, else: :cont
            {signal, updated}
          end

          initial = %{count: 0, items: [], payload: {:suspend, :ordinary_data}}

          assert {:suspended, first, resume} =
                   Enumerable.reduce(collection, {:cont, initial}, callback)

          assert first === %{
                   initial
                   | count: 64,
                     items: expected |> Enum.take(64) |> Enum.reverse()
                 }

          replacement = %{count: 1000, items: [:replacement], payload: {:halt, :ordinary_data}}
          assert {:suspended, second, resume_again} = resume.({:cont, replacement})
          middle = expected |> Enum.slice(64, 128) |> Enum.reverse()
          assert second === %{replacement | count: 1128, items: middle ++ [:replacement]}

          final_seed = %{count: -10, items: [], payload: nil}
          tail = expected |> Enum.drop(192) |> Enum.reverse()

          assert resume_again.({:cont, final_seed}) ===
                   {:done, %{final_seed | count: 55, items: tail}}
        end
      end

      test "callback throws propagate unchanged after continued elements" do
        {collection, _} = inserted_fixture(@collection, Enum.to_list(1..257))

        for thrown <- [{:halted, :user_value}, {:suspended, :user_value}, :user_value] do
          assert catch_throw(
                   Enumerable.reduce(collection, {:cont, 0}, fn item, count ->
                     if ordinal(item) == 129, do: throw(thrown), else: {:cont, count + 1}
                   end)
                 ) === thrown
        end
      end

      test "callback exits propagate unchanged after continued elements" do
        {collection, _} = inserted_fixture(@collection, Enum.to_list(1..257))
        reason = {:halted, :callback_exit}

        assert catch_exit(
                 Enumerable.reduce(collection, {:cont, 0}, fn item, count ->
                   if ordinal(item) == 129, do: exit(reason), else: {:cont, count + 1}
                 end)
               ) === reason
      end

      test "nested halting reductions do not halt an outer reduction that later suspends" do
        {collection, _} = inserted_fixture(@collection, Enum.to_list(1..257))
        {inner, _} = fixture(@collection, Enum.to_list(1..5))

        callback = fn item, total ->
          assert {:halted, 6} =
                   Enumerable.reduce(inner, {:cont, 0}, fn nested_item, sum ->
                     value = ordinal(nested_item)
                     signal = if value == 3, do: :halt, else: :cont
                     {signal, sum + value}
                   end)

          signal = if ordinal(item) == 129, do: :suspend, else: :cont
          {signal, total + 6}
        end

        assert {:suspended, 774, resume} = Enumerable.reduce(collection, {:cont, 0}, callback)
        assert resume.({:cont, 774}) === {:done, 1542}
      end

      test "callback exceptions propagate after continued elements" do
        {collection, _} = inserted_fixture(@collection, Enum.to_list(1..257))

        assert_raise RuntimeError, "callback failure", fn ->
          Enumerable.reduce(collection, {:cont, 0}, fn item, count ->
            if ordinal(item) == 129, do: raise("callback failure"), else: {:cont, count + 1}
          end)
        end
      end

      test "repeated callback suspension retains every pending element in order" do
        {collection, expected} = fixture(@collection, Enum.to_list(1..15))
        callback = fn item, acc -> {:suspend, [item | acc]} end
        result = Enumerable.reduce(collection, {:cont, []}, callback)

        {result, reversed} =
          Enum.reduce(expected, {result, []}, fn item, {result, acc} ->
            next_acc = [item | acc]
            assert {:suspended, ^next_acc, resume} = result
            {resume.({:cont, next_acc}), next_acc}
          end)

        assert result === {:done, reversed}
      end

      test "callback continuation accepts halt and suspension without consuming an element" do
        {collection, [first, second | _]} = fixture(@collection, Enum.to_list(1..15))

        callback = fn item, acc ->
          send(self(), {:visited, item})
          {:suspend, [item | acc]}
        end

        assert {:suspended, [^first], resume} =
                 Enumerable.reduce(collection, {:cont, []}, callback)

        assert_received {:visited, ^first}
        assert {:suspended, [:replacement], resume_again} = resume.({:suspend, [:replacement]})
        refute_received {:visited, _}
        assert resume_again.({:halt, :stopped}) == {:halted, :stopped}
        refute_received {:visited, _}
        assert {:suspended, [^second, :replacement], _} = resume_again.({:cont, [:replacement]})
        assert_received {:visited, ^second}
        refute_received {:visited, _}
      end

      test "a continuation suspended after the last element still honors control signals" do
        {collection, [only]} = fixture(@collection, [1])
        callback = fn item, _ -> {:suspend, item} end
        assert {:suspended, ^only, resume} = Enumerable.reduce(collection, {:cont, nil}, callback)
        assert resume.({:halt, :stopped}) == {:halted, :stopped}
        assert {:suspended, :waiting, resume_again} = resume.({:suspend, :waiting})
        assert resume_again.({:cont, :finished}) == {:done, :finished}
      end

      test "Enum.zip resumes collections and stops when either input ends" do
        for input <- [[], Enum.to_list(1..15)] do
          {collection, expected} = fixture(@collection, input)

          for other <- [[], [:a, :b], Enum.to_list(1..20)] do
            assert Enum.zip(collection, other) === Enum.zip(expected, other)
            assert Enum.zip(other, collection) === Enum.zip(other, expected)
          end
        end
      end

      test "Enum.take supports early termination and exhaustion" do
        for input <- [[], Enum.to_list(1..15)] do
          {collection, expected} = fixture(@collection, input)

          for count <- [0, 1, 4, 20] do
            assert Enum.take(collection, count) === Enum.take(expected, count)
          end
        end
      end

      test "contiguous slices match ordered lists at negative and out-of-range indices" do
        for input <- [[], Enum.to_list(1..15)] do
          {collection, expected} = fixture(@collection, input)

          for {start, count} <- [{0, 0}, {0, 4}, {3, 5}, {-4, 3}, {-20, 3}, {20, 3}] do
            assert Enum.slice(collection, start, count) === Enum.slice(expected, start, count)
          end
        end
      end

      test "stepped slices match ordered lists including negative bounds" do
        for input <- [[], Enum.to_list(1..15)] do
          {collection, expected} = fixture(@collection, input)

          for range <- [0..10//2, 1..14//3, -8..-1//2, 0..-1//2, 20..30//2, 8..2//1] do
            assert Enum.slice(collection, range) === Enum.slice(expected, range)
          end
        end
      end
    end
  end

  defp fixture(SortedMap, input) do
    pairs = Enum.map(input, &{&1, {:value, &1}})
    {SortedMap.new(Map.new(pairs)) |> SortedMap.rebalance(), pairs}
  end

  defp fixture(SortedSet, input), do: {SortedSet.new(Enum.reverse(input)), input}

  defp inserted_fixture(SortedMap, input) do
    pairs = Enum.map(input, &{&1, {:value, &1}})

    map =
      Enum.reduce(pairs, SortedMap.new(), fn {key, value}, acc ->
        SortedMap.put(acc, key, value)
      end)

    {map, pairs}
  end

  defp inserted_fixture(SortedSet, input) do
    {Enum.reduce(input, SortedSet.new(), &SortedSet.add(&2, &1)), input}
  end

  defp ordinal({key, _value}), do: key
  defp ordinal(element), do: element
end
