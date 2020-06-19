defmodule CodeRunner.Comp.Python do
  def compile(cmd, args, path) do
    case System.cmd(cmd, args, cd: path, stderr_to_stdout: true) do
      {msg, 0} ->
        {:ok, msg, []}

      {msg, 1} ->
        {:error, msg, parse_error(msg)}
    end
  end

  defp parse_error(msg) do
    [
      Regex.named_captures(
        ~r/.*\n.*File \"(?<file>.+)\", line (?<row>\d+)\n(?<text>.*\n.*\n.*)/,
        msg
      )
      |> Map.put("column", 0)
      |> Map.put("type", "error")
    ]
  end
end
