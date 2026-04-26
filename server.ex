defmodule Chat.Server do
  use GenServer

  # ==========================================
  # 1. API DO CLIENTE (O que nós chamamos)
  # ==========================================

  @doc "Contrata o funcionário e dá um nome fixo para ele"
  def iniciar() do
    GenServer.start_link(__MODULE__, [], name: :chat_servidor)
  end

  @doc "Pega a nossa mensagem e entrega para o servidor espalhar"
  def enviar(nome, texto) do
    GenServer.cast(:chat_servidor, {:espalhar_mensagem, nome, texto})
  end

  # Função para o CLI perguntar se o nome já existe na rede
  def nome_disponivel?(nome_pretendido) do
    # Pergunta a todos os nós ligados. Se algum retornar 'false', o nome está ocupado.
    respostas = GenServer.multi_call(Node.list(), :chat_servidor, {:verificar_nome, nome_pretendido})
    
    # Verifica se houve alguma resposta negativa (nome ocupado)
    case respostas do
      {replies, _bad_nodes} -> 
        not Enum.any?(replies, fn {_no, resp} -> resp == :ocupado end)
    end
  end

  # ==========================================
  # 2. CALLBACKS (O que roda na salinha fechada)
  # ==========================================

  @impl true
  def init(estado_inicial) do
    # ATENÇÃO: Esta linha ativa o radar de monitorização de quedas!
    :net_kernel.monitor_nodes(true)
    {:ok, estado_inicial}
  end

  # Responder se o nome está ocupado
  @impl true
  def handle_call({:verificar_nome, nome_pretendido}, _from, estado) do
    # Verifica se o meu próprio nome (no CLI) ou de alguém que conheço é igual
    nomes_conhecidos = Map.values(estado)
    if nome_pretendido in nomes_conhecidos do
      {:reply, :ocupado, estado}
    else
      {:reply, :livre, estado}
    end
  end

  @impl true
  def handle_cast({:espalhar_mensagem, nome, texto}, estado) do
    IO.puts(IO.ANSI.green() <> "[Você]: " <> IO.ANSI.reset() <> texto)
    
    # Ao enviar, aproveitamos para atualizar o nosso mapa local de nomes
    novo_estado = Map.put(estado, Node.self(), nome)

    for maquina <- Node.list() do
      GenServer.cast({:chat_servidor, maquina}, {:receber_de_fora, nome, texto})
    end

    {:noreply, novo_estado}
  end

  @impl true
  def handle_cast({:receber_de_fora, nome, texto}, estado) do
    IO.puts("\n" <> IO.ANSI.cyan() <> "[#{nome}]: " <> IO.ANSI.reset() <> texto)
    
    # Guarda o nome deste colega no nosso estado para sabermos quem ele é se ele cair
    {:noreply, Map.put(estado, node(), nome)}
  end

  # --- O TRATAMENTO DE SAÍDA ---
  @impl true
  def handle_info({:nodedown, no}, estado) do
    nome_que_saiu = Map.get(estado, no, "Alguém (IP: #{no})")
    
    IO.puts("\n" <> IO.ANSI.red() <> "❌ #{nome_que_saiu} saiu do chat." <> IO.ANSI.reset())
    
    # Remove a pessoa do nosso registo
    {:noreply, Map.delete(estado, no)}
  end

  # Ignora outras mensagens de sistema
  @impl true
  def handle_info(_, estado), do: {:noreply, estado}

end
