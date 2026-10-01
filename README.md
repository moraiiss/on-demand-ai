# Pipeline de demandas com Claude Code

Pipeline autônomo **PM → Staff → SWE → review → PR**. Cada demanda roda em uma sessão de background, com
worktree e branch próprios. Você dispara várias demandas, fecha o terminal e volta depois para revisar
docs, decisões e PRs.

Funciona com **qualquer stack**: o pipeline só orquestra agentes, git e GitHub. O comando de build/testes é
configurável (veja o quality gate abaixo). Requer Linux ou macOS com `bash`, `git`, `jq`, `gh` e `claude`.
Licença: [MIT](LICENSE).

## Estrutura

```
.claude/
  settings.json                 permissões (allow/deny), env e hook de limite de uso
  agents/
    orquestrador.md             thread principal (Sonnet, low): roteia, mantém checklist e checkpoint
    product-manager.md          "a Dona do Porquê" (Sonnet, medium): prompt reescrito + spec
    staff-engineer.md           "o Guardião" (Opus, high): plano + code review, com memória de projeto
    software-engineer.md        "o Executor Criterioso" (Sonnet, medium): TDD, ajustes, PR
    Explore.md                  override da busca embutida em Haiku (barato)
  hooks/
    guard-paths.sh              PM/Staff só escrevem em docs/demands (e memória/registro)
    guard-bash-readonly.sh      Bash somente leitura para o Staff
    quality-gate.sh             build/testes/lint ao fim do SWE (máx. 3 tentativas)
    on-rate-limit.sh            "levanta a mão": registra interrupção, marca STATE e notifica
    _lib.sh
  skills/demanda/SKILL.md       /demanda <texto> a partir de qualquer sessão
  templates/demanda/            STATE.json, handoffs.md, 00-prompt.md
  quality-gate.conf.example
scripts/demandas/
  demanda                       despacha uma demanda em background
  retomar                       retoma a mesma sessão a partir do checkpoint
  vigia-limites                 retentativa automática após o reset (5h), com registro
  instalar.sh
  systemd/                      timer de usuário para o vigia (Pop!_OS/Linux)
docs/demands/<ID>/              artefatos de cada demanda (entram no PR)
~/.claude/demandas/             registro global: registry.tsv, interrupcoes.jsonl, retentativas.jsonl, ativas/
```

## Instalação

Pré-requisitos: `claude` (instalador nativo), `git`, `jq`, `gh` autenticado e o plugin **superpowers**
instalado. Sua skill `/prompt-orquestrator` precisa estar disponível no projeto ou no usuário.

```bash
cp -r <scaffold>/. <seu-repo>/        # ou mescle com o seu .claude/ existente
cd <seu-repo>
./scripts/demandas/instalar.sh
git add .claude scripts docs .gitignore && git commit -m "chore: pipeline de demandas"
```

O commit é obrigatório: os worktrees são criados a partir do repositório, então agentes, hooks e templates
**precisam estar versionados** para existirem dentro de cada worktree.

Depois:
1. Preencha a seção **Contexto do projeto** em `.claude/agents/staff-engineer.md`.
2. O gate detecta Gradle, Maven e npm sozinho. Para qualquer outra stack (Rust, Go, Python, .NET, Ruby,
   Makefile...), copie `.claude/quality-gate.conf.example` para `.claude/quality-gate.conf` e escolha o comando.
3. Rode `claude` uma vez no repositório e aceite o diálogo de confiança. Sem isso, os hooks definidos nos
   agentes não rodam.

## Uso

```bash
demanda "Permitir simular antecipação informando o valor desejado"
demanda --sem-gate --nome ajuste-log "Mascarar dados sensíveis nos logs do módulo X"
claude agents                 # painel: Working / Needs input / Ready for review
retomar DEM-261001-1004-...   # retoma manualmente uma demanda interrompida
```

Dentro de uma sessão do Claude, também funciona `/demanda <texto>`. Na tela do `claude agents`, use
`@orquestrador ID: ... DEMANDA: ...` só se quiser despachar sem o script. O script é preferível, porque
gera o ID, aplica o modo de permissão e registra a sessão.

**Durante a execução:**
- No agent view, a linha da sessão mostra a etapa atual. Use `Space` para espiar e `Enter` para entrar
  e ver o checklist completo.
- Quando o gate do plano está ligado (padrão), a sessão aparece em **Needs input** depois do plano.
- A sessão também vai para **Needs input** quando um agente retorna `BLOQUEADO`/`FALHA`. Esse é o
  "levantar a mão" por motivo de trabalho.

**Ao final, revise nesta ordem:**
1. `docs/demands/<ID>/handoffs.md` → Resumo, decisões com confiança baixa ou `Validar? sim`, Pendências, Divergências.
2. O PR draft (o corpo traz links para spec, plano e handoffs).
3. `review-NN.md`, se quiser ver o raciocínio do Staff.

## Limite de uso: como funciona

1. **Checkpoint contínuo.** O orquestrador commita `docs/demands/<ID>` ao fim de cada etapa. O SWE commita
   a cada tarefa do plano. No pior caso, perde-se uma tarefa.
2. **Mão levantada.** Ao estourar o limite, o hook `StopFailure` (matcher `rate_limit`) roda sem gastar
   tokens. Ele grava em `~/.claude/demandas/interrupcoes.jsonl`, marca `STATE.json` como
   `interrompida_limite`, adiciona a linha na linha do tempo do handoffs e notifica (`notify-send`).
3. **Retomada.** O timer `demandas-vigia` roda a cada 15 min. Cinco horas depois da última interrupção, ele
   chama `retomar` (`claude --resume <session> --bg "RETOMADA..."`). Cada tentativa vai para
   `retentativas.jsonl`. Depois de 3 tentativas sem sucesso (sinal de limite semanal), ele para e notifica.
   Erros de falta de créditos não são retentados.
4. Para retomar na hora, rode `retomar <ID>`.

Ajustes possíveis: `RETRY_APOS_HORAS` e `MAX_TENTATIVAS` (variáveis de ambiente no `.service`).

## Modelos e custo

| Etapa | Agente | Modelo | Esforço |
|---|---|---|---|
| Roteamento | orquestrador | sonnet | low |
| Prompt + spec | product-manager | sonnet | medium |
| Plano e review | staff-engineer | opus | high |
| Implementação e ajustes | software-engineer | sonnet | medium |
| Buscas na codebase | Explore | haiku | — |

Para mudar, edite `model:`/`effort:` no frontmatter de cada agente. Cada sessão em background consome a
mesma quota da sua assinatura. Comece com **2–3 demandas simultâneas**.

## Guardrails (o que é imposto, não só pedido)

- **Escrita por papel.** PM e Staff só escrevem em `docs/demands/` (o Staff também na própria memória e em
  `~/.claude/demandas/ativas`). O Bash do Staff é somente leitura.
- **Ninguém altera o próprio pipeline.** `.claude/agents`, `.claude/hooks`, `.claude/skills` e
  `settings.json` estão em `deny`.
- **Sem segredos.** `.env*`, chaves e `~/.ssh`, `~/.aws`, `~/.kube` estão em `deny`.
- **Git seguro.** Force-push, push em main/master, `git merge` e `gh pr merge` estão bloqueados. O PR sai
  sempre como draft e o merge é seu.
- **Quality gate.** O SWE não termina com build ou testes quebrados (até 3 tentativas; depois vira `FALHA`
  e pendência).
- **Orçamento.** `maxTurns` por agente, no máximo 2 rodadas de review e no máximo 1 devolução da spec.

Recomendado também: proteção de branch no remoto (review obrigatório) e o Bash em sandbox (`/sandbox`).
As regras `deny` de Bash casam por padrão de texto e não substituem um sandbox.

## Pontos a validar na sua versão (faça um piloto antes de escalar)

- **Agent view** está em research preview. Confirme `claude agents`, `--bg`, `--agent` e `--resume ... --bg`
  com `claude --version` atualizado (`claude update`).
- **`skills:` com skill de plugin.** O SWE pré-carrega `superpowers:test-driven-development`. Se aparecer
  aviso em `claude --debug`, remova a linha `skills:`; o agente ainda invoca a skill pela ferramenta Skill.
- **Overrides das skills do superpowers.** As instruções "não pergunte ao usuário", "salve em
  docs/demands", "não commite" e "sempre PR" estão nos prompts dos agentes. Se uma versão nova do plugin
  mudar o comportamento, ajuste ali.
- **`--agent` substitui o system prompt padrão.** Por isso o orquestrador é autocontido.
- **Excluir uma sessão no agent view remove o worktree, inclusive mudanças não commitadas.** Os checkpoints
  existem para isso, mas confira antes de apagar.
- **Retomada.** `retomar` precisa rodar a partir da raiz do repositório original; o script já faz o `cd`.
- **Conflitos entre demandas.** O Staff lê `~/.claude/demandas/ativas/*.md` e sinaliza sobreposição de
  módulos no plano. O SWE faz rebase antes do PR.

## Personalizar

- **Personas:** o bloco "Persona" de cada agente.
- **Gate do plano:** padrão ligado; `--sem-gate` desliga por demanda.
- **Novas ferramentas:** os agentes registram sugestões em `handoffs.md` → "Sugestões de ferramentas". Você
  decide e aplica: os agentes não podem alterar `.claude/`.
