#!/bin/bash
# ============================================
# rollback.sh
# Restaura backup mais recente
# 5 passos: stop, restore config, restore workspace, restore .env, start
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKUP_DIR=""

# Determinar backup
if [ -n "$1" ]; then
  BACKUP_DIR="$1"
elif [ -f /root/.openclaw-last-backup ]; then
  BACKUP_DIR=$(cat /root/.openclaw-last-backup)
else
  # Pegar o mais recente automaticamente
  BACKUP_DIR=$(ls -td /root/openclaw-backup-* 2>/dev/null | head -1 || echo "")
fi

if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
  echo -e "${RED}[ERRO]${NC} Nenhum backup encontrado em /root/openclaw-backup-*" >&2
  echo -e "${RED}[ERRO]${NC} Uso: $0 [caminho-do-backup]" >&2
  exit 1
fi

echo -e "${GREEN}[INFO]${NC} Iniciando rollback usando $BACKUP_DIR"

# Detectar OPENCLAW_HOME do metadata
OPENCLAW_HOME=""
if [ -f "$BACKUP_DIR/metadata.json" ]; then
  OPENCLAW_HOME=$(jq -r '.openclaw_home' "$BACKUP_DIR/metadata.json" 2>/dev/null || echo "")
fi

if [ -z "$OPENCLAW_HOME" ] || [ "$OPENCLAW_HOME" = "null" ]; then
  if [ -d /root/.openclaw ]; then
    OPENCLAW_HOME="/root/.openclaw"
  elif [ -d /opt/openclaw ]; then
    OPENCLAW_HOME="/opt/openclaw"
  else
    echo -e "${RED}[ERRO]${NC} Nao consegui determinar OPENCLAW_HOME" >&2
    exit 1
  fi
fi

echo -e "${GREEN}[INFO]${NC} Restaurando pra $OPENCLAW_HOME"

# PASSO 1: Parar servico
echo -e "${YELLOW}[1/5]${NC} Parando openclaw-gateway..."
if systemctl is-active --quiet openclaw-gateway 2>/dev/null; then
  systemctl stop openclaw-gateway
  sleep 2
fi

# PASSO 2: Restaurar openclaw.json
echo -e "${YELLOW}[2/5]${NC} Restaurando openclaw.json..."
if [ -f "$BACKUP_DIR/openclaw.json" ]; then
  cp -p "$BACKUP_DIR/openclaw.json" "$OPENCLAW_HOME/openclaw.json"
  echo -e "${GREEN}  [OK]${NC} openclaw.json restaurado"
fi

# PASSO 3: Restaurar workspace
echo -e "${YELLOW}[3/5]${NC} Restaurando workspace..."
if [ -d "$BACKUP_DIR/workspace" ]; then
  rm -rf "$OPENCLAW_HOME/workspace"
  cp -rp "$BACKUP_DIR/workspace" "$OPENCLAW_HOME/workspace"
  echo -e "${GREEN}  [OK]${NC} workspace restaurado"
fi

if [ -d "$BACKUP_DIR/skills" ]; then
  rm -rf "$OPENCLAW_HOME/skills"
  cp -rp "$BACKUP_DIR/skills" "$OPENCLAW_HOME/skills"
  echo -e "${GREEN}  [OK]${NC} skills restauradas (estado pre-upgrade)"
fi

if [ -d "$BACKUP_DIR/subagents" ]; then
  rm -rf "$OPENCLAW_HOME/subagents"
  cp -rp "$BACKUP_DIR/subagents" "$OPENCLAW_HOME/subagents"
  echo -e "${GREEN}  [OK]${NC} subagents restaurados"
fi

if [ -d "$BACKUP_DIR/memory" ]; then
  rm -rf "$OPENCLAW_HOME/memory"
  cp -rp "$BACKUP_DIR/memory" "$OPENCLAW_HOME/memory"
  echo -e "${GREEN}  [OK]${NC} memory restaurada"
fi

# PASSO 4: Restaurar .env
echo -e "${YELLOW}[4/5]${NC} Restaurando .env..."
if [ -f "$BACKUP_DIR/.env" ]; then
  cp -p "$BACKUP_DIR/.env" "$OPENCLAW_HOME/.env"
  echo -e "${GREEN}  [OK]${NC} .env restaurado"
fi

# PASSO 5: Subir servico
echo -e "${YELLOW}[5/5]${NC} Subindo openclaw-gateway..."
systemctl start openclaw-gateway
sleep 3

if systemctl is-active --quiet openclaw-gateway; then
  echo -e "${GREEN}[OK]${NC} Gateway rodando."
else
  echo -e "${RED}[ERRO]${NC} Gateway nao subiu apos rollback." >&2
  echo -e "${RED}[ERRO]${NC} Veja: journalctl -u openclaw-gateway -n 50" >&2
  exit 1
fi

echo -e "${GREEN}[OK]${NC} Rollback concluido. Estado restaurado de $BACKUP_DIR"
