#!/bin/bash
# commit-watcher.sh — Processa fila de commits solicitados pelos agentes
# Executado no HOST via systemd timer ou cron

set -euo pipefail

REPO_DIR="/home/mestresdoseguro/mestresdoseguro-assistant"
QUEUE_DIR="$REPO_DIR/commit-queue"
LOG_FILE="$REPO_DIR/commit-queue/watcher.log"

# === CONFIGURACAO DE SEGURANCA ===

# Diretorios permitidos (regex para git diff --name-only)
ALLOWED_DIRS="^(agentes/|config/|scripts/|docs/)"

# Arquivos NUNCA commitaveis
BLOCKED_FILES=".env docker-compose.yml Dockerfile entrypoint.sh"

# Tamanho maximo do diff (linhas)
MAX_DIFF_LINES=2000

# ================================

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" >> "$LOG_FILE"
  echo "$1"
}

write_result() {
  local request_id="$1"
  local status="$2"
  local message="$3"
  local result_file="$QUEUE_DIR/$request_id.result"
  echo "{\"status\": \"$status\", \"message\": \"$message\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$result_file"
}

process_request() {
  local request_file="$1"
  local request_id
  request_id=$(basename "$request_file" .json)

  log "Processando request: $request_id"

  # Ler request
  if ! commit_msg=$(python3 -c "import json,sys; d=json.load(open('$request_file')); print(d['message'])" 2>/dev/null); then
    log "REJEITADO: JSON invalido em $request_file"
    write_result "$request_id" "error" "JSON invalido no request"
    rm -f "$request_file"
    return
  fi

  # Validar formato da mensagem
  if ! echo "$commit_msg" | grep -qE '^(feat|fix|refactor|docs|chore): .+'; then
    log "REJEITADO: Mensagem fora do padrao: $commit_msg"
    write_result "$request_id" "error" "Mensagem fora do padrao. Use: tipo: descricao"
    rm -f "$request_file"
    return
  fi

  cd "$REPO_DIR"

  # Verificar se ha mudancas
  if git diff --quiet HEAD 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    log "SKIP: Nenhuma mudanca detectada"
    write_result "$request_id" "skip" "Nenhuma mudanca detectada"
    rm -f "$request_file"
    return
  fi

  # Listar arquivos alterados
  changed_files=$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard)

  # Validar: arquivos bloqueados
  for blocked in $BLOCKED_FILES; do
    if echo "$changed_files" | grep -qx "$blocked"; then
      log "REJEITADO: Arquivo bloqueado detectado: $blocked"
      write_result "$request_id" "rejected" "Arquivo bloqueado: $blocked. Commit nao permitido."
      rm -f "$request_file"
      return
    fi
  done

  # Filtrar: apenas arquivos em diretorios permitidos
  allowed_files=$(echo "$changed_files" | grep -E "$ALLOWED_DIRS" || true)

  if [ -z "$allowed_files" ]; then
    log "REJEITADO: Nenhum arquivo em diretorios permitidos. Alterados: $(echo $changed_files | tr '\n' ', ')"
    write_result "$request_id" "rejected" "Nenhum arquivo em diretorios permitidos"
    rm -f "$request_file"
    return
  fi

  # Validar: tamanho do diff
  diff_lines=$(echo "$allowed_files" | xargs git diff --no-ext-diff -- 2>/dev/null | wc -l)
  new_files_lines=$(echo "$allowed_files" | while read f; do [ -f "$f" ] && wc -l < "$f" || echo 0; done | paste -sd+ | bc 2>/dev/null || echo 0)
  total_lines=$((diff_lines + new_files_lines))

  if [ "$total_lines" -gt "$MAX_DIFF_LINES" ]; then
    log "REJEITADO: Diff muito grande ($total_lines linhas, max $MAX_DIFF_LINES)"
    write_result "$request_id" "rejected" "Diff muito grande: $total_lines linhas (max: $MAX_DIFF_LINES)"
    rm -f "$request_file"
    return
  fi

  # Tudo OK — fazer o commit
  log "APROVADO: $commit_msg ($(echo "$allowed_files" | wc -l) arquivos, $total_lines linhas)"

  # Stage apenas arquivos permitidos
  echo "$allowed_files" | xargs git add --

  # Commit
  git commit -m "$commit_msg

Auto-committed by OpenClaw Agent
Request-ID: $request_id"

  log "Commit criado"

  # Sync com remote
  if git pull --rebase origin main 2>&1; then
    if git push origin main 2>&1; then
      log "Push realizado com sucesso"
      write_result "$request_id" "success" "Commit e push realizados com sucesso"
    else
      log "AVISO: Push falhou"
      write_result "$request_id" "partial" "Commit local criado, push falhou"
    fi
  else
    git rebase --abort 2>/dev/null || true
    log "AVISO: Conflito no rebase"
    write_result "$request_id" "partial" "Commit local criado, conflito no rebase"
  fi

  rm -f "$request_file"
}

# === RETRY PUSH PENDENTE ===

retry_pending_push() {
  cd "$REPO_DIR"
  local ahead
  ahead=$(git rev-list --count origin/main..main 2>/dev/null || echo 0)
  if [ "$ahead" -gt 0 ]; then
    log "Push pendente: $ahead commit(s) a frente do remote. Retentando..."
    if git push origin main 2>&1; then
      log "Push pendente realizado com sucesso ($ahead commits)"
    else
      log "AVISO: Retry de push falhou. Tentara novamente na proxima execucao."
    fi
  fi
}

# === MAIN ===

mkdir -p "$QUEUE_DIR"

retry_pending_push

requests=$(find "$QUEUE_DIR" -maxdepth 1 -name "*.json" -not -name "*.result" | sort)

if [ -z "$requests" ]; then
  exit 0
fi

# Limpar results antigos (> 5 min)
find "$QUEUE_DIR" -name "*.result" -mmin +5 -delete 2>/dev/null || true

for request_file in $requests; do
  process_request "$request_file"
done
