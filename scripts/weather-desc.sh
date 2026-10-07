#!/bin/bash
# weather-desc.sh [idx] — descrição PT-BR do clima
WXC="$HOME/.cache/conky/weather.json"
IDX="${1:-0}"
CODE=$(jq -r ".current_condition[0].weatherCode // empty" "$WXC" 2>/dev/null)
if [[ "$IDX" != "0" ]]; then
    CODE=$(jq -r ".weather[$IDX].hourly[4].weatherCode // empty" "$WXC" 2>/dev/null)
fi
case "$CODE" in
    113) echo "Céu limpo" ;;
    116) echo "Parcialmente nublado" ;;
    119) echo "Nublado" ;;
    122) echo "Encoberto" ;;
    143) echo "Névoa" ;;
    248|260) echo "Nevoeiro" ;;
    176|263) echo "Pancadas leves" ;;
    266|293|296|299) echo "Chuva leve" ;;
    353|356) echo "Pancadas" ;;
    302|308|359) echo "Chuva forte" ;;
    200|386) echo "Trovoada" ;;
    227|230) echo "Neve" ;;
    281|282|311|314|377) echo "Granizo" ;;
    362|365|374) echo "Chuva congelante" ;;
    317|320|323|326|329|332|335|338|350|368|371) echo "Neve/Granizo" ;;
    *) jq -r '.current_condition[0].weatherDesc[0].value // "—"' "$WXC" 2>/dev/null ;;
esac
