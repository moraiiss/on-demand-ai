#!/usr/bin/env bash
# Funções compartilhadas pelos hooks e scripts de demandas.

DEMANDAS_HOME="${DEMANDAS_HOME:-$HOME/.claude/demandas}"

notificar() {  # notificar "título" "mensagem"
  local titulo="$1" msg="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical "$titulo" "$msg" 2>/dev/null || true
  elif command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${msg//\"/\'}\" with title \"${titulo//\"/\'}\"" 2>/dev/null || true
  fi
  printf '\a[%s] %s — %s\n' "$(date '+%F %T')" "$titulo" "$msg" >> "$DEMANDAS_HOME/notificacoes.log"
}

agora_utc() { date -u +%FT%TZ; }

# Atualiza um JSON in-place com um filtro jq: jq_inplace arquivo 'filtro' [args jq...]
jq_inplace() {
  local f="$1"; shift
  local tmp; tmp="$(mktemp)"
  if jq "$@" "$f" > "$tmp"; then mv "$tmp" "$f"; else rm -f "$tmp"; return 1; fi
}
