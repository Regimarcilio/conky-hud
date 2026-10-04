#!/bin/bash
# weather.sh — clima via wttr.in (sem chave) + geolocalização via ip-api
# Cache: ~/.cache/conky/weather.json (30 min) / geo.json (7 dias)
CACHE_DIR="$HOME/.cache/conky"
WXC="$CACHE_DIR/weather.json"
GEO="$CACHE_DIR/geo.json"
mkdir -p "$CACHE_DIR"

if [[ ! -f "$GEO" ]] || [[ $(($(date +%s) - $(stat -c %Y "$GEO" 2>/dev/null || echo 0))) -gt 604800 ]]; then
    curl -s --max-time 10 "http://ip-api.com/json/?fields=status,city" -o "$GEO.tmp" 2>/dev/null \
        && mv "$GEO.tmp" "$GEO"
fi

CITY=$(jq -r '.city // "Joinville"' "$GEO" 2>/dev/null)
Q=$(echo "$CITY" | tr ' ' '+')

if [[ ! -f "$WXC" ]] || [[ $(($(date +%s) - $(stat -c %Y "$WXC" 2>/dev/null || echo 0))) -gt 1800 ]]; then
    curl -s --max-time 12 "https://wttr.in/${Q}?format=j1" -o "$WXC.tmp" 2>/dev/null \
        && jq -e '.current_condition' "$WXC.tmp" >/dev/null 2>&1 \
        && mv "$WXC.tmp" "$WXC"
fi

[[ -f "$WXC" ]] && echo "OK ${CITY} $(date '+%H:%M')" || echo "OFFLINE"
