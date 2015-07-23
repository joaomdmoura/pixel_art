defmodule Mix.Tasks.Compile.Phoenix do
  use Mix.Task
  @recursive true

  @moduledoc """
  Compiles Phoenix source files that support code reloading.
  """

  @doc false
  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:phoenix)

    case touch() do
      [] -> :noop
      _  -> :ok
    end
  end

  @doc false
  def touch do
    Mix.Phoenix.modules
    |> modules_for_recompilation
    |> modules_to_file_paths
    |> Stream.each(&File.touch/1)
    |> Enum.to_list()
  end

  defp modules_for_recompilation(modules) do
    modules
    |> Stream.filter fn mod ->
      Code.ensure_loaded?(mod) and
        function_exported?(mod, :__phoenix_recompile__?, 0) and
        mod.__phoenix_recompile__?
    end
  end

  defp modules_to_file_paths(modules) do
    Stream.map(modules, fn mod -> mod.__info__(:compile)[:source] end)
  end
end
