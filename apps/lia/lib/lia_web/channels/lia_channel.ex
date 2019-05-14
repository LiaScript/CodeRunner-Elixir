defmodule LiaWeb.LiaChannel do
  use LiaWeb, :channel

  require Logger

  def join("lia:" <> _party_id, _data, socket) do
    Logger.info("new login")

    {:ok, nil, socket}
  end

  def join("party:" <> _private_room_id, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in(event, data, socket) do
    handle_in(event, data, socket.assigns.active, socket)
  end

  def handle_in("party", %{"store" => table, "slide" => slide, "data" => data}, true, socket) do
    dataset = %{slide: slide, participation_id: socket.assigns.party_id, data: data}

    case table do
      "code" ->
        socket.assigns.log.("store", %{"slide" => slide, "data" => data})

        case Teaching.get_code(socket.assigns.party_id, slide) do
          nil ->
            Teaching.create_code(dataset)

          code ->
            code
            |> Teaching.update_code(%{"data" => data})
        end

      "quiz" ->
        Teaching.create_exam(dataset)

      "survey" ->
        case Teaching.get_survey(socket.assigns.party_id, slide) do
          nil ->
            Teaching.create_survey(dataset)

          survey ->
            survey
            |> Teaching.update_survey(%{"data" => data})
        end
    end

    {:noreply, socket}
  end

  def handle_in("party", %{"load" => table, "slide" => slide}, true, socket) do
    Logger.debug("loading #{table}/#{slide}")

    case table do
      "code" ->
        case Teaching.get_code(socket.assigns.party_id, slide) do
          %{data: data} ->
            {:reply, {:ok, %{data: data, slide: slide, table: "code"}}, socket}

          _ ->
            {:reply, {:ok, %{data: nil, slide: slide, table: "code"}}, socket}
        end

      "survey" ->
        case Teaching.get_survey(socket.assigns.party_id, slide) do
          %{data: data} ->
            {:reply, {:ok, %{data: data, slide: slide, table: "survey"}}, socket}

          _ ->
            {:noreply, socket}
        end

      "quiz" ->
        case Teaching.get_latest_exam(socket.assigns.party_id, slide) do
          %{data: data} ->
            {:reply, {:ok, %{data: data, slide: slide, table: "quiz"}}, socket}

          _ ->
            {:noreply, socket}
        end

      _ ->
        {:reply, {:error, %{msg: table <> " does not exist"}}, socket}
    end
  end

  def handle_in("party", %{"set_local_storage" => dict}, _, socket) do
    party =
      socket.assigns.party_id
      |> Teaching.get_participation!()

    local_storage =
      party
      |> Map.get(:local_storage)
      |> Map.merge(dict)

    Teaching.update_participation(party, %{local_storage: local_storage})

    {:noreply, socket}
  end

  def handle_in("party", %{"get_local_storage" => keys}, _, socket) do
    result =
      if keys == [] do
        socket.assigns.party_id
        |> Teaching.get_participation!()
        |> Map.get(:local_storage)
      else
        socket.assigns.party_id
        |> Teaching.get_participation!()
        |> Map.get(:local_storage)
        |> Map.to_list()
        |> Enum.filter(fn {key, _} -> Enum.member?(keys, key) end)
        |> Map.new()
      end

    {:reply, {:ok, result}, socket}
  end

  def handle_in("party", %{"update" => event_config, "slide" => slide}, true, socket) do
    [event | config] = event_config

    socket.assigns.log.("update", %{"slide" => slide, "event" => event_config})

    case {event, Teaching.get_code(socket.assigns.party_id, slide)} do
      {_, nil} ->
        Logger.debug("Problem with event (fullscreen) slide (#{slide})")

      {"version_update", code} ->
        Teaching.update_code(code, %{"data" => code_version_update(code, config)})

      {"version_append", code} ->
        Teaching.update_code(code, %{"data" => code_version_append(code, config)})

      {"load", code} ->
        Teaching.update_code(code, %{"data" => code_load(code, config)})

      {"fullscreen", code} ->
        Teaching.update_code(code, %{"data" => code_fullscreen(code, config)})

      {"flip_view", code} ->
        Teaching.update_code(code, %{"data" => code_flip_view(code, config)})
    end

    {:noreply, socket}
  end

  def handle_in("party", %{"slide" => slide}, true, socket) do
    socket.assigns.party_id
    |> Teaching.get_participation!()
    |> Teaching.update_participation(%{slide: slide})

    {:noreply, socket}
  end

  def handle_in("party", %{"preferences" => data}, _, socket) do
    socket.assigns.user_id
    |> Account.get_user!()
    |> Account.update_user(%{preferences: data})

    {:noreply, socket}
  end

  def handle_in(
        "party",
        %{"event_id" => event_id, "message" => %{"start" => service, "settings" => settings}},
        _active,
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

      "MissionControl" ->
        case MissionControl.start(
               self(),
               event_id
             ) do
          {:ok, pid} ->
            {:reply,
             {:ok, %{event_id: event_id, message: "MissionControl started successfully\n"}},
             set_(socket, event_id, MissionControl, pid)}

          {:error, msg} ->
            {:reply, {:error, %{event_id: event_id, message: msg}}, socket}

          msg ->
            Logger.error("Fuck: " <> Kernel.inspect(msg))
            {:reply, {:error, %{event_id: event_id, message: Kernel.inspect(msg)}}, socket}
        end

      _ ->
        {:reply, {:error, %{event_id: event_id, message: "undefined service #{service}\n"}},
         socket}
    end
  end

  def handle_in(
        "party",
        %{"event_id" => event_id, "message" => %{"stop" => _data}},
        _active,
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
        "party",
        %{"event_id" => event_id, "message" => %{"serialize" => services}},
        active,
        socket
      ) do
    case services do
      [] ->
        {:noreply, socket}

      [event] ->
        handle_in("party", event, active, socket)

      [event | rest] ->
        {_, result, socket} = handle_in("party", event, active, socket)

        push(socket, "service", result)

        case result do
          {:ok, _} ->
            handle_in(
              "party",
              %{"event_id" => event_id, "message" => %{"serialize" => rest}},
              active,
              socket
            )

          _ ->
            {:noreply, socket}
        end
    end
  end

  def handle_in(
        "party",
        %{"event_id" => _event_id, "message" => %{"connect" => list}},
        active,
        socket
      ) do
    [[send_id, send_msg], [recv_id, recv_msg]] = list

    case handle_in("party", %{"event_id" => send_id, "message" => send_msg}, active, socket) do
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
          "party",
          %{"event_id" => recv_id, "message" => msg},
          active,
          new_socket
        )

      other_results ->
        other_results
    end
  end

  def handle_in("party", %{"event_id" => event_id, "message" => message}, _active, socket) do
    Logger.info("PARTY SERVICE HANDLE for event_id #{event_id}")

    case get_(socket, event_id) do
      {pid, module} ->
        {:reply, module.handle(pid, message, event_id, socket.assigns.log), socket}

      nil ->
        {:reply, {:error, %{message: "unknown event id: " <> event_id}, socket}}
    end
  end

  def handle_in(_topic, _message, _active, socket) do
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

  defp code_fullscreen(code, data) do
    [project_id, file_id, bool] = data

    List.update_at(code.data, project_id, fn project ->
      %{
        project
        | "file" =>
            List.update_at(project["file"], file_id, fn file ->
              %{file | "fullscreen" => bool}
            end)
      }
    end)
  end

  defp code_flip_view(code, data) do
    [project_id, file_id, bool] = data

    List.update_at(code.data, project_id, fn project ->
      %{
        project
        | "file" =>
            List.update_at(project["file"], file_id, fn file ->
              %{file | "visible" => bool}
            end)
      }
    end)
  end

  defp code_version_update(code, config) do
    [project_id, %{"version_active" => version_active, "log" => log, "version" => version}] =
      config

    List.update_at(code.data, project_id, fn project ->
      %{
        project
        | "version_active" => version_active,
          "log" => log,
          "version" =>
            if is_nil(version) do
              project["version"]
            else
              List.update_at(project["version"], version_active, fn _ ->
                version
              end)
            end
      }
    end)
  end

  defp code_version_append(code, config) do
    [
      project_id,
      %{"version_active" => version_active, "log" => log, "version" => version, "file" => file}
    ] = config

    List.update_at(code.data, project_id, fn project ->
      %{
        project
        | "version_active" => version_active,
          "log" => log,
          "file" => file,
          "version" =>
            if is_nil(version) do
              project["version"]
            else
              project["version"] ++ [version]
            end
      }
    end)
  end

  defp code_load(code, config) do
    [project_id, %{"version_active" => version_active, "log" => log, "file" => file}] = config

    List.update_at(code.data, project_id, fn project ->
      %{project | "version_active" => version_active, "log" => log, "file" => file}
    end)
  end
end
