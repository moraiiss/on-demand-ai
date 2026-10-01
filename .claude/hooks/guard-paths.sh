#!/usr/bin/env bash
# PreToolUse (Write|Edit|MultiEdit|NotebookEdit)
# Bloqueia escrita fora dos prefixos permitidos, passados como argumentos.
# Prefixos relativos são resolvidos a partir da raiz do repositório (ou do worktree).
set -uo pipefail
INPUT="$(cat)"
FILE="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$INPUT")"
[ -z "$FILE" ] && exit 0

CWD="$(jq -r '.cwd // empty' <<<"$INPUT")"
ROOT="$(git -C "${CWD:-.}" rev-parse --show-toplevel 2>/dev/null || echo "${CWD:-$PWD}")"

case "$FILE" in /*) ABS="$FILE" ;; *) ABS="$ROOT/$FILE" ;; esac
case "$ABS" in */../*|*/..) echo "Bloqueado: caminho com '..' não é permitido ($FILE)." >&2; exit 2 ;; esac

for p in "$@"; do
  case "$p" in
    /*) pref="$p" ;;
    "~"*) pref="$HOME${p#\~}" ;;
    *) pref="$ROOT/$p" ;;
  esac
  pref="${pref%/}"
  case "$ABS" in "$pref"|"$pref"/*) exit 0 ;; esac
done

echo "Bloqueado pelo guardrail: este agente só pode escrever em [$*]. Tentativa: $FILE" >&2
exit 2
