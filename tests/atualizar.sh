#!/usr/bin/env bash
# Testes do scripts/demandas/atualizar em repositórios temporários.
# Uso: tests/atualizar.sh   (a origem é o working tree atual deste repositório, inclusive o não commitado)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ATUALIZAR="$REPO/scripts/demandas/atualizar"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=teste GIT_AUTHOR_EMAIL=teste@exemplo GIT_COMMITTER_NAME=teste GIT_COMMITTER_EMAIL=teste@exemplo
export GIT_CONFIG_GLOBAL=/dev/null

FALHAS=0
ok() { echo "  ✓ $1"; }
falha() { echo "  ✗ $1"; FALHAS=$((FALHAS + 1)); }
confere() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else falha "$d"; fi; }
limpo() { [[ -z $(git status --porcelain) ]]; }
commita() { git add -A && git commit -qm "$1"; }
roda() { "$ATUALIZAR" --origem "$UP" "$@" >"$T/saida" 2>&1; }
alvo() { rm -rf "$T/$1"; git init -q -b main "$T/$1"; cd "$T/$1"; echo "# app" >README.md; commita inicial; }

# ── origem: histórico real + working tree atual (v1.0.0) + uma mudança sintética (v2.0.0) ──
UP="$T/origem"
git clone -q "$REPO" "$UP"
LEGADO="$(git -C "$UP" rev-list --max-parents=0 HEAD)"
(
  cd "$UP"
  git ls-files -z | xargs -0 rm -f
  (cd "$REPO" && git ls-files -co --exclude-standard -z | tar --null -cf - -T -) | tar -xf -
  git add -A && { git diff --cached --quiet || git commit -qm "working tree"; }
  git tag v1.0.0
  echo "linha nova v2" >>.claude/agents/orquestrador.md
  echo "linha nova v2" >>.claude/agents/product-manager.md
  git rm -q .claude/templates/demanda/00-prompt.md
  printf -- '---\nname: novo\n---\n' >.claude/agents/novo.md
  git add -A && git commit -qm v2 && git tag v2.0.0
)

echo "Instalação do zero"
alvo novo
confere "instala v1.0.0" roda --ref v1.0.0
confere "agente copiado" cmp .claude/agents/orquestrador.md <(git -C "$UP" show v1.0.0:.claude/agents/orquestrador.md)
confere "script executável" test -x scripts/demandas/atualizar
confere "hook executável" test -x .claude/hooks/quality-gate.sh
confere "semente projeto.md criada" test -f .claude/projeto.md
confere "lock gravado com a ref" grep -qx $'ref\tv1.0.0' .claude/on-demand-ai.lock
confere ".gitignore com as entradas do manifesto" grep -qxF ".claude/worktrees/" .gitignore
confere "README do scaffold não é copiado" grep -qx "# app" README.md
commita "instala pipeline"

echo "Idempotência"
confere "segunda execução sem mudanças" roda --ref v1.0.0
confere "relata que já está na versão" grep -q "Já está em v1.0.0" "$T/saida"
confere "working tree continua limpo" limpo

echo "Simulação"
confere "--simular roda" roda --simular
confere "--simular lista o que mudaria" grep -q "atualizado .*orquestrador.md" "$T/saida"
confere "--simular não altera nada" limpo

echo "Proteção contra alterações não commitadas"
echo "rascunho" >>.claude/agents/Explore.md
if roda; then falha "aborta com arquivo do pipeline sujo"; else ok "aborta com arquivo do pipeline sujo"; fi
git checkout -q -- .claude/agents/Explore.md

echo "Atualização com customizações"
echo "customização do projeto" >>.claude/agents/product-manager.md
echo "customização do projeto" >>.claude/agents/Explore.md
echo "- Stack: Go" >>.claude/projeto.md
commita "customiza"
confere "atualiza para a tag mais recente" roda
confere "usa v2.0.0 por padrão" grep -qx $'ref\tv2.0.0' .claude/on-demand-ai.lock
confere "arquivo não customizado atualizado" grep -q "linha nova v2" .claude/agents/orquestrador.md
confere "customizado e alterado na origem é preservado" grep -q "customização do projeto" .claude/agents/product-manager.md
confere "versão nova vai para .novo" cmp .claude/agents/product-manager.md.novo <(git -C "$UP" show v2.0.0:.claude/agents/product-manager.md)
confere "conflito listado como pendente" grep -q "product-manager.md.novo" "$T/saida"
confere "customizado sem mudança na origem fica sem .novo" test ! -e .claude/agents/Explore.md.novo
confere "customizado sem mudança na origem é preservado" grep -q "customização do projeto" .claude/agents/Explore.md
confere "arquivo removido do pipeline é apagado" test ! -e .claude/templates/demanda/00-prompt.md
confere "arquivo novo do pipeline é criado" test -f .claude/agents/novo.md
confere "semente não é sobrescrita" grep -q "Stack: Go" .claude/projeto.md
confere ".novo fica fora do git" test -z "$(git status --porcelain -- '*.novo')"
commita "atualiza pipeline"
confere "nova execução sem mudanças" roda
confere "nova execução mantém o working tree limpo" limpo
confere "pendência continua listada enquanto o .novo existir" grep -q "product-manager.md.novo" "$T/saida"

echo "Adoção de instalação antiga (sem lock, contexto dentro do staff-engineer)"
alvo legado
git -C "$UP" archive "$LEGADO" .claude scripts docs | tar -xf -
sed -i.bak 's|^- Stack: <ex\.:.*|- Stack: Java 21 / Spring Boot|' .claude/agents/staff-engineer.md && rm .claude/agents/staff-engineer.md.bak
commita "pipeline copiado à mão"
confere "adota e atualiza para v1.0.0" roda --ref v1.0.0
confere "nenhum conflito em arquivo não customizado" test -z "$(find . -name '*.novo')"
confere "contexto migrado para projeto.md" grep -q "Stack: Java 21 / Spring Boot" .claude/projeto.md
confere "projeto.md sem o título antigo" test -z "$(grep -F '(edite esta seção)' .claude/projeto.md)"
confere "staff-engineer volta à versão publicada" cmp .claude/agents/staff-engineer.md <(git -C "$UP" show v1.0.0:.claude/agents/staff-engineer.md)
confere "settings.json atualizado" cmp .claude/settings.json <(git -C "$UP" show v1.0.0:.claude/settings.json)
confere "lock criado" test -f .claude/on-demand-ai.lock

echo "Recusa rodar no próprio repositório do pipeline"
cd "$UP"
if roda; then falha "recusa o repositório de origem"; else ok "recusa o repositório de origem"; fi

echo
if ((FALHAS)); then echo "✗ $FALHAS falha(s). Última saída:"; cat "$T/saida"; exit 1; fi
echo "✅ Todos os testes passaram"
