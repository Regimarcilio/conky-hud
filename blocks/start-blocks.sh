#!/bin/bash
# start-blocks.sh — TESTE: 4 blocos Kraft no rodapé (1360px)
# O card lateral (conky.conf) fica guardado como fallback.
SRC_DIR="$HOME/PROJETOS/conky-hud/blocks"
[[ -d "$SRC_DIR" ]] || SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)/blocks"
killall -q conky 2>/dev/null
sleep 1
IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
for n in 1 2 3 4; do
    sed -E "s/wlp2s0|wlan[0-9]+|wlo[0-9]+|wlxe[0-9a-f]{12}|__IFACE__/${IFACE}/g" \
        "$SRC_DIR/bloco$n-"*.conf > "/tmp/conky-bloco$n.conf"
    setsid nohup /usr/bin/conky -c "/tmp/conky-bloco$n.conf" --pause=2 > "/tmp/conky-bloco$n.log" 2>&1 < /dev/null &
done
echo "4 blocos lançados (iface: $IFACE)."
echo "Para voltar ao card lateral: ~/.config/conky/scripts/start-conky.sh"
