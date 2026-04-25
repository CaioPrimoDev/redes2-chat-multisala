defmodule Chat.CLI do

  # MODULO DA INTERFACE
  
  @doc "O ponto de partida do nosso aplicativo"
  def iniciar() do
    # Limpa a tela do terminal para ficar bonito (funciona no Linux/Mac)
    IO.write("\e[H\e[2J")
    
    IO.puts("=============================================")
    IO.puts("        BEM-VINDO AO ELIXIR CHAT P2P         ")
    IO.puts("=============================================")

    # 1. Pede o nome do usuário e remove os espaços extras/quebra de linha com String.trim()
    nome = IO.gets("Digite seu nome de usuário: ") |> String.trim()

    IO.puts("\nConfigurando rede, aguarde...")

    # 2. O CLI liga os motores por nós!
    Chat.Network.configurar_no()
    Chat.Server.iniciar()

    IO.puts("=============================================")
    IO.puts("Olá, #{nome}! Digite sua mensagem e aperte Enter.")
    IO.puts("=============================================\n")

    # 3. Manda o usuário para a sala de bate-papo (Loop infinito)
    loop_chat(nome)
  end

  # Função privada (só o CLI usa) que mantém o prompt aberto
  defp loop_chat(nome) do
    # Fica com o cursor piscando, esperando o usuário digitar algo
    texto = IO.gets("") |> String.trim()

    # Se o texto não for vazio, envia para o servidor espalhar
    if texto != "" do
      # Aqui está a mágica! O usuário digita texto, o código manda pro GenServer.
      Chat.Server.enviar(nome, texto)
    end

    # A recursão infinita: chama a si mesma para continuar escutando o teclado
    loop_chat(nome)
  end

end
