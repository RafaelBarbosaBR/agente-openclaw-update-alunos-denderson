# COMPATIBILIDADE — Versoes do OpenClaw Suportadas

## Tabela rapida

| Versao do OpenClaw | Status | Acao |
|--------------------|--------|------|
| 2026.4.0 a 2026.4.x | Suportada | Upgrade direto via `scripts/update.sh` |
| 2026.3.x | Parcialmente suportada | Ver "Upgrade manual" abaixo |
| 2026.2.x ou anterior | Nao suportada | Reinstalar do zero |
| Versao desconhecida | Tentar com cuidado | Backup primeiro, testar com 1 skill |

## Versoes oficialmente suportadas

### 2026.4.x

Versao instalada via repo `agente-openclaw-telegram-setup-alunos-denderson`.

Compativel com todas as 4 skills novas. Upgrade direto.

```bash
bash scripts/update.sh
```

## Versoes parcialmente suportadas

### 2026.3.x

OpenClaw antes da reestruturacao do schema `openclaw.json`. As skills funcionam, mas o registro automatico em `openclaw.json` pode falhar pq o schema mudou.

Pra fazer upgrade:

1. Faz backup como sempre: `bash scripts/backup-config.sh`
2. Atualiza o openclaw primeiro:
   ```bash
   cd /opt/openclaw
   git pull origin master
   npm install
   systemctl restart openclaw-gateway
   ```
3. Verifica se subiu: `bash scripts/detect-version.sh`
4. Se versao virou 2026.4.x, ai roda o upgrade normal: `bash scripts/update.sh`

## Versoes nao suportadas

### 2026.2.x ou anterior

Schema do `openclaw.json` muito diferente. Migrar config manualmente da risco alto de corromper.

**Recomendacao:** reinstalar do zero usando o repo:
- https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson

A reinstalacao preserva memoria vetorial PostgreSQL (banco `naia_memory`) automaticamente. So a config do bot e os crons precisam ser refeitos.

## Como descobrir qual versao voce tem

Roda na VPS:

```bash
bash scripts/detect-version.sh
```

O script tenta 5 metodos diferentes. Sempre acha alguma coisa.

Se mesmo assim nao detectar:

```bash
# Metodo manual
cat /opt/openclaw/.version
cat /opt/openclaw/package.json | jq -r '.version'
systemctl status openclaw-gateway | grep -i version
```

## Versao desconhecida (sem arquivo de versao)

Se voce instalou o OpenClaw antes do `.version` existir, o `detect-version.sh` retorna `unknown-no-version-file`. Nesse caso:

1. Faz backup primeiro (sempre)
2. Tenta instalar 1 skill por vez:
   ```bash
   bash scripts/install-skill.sh gerar-proposta-comercial
   systemctl restart openclaw-gateway
   ```
3. Se a skill funciona, instala as outras.
4. Se nao funciona, roda `bash scripts/rollback.sh` e reinstala do zero.

## Sistemas operacionais suportados

| OS | Status |
|----|--------|
| Ubuntu 22.04 LTS | Recomendado |
| Ubuntu 24.04 LTS | Suportado |
| Debian 12 | Suportado |
| Debian 11 | Suportado com avisos |
| Outros (Arch, Fedora, etc.) | Sem garantia |

## Dependencias minimas

- Node.js 20+ (instalado pelo OpenClaw)
- PostgreSQL 15+ (instalado pelo OpenClaw)
- systemd
- jq (instalado automaticamente pelo `update.sh` se faltar)
- curl
- git
