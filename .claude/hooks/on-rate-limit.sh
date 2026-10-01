#!/usr/bin/env bash
# StopFailure (matcher: rate_limit). Roda sem consumir tokens:
# registra a interrupção, marca STATE.json e handoffs.md da demanda ativa e notifica.
# A saída deste hook é ignorada pelo Claude Code: ele só registra e alerta.
set -uo pipefail
. "$(dirname "$0")/_lib.sh"
mkdir -p "$DEMANDAS_HOME"

INPUT="$(cat)"
SID="$(jq -r '.session_id // empty' <<<"$INPUT")"
CWD="$(jq -r '.cwd // empty' <<<"$INPUT")"
ROOT="$(git -C "${CWD:-.}" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")"
AGORA="$(agora_utc)"; EPOCH="$(date +%s)"

# "rate_limit" também cobre falta de créditos, que não se resolve esperando.
RETENTAVEL=true
grep -qi 'credit' <<<"$INPUT" && RETENTAVEL=false

DEM=""
[ -f "$ROOT/.claude/.demanda-ativa" ] && DEM="$(tr -d '[:space:]' < "$ROOT/.claude/.demanda-ativa")"

jq -nc --arg dem "$DEM" --arg sid "$SID" --arg root "$ROOT" --arg ts "$AGORA" \
       --argjson epoch "$EPOCH" --argjson ret "$RETENTAVEL" \
  '{dem:$dem, session_id:$sid, root:$root, ts:$ts, epoch:$epoch, retentavel:$ret}' \
  >> "$DEMANDAS_HOME/interrupcoes.jsonl"

ETAPA="?"
D="$ROOT/docs/demands/$DEM"
if [ -n "$DEM" ] && [ -f "$D/STATE.json" ]; then
  ETAPA="$(jq -r '.etapa_atual' "$D/STATE.json")"
  jq_inplace "$D/STATE.json" --arg ts "$AGORA" --arg sid "$SID" \
    '.status="interrompida_limite" | .atualizado_em=$ts | .interrupcoes += [{ts:$ts, etapa:.etapa_atual, session_id:$sid}]'
  printf -- '- %s ⛔ interrompida por limite de uso na etapa `%s`. Retomar: `retomar %s`\n' \
    "$AGORA" "$ETAPA" "$DEM" >> "$D/handoffs.md"
fi

if [ "$RETENTAVEL" = true ]; then
  notificar "✋ ${DEM:-Sessão Claude} parou (limite de uso)" "Etapa: $ETAPA. O vigia tenta retomar sozinho; ou rode: retomar ${DEM:-$SID}"
else
  notificar "✋ ${DEM:-Sessão Claude} parou (créditos)" "Não é retentável automaticamente. Verifique o plano/créditos."
fi
exit 0
