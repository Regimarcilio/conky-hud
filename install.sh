#!/bin/bash
# install.sh — instala Conky Cyberpunk HUD v3.0
set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "🚀 Instalando Cyberpunk HUD v3.0..."

sudo apt update && sudo apt install -y conky-all curl lm-sensors 2>/dev/null || true

mkdir -p ~/.config/conky/scripts ~/.cache/conky ~/.config/autostart

cp -v "$REPO_DIR/conky.conf" ~/.config/conky/conky.conf
cp -v "$REPO_DIR/scripts/btc.sh" ~/.config/conky/scripts/btc.sh
cp -v "$REPO_DIR/scripts/start-conky.sh" ~/.config/conky/scripts/start-conky.sh
chmod +x ~/.config/conky/scripts/*.sh

# Autostart apontando para $HOME real do usuário
sed "s|/home/project|$HOME|g" "$REPO_DIR/autostart/conky.desktop" > ~/.config/autostart/conky.desktop
chmod +x ~/.config/autostart/conky.desktop

echo ""
echo "✅ Instalado! Iniciando..."
~/.config/conky/scripts/start-conky.sh
echo ""
echo "Para matar: killall conky"
