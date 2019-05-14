defmodule CodeRunner do
  @moduledoc """
  Documentation for CodeRunner.
  """

  require Logger

  def start(base, project, other_pid, event_id) do
    Logger.debug("start")
    CodeRunner.Agent.start(base, project, other_pid, event_id)
  end

  def stop(pid, _event_id) do
    Logger.debug("stop")
    CodeRunner.Agent.stop(pid)
  end

  def handle(pid, %{"files" => files}, event_id, _log) do
    Logger.debug("files")

    case CodeRunner.Agent.set_files(pid, files) do
      :ok ->
        {:ok, %{event_id: event_id, message: "filesystem updated\n"}}

      :error ->
        {:ok, %{event_id: event_id, message: "could not create filesystem\n"}}
    end
  end

  def handle(pid, %{"compile" => config, "order" => order}, event_id, log) do
    Logger.debug("compile")
    {rslt, info, details} = CodeRunner.Agent.compile(pid, config)
    Logger.debug(Kernel.inspect({rslt, info, details}))

    log.("compile", %{"rslt" => rslt, "info" => info, "details" => details})

    {rslt, %{message: info, details: Enum.map(order, &filter(&1, details)), event_id: event_id}}
  end

  def handle(pid, %{"compile" => config}, event_id, log) do
    Logger.debug("compile")
    {rslt, info, details} = CodeRunner.Agent.compile(pid, config)

    log.("compile", %{"rslt" => rslt, "info" => info, "details" => details})

    {rslt, %{message: info, details: details, event_id: event_id}}
  end

  def handle(pid, %{"execute" => config}, event_id, _log) do
    Logger.debug("execute")
    CodeRunner.Agent.execute(pid, config, event_id)
  end

  def handle(pid, %{"stop" => _config}, _event_id, _log) do
    Logger.debug("stop")
    CodeRunner.Agent.stop(pid)
  end

  def handle(pid, %{"input" => string}, _event_id, _log) do
    Logger.debug("input")
    CodeRunner.Agent.input(pid, string)
  end

  def handle(pid, %{"get_path" => file}, event_id, _log) do
    {:ok, %{message: CodeRunner.Agent.get_path(pid) <> "/" <> file, event_id: event_id}}
  end

  def handle(_pid, data, event_id, _log) do
    Logger.debug("could not handle #{Kernel.inspect(data)}")
    {:error, %{message: "no such option: " <> Kernel.inspect(data), event_id: event_id}}
  end

  defp filter(file_name, details) do
    details
    |> Enum.filter(fn x -> String.ends_with?(x["file"], file_name) end)
    |> Enum.map(&Map.drop(&1, ["file"]))
  end
end
