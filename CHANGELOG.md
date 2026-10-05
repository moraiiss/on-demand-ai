# Changelog

Versões publicadas como tags `vX.Y.Z`. O `atualizar` usa a tag mais recente por padrão.
Marque com **Ação** o que exigir um passo manual no projeto alvo depois de atualizar.

## Não publicado

- `.claude/settings.json`: `attribution` vazio para commits e PRs. O Claude Code deixa de adicionar
  `Co-Authored-By: Claude` nos commits e `Generated with Claude Code` na descrição dos PRs.
- **Ação:** se o `settings.json` do projeto alvo tiver customizações, a versão nova vai para
  `settings.json.novo`; copie a chave `attribution` para o seu arquivo.

## v0.2.0

- `scripts/demandas/atualizar`: instala e atualiza o pipeline nos projetos alvo a partir de uma tag, branch
  ou commit, preservando customizações locais (`<arquivo>.novo`) e gravando `.claude/on-demand-ai.lock`.
- `scripts/demandas/manifesto`: lista o que é gerenciado pelo pipeline, o que é semente do projeto e as
  entradas do `.gitignore` (agora lidas também pelo `instalar.sh`).
- Contexto do projeto do Staff sai do `staff-engineer.md` e vai para `.claude/projeto.md`. A migração é
  automática no primeiro `atualizar`.
- Skill `prompt-orquestrador` nativa do projeto, em modo autônomo.
- **Ação:** nenhuma além de revisar o diff e commitar.

## v0.1.0

- Pipeline de demandas PM → Staff → SWE → review → PR.
