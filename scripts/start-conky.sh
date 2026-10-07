#!/bin/bash
# start-conky.sh — wrapper robusto com auto-detecção de hardware
# Detecta iface de rede + sensores de temperatura e gera /tmp/conky.generated.conf
CONF_SRC="$HOME/.config/conky/conky.conf"
CONF_GEN="/tmp/conky.generated.conf"

# --- Rede: iface default ---
IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
if [[ -z "$IFACE" ]]; then
    IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -E '^wl' | head -n1)
fi
if [[ -z "$IFACE" ]]; then
    IFACE="wlxe84e064fbde7"
fi

# --- CPU temp: detecta hwmon por nome (Intel coretemp tem per-core; AMD k10temp só pacote) ---
# Retorna "HWMON T0 T1" (índice hwmon + entradas temp para C0/C1)
detect_cpu_temp() {
    local d name idx
    for d in /sys/class/hwmon/hwmon*; do
        [[ -d "$d" ]] || continue
        name=$(cat "$d/name" 2>/dev/null)
        idx=${d##*hwmon}
        case "$name" in
            coretemp)
                [[ -f "$d/temp2_input" && -f "$d/temp3_input" ]] && { echo "$idx 2 3"; return; } ;;
        esac
    done
    for d in /sys/class/hwmon/hwmon*; do
        [[ -d "$d" ]] || continue
        name=$(cat "$d/name" 2>/dev/null)
        idx=${d##*hwmon}
        case "$name" in
            k10temp|cpu_thermal|acpitz|fam15h_power)
                [[ -f "$d/temp1_input" ]] && { echo "$idx 1 1"; return; } ;;
        esac
    done
    for d in /sys/class/hwmon/hwmon*; do
        [[ -d "$d" ]] || continue
        idx=${d##*hwmon}
        [[ -f "$d/temp1_input" ]] && { echo "$idx 1 1"; return; }
    done
    echo ""
}

CPU_DET=$(detect_cpu_temp)
if [[ -n "$CPU_DET" ]]; then
    read -r CPU_HWMON CPU_T0 CPU_T1 <<< "$CPU_DET"
    CPU_EXPR_C0="\${hwmon $CPU_HWMON temp $CPU_T0}"
    CPU_EXPR_C1="\${hwmon $CPU_HWMON temp $CPU_T1}"
else
    CPU_EXPR_C0='${acpitemp}'
    CPU_EXPR_C1='${acpitemp}'
fi

# Aplica: placeholders do template novo + normaliza confs antigas com hwmon fixo
# (linhas C0 usam expr C0; linhas C1 usam expr C1 — preserva per-core Intel quando detectado)
sed -E "s/wlp2s0|wlan[0-9]+|wlo[0-9]+|wlxe[0-9a-f]{12}|__IFACE__/${IFACE}/g" "$CONF_SRC" > "$CONF_GEN.tmp"
sed -i -e "s/__CPU_TEMP_C0__/${CPU_EXPR_C0}/g; s/__CPU_TEMP_C1__/${CPU_EXPR_C1}/g" "$CONF_GEN.tmp"
# Compat: conf antiga com sensor fixo → C0 ganha expr C0, C1 ganha expr C1
sed -i -E "/C0.*\\\$\{hwmon/s/\\\$\{hwmon [0-9]+ temp [0-9]+\}/${CPU_EXPR_C0}/g" "$CONF_GEN.tmp"
sed -i -E "/C1.*\\\$\{hwmon/s/\\\$\{hwmon [0-9]+ temp [0-9]+\}/${CPU_EXPR_C1}/g" "$CONF_GEN.tmp"
mv "$CONF_GEN.tmp" "$CONF_GEN"

killall -q conky 2>/dev/null
sleep 1
/usr/bin/conky -c "$CONF_GEN" --daemonize --pause=2 > /tmp/conky-start.log 2>&1 < /dev/null
echo "Conky iniciado com interface: $IFACE / CPU temp: ${CPU_EXPR_C0} / ${CPU_EXPR_C1}"
