defmodule CodeRunner.Comp.DotNet do
  import CodeRunner.Comp.Helper, only: [append: 2, parse_: 3, decrease_row_by1: 1]

  def compile(args, path) do
    case System.cmd("dotnet", args, cd: path, stderr_to_stdout: true) do
      {msg, 0} ->
        {:ok, msg, parse_warning(msg)}

      {msg, 1} ->
        {:error, msg, parse_warning(msg) ++ parse_error(msg)}
    end
  end

  defp parse_warning(msg) do
    parse_(pattern(), msg, ": warning")
    |> decrease_row_by1
    |> Enum.map(&append(&1, "warning"))
  end

  defp parse_error(msg) do
    errors = parse_(pattern(), msg, ": error")
             |> decrease_row_by1
    fatals = parse_(pattern(), msg, ": fatal error:")
             |> decrease_row_by1

    errors
    |> Enum.concat(fatals)
    |> Enum.map(&append(&1, "error"))
  end

  defp pattern(), do: ~r/\/[^\/]*\/[^\/]*\/[^\/]*\/(?<file>.+)\((?<row>\d+),\d+\): [^ ]+ (?<text>.*)/
end
