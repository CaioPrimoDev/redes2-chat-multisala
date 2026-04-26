defmodule Chat.Network do
  @cookie :chat_secreto_das_redes # A senha do cluster

  def configurar_no() do
    # 1. Pega o IP usando a sua função nativa brilhante
    ip_string = buscar_ip_local()
    
    # 2. O prefixo DEVE ser "chat" em vez de "usuario" para o radar adivinhar
    nome_no = String.to_atom("chat@#{ip_string}")

    # 3. Inicia a rede com tratamento de erros (muito mais seguro)
    case Node.start(nome_no) do
      {:ok, _pid} ->
        Node.set_cookie(@cookie)
        IO.puts("✅ Rede iniciada! Seu endereço é: #{nome_no}")
      {:error, razao} ->
        IO.puts("❌ Erro ao iniciar rede: #{inspect(razao)}")
    end
  end

  def conectar_com(ip_destino) do
    alvo = String.to_atom("chat@#{ip_destino}")
    
    # Apenas tenta conectar e retorna true ou false.
    # Tiramos o IO.puts daqui para o radar não "gritar" na tela quando errar!
    Node.connect(alvo)
  end

  # Mudamos de defp (privada) para def (pública) para o cli.ex conseguir usar no radar
  def buscar_ip_local() do
    {:ok, interfaces} = :inet.getifaddrs()
    
    ips = for {iface, opts} <- interfaces, 
              iface == ~c"eth0" or iface == ~c"enp0s3",
              addr = List.keyfind(opts, :addr, 0),
              {_, {a, b, c, d}} = addr,
              a != 127, do: "#{a}.#{b}.#{c}.#{d}"

    List.first(ips) || "127.0.0.1"
  end
end
