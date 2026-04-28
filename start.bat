@echo off
cd /d "%~dp0"
chcp 65001 >nul

del *.beam >nul 2>&1

echo Compilando o codigo fonte...
call elixirc server.ex cli.ex

if %errorlevel% equ 0 (
    echo Compilacao concluida!
    set /p ROLE="Iniciar servidor (S) ou cliente (C)? "
    if /I "%ROLE%"=="S" (
        iex -e "Chat.ServerCLI.iniciar()"
    ) else (
        iex -e "Chat.CLI.iniciar()"
    )
) else (
    echo Erro na compilacao. Verifique o codigo.
    pause
)