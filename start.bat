@echo off
REM Garante que o script trabalhe na pasta correta mesmo se for elevado a Administrador
cd /d "%~dp0"
chcp 65001 >nul

REM 1. Verifica se a regra de firewall ja existe (para nao pedir permissao toda vez)
netsh advfirewall firewall show rule name="Elixir_Chat_EPMD" >nul 2>&1
if %errorlevel% equ 0 goto IniciarChat

REM 2. Se a regra nao existe, verifica se tem privilegios de Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ================================================================
    echo [PRIMEIRA EXECUCAO] Configurando regras de rede...
    echo O Windows precisa de permissao para liberar o P2P.
    echo Na tela do escudo que vai aparecer, clique em "SIM"
    echo ================================================================
    REM Pede permissao e reinicia o proprio script como Administrador
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM 3. A magica acontece aqui: Libera o Firewall sem comprometer a seguranca da rede!
echo [Auto-Setup] Configurando Firewall automaticamente...

REM Libera a porta principal do Elixir (4369) de forma segura
netsh advfirewall firewall add rule name="Elixir_Chat_EPMD" dir=in action=allow protocol=TCP localport=4369 >nul 2>&1

REM Caca o Erlang no PC do usuario e libera o programa no Firewall dinamicamente
powershell -Command "$erl=(Get-Command erl.exe -ErrorAction SilentlyContinue).Source; if($erl){ netsh advfirewall firewall add rule name='Elixir_Erlang_In' dir=in action=allow program=\"$erl\" enable=yes }" >nul 2>&1
powershell -Command "$epmd=(Get-Command epmd.exe -ErrorAction SilentlyContinue).Source; if($epmd){ netsh advfirewall firewall add rule name='Elixir_EPMD_In' dir=in action=allow program=\"$epmd\" enable=yes }" >nul 2>&1

REM ==========================================
REM SESSAO NORMAL DE INICIALIZACAO DO CHAT
REM ==========================================
:IniciarChat
echo Limpando processos antigos do Elixir...
taskkill /f /im epmd.exe >nul 2>&1
del *.beam >nul 2>&1

echo Compilando o codigo fonte...
call elixirc network.ex server.ex cli.ex

if %errorlevel% equ 0 (
    echo Compilacao concluida! Iniciando o sistema...
    iex -e "Chat.CLI.iniciar()"
) else (
    echo Erro na compilacao. Verifique o codigo.
    pause
)