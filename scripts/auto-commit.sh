#!/bin/bash
# auto-commit.sh — Versionamento automatico do workspace OpenClaw
# Chamado no HOST para commits diretos (sem fila)
#
# Uso: ./scripts/auto-commit.sh "mensagem descritiva"

set -euo pipefail

REPO_DIR="/home/assistentemestre/mestresdoseguro-assistant"
cd "$REPO_DIR"

COMMIT_MSG="${1:-}"
if [ -z "$COMMIT_MSG" ]; then
  echo "ERRO: Informe a mensagem de commit como argumento."
  echo "Uso: $0 \"mensagem descritiva\""
  exit 1
fi

if git diff --quiet HEAD 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "OK: Nenhuma mudanca detectada. Nada para commitar."
  exit 0
fi

git add -A

if git diff --cached --quiet; then
  echo "OK: Nenhuma mudanca no staging. Nada para commitar."
  exit 0
fi

echo "=== Arquivos a commitar ==="
git diff --cached --name-status
echo "=========================="

git commit -m "$COMMIT_MSG

Auto-committed by OpenClaw Agent"

echo "Commit criado com sucesso."

echo "Sincronizando com remote..."

if ! git pull --rebase origin main 2>&1; then
  echo "AVISO: Conflito no rebase. Abortando rebase e mantendo commit local."
  git rebase --abort 2>/dev/null || true
  echo "Intervencao manual necessaria para resolver o conflito."
  exit 2
fi

if git push origin main 2>&1; then
  echo "Push realizado com sucesso."
else
  echo "AVISO: Push falhou. O commit local existe mas nao foi enviado."
  exit 3
fi

echo "OK: Versionamento completo."
