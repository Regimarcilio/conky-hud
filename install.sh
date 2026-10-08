#!/bin/bash
# install.sh — instala DOSSIÊ KRAFT 1974 v3.3.1 (+ temas/*, blocos, cluster)
set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "🚀 Instalando DOSSIÊ KRAFT 1974 v3.3.1..."

sudo apt update && sudo apt install -y conky-all curl lm-sensors python3-gi 2>/dev/null || true

mkdir -p ~/.config/conky/scripts ~/.config/conky/themes ~/.config/conky/blocks ~/.config/conky/cluster ~/.cache/conky ~/.config/autostart

cp -v "$REPO_DIR/conky.conf" ~/.config/conky/conky.conf
cp -v "$REPO_DIR"/chip.png "$REPO_DIR"/dwn.png "$REPO_DIR"/line.png "$REPO_DIR"/micro.png "$REPO_DIR"/thermo.png "$REPO_DIR"/up.png ~/.config/conky/ 2>/dev/null || true
cp -v "$REPO_DIR/themes/"*.conf ~/.config/conky/themes/
cp -v "$REPO_DIR/blocks/"*.conf ~/.config/conky/blocks/ 2>/dev/null || true
cp -v "$REPO_DIR/cluster/kraft-cluster.conf" "$REPO_DIR/cluster/kraft-cluster.lua" ~/.config/conky/cluster/ 2>/dev/null || true
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
echo "Temas: ~/.config/conky/scripts/theme-switch.sh [kraft|neon|paper|stealth|nord|sage]"
echo "Para matar: killall conky; pkill -f theme-bar.py"
