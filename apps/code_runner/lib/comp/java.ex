defmodule CodeRunner.Comp.Java do
  import CodeRunner.Comp.Helper, only: [append: 2, parse_: 3]

  def compile(args, path) do
    case System.cmd("javac", args, cd: path, stderr_to_stdout: true) do
      {msg, 0} ->
        {:ok, msg, parse_warning(msg)}

      {msg, 1} ->
        {:error, msg, parse_warning(msg) ++ parse_error(msg)}
    end
  end

  defp parse_warning(msg) do
    msg
    |> parse_(": warning:")
    |> Enum.map(&append(&1, "warning"))
  end

  defp parse_error(msg) do
    errors = parse_(msg, ": error:")
    fatals = parse_(msg, ": fatal error:")

    errors
    |> Enum.concat(fatals)
    |> Enum.map(&append(&1, "error"))
  end

  defp parse_(msg, pattern) do
    parse_(~r/(?<file>.+)\:(?<row>\d+)\:[^\:]+\: (?<text>.*)/, msg, pattern)
  end
end
