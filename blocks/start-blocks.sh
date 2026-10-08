#!/bin/bash
# start-blocks.sh — TESTE: 4 blocos Kraft no rodapé (1360px)
# O card lateral (conky.conf) fica guardado como fallback.
SRC_DIR="$HOME/PROJETOS/conky-hud/blocks"
[[ -d "$SRC_DIR" ]] || SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)/blocks"
killall -q conky 2>/dev/null
sleep 1
IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
[[ -z "$IFACE" ]] && IFACE="wlxe84e064fbde7"
# CPU temp: mesma detecção do start-conky.sh (coretemp per-core > k10temp pacote > qq temp1 > acpitemp)
detect_cpu_temp() {
    local d name idx
    for d in /sys/class/hwmon/hwmon*; do
        [[ -d "$d" ]] || continue
        name=$(cat "$d/name" 2>/dev/null); idx=${d##*hwmon}
        [[ "$name" == "coretemp" && -f "$d/temp2_input" && -f "$d/temp3_input" ]] && { echo "$idx 2 3"; return; }
    done
    for d in /sys/class/hwmon/hwmon*; do
        [[ -d "$d" ]] || continue
        name=$(cat "$d/name" 2>/dev/null); idx=${d##*hwmon}
        case "$name" in k10temp|cpu_thermal|acpitz|fam15h_power)
            [[ -f "$d/temp1_input" ]] && { echo "$idx 1 1"; return; } ;; esac
    done
    for d in /sys/class/hwmon/hwmon*; do
        [[ -d "$d" ]] || continue; idx=${d##*hwmon}
        [[ -f "$d/temp1_input" ]] && { echo "$idx 1 1"; return; }
    done
    echo ""
}
CPU_DET=$(detect_cpu_temp)
if [[ -n "$CPU_DET" ]]; then
    read -r CPU_HWMON CPU_T0 CPU_T1 <<< "$CPU_DET"
    CPU_EXPR_C0="\${hwmon $CPU_HWMON temp $CPU_T0}"; CPU_EXPR_C1="\${hwmon $CPU_HWMON temp $CPU_T1}"
else
    CPU_EXPR_C0='${acpitemp}'; CPU_EXPR_C1='${acpitemp}'
fi
for n in 1 2 3 4; do
    sed -E "s/wlp2s0|wlan[0-9]+|wlo[0-9]+|wlxe[0-9a-f]+|__IFACE__/${IFACE}/g" \
        "$SRC_DIR/bloco$n-"*.conf > "/tmp/conky-bloco$n.conf"
    sed -i -e "s/__CPU_TEMP_C0__/${CPU_EXPR_C0}/g; s/__CPU_TEMP_C1__/${CPU_EXPR_C1}/g" "/tmp/conky-bloco$n.conf"
    sed -i -E "/C0.*\\\$\{hwmon/s/\\\$\{hwmon [0-9]+ temp [0-9]+\}/${CPU_EXPR_C0}/g; /C1.*\\\$\{hwmon/s/\\\$\{hwmon [0-9]+ temp [0-9]+\}/${CPU_EXPR_C1}/g" "/tmp/conky-bloco$n.conf"
    setsid nohup /usr/bin/conky -c "/tmp/conky-bloco$n.conf" --pause=2 > "/tmp/conky-bloco$n.log" 2>&1 < /dev/null &
done
echo "4 blocos lançados (iface: $IFACE / CPU temp: ${CPU_EXPR_C0} / ${CPU_EXPR_C1})."
echo "Para voltar ao card lateral: ~/.config/conky/scripts/start-conky.sh"
