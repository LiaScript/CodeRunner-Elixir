defmodule CodeRunner.Comp.Newbie do
  @newbie "python3 /home/andre/Workspace/Projects/lia/apps/code_runner/assets/compileErrorHintAdder.py"

  # @newbie "python3 /lia/apps/code_runner/assets/compileErrorHintAdder.py"

  def compile(args, path) do
    case System.cmd("g++", args, cd: path, stderr_to_stdout: true) do
      {msg, 0} ->
        {:ok, msg, []}

      {msg, 1} ->
        cmd = "g++ " <> Enum.join(args, " ") <> " 2>&1 | " <> @newbie

        case(
          System.cmd(
            "sh",
            ["-c", cmd],
            cd: path,
            stderr_to_stdout: true
          )
        ) do
          {msg2, 0} ->
            {:error, msg2, []}

          ggg ->
            {:error, msg, []}
        end
    end
  end
end
