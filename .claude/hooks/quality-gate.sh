#!/usr/bin/env bash
# Stop do software-engineer (vira SubagentStop em runtime).
# Roda build, testes e lint. Se falhar, devolve o erro (exit 2) para o agente corrigir.
# Para evitar loop infinito, bloqueia no máximo QG_MAX_TENTATIVAS vezes por execução do agente.
# Configuração opcional em .claude/quality-gate.conf (QG_CMD, QG_EXTRA_CMD, QG_MAX_TENTATIVAS).
set -uo pipefail
INPUT="$(cat)"
CWD="$(jq -r '.cwd // empty' <<<"$INPUT")"
ROOT="$(git -C "${CWD:-.}" rev-parse --show-toplevel 2>/dev/null || echo "${CWD:-$PWD}")"
cd "$ROOT" || exit 0

QG_MAX_TENTATIVAS=3
QG_CMD=""
QG_EXTRA_CMD=""
[ -f .claude/quality-gate.conf ] && . .claude/quality-gate.conf

if [ -z "$QG_CMD" ]; then
  if   [ -x ./gradlew ]; then QG_CMD="./gradlew check --console=plain -q"
  elif [ -x ./mvnw ];    then QG_CMD="./mvnw -B -q verify"
  elif [ -f package.json ]; then QG_CMD="npm test --silent"
  else exit 0  # nada detectado: não bloqueia
  fi
fi

AGENTE="$(jq -r '.agent_id // .session_id // "x"' <<<"$INPUT")"
CONTADOR="${TMPDIR:-/tmp}/qg-${AGENTE//[^a-zA-Z0-9_-]/}"
N="$(cat "$CONTADOR" 2>/dev/null || echo 0)"

SAIDA="$(bash -c "$QG_CMD" 2>&1)"; RC=$?
if [ $RC -eq 0 ] && [ -n "$QG_EXTRA_CMD" ]; then
  SAIDA="$(bash -c "$QG_EXTRA_CMD" 2>&1)"; RC=$?
fi

if [ $RC -eq 0 ]; then rm -f "$CONTADOR"; exit 0; fi

if [ "$N" -ge "$QG_MAX_TENTATIVAS" ]; then
  rm -f "$CONTADOR"
  echo "Quality gate ainda falhando após $N tentativas; liberando para o agente reportar FALHA." >&2
  exit 0
fi
echo $((N + 1)) > "$CONTADOR"
{
  echo "Quality gate falhou (tentativa $((N + 1))/$QG_MAX_TENTATIVAS). Comando: $QG_CMD"
  echo "Corrija e só então finalize. Últimas linhas:"
  echo "$SAIDA" | tail -n 60
} >&2
exit 2
