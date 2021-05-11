defmodule CodeRunner.Agent do
  alias CodeRunner.Project

  alias CodeRunner.Comp
  require Logger

  @cmd_prefix "firejail --noroot --private --quiet --cpu=1 --nonewprivs --nogroups --nice=19 --hostname=host --net=none --no3d --nosound --x11=none --rlimit-cpu=1 -- stdbuf -o 0 "

  # @cmd_prefix "stdbuf -o 0 cpulimit -l 1 -z -- "
  # @cmd_prefix "/home/andre/Workspace/Projects/cpulimit/src/cpulimit -l 1 -- stdbuf -o 0 "

  defmodule Settings do
    defstruct path: "",
              files: %{},
              lang: nil,
              other_pid: nil,
              event_id: nil,
              port: nil
  end

  def start(base, project, other_pid, event_id) do
    if not Project.exists?(project, base) do
      Project.init!(project, base)

      %Settings{path: Project.path(project, base), other_pid: other_pid, event_id: event_id}
      |> start_link()
    else
      {:error, "project already exists"}
    end
  end

  def stop(pid) do
    conf = get_plug(pid)

    IO.inspect(conf.port)

    # Port.info(conf.port)
    if is_port(conf.port) do
      execte_stop(conf.port)
      # {:os_pid, pid_} = Port.info(conf.port, :os_pid)
      # System.cmd("kill", ["-9", "#{pid_}"])
    end

    Project.delete(conf.path)

    Agent.stop(pid, :normal, 1000)
  end

  def set_language(pid, lang) do
    pid
    |> get_plug()
    |> Map.put(:lang, lang)
    |> set_plug(pid)
  end

  def get_path(pid) do
    pid
    |> get_plug()
    |> Map.get(:path)
  end

  def set_files(pid, files) do
    config = get_plug(pid)

    try do
      if files != config.files do
        files
        |> Map.merge(config.files, &update_files(&1, &2, &3))
        |> filter_files()
        |> Project.write_files!(config.path)

        set_plug(%{config | files: files}, pid)
      end

      :ok
    catch
      _ -> :error
    end
  end

  defp split(cmd, path) do
    cmd
    |> String.replace("$PWD", path)
    |> (&Regex.scan(~r/[^ ]*"[^"]*"|[^ ]*'[^']*'|[^ ]+/, &1)).()
    |> List.flatten()
  end

  def compile(pid, cmd) do
    config = get_plug(pid)

    case split(cmd, config.path) do
      ["avr-g++" | args] ->
        Comp.AvrGpp.compile(args, config.path)

      ["arduino-builder" | args] ->
        Comp.ArduinoBuilder.compile(args, config.path)

      ["clang" | args] ->
        Comp.Clang.compile(args, config.path)

      ["gcc" | args] ->
        Comp.Gcc.compile(args, config.path)

      ["g++" | args] ->
        Comp.Gpp.compile(args, config.path)

      ["go" | args] ->
        Comp.Go.compile(args, config.path)

      ["javac" | args] ->
        Comp.Java.compile(args, config.path)

      ["python" | args] ->
        Comp.Python.compile("python", args, config.path)

      ["python3" | args] ->
        Comp.Python.compile("python3", args, config.path)

      ["mono" | args] ->
        Comp.Mono.compile(args, config.path)

      ["dotnet" | args] ->
        Comp.DotNet.compile(args, config.path)

      ["rustc" | args] ->
        Comp.Rust.compile(args, config.path)

      [comp | _args] ->
        {:error, "Compiler not found: #{comp}", []}
    end
  end

  def execute(pid, cmd, event_id) do
    config = get_plug(pid)

    IO.inspect(@cmd_prefix <> cmd)

    port =
      Port.open(
        {:spawn, @cmd_prefix <> cmd},
        [:binary, :stderr_to_stdout, cd: config.path, parallelism: true]
      )

    mediator = spawn(fn -> port_monitor(port, event_id, config.other_pid) end)

    Port.connect(port, mediator)

    set_plug(%{config | port: port}, pid)

    {:ok, %{event_id: event_id, message: "started to execut #{cmd}\n"}}
  end

  def execte_stop(port) do
    if port && Port.info(port) do
      Port.close(port)
    end
  end

  def execute_input(port, msg) do
    if port && Port.info(port) do
      send(port, {self(), {:command, msg}})
    end
  end

  def input(pid, string) do
    Logger.debug("input: #{string}")
    plug = get_plug(pid)

    if plug.port && Port.info(plug.port) do
      # send(plug.port, {self(), {:command, string}})
      Port.command(plug.port, string)
    end

    :ok
  end

  defp port_monitor(port, event_id, other_pid) do
    Port.monitor(port)
    running(event_id, other_pid)
  end

  defp running(event_id, other_pid) do
    receive do
      {_port, {:data, msg}} ->
        Logger.debug("receive #{event_id}: #{msg}")
        send(other_pid, {:data, %{message: %{stdout: msg}, event_id: event_id}})
        running(event_id, other_pid)

      {:DOWN, _, _, _, _} ->
        Logger.debug(":DOWN #{event_id}")
        send(other_pid, {:data, %{message: %{exit: "process terminated\n"}, event_id: event_id}})

      msg ->
        Logger.error("unknown message (#{event_id}): #{Kernel.inspect(msg)}}")
    end
  end

  defp update_files(_name, v1, v2) do
    if v1 == v2, do: nil, else: v1
  end

  defp filter_files(map) do
    for {key, value} <- map, !is_nil(value), into: %{}, do: {key, value}
  end

  defp start_link(plug),
    do: Agent.start_link(fn -> plug end)

  defp get_plug(pid),
    do: Agent.get(pid, & &1)

  defp set_plug(plug, pid),
    do: Agent.update(pid, &(&1 = plug))
end
