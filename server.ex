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


  # ==========================================
  # 2. CALLBACKS (O que roda na salinha fechada)
  # ==========================================

  @impl true
  def init(estado_inicial) do
    # O servidor liga e guarda um caderno em branco (estado)
    {:ok, estado_inicial}
  end

  @impl true
  def handle_cast({:espalhar_mensagem, nome, texto}, estado) do
    # Passo 1: Imprime a mensagem na NOSSA tela
    IO.puts("\n[#{nome}]: #{texto}")

    # Passo 2: Pega a lista de IPs das outras máquinas conectadas
    outras_maquinas = Node.list()

    # Passo 3: Envia a mensagem pela rede para os servidores das outras VMs
    for maquina <- outras_maquinas do
      GenServer.cast({:chat_servidor, maquina}, {:receber_de_fora, nome, texto})
    end

    # Volta a dormir esperando a próxima mensagem
    {:noreply, estado}
  end

  @impl true
  def handle_cast({:receber_de_fora, nome, texto}, estado) do
    # Quando uma mensagem chega pela rede, a gente apenas imprime
    IO.puts("\n[#{nome}] (de fora): #{texto}")
    {:noreply, estado}
  end

end
