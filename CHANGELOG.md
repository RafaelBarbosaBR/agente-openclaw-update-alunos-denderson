# CHANGELOG.md — O que muda no Upgrade

Este upgrade adiciona 4 skills novas ao seu OpenClaw existente. Sem alterar nada do que ja funciona.

## Versao do upgrade

`2026.4-naia-upgrade-1` (compativel com OpenClaw 2026.4.x)

## Skills novas

### 1. gerar-proposta-comercial

Gera propostas comerciais profissionais em HTML, com:
- Layout single-page responsivo (estilo light navy)
- Tabs interativas (Visao Geral, Ecossistema, Entregaveis, Plano de Acao, Investimento)
- Checkboxes interativos com localStorage
- Progress bar e Gantt chart
- Templates Mentoria (R$20k a R$30k) e Consultoria (R$50k a R$60k)
- Deploy automatico no Vercel
- DNS Cloudflare (subdominio nomedocliente.denderson.com)
- Registro automatico na dashboard de propostas

Como invocar:
> "Gera proposta pro cliente Joao da padaria, modelo mentoria R$30k"

### 2. gerar-landing-page

Cria landing pages de alta conversao com 2 templates favoritos do Chefe:

**Template NYOS (editorial tech):**
- Tipografia Cormorant Garamond + DM Sans
- Paleta light navy / dourado
- Estilo revista digital, premium

**Template Imersao (terminal/matrix):**
- Estetica terminal com cursor piscante
- Paleta preto / verde fosforo
- Voltado pra produtos tech / cursos de IA

Tudo single-page, deploy automatico no Vercel, DNS Cloudflare.

Como invocar:
> "Cria uma landing page com o template NYOS pra mentoria de IA"

### 3. analisar-instagram-bmad

Pipeline BMAD 10 etapas com 3 chamadas Gemini, gera relatorio HTML completo:
1. Coleta dados publicos do perfil
2. Analise demografica e psicografica
3. Identifica pilares de conteudo
4. Mede engajamento real (vs vanity metrics)
5. Detecta padroes de viral
6. Mapeia concorrentes
7. Sugere lacunas de mercado
8. Roadmap de 30 dias
9. Plano editorial card a card
10. Deploy em USERNAME.denderson.com

Como invocar:
> "Analisa o Instagram do @denderson.ai com BMAD"

### 4. criar-subagente

Cria subagentes especialistas no formato compativel com OpenClaw:
- Define personalidade, tom de voz, anti-patterns
- Configura ferramentas disponiveis (Bash, Read, Write, Edit, Agent)
- Configura contexto inicial e regras operacionais
- Salva em `/root/.openclaw/subagents/<nome>.md`
- Registra em `openclaw.json` automaticamente
- Pronto pra ser invocado via Agent tool

Como invocar:
> "Cria um subagente chamado Marcos especialista em SEO tecnico"

## O que NAO muda

- Configuracao do bot Telegram (continua igual)
- Memoria vetorial PostgreSQL (intacta)
- Workspace e knowledge base (preservados)
- Crons e schedulers existentes (preservados)
- Outras skills ja instaladas (preservadas)

## Compatibilidade

OpenClaw 2026.4.x. Pra versoes mais antigas, ver [docs/COMPATIBILIDADE.md](./docs/COMPATIBILIDADE.md).
