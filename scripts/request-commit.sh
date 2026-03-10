#!/bin/bash
# request-commit.sh — Solicita versionamento ao watcher do host
# Executado DENTRO do container pelos agentes
#
# Uso: /app/scripts/request-commit.sh "tipo: descricao"
# Exemplo: /app/scripts/request-commit.sh "fix: corrigir prompt do agente"

set -euo pipefail

QUEUE_DIR="/app/commit-queue"
COMMIT_MSG="${1:-}"

if [ -z "$COMMIT_MSG" ]; then
  echo "ERRO: Informe a mensagem de commit."
  echo "Uso: $0 \"tipo: descricao\""
  echo "Tipos: feat, fix, refactor, docs, chore"
  exit 1
fi

# Validar formato da mensagem
if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|refactor|docs|chore): .+'; then
  echo "ERRO: Mensagem deve seguir o padrao: tipo: descricao"
  echo "Tipos validos: feat, fix, refactor, docs, chore"
  exit 1
fi

# Gerar ID unico
REQUEST_ID="$(date +%Y%m%d-%H%M%S)-$$"
REQUEST_FILE="$QUEUE_DIR/$REQUEST_ID.json"

# Escrever request
cat > "$REQUEST_FILE" << JSONEOF
{
  "id": "$REQUEST_ID",
  "message": "$COMMIT_MSG",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "agent": "${OPENCLAW_AGENT_ID:-unknown}"
}
JSONEOF

echo "OK: Commit solicitado (id: $REQUEST_ID)"
echo "O watcher do host processara em breve."

# Aguardar resultado (max 60s)
RESULT_FILE="$QUEUE_DIR/$REQUEST_ID.result"
for i in $(seq 1 60); do
  if [ -f "$RESULT_FILE" ]; then
    cat "$RESULT_FILE"
    exit 0
  fi
  sleep 1
done

echo "AVISO: Timeout aguardando resultado. O commit pode ainda estar sendo processado."
exit 0
