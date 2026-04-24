
IO.puts("\n\nIniciando chat...\n")

defmodule Chat do
	
	def iniciar() do
		mensagem_boas_vindas = "Sistema de Chat Iniciado"

		formatar = fn texto -> "AVISO: " <> texto end

		mensagem = formatar.(mensagem_boas_vindas)

		IO.puts(mensagem)				
	end
end

defmodule ServidorChat do
	
	# Será executada pelo Spawn
	def escutar() do
	  receive do
	    
	    {:login, nome} ->
	      IO.puts("<<< #{nome} entrou na sala! >>>")
	      escutar()

	    {:mensagem, nome, texto} ->
	      IO.puts("[#{nome}]: #{texto}")
	      escutar()

	    {:sair, nome} ->
	      IO.puts("<<< #{nome} saiu do chat >>>")
	      # Não usará recursão aqui, pois o Spawn será encerrado
	    
	  end
	end
end

Chat.iniciar()

# Contratamos o 'funcionario' através do Spawn
pid_1 = spawn(fn -> ServidorChat.escutar() end)

send(pid_1, {:login, "Caio P."})
send(pid_1, {:mensagem, "Caio P.", "O Servidor está online?"})
send(pid_1, {:mensagem, "Caio P.", "Alguém está ouvindo?"})
send(pid_1, {:sair, "Caio P."})
# Devido as codições de corrida, o sistema finaliza antes de todas as mensagens carregarem, já que SEND é assincrono

# 500 milissegundos
Process.sleep(500) 
# Isso só está aqui por que esté é um ambiente de testes, na realidade o chat ficará ativo de forma interminável
