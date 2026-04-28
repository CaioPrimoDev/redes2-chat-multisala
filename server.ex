defmodule Chat.ServerCLI do
  def iniciar() do
    IO.puts("=============================================")
    IO.puts("           TCP CHAT SERVER (CENTRAL)        ")
    IO.puts("=============================================")

    ip = prompt_ip()
    port = prompt_port()

    case Chat.Server.start(ip, port) do
      {:ok, _pid} ->
        IO.puts("Server running on #{format_ip(ip)}:#{port}")
        IO.puts("Press Ctrl+C twice to stop.")
        Process.sleep(:infinity)
      {:error, reason} ->
        IO.puts("Failed to start server: #{inspect(reason)}")
    end
  end

  defp prompt_ip() do
    input = IO.gets("Server IP (blank for 0.0.0.0): ") |> to_string() |> String.trim()

    case input do
      "" -> {0, 0, 0, 0}
      _ ->
        case :inet.parse_address(String.to_charlist(input)) do
          {:ok, ip} -> ip
          {:error, _} ->
            IO.puts("Invalid IP, try again.")
            prompt_ip()
        end
    end
  end

  defp prompt_port() do
    input = IO.gets("Server port (blank for 4040): ") |> to_string() |> String.trim()

    case input do
      "" -> 4040
      _ ->
        case Integer.parse(input) do
          {port, ""} when port > 0 and port < 65536 -> port
          _ ->
            IO.puts("Invalid port, try again.")
            prompt_port()
        end
    end
  end

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
end

defmodule Chat.Server do
  use GenServer

  def start(ip, port) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: :chat_server)

    listen_opts = [
      :binary,
      packet: :line,
      active: false,
      reuseaddr: true,
      ip: ip
    ]

    case :gen_tcp.listen(port, listen_opts) do
      {:ok, listen_socket} ->
        spawn(fn -> accept_loop(listen_socket, pid) end)
        {:ok, pid}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def init(_opts) do
    state = %{clients: %{}, rooms: %{}}
    {:ok, state}
  end

  @impl true
  def handle_cast({:register_client, pid, socket}, state) do
    client = %{socket: socket, name: nil, room: nil}
    {:noreply, put_in(state, [:clients, pid], client)}
  end

  @impl true
  def handle_cast({:handle_line, pid, line}, state) do
    case Map.get(state.clients, pid) do
      nil ->
        {:noreply, state}
      client ->
        handle_client_line(pid, client, line, state)
    end
  end

  @impl true
  def handle_cast({:disconnect, pid}, state) do
    state = remove_client(pid, state)
    {:noreply, state}
  end

  defp accept_loop(listen_socket, server_pid) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        pid = spawn(fn -> Chat.ClientHandler.run(socket, server_pid) end)
        :ok = :gen_tcp.controlling_process(socket, pid)
        GenServer.cast(server_pid, {:register_client, pid, socket})
        accept_loop(listen_socket, server_pid)
      {:error, _reason} ->
        :ok
    end
  end

  defp handle_client_line(pid, client, line, state) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        {:noreply, state}

      client.name == nil ->
        set_name(pid, client, trimmed, state)

      String.starts_with?(trimmed, "/join ") ->
        room = trimmed |> String.replace("/join ", "") |> normalize_room()
        join_room(pid, client, room, state)

      trimmed == "/leave" ->
        leave_room(pid, client, state)

      trimmed in ["/exit", "/quit"] ->
        send_to(pid, "Bye!\n", state)
        close_client(pid, state)
        {:noreply, remove_client(pid, state)}

      String.starts_with?(trimmed, "/") ->
        send_to(pid, "Unknown command. Use /join, /leave, /exit.\n", state)
        {:noreply, state}

      true ->
        send_message(pid, client, trimmed, state)
    end
  end

  defp set_name(pid, client, name, state) do
    clean = String.trim(name)

    cond do
      clean == "" ->
        send_to(pid, "Name cannot be empty. Try again.\n", state)
        {:noreply, state}
      String.starts_with?(clean, "/") ->
        send_to(pid, "Invalid name. Try again.\n", state)
        {:noreply, state}
      name_in_use?(clean, state) ->
        send_to(pid, "Name already in use. Try another.\n", state)
        {:noreply, state}
      true ->
        updated = %{client | name: clean}
        state = put_in(state, [:clients, pid], updated)
        send_to(pid, "Welcome #{clean}! Use /join #room to enter a room.\n", state)
        {:noreply, state}
    end
  end

  defp join_room(pid, _client, nil, state) do
    send_to(pid, "Invalid room. Use /join #room.\n", state)
    {:noreply, state}
  end

  defp join_room(pid, client, room, state) do
    state = remove_from_room(pid, state)

    rooms = Map.update(state.rooms, room, MapSet.new([pid]), fn set ->
      MapSet.put(set, pid)
    end)

    updated = %{client | room: room}
    state = %{state | rooms: rooms, clients: Map.put(state.clients, pid, updated)}
    send_to(pid, "Joined #{room}.\n", state)
    {:noreply, state}
  end

  defp leave_room(pid, client, state) do
    state = remove_from_room(pid, state)
    updated = %{client | room: nil}
    state = put_in(state, [:clients, pid], updated)
    send_to(pid, "Left room.\n", state)
    {:noreply, state}
  end

  defp send_message(pid, client, message, state) do
    cond do
      client.room == nil ->
        send_to(pid, "You are not in a room. Use /join #room.\n", state)
        {:noreply, state}
      true ->
        room = client.room
        text = "[#{room}] #{client.name}: #{message}\n"
        broadcast(room, text, state)
        {:noreply, state}
    end
  end

  defp broadcast(room, text, state) do
    case Map.get(state.rooms, room) do
      nil ->
        :ok
      pids ->
        Enum.each(pids, fn pid -> send_to(pid, text, state) end)
    end
  end

  defp name_in_use?(name, state) do
    state.clients
    |> Map.values()
    |> Enum.any?(fn client -> client.name == name end)
  end

  defp normalize_room(room) do
    clean = String.trim(room)

    cond do
      clean == "" -> nil
      String.starts_with?(clean, "#") -> clean
      true -> "#" <> clean
    end
  end

  defp send_to(pid, text, state) do
    case Map.get(state.clients, pid) do
      nil -> :ok
      client -> :gen_tcp.send(client.socket, text)
    end
  end

  defp close_client(pid, state) do
    case Map.get(state.clients, pid) do
      nil -> :ok
      client -> :gen_tcp.close(client.socket)
    end
  end

  defp remove_client(pid, state) do
    state = remove_from_room(pid, state)
    %{state | clients: Map.delete(state.clients, pid)}
  end

  defp remove_from_room(pid, state) do
    case Map.get(state.clients, pid) do
      nil -> state
      %{room: nil} -> state
      %{room: room} ->
        rooms = Map.update(state.rooms, room, MapSet.new(), fn set ->
          MapSet.delete(set, pid)
        end)

        rooms =
          case Map.get(rooms, room) do
            set when is_struct(set, MapSet) and MapSet.size(set) == 0 -> Map.delete(rooms, room)
            _ -> rooms
          end

        %{state | rooms: rooms}
    end
  end
end

defmodule Chat.ClientHandler do
  def run(socket, server_pid) do
    :gen_tcp.send(socket, "Welcome. Enter your name:\n")
    loop(socket, server_pid)
  end

  defp loop(socket, server_pid) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        GenServer.cast(server_pid, {:handle_line, self(), data})
        loop(socket, server_pid)
      {:error, :closed} ->
        GenServer.cast(server_pid, {:disconnect, self()})
      {:error, _reason} ->
        GenServer.cast(server_pid, {:disconnect, self()})
    end
  end
end
