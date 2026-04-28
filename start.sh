#!/bin/bash

# 1. Apaga os .beam antigos por segurança (para garantir uma compilação limpa)
rm -f *.beam

echo "Compilando o codigo fonte..."
elixirc server.ex cli.ex

# Verifica se a compilação deu certo antes de tentar abrir
if [ $? -eq 0 ]; then
  echo "Compilacao concluida."
  read -p "Iniciar servidor (s) ou cliente (c)? " ROLE
  if [ "$ROLE" = "s" ] || [ "$ROLE" = "S" ]; then
    iex -e "Chat.ServerCLI.iniciar()"
  else
    iex -e "Chat.CLI.iniciar()"
  fi
else
  echo "Erro na compilacao. Verifique seu codigo e tente novamente."
fi
