# Instrucao pra Aluno — Upgrade do OpenClaw

Esse arquivo e pra quem nunca mexeu com codigo. Le com calma e segue o passo a passo.

## O que voce precisa antes de comecar

1. Sua VPS com OpenClaw ja rodando (instalada pelo repo `agente-openclaw-telegram-setup-alunos-denderson`)
2. IP, usuario (`root` na maioria dos casos) e senha da VPS em maos
3. Um agente IA no seu PC: Claude Code (recomendado), Claude Desktop, GLM ou GPT
4. 5 minutos sem interrupcao

## Como funciona

Voce nao vai digitar nenhum comando tecnico. Voce vai conversar em portugues com seu agente IA, e ele faz todo o trabalho na sua VPS.

## Passo 1: Abre seu agente IA

Pode ser:
- Claude Code (terminal do PC)
- Claude Desktop (app)
- GLM (https://chat.z.ai)
- ChatGPT (https://chat.openai.com)
- Cursor IDE

Qualquer um funciona.

## Passo 2: Cola o prompt

Abre o arquivo [prompt-instalador.txt](./prompt-instalador.txt) desse repositorio, copia TODO o conteudo, e cola na conversa do seu agente.

## Passo 3: Responde as perguntas do agente

O agente vai te perguntar:
- Qual o IP da VPS?
- Qual o usuario? (geralmente `root`)
- Qual a senha?

Voce informa. Ele faz SSH e comeca a trabalhar.

## Passo 4: Confirma o backup

Antes de aplicar qualquer alteracao, o agente vai te avisar:

> "Vou fazer backup completo da configuracao atual em /root/openclaw-backup-XXXX. Posso prosseguir?"

Voce responde **SIM**.

## Passo 5: Espera

O agente vai:
1. Detectar a versao atual do OpenClaw
2. Fazer backup completo (config, workspace, .env)
3. Baixar as 4 skills novas do repositorio
4. Instalar cada skill em `/root/.openclaw/skills/`
5. Atualizar `openclaw.json` com as novas entradas
6. Reiniciar o gateway do OpenClaw
7. Rodar `openclaw doctor` pra validar
8. Mandar 1 ping no Telegram pra confirmar que esta no ar

Tudo isso leva cerca de 5 minutos.

## Passo 6: Testa

Manda uma mensagem no Telegram do teu bot (o mesmo que ja usava antes do upgrade):

> "Naia, gera uma proposta comercial pro cliente Joao da padaria"

Se ela responder e comecar a executar a skill nova, deu certo.

Outras mensagens pra testar:
> "Cria uma landing page com o template NYOS"

> "Analisa o instagram do @denderson.ai usando BMAD"

> "Cria um subagente chamado Marcos especialista em SEO"

## Se der problema

### Problema 1: Agente nao consegue fazer SSH
Verifica se o IP, usuario e senha estao corretos. Tenta conectar manualmente pra ver se funciona.

### Problema 2: Erro durante o upgrade
O agente roda `bash scripts/rollback.sh` automaticamente e restaura o estado anterior. Voce nao perde nada. Manda screenshot do erro pro grupo dos alunos.

### Problema 3: Gateway nao sobe depois do upgrade
Le [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md). Tem solucoes pros erros mais comuns.

### Problema 4: Skill nao aparece quando voce manda comando no Telegram
Pede pro agente rodar `openclaw doctor` e te mostrar o output. Provavelmente tem erro de sintaxe no `openclaw.json`. O proprio doctor aponta a linha errada.

## Quanto tempo demora

- Backup: 30 segundos
- Download das skills: 1 minuto
- Instalacao: 1 minuto
- Restart do gateway: 30 segundos
- Validacao: 1 minuto
- Total: cerca de 4 a 5 minutos

## E seguro?

Sim. O processo e idempotente (pode rodar 2 vezes sem quebrar nada) e tem rollback automatico. Antes de qualquer alteracao, backup completo. Se der qualquer erro, voce volta ao estado anterior em 1 comando.

## E se eu quiser desfazer depois de tudo funcionar?

Pede pro agente rodar:

```bash
bash scripts/rollback.sh
```

Ele restaura o backup mais recente e voce volta pra versao anterior.

## Duvidas

Grupo dos alunos no Telegram. La a galera ajuda e o time da Naia tambem.
