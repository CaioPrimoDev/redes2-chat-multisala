#!/bin/bash

# 1. Apaga os .beam antigos por segurança (para garantir uma compilação limpa)
rm -f *.beam

echo "🚀 Compilando o código fonte..."
elixirc network.ex server.ex cli.ex

# Verifica se a compilação deu certo antes de tentar abrir
if [ $? -eq 0 ]; then
  echo "✅ Compilação concluída! Iniciando o sistema..."
  # Abre o iex e já executa a função de iniciar automaticamente
  iex -e "Chat.CLI.iniciar()"
else
  echo "❌ Erro na compilação. Verifique seu código e tente novamente."
fi
