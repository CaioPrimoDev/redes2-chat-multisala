defmodule Chat.Network do
  @cookie :chat_secreto_das_redes # A "senha" do cluster

  @doc "Inicia o nó do Elixir dinamicamente usando o IP da máquina"
  def configurar_no() do
    # 1. Descobrimos o IP da placa de rede (eth0 no Debian)
    ip_string = buscar_ip_local()
    
    # 2. Criamos o nome do nó, ex: "caio@10.0.2.15"
    nome_no = String.to_atom("usuario@#{ip_string}")

    # 3. Ligamos a rede do Elixir
    case Node.start(nome_no) do
      {:ok, _pid} ->
        Node.set_cookie(@cookie)
        IO.puts("✅ Rede iniciada! Seu endereço é: #{nome_no}")
      {:error, razao} ->
        IO.puts("❌ Erro ao iniciar rede: #{inspect(razao)}")
    end
  end

  @doc "Tenta conectar com outra máquina pelo IP"
  def conectar_com(ip_destino) do
    alvo = String.to_atom("usuario@#{ip_destino}")
    
    if Node.connect(alvo) do
      IO.puts("🤝 Conectado com sucesso ao nó: #{alvo}")
    else
      IO.puts("⚠️ Não foi possível encontrar o nó: #{alvo}")
    end
  end

  # Função auxiliar "mágica" para pegar o IP do Debian
  defp buscar_ip_local() do
    {:ok, interfaces} = :inet.getifaddrs()
    
    # Procuramos na lista de placas de rede (eth0) o endereço IPv4
    # No VirtualBox, a placa principal costuma ser 'eth0' ou 'enp0s3'
    # Esse trecho filtra a lista e pega o IP que não seja o local (127.0.0.1)
    ips = for {iface, opts} <- interfaces, 
              iface == ~c"eth0" or iface == ~c"enp0s3", # Nomes comuns no Debian
              addr = List.keyfind(opts, :addr, 0),
              {_, {a, b, c, d}} = addr,
              a != 127, do: "#{a}.#{b}.#{c}.#{d}"

    List.first(ips) || "127.0.0.1"
  end
end
