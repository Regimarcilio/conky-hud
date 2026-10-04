#!/bin/bash
# theme-switch.sh — troca paleta do HUD: neon | nord | paper | stealth | kraft
# Uso: theme-switch.sh [neon|nord|paper|stealth|kraft]  (sem arg = ciclo)
REPO_THEMES="$HOME/PROJETOS/conky-hud/themes"
SYS_THEMES="$HOME/.config/conky/themes"
THEME_STATE="$HOME/.cache/conky/theme.current"
mkdir -p "$(dirname "$THEME_STATE")"

cur() { cat "$THEME_STATE" 2>/dev/null || echo "neon"; }

pick="$1"
if [[ -z "$pick" ]]; then
    case "$(cur)" in
        neon) pick="nord" ;;
        nord) pick="kraft" ;;
        kraft) pick="paper" ;;
        paper) pick="stealth" ;;
        *) pick="neon" ;;
    esac
fi
case "$pick" in
    neon|nord|paper|stealth|kraft) ;;
    *) echo "Uso: $0 [neon|nord|paper|stealth|kraft]"; exit 1 ;;
esac

SRC=""
[[ -f "$SYS_THEMES/$pick.conf" ]] && SRC="$SYS_THEMES/$pick.conf"
[[ -z "$SRC" && -f "$REPO_THEMES/$pick.conf" ]] && SRC="$REPO_THEMES/$pick.conf"
if [[ -z "$SRC" ]]; then
    echo "Tema $pick não encontrado em $REPO_THEMES nem $SYS_THEMES"
    exit 1
fi

cp -v "$SRC" "$HOME/.config/conky/conky.conf"
echo "$pick" > "$THEME_STATE"
echo "🎨 Tema ativo: $pick"

# Recarrega conky com o novo tema
if [[ -x "$HOME/.config/conky/scripts/start-conky.sh" ]]; then
    "$HOME/.config/conky/scripts/start-conky.sh"
fi
