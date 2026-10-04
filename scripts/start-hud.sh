#!/bin/bash
# start-hud.sh — inicia Conky (tema atual) + mini-bar de botões
~/.config/conky/scripts/start-conky.sh
sleep 1
pkill -f "theme-bar[.]py" 2>/dev/null; sleep 1
setsid nohup python3 ~/.config/conky/scripts/theme-bar.py > /tmp/theme-bar.log 2>&1 < /dev/null &
echo "HUD + theme-bar iniciados."
