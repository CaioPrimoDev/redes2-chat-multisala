@echo off
echo Limpando arquivos antigos...
del *.beam 2>nul

echo Compilando o codigo fonte...
call elixirc network.ex server.ex cli.ex

if %errorlevel% equ 0 (
    echo Compilacao concluida! Acordando a rede...
    iex --name temporario@127.0.0.1 -e "Node.stop(); Chat.CLI.iniciar()"
) else (
    echo Erro na compilacao. Verifique o codigo.
    pause
)
