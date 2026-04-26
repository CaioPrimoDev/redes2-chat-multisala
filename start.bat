@echo off
echo Iniciando o EPMD (Guarda de Transito do Erlang)...
epmd -daemon

echo Limpando arquivos antigos...
del *.beam 2>nul

echo Compilando o codigo fonte...
call elixirc network.ex server.ex cli.ex

if %errorlevel% equ 0 (
    echo Compilacao concluida! Iniciando o sistema...
    iex -e "Chat.CLI.iniciar()"
) else (
    echo Erro na compilacao. Verifique o codigo.
    pause
)
