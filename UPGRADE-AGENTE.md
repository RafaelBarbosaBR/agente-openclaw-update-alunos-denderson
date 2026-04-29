# UPGRADE-AGENTE.md — Manual Tecnico do Upgrade

Este documento e pro agente IA que vai executar o upgrade. Voce le, segue passo a passo na VPS do aluno via SSH.

## Visao geral

O upgrade adiciona 4 skills novas a uma instalacao OpenClaw 2026.4.x existente, sem reinstalar nada.

Fluxo:
1. SSH na VPS do aluno
2. Clone deste repo em `/tmp/openclaw-update`
3. Detecta versao atual
4. Backup completo
5. Aplica skills
6. Restart gateway
7. Valida
8. Reporta status pro aluno

## Pre-requisitos

Antes de comecar, garanta que:
- VPS esta acessivel via SSH
- Usuario tem permissao sudo (geralmente `root`)
- OpenClaw esta instalado em `/opt/openclaw` ou `/root/.openclaw`
- Servico `openclaw-gateway` esta no `systemctl`
- Conexao com internet pra clonar o repo

## Passo 1: SSH e clone do repo

```bash
ssh root@IP_DA_VPS
cd /tmp
rm -rf openclaw-update
git clone https://github.com/denderson2013-bot/agente-openclaw-update-alunos-denderson openclaw-update
cd openclaw-update
chmod +x scripts/*.sh
```

## Passo 2: Detectar versao atual

```bash
bash scripts/detect-version.sh
```

O script:
- Le `/opt/openclaw/.version` se existir
- Senao, infere via `systemctl status openclaw-gateway`
- Senao, le `package.json` em `/opt/openclaw`
- Imprime: versao detectada + caminho da instalacao + status do servico

Se a versao for menor que 2026.4.0, parar e pedir pro aluno reinstalar via repo `agente-openclaw-telegram-setup-alunos-denderson`.

Se for entre 2026.4.0 e 2026.4.x, prosseguir.

## Passo 3: Backup completo

```bash
bash scripts/backup-config.sh
```

O script gera um diretorio `/root/openclaw-backup-YYYYMMDD-HHMMSS/` com:
- `openclaw.json` (config principal)
- `workspace/` (memorias, knowledge, skills antigas)
- `.env` (variaveis de ambiente)
- `version.txt` (versao atual antes do upgrade)
- `metadata.json` (timestamp, hash dos arquivos)

Imprime o caminho do backup. Anota no terminal pro aluno.

PARAR antes de prosseguir e perguntar pro aluno: "Backup feito em <caminho>. Posso aplicar o upgrade?". So prossegue se ele aprovar.

## Passo 4: Aplicar as 4 skills

```bash
SKILLS=("gerar-proposta-comercial" "gerar-landing-page" "analisar-instagram-bmad" "criar-subagente")

for skill in "${SKILLS[@]}"; do
  bash scripts/install-skill.sh "$skill"
done
```

O `install-skill.sh`:
- Copia `skills/<nome>/` deste repo pra `/root/.openclaw/skills/<nome>/`
- Le `openclaw.json`, adiciona entrada em `skills.entries` se nao existir
- Valida JSON depois da edicao com `jq`
- Se a skill ja existir, pula (idempotente)

## Passo 5: Restart do gateway

```bash
systemctl restart openclaw-gateway
sleep 3
systemctl status openclaw-gateway --no-pager
```

Se nao subir, parar e rodar:

```bash
journalctl -u openclaw-gateway -n 50 --no-pager
```

Olhar os ultimos logs e diagnosticar. Se tiver erro de JSON em `openclaw.json`, rodar `bash scripts/rollback.sh` imediatamente.

## Passo 6: Validar

```bash
bash scripts/validate.sh
```

O script:
- Roda `openclaw doctor` (se o binario tiver esse comando)
- Verifica que cada skill nova esta listada via API local: `curl http://127.0.0.1:18789/skills`
- Manda 1 ping no Telegram do bot do aluno via API: `curl -X POST http://127.0.0.1:18789/test-ping`
- Imprime resumo: skills instaladas, gateway rodando, telegram OK

## Passo 7: Reportar pro aluno

Mensagem padrao pro Telegram do aluno:

> "Upgrade concluido. 4 skills novas ativas: propostas, landing pages, BMAD Instagram, criacao de subagentes. Backup salvo em <caminho>. Pode testar mandando comando no teu bot."

Inclui:
- Caminho do backup (pra rollback se precisar)
- Versao final do OpenClaw
- Lista das 4 skills ativas
- Comandos de teste sugeridos

## Rollback (se der ruim)

Se em qualquer passo der erro grave (gateway nao sobe, skill conflita, config corrompido), executar:

```bash
bash scripts/rollback.sh
```

O script:
1. Para o servico (`systemctl stop openclaw-gateway`)
2. Restaura `openclaw.json` do backup mais recente
3. Restaura `workspace/` do backup
4. Restaura `.env` do backup
5. Sobe o servico de novo (`systemctl start openclaw-gateway`)

Em 5 passos, instalacao volta ao estado anterior.

## Checklist final

- [ ] Versao detectada e compativel (2026.4.x)
- [ ] Backup feito e caminho anotado
- [ ] Aluno aprovou o backup
- [ ] 4 skills instaladas em `/root/.openclaw/skills/`
- [ ] `openclaw.json` validado com `jq`
- [ ] Gateway reiniciou sem erro
- [ ] `openclaw doctor` passou
- [ ] Ping no Telegram OK
- [ ] Aluno notificado com resumo

## Idempotencia

Se rodar `bash scripts/update.sh` 2 vezes seguidas:
- 1a vez: instala as 4 skills, atualiza config
- 2a vez: detecta que skills ja existem, pula instalacao, mas faz novo backup e revalida

Sem efeito colateral. Sem duplicar entrada em `openclaw.json`.

## Logs do upgrade

Tudo que o `update.sh` faz e logado em `/var/log/openclaw-upgrade.log`. Se algo der errado, esse arquivo tem o passo a passo do que foi executado.
