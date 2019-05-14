defmodule LiaWeb.LiaChannel do
  use LiaWeb, :channel

  require Logger

  def join("lia:" <> _id, _data, socket) do
    Logger.info("new login")

    {:ok, nil, socket |> assign(:event_pid, %{})}
  end

  def join("lia:" <> _private_room_id, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in(
        "lia",
        %{"event_id" => event_id, "message" => %{"start" => service, "settings" => _settings}},
        socket
      ) do
    Logger.info("PARTY SERVICE START for service (#{service}) and event_id #{event_id}")

    case get_(socket, event_id) do
      {pid, module} ->
        stop_(module, pid, event_id)

      nil ->
        nil
    end

    case service do
      "CodeRunner" ->
        case CodeRunner.start(
               "/tmp/elab",
               :crypto.strong_rand_bytes(10) |> Base.encode16(),
               self(),
               event_id
             ) do
          {:ok, pid} ->
            {:reply, {:ok, %{event_id: event_id, message: "CodeRunner started successfully\n"}},
             set_(socket, event_id, CodeRunner, pid)}

          {:error, msg} ->
            {:reply, {:error, %{event_id: event_id, message: msg}}, socket}
        end

      _ ->
        {:reply, {:error, %{event_id: event_id, message: "undefined service #{service}\n"}},
         socket}
    end
  end

  def handle_in(
        "lia",
        %{"event_id" => event_id, "message" => %{"stop" => _data}},
        socket
      ) do
    Logger.info("PARTY SERVICE STOP for event #{event_id}")

    case get_(socket, event_id) do
      {pid, module} ->
        stop_(module, pid, event_id)
        {:noreply, socket}

      _ ->
        Logger.info("pid not found for event_id: #{event_id}")
        {:noreply, socket}
    end
  end

  def handle_in(
        "lia",
        %{"event_id" => event_id, "message" => %{"serialize" => services}},
        socket
      ) do
    case services do
      [] ->
        {:noreply, socket}

      [event] ->
        handle_in("lia", event, socket)

      [event | rest] ->
        {_, result, socket} = handle_in("lia", event, socket)

        push(socket, "service", result)

        case result do
          {:ok, _} ->
            handle_in(
              "lia",
              %{"event_id" => event_id, "message" => %{"serialize" => rest}},
              socket
            )

          _ ->
            {:noreply, socket}
        end
    end
  end

  def handle_in(
        "lia",
        %{"event_id" => _event_id, "message" => %{"connect" => list}},
        socket
      ) do
    [[send_id, send_msg], [recv_id, recv_msg]] = list

    case handle_in("lia", %{"event_id" => send_id, "message" => send_msg}, socket) do
      {_, {:ok, rslt}, new_socket} ->
        msg =
          recv_msg
          |> Map.to_list()
          |> Enum.map(fn {k, v} ->
            if v == nil do
              {k, rslt.message}
            else
              {k, v}
            end
          end)
          |> Map.new()

        handle_in(
          "lia",
          %{"event_id" => recv_id, "message" => msg},
          new_socket
        )

      other_results ->
        other_results
    end
  end

  def handle_in("lia", %{"event_id" => event_id, "message" => message}, socket) do
    Logger.info("PARTY SERVICE HANDLE for event_id #{event_id}")

    case get_(socket, event_id) do
      {pid, module} ->
        {:reply, module.handle(pid, message, event_id), socket}

      nil ->
        {:reply, {:error, %{message: "unknown event id: " <> event_id}, socket}}
    end
  end

  def handle_in(_topic, _message, socket) do
    {:noreply, socket}
  end

  def handle_info(
        {:data, %{message: %{exit: "process terminated\n"}, event_id: event_id}},
        socket
      ) do
    push(socket, "service", %{message: %{exit: "process terminated\n"}, event_id: event_id})
    {:noreply, socket}
  end

  def handle_info({:data, message}, socket) do
    push(socket, "service", message)
    {:noreply, socket}
  end

  # handle the trapped exit call
  def handle_info({:EXIT, _from, reason}, socket) do
    Logger.info("exiting")
    cleanup(reason, socket)

    {:stop, reason, socket}
  end

  # handle termination
  def terminate({%Protocol.UndefinedError{value: event_id}, _}, socket) do
    Logger.info("terminating")
    cleanup(event_id, socket)
  end

  def terminate(_reason, socket) do
    cleanup(socket)
  end

  defp cleanup(event_id, socket) do
    IO.inspect(socket.assigns.event_pid)

    socket.assigns.event_pid
    |> Map.to_list()
    |> Enum.filter(fn {id, _} -> id != event_id end)
    |> Map.new()
    |> Enum.map(&assign(socket, :event_pid, &1))
  end

  defp cleanup(socket) do
    socket.assigns.event_pid
    |> Map.to_list()
    |> Enum.map(fn {id, {pid, module}} -> stop_(module, pid, id) end)

    assign(socket, :event_pid, %{})
  end

  defp stop_(module, pid, id) do
    try do
      if Process.alive?(pid) do
        module.stop(pid, id)
      end
    catch
      whatever ->
        Logger.debug("cleanup not working for #{Kernel.inspect(whatever)}")
    end

    :ok
  end

  defp get_(socket, event_id) do
    Map.get(socket.assigns.event_pid, event_id)
  end

  defp set_(socket, event_id, module, pid) do
    assign(socket, :event_pid, Map.put(socket.assigns.event_pid, event_id, {pid, module}))
  end
end
