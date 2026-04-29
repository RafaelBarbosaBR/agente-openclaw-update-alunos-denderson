#!/bin/bash
# ============================================
# install-skill.sh
# Instala uma skill nova no OpenClaw
# Idempotente: pula se ja existir
# Uso: bash install-skill.sh <nome-da-skill>
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SKILL_NAME="$1"

if [ -z "$SKILL_NAME" ]; then
  echo -e "${RED}[ERRO]${NC} Uso: $0 <nome-da-skill>" >&2
  exit 1
fi

# Detectar OPENCLAW_HOME
OPENCLAW_HOME=""
if [ -d /root/.openclaw ]; then
  OPENCLAW_HOME="/root/.openclaw"
elif [ -d /opt/openclaw ]; then
  OPENCLAW_HOME="/opt/openclaw"
else
  echo -e "${RED}[ERRO]${NC} OpenClaw nao encontrado" >&2
  exit 1
fi

# Detectar repo root (onde estao as skills fontes)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILL_SOURCE="$REPO_ROOT/skills/$SKILL_NAME"
SKILL_DEST="$OPENCLAW_HOME/skills/$SKILL_NAME"

# Verificar se a skill fonte existe
if [ ! -d "$SKILL_SOURCE" ]; then
  echo -e "${YELLOW}[AVISO]${NC} Skill fonte nao encontrada em $SKILL_SOURCE."
  echo -e "${YELLOW}[AVISO]${NC} As skills sao populadas pela Naia na consolidacao final."
  echo -e "${YELLOW}[AVISO]${NC} Pulando instalacao de $SKILL_NAME."
  exit 0
fi

# Garantir que diretorio skills/ existe
mkdir -p "$OPENCLAW_HOME/skills"

# Idempotencia: se ja existe, validar mas nao reinstalar
if [ -d "$SKILL_DEST" ]; then
  echo -e "${YELLOW}[INFO]${NC} Skill $SKILL_NAME ja instalada em $SKILL_DEST. Validando..."
  # Comparar checksums pra ver se precisa atualizar
  if diff -rq "$SKILL_SOURCE" "$SKILL_DEST" > /dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} Skill $SKILL_NAME ja esta na versao mais recente."
    exit 0
  else
    echo -e "${YELLOW}[INFO]${NC} Skill $SKILL_NAME tem diferencas. Atualizando..."
    rm -rf "$SKILL_DEST"
  fi
fi

# Copiar skill
cp -rp "$SKILL_SOURCE" "$SKILL_DEST"
echo -e "${GREEN}[OK]${NC} Skill $SKILL_NAME copiada pra $SKILL_DEST"

# Atualizar openclaw.json
CONFIG_FILE="$OPENCLAW_HOME/openclaw.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${YELLOW}[AVISO]${NC} $CONFIG_FILE nao existe. Criando estrutura minima..."
  echo '{"skills": {"entries": []}}' > "$CONFIG_FILE"
fi

# Validar JSON antes de editar
if ! jq -e . "$CONFIG_FILE" > /dev/null 2>&1; then
  echo -e "${RED}[ERRO]${NC} $CONFIG_FILE tem JSON invalido. Abortar pra nao corromper." >&2
  exit 1
fi

# Garantir estrutura skills.entries
if ! jq -e '.skills' "$CONFIG_FILE" > /dev/null 2>&1; then
  TMP=$(mktemp)
  jq '. + {skills: {entries: []}}' "$CONFIG_FILE" > "$TMP" && mv "$TMP" "$CONFIG_FILE"
fi

if ! jq -e '.skills.entries' "$CONFIG_FILE" > /dev/null 2>&1; then
  TMP=$(mktemp)
  jq '.skills.entries = []' "$CONFIG_FILE" > "$TMP" && mv "$TMP" "$CONFIG_FILE"
fi

# Adicionar entrada se nao existir
EXISTS=$(jq --arg name "$SKILL_NAME" '.skills.entries | map(.name) | index($name)' "$CONFIG_FILE")

if [ "$EXISTS" = "null" ]; then
  TMP=$(mktemp)
  jq --arg name "$SKILL_NAME" --arg path "skills/$SKILL_NAME" \
    '.skills.entries += [{"name": $name, "path": $path, "enabled": true}]' \
    "$CONFIG_FILE" > "$TMP" && mv "$TMP" "$CONFIG_FILE"
  echo -e "${GREEN}[OK]${NC} Entrada $SKILL_NAME adicionada em $CONFIG_FILE"
else
  echo -e "${GREEN}[OK]${NC} Entrada $SKILL_NAME ja existia em $CONFIG_FILE"
fi

# Validar JSON final
if ! jq -e . "$CONFIG_FILE" > /dev/null 2>&1; then
  echo -e "${RED}[ERRO]${NC} JSON ficou invalido apos edicao. Restaurando do backup mais recente." >&2
  if [ -f /root/.openclaw-last-backup ]; then
    LAST_BACKUP=$(cat /root/.openclaw-last-backup)
    cp "$LAST_BACKUP/openclaw.json" "$CONFIG_FILE"
    echo -e "${GREEN}[OK]${NC} openclaw.json restaurado de $LAST_BACKUP"
  fi
  exit 1
fi

echo -e "${GREEN}[OK]${NC} Skill $SKILL_NAME instalada e registrada."
exit 0
