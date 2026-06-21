#!/bin/bash
# key-rotate-functions.sh — Только функции из search-key-rotate.sh (без CLI)
# Для использования в тестах через source

set -euo pipefail

KEYS_FILE="${KEYS_FILE:-/root/.openclaw/.api-keys.json}"
STATE_FILE="${STATE_FILE:-/tmp/search-key-rotate-state.json}"

init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"tavily_idx":0,"firecrawl_idx":0,"tinyfish_idx":0}' > "$STATE_FILE"
    fi
}

get_idx() {
    local provider="$1"
    jq -r ".${provider}_idx" "$STATE_FILE"
}

set_idx() {
    local provider="$1"
    local idx="$2"
    jq ".${provider}_idx = $idx" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

get_key_by_idx() {
    local provider="$1"
    local idx="$2"
    jq -r --arg p "$provider" --argjson i "$idx" '.[$p][$i]' "$KEYS_FILE"
}

get_key_count() {
    local provider="$1"
    jq --arg p "$provider" '.[$p] | length' "$KEYS_FILE"
}

check_tavily_balance() {
    local key="$1"
    curl -s "https://api.tavily.com/usage" \
        -H "Authorization: Bearer $key" 2>/dev/null | jq -c '{usage: (.key.usage // "error"), limit: (.key.limit // 1000)}'
}

check_firecrawl_balance() {
    local key="$1"
    local remaining
    remaining=$(curl -s "https://api.firecrawl.dev/v2/team/credit-usage" \
        -H "Authorization: Bearer $key" 2>/dev/null | jq -r '.data.remainingCredits // "error"')
    echo "$remaining"
}

get_tavily_key() {
    init_state
    local idx
    idx=$(get_idx "tavily")
    local count
    count=$(get_key_count "tavily")
    
    for ((i=0; i<count; i++)); do
        local current_idx=$(( (idx + i) % count ))
        local key
        key=$(get_key_by_idx "tavily" "$current_idx")
        local balance_info
        balance_info=$(check_tavily_balance "$key")
        
        local usage
        usage=$(echo "$balance_info" | jq -r '.usage')
        local limit
        limit=$(echo "$balance_info" | jq -r '.limit')
        
        if [ "$usage" != "error" ] && [ "$usage" != "null" ]; then
            local remaining=$((limit - usage))
            if [ "$remaining" -gt 10 ]; then
                set_idx "tavily" "$current_idx"
                echo "$key"
                return 0
            fi
        fi
    done
    
    echo "ERROR: No Tavily keys available" >&2
    return 1
}

get_firecrawl_key() {
    init_state
    local idx
    idx=$(get_idx "firecrawl")
    local count
    count=$(get_key_count "firecrawl")
    
    for ((i=0; i<count; i++)); do
        local current_idx=$(( (idx + i) % count ))
        local key
        key=$(get_key_by_idx "firecrawl" "$current_idx")
        local remaining
        remaining=$(check_firecrawl_balance "$key")
        
        if [ "$remaining" != "error" ] && [ "$remaining" != "null" ]; then
            if [ "$remaining" -gt 10 ]; then
                set_idx "firecrawl" "$current_idx"
                echo "$key"
                return 0
            fi
        fi
    done
    
    echo "ERROR: No Firecrawl keys available" >&2
    return 1
}

get_tinyfish_key() {
    init_state
    local idx
    idx=$(get_idx "tinyfish")
    local count
    count=$(get_key_count "tinyfish")
    local key
    key=$(get_key_by_idx "tinyfish" "$idx")
    set_idx "tinyfish" "$(( (idx + 1) % count ))"
    echo "$key"
}

status() {
    echo "=== Статус ключей ==="
    echo ""
    
    echo "--- Tavily ---"
    local tavily_count
    tavily_count=$(get_key_count "tavily")
    for ((i=0; i<tavily_count; i++)); do
        local key
        key=$(get_key_by_idx "tavily" "$i")
        local balance_info
        balance_info=$(check_tavily_balance "$key")
        local usage
        usage=$(echo "$balance_info" | jq -r '.usage')
        local limit
        limit=$(echo "$balance_info" | jq -r '.limit')
        echo "  Key $((i+1)): $usage / $limit"
    done
    
    echo ""
    echo "--- Firecrawl ---"
    local fc_count
    fc_count=$(get_key_count "firecrawl")
    for ((i=0; i<fc_count; i++)); do
        local key
        key=$(get_key_by_idx "firecrawl" "$i")
        local remaining
        remaining=$(check_firecrawl_balance "$key")
        echo "  Key $((i+1)): $remaining credits remaining"
    done
    
    echo ""
    echo "--- TinyFish ---"
    local tf_count
    tf_count=$(get_key_count "tinyfish")
    for ((i=0; i<tf_count; i++)); do
        echo "  Key $((i+1)): free"
    done
}
