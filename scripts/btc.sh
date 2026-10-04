#!/bin/bash
# btc.sh v2.0 — Preço BTC com cache + fallback robusto
# Uso no conky: ${execi 60 ~/.config/conky/scripts/btc.sh}
CACHE_DIR="$HOME/.cache/conky"
CACHE_FILE="$CACHE_DIR/btc.cache"
CACHE_MAX_AGE=120
mkdir -p "$CACHE_DIR"

get_price() {
    local resp price
    resp=$(curl -s --max-time 5 "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" 2>/dev/null)
    price=$(echo "$resp" | grep -o '"usd":[0-9.]*' | cut -d':' -f2 | cut -d'.' -f1)
    if [[ -n "$price" && "$price" =~ ^[0-9]+$ ]]; then
        # Formata com separador de milhar conforme locale
        LC_NUMERIC=en_US.UTF-8 printf "\$%'.0f" "$price"
        return 0
    fi
    return 1
}

# Atualiza cache se expirado
if [[ ! -f "$CACHE_FILE" ]] || [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]]; then
    if fresh=$(get_price); then
        echo "$fresh" > "$CACHE_FILE"
    fi
fi

if [[ -f "$CACHE_FILE" ]]; then
    cat "$CACHE_FILE"
else
    # Fallback: tenta ao vivo uma última vez, senão placeholder
    get_price || echo "\$---"
fi
