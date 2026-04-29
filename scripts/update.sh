#!/bin/bash
# ============================================
# OpenClaw Upgrade — alunos.denderson
# Atualiza OpenClaw existente pra versao Naia/Avalanche
# Idempotente: pode rodar varias vezes sem quebrar
# ============================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a /var/log/openclaw-upgrade.log
}

warn() {
  echo -e "${YELLOW}[AVISO]${NC} $1" | tee -a /var/log/openclaw-upgrade.log
}

err() {
  echo -e "${RED}[ERRO]${NC} $1" | tee -a /var/log/openclaw-upgrade.log
  exit 1
}

# Configuracao
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS=("gerar-proposta-comercial" "gerar-landing-page" "analisar-instagram-bmad" "criar-subagente")

mkdir -p /var/log
touch /var/log/openclaw-upgrade.log

log "=========================================="
log "OpenClaw Upgrade pra Naia/Avalanche"
log "=========================================="

# Pre-checks
if [ "$(id -u)" -ne 0 ]; then
  err "Esse script precisa rodar como root."
fi

if ! command -v jq &> /dev/null; then
  log "Instalando jq..."
  apt-get update -qq && apt-get install -y jq
fi

if ! command -v systemctl &> /dev/null; then
  err "systemctl nao encontrado. Esse upgrade requer systemd."
fi

# Passo 1: Detectar versao
log "Passo 1/5: Detectando versao atual do OpenClaw..."
bash "$SCRIPT_DIR/detect-version.sh" || err "Falha ao detectar versao"

# Passo 2: Backup
log "Passo 2/5: Fazendo backup completo..."
BACKUP_PATH=$(bash "$SCRIPT_DIR/backup-config.sh" | tail -1)
log "Backup salvo em: $BACKUP_PATH"

# Passo 3: Aplicar skills (idempotente)
log "Passo 3/5: Aplicando ${#SKILLS[@]} skills novas..."
for skill in "${SKILLS[@]}"; do
  log "  Instalando skill: $skill"
  bash "$SCRIPT_DIR/install-skill.sh" "$skill" || warn "Skill $skill ja existia ou falhou. Continuando..."
done

# Passo 4: Restart gateway
log "Passo 4/5: Reiniciando openclaw-gateway..."
if systemctl is-active --quiet openclaw-gateway; then
  systemctl restart openclaw-gateway
else
  systemctl start openclaw-gateway
fi
sleep 3

if ! systemctl is-active --quiet openclaw-gateway; then
  err "Gateway nao subiu apos o restart. Veja: journalctl -u openclaw-gateway -n 50"
fi
log "Gateway rodando."

# Passo 5: Validar
log "Passo 5/5: Validando upgrade..."
bash "$SCRIPT_DIR/validate.sh" || warn "Validacao retornou avisos. Verificar manualmente."

log "=========================================="
log "Upgrade concluido com sucesso."
log "Backup em: $BACKUP_PATH"
log "Skills ativas: ${SKILLS[*]}"
log "Pra rollback: bash $SCRIPT_DIR/rollback.sh"
log "=========================================="
