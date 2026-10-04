#!/bin/bash
# weather-icon.sh [idx] — símbolo do clima (idx 0=agora, 1=amanhã, 2=+2d)
WXC="$HOME/.cache/conky/weather.json"
IDX="${1:-0}"
CODE=$(jq -r ".current_condition[0].weatherCode // empty" "$WXC" 2>/dev/null)
if [[ "$IDX" != "0" ]]; then
    CODE=$(jq -r ".weather[$IDX].hourly[4].weatherCode // empty" "$WXC" 2>/dev/null)
fi
[[ -z "$CODE" ]] && { echo "☁"; exit 0; }
H=$(date +%H)
DAY=1; [[ "$H" -ge 6 && "$H" -lt 18 ]] && DAY=1 || DAY=0
case "$CODE" in
    113) [[ "$DAY" == "1" ]] && echo "☀" || echo "☾" ;;
    116) [[ "$DAY" == "1" ]] && echo "⛅" || echo "☁" ;;
    119|122) echo "☁" ;;
    143|248|260) echo "≈" ;;
    176|263|266|293|296|299|353|356) echo "☂" ;;
    302|308|359) echo "☂" ;;
    200|386) echo "⚡" ;;
    227|230|281|282|311|314|317|320|323|326|329|332|335|338|350|362|365|368|371|374|377) echo "❄" ;;
    *) echo "☁" ;;
esac
