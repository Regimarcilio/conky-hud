#!/bin/bash
# start-conky.sh — wrapper robusto com auto-detecção de interface
# Detecta iface default e gera /tmp/conky.generated.conf antes de iniciar
CONF_SRC="$HOME/.config/conky/conky.conf"
CONF_GEN="/tmp/conky.generated.conf"

IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
if [[ -z "$IFACE" ]]; then
    IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -E '^wl' | head -n1)
fi
if [[ -z "$IFACE" ]]; then
    IFACE="wlxe84e064fbde7"
fi

# Substitui qualquer iface wifi conhecido pelo detectado (mantém template intacto)
sed -E "s/wlp2s0|wlan[0-9]+|wlo[0-9]+|wlxe[0-9a-f]{12}|__IFACE__/${IFACE}/g" "$CONF_SRC" > "$CONF_GEN"

killall -q conky 2>/dev/null
sleep 1
/usr/bin/conky -c "$CONF_GEN" --daemonize --pause=2
echo "Conky iniciado com interface: $IFACE"
