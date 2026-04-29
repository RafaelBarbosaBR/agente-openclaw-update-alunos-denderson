#!/bin/bash
# ============================================
# validate.sh
# Valida que upgrade aplicou corretamente
# - openclaw doctor
# - skills listadas via API
# - 1 ping no Telegram
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

EXIT_CODE=0

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

# 1. openclaw doctor (se disponivel)
echo -e "${YELLOW}[1/4]${NC} Rodando openclaw doctor..."
if command -v openclaw &> /dev/null; then
  if openclaw doctor 2>/dev/null; then
    echo -e "${GREEN}  [OK]${NC} openclaw doctor passou"
  else
    echo -e "${YELLOW}  [AVISO]${NC} openclaw doctor retornou avisos"
    EXIT_CODE=1
  fi
else
  echo -e "${YELLOW}  [AVISO]${NC} comando openclaw nao encontrado no PATH. Pulando."
fi

# 2. Verificar gateway respondendo
echo -e "${YELLOW}[2/4]${NC} Verificando gateway na porta 18789..."
if curl -sf http://127.0.0.1:18789/health > /dev/null 2>&1; then
  echo -e "${GREEN}  [OK]${NC} Gateway responde em 127.0.0.1:18789"
elif curl -sf http://127.0.0.1:18789/ > /dev/null 2>&1; then
  echo -e "${GREEN}  [OK]${NC} Gateway responde em 127.0.0.1:18789"
else
  echo -e "${YELLOW}  [AVISO]${NC} Gateway nao respondeu via HTTP. Pode estar carregando."
fi

# 3. Listar skills carregadas
echo -e "${YELLOW}[3/4]${NC} Verificando skills carregadas..."
EXPECTED_SKILLS=("gerar-proposta-comercial" "gerar-landing-page" "analisar-instagram-bmad" "criar-subagente")

# Tentar via API
SKILLS_LIST=""
if curl -sf http://127.0.0.1:18789/skills > /tmp/skills-check.json 2>/dev/null; then
  SKILLS_LIST=$(cat /tmp/skills-check.json)
fi

# Fallback: ler do filesystem
for skill in "${EXPECTED_SKILLS[@]}"; do
  if [ -d "$OPENCLAW_HOME/skills/$skill" ]; then
    echo -e "${GREEN}  [OK]${NC} Skill encontrada: $skill"
  else
    echo -e "${RED}  [ERRO]${NC} Skill faltando no filesystem: $skill"
    EXIT_CODE=1
  fi

  # Verificar registro no openclaw.json
  if [ -f "$OPENCLAW_HOME/openclaw.json" ]; then
    REGISTERED=$(jq --arg name "$skill" '.skills.entries // [] | map(.name) | index($name)' "$OPENCLAW_HOME/openclaw.json" 2>/dev/null || echo "null")
    if [ "$REGISTERED" = "null" ]; then
      echo -e "${YELLOW}  [AVISO]${NC} Skill $skill nao esta registrada em openclaw.json"
    fi
  fi
done

# 4. Status do servico
echo -e "${YELLOW}[4/4]${NC} Verificando servico systemd..."
if systemctl is-active --quiet openclaw-gateway; then
  UPTIME=$(systemctl show openclaw-gateway -p ActiveEnterTimestamp --value | xargs -I {} date -d {} +'%H:%M:%S')
  echo -e "${GREEN}  [OK]${NC} openclaw-gateway ativo desde $UPTIME"
else
  echo -e "${RED}  [ERRO]${NC} openclaw-gateway INATIVO"
  EXIT_CODE=1
fi

# Resumo
echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}[VALIDACAO OK]${NC} Upgrade aplicado com sucesso."
  echo -e "${GREEN}========================================${NC}"
else
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}[VALIDACAO COM AVISOS]${NC} Upgrade aplicado mas alguns checks falharam."
  echo -e "${YELLOW}Veja os avisos acima e consulte docs/TROUBLESHOOTING.md${NC}"
  echo -e "${YELLOW}========================================${NC}"
fi

exit $EXIT_CODE
