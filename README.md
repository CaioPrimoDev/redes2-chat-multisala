# Chat TCP Multi-Sala

Sistema de chat em tempo real com arquitetura cliente-servidor desenvolvido em Elixir, permitindo comunicação entre múltiplos usuários através de salas temáticas gerenciadas por um servidor central.

## Visão Geral

- Servidor central que gerencia clientes e salas de chat
- Cliente interativo com interface em terminal (CLI)
- Comunicação via TCP com suporte a múltiplas conexões simultâneas
- Validação de entrada e tratamento de erros
- Suporte multiplataforma (Windows, Linux, macOS)

## Requisitos

- **Elixir** 1.14+ (com Erlang/OTP 25+)

Verifique a instalação:
```bash
elixir --version
```

## Como Executar

### Windows
```bash
start.bat
```

### Linux / macOS
```bash
chmod +x start.sh
./start.sh
```

Escolha na sequência:
- `[1]` para iniciar o **Servidor**
- `[2]` para iniciar um **Cliente**

## Configuração do Servidor

Ao iniciar em modo servidor:
- **IP**: Digite um IP específico ou deixe em branco para `0.0.0.0`
- **Porta**: Digite a porta ou deixe em branco para `4040`

O servidor aguardará conexões de clientes de forma concorrente.

## Configuração do Cliente

Ao iniciar em modo cliente:
- **IP do Servidor**: Digite o IP ou deixe em branco para `127.0.0.1`
- **Porta**: Digite a porta ou deixe em branco para `4040`
- **Nome de Usuário**: Escolha um nome (obrigatório)

## Comandos do Cliente

| Comando | Função |
|---------|--------|
| `/join #sala` | Entrar em uma sala |
| `/leave` | Sair da sala atual |
| `/exit` ou `/quit` | Desconectar do servidor |

Mensagens digitadas normalmente são enviadas à sala ativa.

## Estrutura do Projeto

```
.
├── server.ex       # Servidor TCP (gerenciamento de clientes e salas)
├── cli.ex          # Cliente interativo (interface em terminal)
├── start.sh        # Script de inicialização (Linux/macOS)
├── start.bat       # Script de inicialização (Windows)
└── README.md       # Esta documentação
```

## Componentes

### `server.ex` - Servidor
- Inicializa socket TCP e aguarda conexões
- Gerencia estado de clientes e salas
- Roteia mensagens entre usuários da mesma sala
- Usa GenServer para gerenciamento de estado concorrente

### `cli.ex` - Cliente
- Conecta ao servidor e autentica com nome de usuário
- Loop de entrada/saída com validação de IP e porta
- Recepção de mensagens em thread concorrente
- Formatação com cores ANSI para melhor legibilidade

## Funcionamento Técnico

1. Scripts compilam todos os arquivos `.ex` para bytecode Erlang (`.beam`)
2. Servidor inicia GenServer e abre socket TCP na porta especificada
3. Clientes conectam, enviam nome e participam de salas
4. Mensagens são encaminhadas apenas para usuários da mesma sala
5. Desconexão limpa o estado do cliente no servidor

**Protocolo**: TCP com delimitador de linha (`\n`)  
**Concorrência**: GenServer + processos Erlang  
**Encoding**: Binário com suporte a UTF-8

---
**Disciplina**: Redes de Computadores 2  
**Linguagem**: Elixir