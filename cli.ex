defmodule Chat.CLI do
  def iniciar() do
    # Limpa a tela do terminal
    IO.write("\e[H\e[2J")
    IO.puts(IO.ANSI.cyan() <> "=============================================")
    IO.puts("              CLIENTE TCP CHAT               ")
    IO.puts("=============================================" <> IO.ANSI.reset())

    ip = prompt_ip()
    port = prompt_port()

    case :gen_tcp.connect(ip, port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        nome = prompt_name()
        # Envia o nome para o servidor assim que conecta
        :gen_tcp.send(socket, nome <> "\n")

        IO.puts(IO.ANSI.yellow() <> "\nConectado! Comandos: /join #sala, /leave, /exit." <> IO.ANSI.reset())
        
        # Passamos o 'nome' para o receive_loop para ele saber quem é você
        spawn(fn -> receive_loop(socket, nome) end)
        input_loop(socket)
        
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "Falha ao conectar: #{inspect(reason)}" <> IO.ANSI.reset())
    end
  end

  defp prompt_ip() do
    input = IO.gets(IO.ANSI.yellow() <> "IP do servidor (vazio para 127.0.0.1): " <> IO.ANSI.reset()) 
            |> to_string() 
            |> String.trim()

    case input do
      "" -> {127, 0, 0, 1}
      _ ->
        case :inet.parse_address(String.to_charlist(input)) do
          {:ok, ip} -> ip
          {:error, _} ->
            IO.puts(IO.ANSI.red() <> "IP invalido, tente novamente." <> IO.ANSI.reset())
            prompt_ip()
        end
    end
  end

  defp prompt_port() do
    input = IO.gets(IO.ANSI.yellow() <> "Porta do servidor (vazio para 4040): " <> IO.ANSI.reset()) 
            |> to_string() 
            |> String.trim()

    case input do
      "" -> 4040
      _ ->
        case Integer.parse(input) do
          {port, ""} when port > 0 and port < 65536 -> port
          _ ->
            IO.puts(IO.ANSI.red() <> "Porta invalida, tente novamente." <> IO.ANSI.reset())
            prompt_port()
        end
    end
  end

  defp prompt_name() do
    input = IO.gets(IO.ANSI.green() <> "Escolha seu nome de usuário: " <> IO.ANSI.reset()) 
            |> to_string() 
            |> String.trim()

    if input == "" do
      IO.puts(IO.ANSI.red() <> "Nome nao pode ser vazio." <> IO.ANSI.reset())
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
      # Apaga a linha que você acabou de digitar (Mágica ANSI) para evitar duplicação visual
      IO.write("\e[1A\e[2K")

      trimmed = String.trim(text)

      cond do
        trimmed == "" ->
          # Corrigido: volta pro loop ao invés de matar o processo com :ok
          input_loop(socket)
          
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

  defp receive_loop(socket, meu_nome) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        texto = to_string(data)

        # Lógica de formatação e cores
        cond do
          String.contains?(texto, "] #{meu_nome}: ") ->
            # É a SUA mensagem. Substitui o nome por "Você" e pinta de verde.
            msg_formatada = String.replace(texto, "] #{meu_nome}: ", "] Você: ")
            IO.write(IO.ANSI.green() <> msg_formatada <> IO.ANSI.reset())

          String.match?(texto, ~r/\[.*\] .+: /) ->
            # É a mensagem de outra pessoa na sala. Pinta de ciano (azul claro).
            IO.write(IO.ANSI.cyan() <> texto <> IO.ANSI.reset())

          true ->
            # Mensagem do sistema (Servidor avisando quem entrou/saiu). Pinta de amarelo.
            IO.write(IO.ANSI.yellow() <> texto <> IO.ANSI.reset())
        end

        receive_loop(socket, meu_nome)

      {:error, :closed} ->
        IO.puts(IO.ANSI.red() <> "\nDesconectado do servidor." <> IO.ANSI.reset())

      {:error, _reason} ->
        IO.puts(IO.ANSI.red() <> "\nErro de conexão." <> IO.ANSI.reset())
    end
  end
end
