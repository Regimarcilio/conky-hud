#!/bin/bash
# start-cluster.sh — sobe o cluster Kraft (bloco único à direita)
# Uso: start-cluster.sh | Guarda o card/4-blocos como fallback (não mexe no autostart)
SRC="$HOME/PROJETOS/conky-hud/cluster"
DST="$HOME/.config/conky/cluster"
mkdir -p "$DST"
cp -v "$SRC/kraft-cluster.lua" "$SRC/kraft-cluster.conf" "$DST/"
IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
[ -z "$IFACE" ] && IFACE="wlxe84e064fbde7"
sed -i "s|__HOME__|$HOME|g" "$DST/kraft-cluster.conf"
sed -i "s|__IFACE__|$IFACE|g" "$DST/kraft-cluster.lua"
killall -q conky 2>/dev/null
sleep 1
setsid nohup /usr/bin/conky -c "$DST/kraft-cluster.conf" --pause=1 > /tmp/conky-cluster.log 2>&1 < /dev/null &
echo "Cluster Kraft lançado (iface: $IFACE)."
echo "Para voltar: ~/.config/conky/blocks/start-blocks.sh (blocos) ou ~/.config/conky/scripts/start-conky.sh (card)"
