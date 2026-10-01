#!/usr/bin/env bash
# PreToolUse (Bash) do staff-engineer: permite ler, inspecionar git e rodar testes;
# bloqueia comandos que escrevem arquivos ou alteram o estado do git.
set -uo pipefail
INPUT="$(cat)"
CMD="$(jq -r '.tool_input.command // empty' <<<"$INPUT")"
[ -z "$CMD" ] && exit 0

bloquear() {
  echo "Bloqueado (staff-engineer é somente leitura no Bash): $1. Para escrever review/plano, use a ferramenta Write em docs/demands/." >&2
  exit 2
}

if grep -Eq '(^|[;&|(`[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(commit|push|reset|checkout|switch|rebase|merge|stash|restore|clean|cherry-pick|revert|am|apply|tag|branch[[:space:]]+-[dDmM])' <<<"$CMD"; then
  bloquear "comando git que altera estado"
fi
if grep -Eq '(^|[;&|(`[:space:]])(rm|mv|cp|tee|truncate|chmod|chown|dd|install|patch)[[:space:]]' <<<"$CMD"; then
  bloquear "comando que altera arquivos"
fi
if grep -Eq '(^|[;&|(`[:space:]])(sed|perl)[[:space:]]+(-[a-zA-Z]*i)' <<<"$CMD"; then
  bloquear "edição in-place"
fi
# Redirecionamento de saída para arquivo (ignora >/dev/null, 2>&1 e afins)
LIMPO="$(sed -E 's/[0-9&]*>>?[[:space:]]*\/dev\/null//g; s/[0-9]*>&[0-9]//g' <<<"$CMD")"
if grep -Eq '>>?[[:space:]]*[^[:space:]>&|]' <<<"$LIMPO"; then
  bloquear "redirecionamento de saída para arquivo"
fi
exit 0
