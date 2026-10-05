#!/usr/bin/env bash
# Instala o pipeline de demandas neste repositório (rode a partir da raiz do repo).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
H="$HOME/.claude/demandas"

echo "→ Verificando dependências"
for c in git jq claude; do command -v "$c" >/dev/null || { echo "  ✗ falta: $c"; exit 1; }; done
command -v gh >/dev/null || echo "  ! gh (GitHub CLI) não encontrado: a abertura de PR vai falhar"
command -v notify-send >/dev/null || echo "  ! notify-send não encontrado: notificações só no log ($H/notificacoes.log)"

echo "→ Criando $H"
mkdir -p "$H/ativas"
touch "$H/registry.tsv" "$H/interrupcoes.jsonl" "$H/retentativas.jsonl"

echo "→ Permissões de execução"
chmod +x .claude/hooks/*.sh scripts/demandas/demanda scripts/demandas/retomar scripts/demandas/vigia-limites scripts/demandas/atualizar

echo "→ Comandos em ~/.local/bin"
mkdir -p "$HOME/.local/bin"
for s in demanda retomar vigia-limites; do ln -sf "$ROOT/scripts/demandas/$s" "$HOME/.local/bin/$s"; done
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "  ! adicione ~/.local/bin ao PATH no ~/.zshrc";; esac

echo "→ .gitignore"
awk '$1 == "ignorar" {print $2}' scripts/demandas/manifesto | while IFS= read -r l; do
  grep -qxF -- "$l" .gitignore 2>/dev/null || echo "$l" >> .gitignore
done

if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
  echo "→ Vigia de limites (systemd --user timer)"
  mkdir -p "$HOME/.config/systemd/user"
  cp scripts/demandas/systemd/demandas-vigia.* "$HOME/.config/systemd/user/"
  systemctl --user daemon-reload
  systemctl --user enable --now demandas-vigia.timer
  systemctl --user list-timers demandas-vigia.timer --no-pager || true
else
  echo "→ Sem systemd de usuário. Adicione ao crontab (crontab -e):"
  echo "  */15 * * * * PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin $HOME/.local/bin/vigia-limites >> $H/vigia.log 2>&1"
fi

cat <<MSG

✅ Instalado. Próximos passos:
  1. Preencha .claude/projeto.md (contexto do projeto lido pelo staff-engineer)
  2. (Opcional) cp .claude/quality-gate.conf.example .claude/quality-gate.conf
  3. Abra 'claude' uma vez neste repo e aceite o diálogo de confiança (necessário para hooks dos agentes)
  4. Teste: demanda --nome piloto "descreva aqui uma demanda pequena"
  Para atualizar o pipeline depois: ./scripts/demandas/atualizar
MSG
