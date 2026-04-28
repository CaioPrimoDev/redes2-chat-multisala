#!/bin/bash

# Limpa a tela
clear

echo "============================================="
echo "      INICIALIZADOR CHAT TCP - REDES 2       "
echo "============================================="
echo "Escolha o papel desta maquina virtual:"
echo ""
echo "[1] Iniciar como SERVIDOR (Central)"
echo "[2] Iniciar como CLIENTE (Usuario)"
echo "============================================="
read -p "Digite 1 ou 2: " OPCAO

# Compila todos os arquivos .ex da pasta em arquivos executaveis (.beam)
elixirc *.ex

if [ "$OPCAO" = "1" ]; then
    echo "Iniciando o Servidor..."
    elixir -e "Chat.ServerCLI.iniciar()"
elif [ "$OPCAO" = "2" ]; then
    echo "Iniciando o Cliente..."
    elixir -e "Chat.CLI.iniciar()"
else
    echo "Opcao invalida. Execute o script novamente."
fi
