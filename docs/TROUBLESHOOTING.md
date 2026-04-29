# TROUBLESHOOTING — Erros Comuns no Upgrade

Guia de bolso pros erros mais comuns durante o upgrade. Sempre tenta as solucoes na ordem.

## Erro 1: Gateway nao sobe depois do restart

### Sintoma
```bash
systemctl status openclaw-gateway
# Active: failed (Result: exit-code)
```

### Diagnostico
```bash
journalctl -u openclaw-gateway -n 50 --no-pager
```

### Causas mais comuns

**1.1 — JSON invalido em `openclaw.json`**

Output do journalctl contem `SyntaxError: Unexpected token` ou `JSON parse error`.

Solucao:
```bash
# Validar JSON
jq . /root/.openclaw/openclaw.json

# Se nao valida, restaurar do backup
bash scripts/rollback.sh
```

**1.2 — Porta 18789 ja ocupada**

Output: `EADDRINUSE: address already in use`

Solucao:
```bash
# Descobrir quem esta usando
lsof -i :18789

# Matar processo orfao
kill -9 <PID>

# Reiniciar
systemctl restart openclaw-gateway
```

**1.3 — Skill mal formada quebra o load**

Output: `Cannot load skill: <nome>`

Solucao:
```bash
# Editar openclaw.json e desativar a skill problematica
jq '(.skills.entries[] | select(.name=="<nome>") | .enabled) = false' /root/.openclaw/openclaw.json > /tmp/x && mv /tmp/x /root/.openclaw/openclaw.json
systemctl restart openclaw-gateway
```

## Erro 2: Skill conflita com skill ja instalada

### Sintoma
```
[ERRO] Skill gerar-proposta-comercial ja existe com conteudo diferente
```

### Solucao
O `install-skill.sh` ja resolve isso automaticamente (substitui pela versao mais recente). Mas se ficar inseguro:

```bash
# Backup manual da skill antiga
cp -rp /root/.openclaw/skills/gerar-proposta-comercial /root/skill-backup-$(date +%s)

# Forcar reinstalacao
rm -rf /root/.openclaw/skills/gerar-proposta-comercial
bash scripts/install-skill.sh gerar-proposta-comercial
```

## Erro 3: Config corrompido apos edicao

### Sintoma
```bash
jq . /root/.openclaw/openclaw.json
# parse error: ... at line N, column M
```

### Solucao
```bash
# Restaurar do backup mais recente
LAST_BACKUP=$(cat /root/.openclaw-last-backup)
cp $LAST_BACKUP/openclaw.json /root/.openclaw/openclaw.json
systemctl restart openclaw-gateway
```

## Erro 4: SSH cai durante o upgrade

### Sintoma
Conexao SSH morre no meio do `update.sh`.

### Solucao
Reconecta e roda de novo. O script e idempotente. Vai detectar o que ja foi feito e pular.

```bash
ssh root@IP_DA_VPS
cd /tmp/openclaw-update
bash scripts/update.sh
```

## Erro 5: Espaco em disco insuficiente

### Sintoma
```
No space left on device
```

### Solucao
```bash
df -h /
# Se /root estiver cheio, limpar backups antigos
ls -lh /root/openclaw-backup-*
# Manter so o ultimo
ls -dt /root/openclaw-backup-* | tail -n +2 | xargs rm -rf
```

## Erro 6: Skill instalou mas Naia nao reconhece

### Sintoma
Voce manda comando no Telegram, Naia responde mas nao executa a skill nova.

### Causas

**6.1 — Skill nao registrada em openclaw.json**
```bash
jq '.skills.entries[].name' /root/.openclaw/openclaw.json
```

Se a skill nao aparecer:
```bash
bash scripts/install-skill.sh <nome-da-skill>
systemctl restart openclaw-gateway
```

**6.2 — Skill desativada**
```bash
jq '.skills.entries[] | select(.name=="<nome>")' /root/.openclaw/openclaw.json
# Se .enabled estiver false:
jq '(.skills.entries[] | select(.name=="<nome>") | .enabled) = true' /root/.openclaw/openclaw.json > /tmp/x && mv /tmp/x /root/.openclaw/openclaw.json
systemctl restart openclaw-gateway
```

**6.3 — Cache do gateway**
```bash
systemctl stop openclaw-gateway
sleep 2
systemctl start openclaw-gateway
```

## Erro 7: Telegram parou de responder apos upgrade

### Sintoma
Bot Telegram nao responde mais.

### Diagnostico
```bash
# Verificar se gateway esta rodando
systemctl status openclaw-gateway

# Verificar se canal Telegram esta carregado
journalctl -u openclaw-gateway | grep -i telegram | tail -20
```

### Solucao
```bash
# Verificar token do bot ainda esta no .env
grep TELEGRAM /root/.openclaw/.env

# Se tudo certo, restart
systemctl restart openclaw-gateway

# Se ainda nao funciona, rollback
bash scripts/rollback.sh
```

## Erro 8: jq nao instalado

### Sintoma
```
scripts/install-skill.sh: line 47: jq: command not found
```

### Solucao
```bash
apt-get update && apt-get install -y jq
```

O `update.sh` ja instala isso automaticamente, mas se rodar scripts isolados pode dar.

## Erro 9: Permissoes erradas

### Sintoma
```
Permission denied
```

### Solucao
```bash
# Tem que rodar como root
sudo -i
cd /tmp/openclaw-update
bash scripts/update.sh
```

## Quando nada funciona

1. Roda rollback: `bash scripts/rollback.sh`
2. Confirma que voltou ao estado anterior: `systemctl status openclaw-gateway`
3. Salva os logs: `journalctl -u openclaw-gateway --since '1 hour ago' > /tmp/logs.txt`
4. Manda os logs + descricao do erro no grupo dos alunos
5. Espera ajuda. Nao tenta reinstalar do zero sem orientacao.

## Logs uteis

| Log | Comando |
|-----|---------|
| Upgrade | `tail -f /var/log/openclaw-upgrade.log` |
| Gateway | `journalctl -u openclaw-gateway -f` |
| Sistema | `journalctl -xe` |
| Disk | `df -h` |
| Memoria | `free -h` |
| Processos | `top` |
