defmodule Chat.CLI do
  def iniciar() do
    IO.puts("=============================================")
    IO.puts("              CLIENTE TCP CHAT              ")
    IO.puts("=============================================")

    ip = prompt_ip()
    port = prompt_port()

    case :gen_tcp.connect(ip, port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        nome = prompt_name()
        :gen_tcp.send(socket, nome <> "\n")

        IO.puts("Conectado. Use /join #sala, /leave, /exit.")
        spawn(fn -> receive_loop(socket) end)
        input_loop(socket)
      {:error, reason} ->
        IO.puts("Falha ao conectar: #{inspect(reason)}")
    end
  end

  defp prompt_ip() do
    input = IO.gets("IP do servidor (vazio para 127.0.0.1): ") |> to_string() |> String.trim()

    case input do
      "" -> {127, 0, 0, 1}
      _ ->
        case :inet.parse_address(String.to_charlist(input)) do
          {:ok, ip} -> ip
          {:error, _} ->
            IO.puts("IP invalido, tente novamente.")
            prompt_ip()
        end
    end
  end

  defp prompt_port() do
    input = IO.gets("Porta do servidor (vazio para 4040): ") |> to_string() |> String.trim()

    case input do
      "" -> 4040
      _ ->
        case Integer.parse(input) do
          {port, ""} when port > 0 and port < 65536 -> port
          _ ->
            IO.puts("Porta invalida, tente novamente.")
            prompt_port()
        end
    end
  end

  defp prompt_name() do
    input = IO.gets("Seu nome: ") |> to_string() |> String.trim()

    if input == "" do
      IO.puts("Nome nao pode ser vazio.")
      prompt_name()
    else
      input
    end
  end

  defp input_loop(socket) do
    text = IO.gets("")

    if text == nil do
      :gen_tcp.close(socket)
    else
      trimmed = String.trim(text)

      cond do
        trimmed == "" ->
          :ok
        trimmed in ["/exit", "/quit"] ->
          :gen_tcp.send(socket, trimmed <> "\n")
          :gen_tcp.close(socket)
          :ok
        true ->
          :gen_tcp.send(socket, trimmed <> "\n")
          input_loop(socket)
      end
    end
  end

  defp receive_loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        IO.write(data)
        receive_loop(socket)
      {:error, :closed} ->
        IO.puts("Desconectado.")
      {:error, _reason} ->
        IO.puts("Erro de conexao.")
    end
  end
end
