# Agente OpenClaw — Upgrade pra Versao Naia/Avalanche

Repositorio publico oficial pra alunos do Denderson Rodrigues que JA TEM OpenClaw rodando na VPS e querem ATUALIZAR pra a versao mais recente da Naia/Avalanche, com as 4 skills novas.

## O que esse repo faz

Atualiza um OpenClaw existente em ate 5 minutos, sem reinstalar nada, sem perder configuracao, sem perder historico.

Detecta a versao atual, faz backup completo, baixa apenas as skills novas, aplica de forma idempotente, valida que esta tudo no ar e te avisa.

## As 4 skills novas

1. **gerar-proposta-comercial** — gera proposta comercial completa em HTML, deploy no Vercel, DNS Cloudflare e dashboard, em 1 comando
2. **gerar-landing-page** — cria landing page de alta conversao com 2 templates favoritos (NYOS editorial e Imersao terminal/matrix)
3. **analisar-instagram-bmad** — pipeline BMAD 10 etapas com 3 chamadas Gemini, deploy em USERNAME.denderson.com
4. **criar-subagente** — cria subagentes especialistas com personalidade, ferramentas e contexto proprio

Detalhes em [CHANGELOG.md](./CHANGELOG.md).

## Pra quem e

Aluno que ja seguiu o repo `agente-openclaw-telegram-setup-alunos-denderson` e tem OpenClaw 2026.4.x rodando.

Se voce nao tem OpenClaw instalado ainda, comece por aquele repo primeiro.

## Fluxo de upgrade (5 minutos)

1. Voce abre o Claude Code (ou seu agente Claude/GLM/GPT favorito) no PC
2. Cola o conteudo do [prompt-instalador.txt](./prompt-instalador.txt)
3. Da o IP, usuario e senha da sua VPS quando o agente pedir
4. Confirma o backup automatico
5. Espera 5 minutos. Pronto.

O agente faz tudo: SSH, detecta versao, backup, baixa skills, aplica, restart, valida.

## Caracteristicas

- **Idempotente:** pode rodar o upgrade 2 vezes sem quebrar nada
- **Backup automatico:** antes de qualquer alteracao, backup completo com timestamp
- **Rollback funcional:** se der ruim, 1 comando restaura o estado anterior
- **Compativel com Claude, GLM e GPT:** funciona com qualquer agente do PC
- **Sem tokens reais:** o repo nao contem nenhuma credencial, voce informa apenas no momento do upgrade
- **PT-BR:** toda documentacao e mensagens em portugues brasileiro

## Compatibilidade

OpenClaw 2026.4.x (versao instalada via repo `agente-openclaw-telegram-setup-alunos-denderson`).

Pra versoes mais antigas, ver [docs/COMPATIBILIDADE.md](./docs/COMPATIBILIDADE.md).

## Quando da problema

Antes de pedir ajuda, le [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md). Cobre os erros mais comuns durante upgrade.

Se ainda assim travar, executa `bash scripts/rollback.sh` na VPS e abre uma issue aqui no repo.

## Links uteis

- Instalacao do zero (Claude Code): https://github.com/denderson2013-bot/agente-claude-telegram-setup-alunos-denderson
- Instalacao do zero (OpenClaw): https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson
- Este repo (upgrade): https://github.com/denderson2013-bot/agente-openclaw-update-alunos-denderson

## Licenca

MIT. Ver [LICENSE](./LICENSE).
