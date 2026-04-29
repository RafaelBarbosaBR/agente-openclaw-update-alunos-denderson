#!/bin/bash
# ============================================
# detect-version.sh
# Detecta versao atual do OpenClaw na VPS
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VERSION=""
INSTALL_PATH=""

# Tentativa 1: arquivo .version oficial
if [ -f /opt/openclaw/.version ]; then
  VERSION=$(cat /opt/openclaw/.version | tr -d '[:space:]')
  INSTALL_PATH="/opt/openclaw"
fi

# Tentativa 2: package.json em /opt/openclaw
if [ -z "$VERSION" ] && [ -f /opt/openclaw/package.json ]; then
  VERSION=$(jq -r '.version' /opt/openclaw/package.json 2>/dev/null || echo "")
  INSTALL_PATH="/opt/openclaw"
fi

# Tentativa 3: package.json em /root/.openclaw
if [ -z "$VERSION" ] && [ -f /root/.openclaw/package.json ]; then
  VERSION=$(jq -r '.version' /root/.openclaw/package.json 2>/dev/null || echo "")
  INSTALL_PATH="/root/.openclaw"
fi

# Tentativa 4: inferir via systemctl status
if [ -z "$VERSION" ]; then
  if systemctl list-units --full -all | grep -q openclaw-gateway; then
    VERSION="unknown-but-installed"
    INSTALL_PATH=$(systemctl show openclaw-gateway -p ExecStart --value 2>/dev/null | grep -oP '/[^ ]+/openclaw' | head -1 || echo "/opt/openclaw")
  fi
fi

# Tentativa 5: existencia do diretorio
if [ -z "$VERSION" ] && [ -d /root/.openclaw ]; then
  VERSION="unknown-no-version-file"
  INSTALL_PATH="/root/.openclaw"
fi

if [ -z "$VERSION" ]; then
  echo -e "${YELLOW}[AVISO]${NC} OpenClaw nao detectado. Verifique se esta instalado." >&2
  echo "VERSION=not-installed"
  echo "INSTALL_PATH=none"
  exit 1
fi

# Verificar compatibilidade
COMPATIBLE=false
case "$VERSION" in
  2026.4.*) COMPATIBLE=true ;;
  unknown*) COMPATIBLE=true ;;  # tenta upgrade mesmo assim
  *) COMPATIBLE=false ;;
esac

# Status do servico
SERVICE_STATUS="inativo"
if systemctl is-active --quiet openclaw-gateway 2>/dev/null; then
  SERVICE_STATUS="ativo"
fi

echo -e "${GREEN}[OK]${NC} OpenClaw detectado:"
echo "  Versao: $VERSION"
echo "  Caminho: $INSTALL_PATH"
echo "  Servico: $SERVICE_STATUS"
echo "  Compativel: $COMPATIBLE"

# Exporta pras outras scripts
echo "VERSION=$VERSION"
echo "INSTALL_PATH=$INSTALL_PATH"
echo "SERVICE_STATUS=$SERVICE_STATUS"
echo "COMPATIBLE=$COMPATIBLE"

if [ "$COMPATIBLE" = "false" ]; then
  echo -e "${YELLOW}[AVISO]${NC} Versao $VERSION pode nao ser compativel. Veja docs/COMPATIBILIDADE.md" >&2
  exit 2
fi

exit 0
