defmodule DialyzerHelper do
  alias OrderedCollections

  @moduledoc """
  Helper functions to wrap calls that intentionally trigger Dialyzer warnings.

  Use these helpers in tests where you need to bypass type warnings for functions
  that are meant to error with non-standard inputs.
  """

  @dialyzer {:nowarn_function, [dialyzer_warning_ignore: 2]}

  @doc """
  Applies the given function with a list of arguments, suppressing Dialyzer warnings.

  ## Examples

      iex> DialyzerHelper.dialyzer_warning_ignore(&OrderedCollections.to_map/1, [%{a: 1}])
      ** (FunctionClauseError) ...

      iex> DialyzerHelper.dialyzer_warning_ignore(&OrderedCollections.to_map/1, %{a: 1})
      ** (FunctionClauseError) ...
  """
  def dialyzer_warning_ignore(function, args) when is_list(args) do
    apply(function, args)
  end

  def dialyzer_warning_ignore(fun, arg) do
    fun.(arg)
  end
end
