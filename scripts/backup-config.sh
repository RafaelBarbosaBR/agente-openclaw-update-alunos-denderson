#!/bin/bash
# ============================================
# backup-config.sh
# Backup completo da configuracao OpenClaw
# Antes de qualquer alteracao
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
BACKUP_DIR="/root/openclaw-backup-$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

# Detectar caminhos
OPENCLAW_HOME=""
if [ -d /root/.openclaw ]; then
  OPENCLAW_HOME="/root/.openclaw"
elif [ -d /opt/openclaw ]; then
  OPENCLAW_HOME="/opt/openclaw"
else
  echo -e "${RED}[ERRO]${NC} OpenClaw nao encontrado em /root/.openclaw nem em /opt/openclaw" >&2
  exit 1
fi

echo -e "${GREEN}[INFO]${NC} Fazendo backup de $OPENCLAW_HOME pra $BACKUP_DIR..."

# 1. Config principal
if [ -f "$OPENCLAW_HOME/openclaw.json" ]; then
  cp -p "$OPENCLAW_HOME/openclaw.json" "$BACKUP_DIR/openclaw.json"
  echo "  openclaw.json salvo"
else
  echo -e "${YELLOW}[AVISO]${NC} openclaw.json nao encontrado em $OPENCLAW_HOME"
fi

# 2. .env
if [ -f "$OPENCLAW_HOME/.env" ]; then
  cp -p "$OPENCLAW_HOME/.env" "$BACKUP_DIR/.env"
  echo "  .env salvo"
fi

# 3. Workspace (memorias, knowledge)
if [ -d "$OPENCLAW_HOME/workspace" ]; then
  cp -rp "$OPENCLAW_HOME/workspace" "$BACKUP_DIR/workspace"
  echo "  workspace/ salvo"
fi

# 4. Memory (se existir)
if [ -d "$OPENCLAW_HOME/memory" ]; then
  cp -rp "$OPENCLAW_HOME/memory" "$BACKUP_DIR/memory"
  echo "  memory/ salvo"
fi

# 5. Skills existentes (pra restaurar se conflitar)
if [ -d "$OPENCLAW_HOME/skills" ]; then
  cp -rp "$OPENCLAW_HOME/skills" "$BACKUP_DIR/skills"
  echo "  skills/ existentes salvas"
fi

# 6. Subagents (se existir)
if [ -d "$OPENCLAW_HOME/subagents" ]; then
  cp -rp "$OPENCLAW_HOME/subagents" "$BACKUP_DIR/subagents"
  echo "  subagents/ salvos"
fi

# 7. Versao
if [ -f "$OPENCLAW_HOME/.version" ]; then
  cp -p "$OPENCLAW_HOME/.version" "$BACKUP_DIR/version.txt"
elif [ -f "$OPENCLAW_HOME/package.json" ]; then
  jq -r '.version' "$OPENCLAW_HOME/package.json" > "$BACKUP_DIR/version.txt" 2>/dev/null || echo "unknown" > "$BACKUP_DIR/version.txt"
else
  echo "unknown" > "$BACKUP_DIR/version.txt"
fi

# 8. Metadata
cat > "$BACKUP_DIR/metadata.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "openclaw_home": "$OPENCLAW_HOME",
  "version": "$(cat "$BACKUP_DIR/version.txt")",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "backup_size_mb": $(du -sm "$BACKUP_DIR" | cut -f1)
}
EOF

# 9. Salvar caminho do backup mais recente (pra rollback usar)
echo "$BACKUP_DIR" > /root/.openclaw-last-backup

echo -e "${GREEN}[OK]${NC} Backup completo em $BACKUP_DIR"
echo -e "${GREEN}[OK]${NC} Tamanho: $(du -sh "$BACKUP_DIR" | cut -f1)"

# Output final pra script chamador capturar
echo "$BACKUP_DIR"
