#!/bin/bash
# install.sh — instala Conky HUD v3.1 (3 temas + theme-bar)
set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "🚀 Instalando Conky HUD v3.1 (neon/paper/stealth)..."

sudo apt update && sudo apt install -y conky-all curl lm-sensors python3-gi 2>/dev/null || true

mkdir -p ~/.config/conky/scripts ~/.config/conky/themes ~/.cache/conky ~/.config/autostart

cp -v "$REPO_DIR/conky.conf" ~/.config/conky/conky.conf
cp -v "$REPO_DIR/themes/"*.conf ~/.config/conky/themes/
cp -v "$REPO_DIR/scripts/btc.sh" "$REPO_DIR/scripts/start-conky.sh" "$REPO_DIR/scripts/theme-switch.sh" "$REPO_DIR/scripts/start-hud.sh" ~/.config/conky/scripts/
cp -v "$REPO_DIR/scripts/theme-bar.py" ~/.config/conky/scripts/
chmod +x ~/.config/conky/scripts/*.sh ~/.config/conky/scripts/*.py

# Autostart apontando para $HOME real do usuário
sed "s|/home/project|$HOME|g" "$REPO_DIR/autostart/conky.desktop" > ~/.config/autostart/conky.desktop
chmod +x ~/.config/autostart/conky.desktop

echo ""
echo "✅ Instalado! Iniciando HUD + barrinha..."
~/.config/conky/scripts/start-hud.sh
echo ""
echo "Temas: ~/.config/conky/scripts/theme-switch.sh [neon|paper|stealth]"
echo "Para matar: killall conky; pkill -f theme-bar.py"
