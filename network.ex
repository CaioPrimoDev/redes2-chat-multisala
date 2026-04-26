defmodule Chat.Network do
  @cookie :chat_secreto_das_redes # A senha do cluster

  def configurar_no() do
    # 1. Pega o IP usando a sua função nativa brilhante
    ip_string = buscar_ip_local()
    
    # 2. O prefixo DEVE ser "chat" em vez de "usuario" para o radar adivinhar
    nome_no = String.to_atom("chat@#{ip_string}")

    # Força o EPMD a ligar de forma nativa e aguarda meio segundo
    System.cmd("epmd", ["-daemon"])
    :timer.sleep(500)

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

  def buscar_ip_local() do
    {:ok, interfaces} = :inet.getifaddrs()
    
    # Procura em todas as placas de rede
    ip_tupla = Enum.find_value(interfaces, fn {_nome_da_placa, dados} ->
      Enum.find_value(dados, fn
        # Ignora localhost (127.0.0.1)
        {:addr, {127, _, _, _}} -> false
        
        # MUDANÇA: Ignora o IP Fantasma do Windows (APIPA 169.254.x.x)
        {:addr, {169, 254, _, _}} -> false
        
        # Opcional (se tiver VirtualBox instalado, ele ignora a placa virtual)
        {:addr, {192, 168, 56, _}} -> false
        
        # Se for um IPv4 válido de rede local, nós GUARDAMOS
        {:addr, {a, b, c, d} = ip} -> ip
        
        # Ignora IPv6 e outras configurações irrelevantes
        _ -> false
      end)
    end)

    # Converte a tupla {192, 168, 1, X} em texto "192.168.1.X"
    {a, b, c, d} = ip_tupla
    "#{a}.#{b}.#{c}.#{d}"
  end
end