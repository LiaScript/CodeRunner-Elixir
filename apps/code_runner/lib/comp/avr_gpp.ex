defmodule CodeRunner.Comp.AvrGpp do
  import CodeRunner.Comp.Helper, only: [append: 2, parse_clike: 2]

  @cmd Application.get_env(:code_runner, :avr_gpp)

  def compile(args, path) do
    case System.cmd(@cmd, args, cd: path, stderr_to_stdout: true) do
      {msg, 0} ->
        {:ok, msg, parse_warning(msg)}

      {msg, 1} ->
        {:error, msg, parse_warning(msg) ++ parse_error(msg)}

      {_, 2} ->
        {:error, "sketch not found", []}

      {_, 3} ->
        {:error, "argument error", []}

      {_, 4} ->
        {:error, "preference error", []}
    end
  end

  defp parse_warning(msg) do
    parse_clike(msg, ": warning:")
    |> Enum.map(&append(&1, "warning"))
  end

  defp parse_error(msg) do
    errors = parse_clike(msg, ": error:")
    fatals = parse_clike(msg, ": fatal error:")

    errors
    |> Enum.concat(fatals)
    |> Enum.map(&append(&1, "error"))
  end
end
