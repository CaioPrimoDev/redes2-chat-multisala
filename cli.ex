defmodule Chat.CLI do

  def iniciar() do
    IO.write("\e[H\e[2J")
    IO.puts("=============================================")
    IO.puts("        BEM-VINDO AO ELIXIR CHAT P2P         ")
    IO.puts("=============================================")

    # Iniciamos a rede ANTES para podermos validar o nome com os vizinhos
    IO.puts("Configurando rede...")
    Chat.Network.configurar_no()
    Chat.Server.iniciar()

    nome = escolher_nome()

    IO.puts("=============================================")
    IO.puts("Olá, #{nome}! Digite sua mensagem e aperte Enter.")
    IO.puts("Comandos: Para conectar manualmente, digite: /conectar IP")
    IO.puts("          Para buscar colegas na rede, digite: /procurar")
    IO.puts("=============================================\n")

    loop_chat(nome)
  end

  defp escolher_nome() do
    nome = IO.gets("Escolha seu nome de usuário: ") |> String.trim()
    
    # Validação: Se houver colegas, pergunta se o nome existe
    if Chat.Server.nome_disponivel?(nome) do
      nome
    else
      IO.puts(IO.ANSI.yellow() <> "⚠️ Nome '#{nome}' já está em uso! Tente outro." <> IO.ANSI.reset())
      escolher_nome()
    end
  end

  defp loop_chat(nome) do
    texto = IO.gets("") |> String.trim()

    cond do
      # Se o usuário apenas apertar Enter, não faz nada
      texto == "" ->
        :ok

      # Comando manual de conexão
      String.starts_with?(texto, "/conectar ") ->
        ip_destino = String.replace(texto, "/conectar ", "")
        
        if Chat.Network.conectar_com(ip_destino) do
          IO.puts("🤝 Conectado com sucesso a #{ip_destino}!")
        else
          IO.puts("⚠️ Não foi possível encontrar a máquina em #{ip_destino}.")
        end

      # Comando do radar universal
      texto == "/procurar" ->
        meu_ip = Chat.Network.buscar_ip_local()
        
        # Pega o IP (ex: 192.168.1.10) e divide nos pontos para pegar o prefixo
        [p1, p2, p3, _p4] = String.split(meu_ip, ".")
        prefixo_da_rede = "#{p1}.#{p2}.#{p3}"
        
        IO.puts("🔎 O seu IP é #{meu_ip}. Varrendo a rede #{prefixo_da_rede}.X...")
        
        # Varre TODOS os IPs possíveis de uma rede local (1 até 254)
        for final <- 1..254 do
          ip_alvo = "#{prefixo_da_rede}.#{final}"
          
          # Se o alvo for a nossa própria máquina, a gente pula
          if ip_alvo != meu_ip do
            Task.start(fn ->
              if Chat.Network.conectar_com(ip_alvo) == true do
                IO.puts("\n🛰️ Nova conexão automática com: #{ip_alvo}!")
              end
            end)
          end
        end

      # Se não for vazio nem comando, é uma mensagem normal de chat
      true ->
        Chat.Server.enviar(nome, texto)
    end

    # Chama a função de novo para continuar ouvindo o teclado (Loop infinito)
    loop_chat(nome)
  end

end
