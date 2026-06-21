#!/bin/bash
# search-parallel.sh — Параллельный поиск по нескольким провайдерам
# Использование: ./search-parallel.sh "query" [provider1 provider2 ...]
# По умолчанию: tavily searxng tinyfish
# Вывод: JSON с результатами от каждого провайдера

set -euo pipefail

QUERY="${1:?Usage: $0 <query> [providers...]}"
shift
PROVIDERS=("${@:-tavily searxng tinyfish firecrawl}")
KEYS_FILE="${KEYS_FILE:-/root/.openclaw/.api-keys.json}"
OUTPUT_DIR="/tmp/search-parallel-$$"
mkdir -p "$OUTPUT_DIR"

# Гарантированная очистка при выходе
trap 'rm -rf "$OUTPUT_DIR"' EXIT

# Получить ключ из файла
get_key() {
    local provider="$1"
    case "$provider" in
        tavily)    jq -r '.tavily[0]' "$KEYS_FILE" ;;
        firecrawl) jq -r '.firecrawl[0]' "$KEYS_FILE" ;;
        tinyfish)  jq -r '.tinyfish[0]' "$KEYS_FILE" ;;
        *)         echo "" ;;
    esac
}

# Поиск через Tavily
search_tavily() {
    local query="$1"
    local key
    key=$(get_key "tavily")
    [ -z "$key" ] && echo '{"error":"no key"}' && return
    
    curl -s -X POST "https://api.tavily.com/search" \
        -H "Content-Type: application/json" \
        -d "{\"api_key\":\"$key\",\"query\":\"$query\",\"max_results\":5,\"include_answer\":true}" \
        2>/dev/null || echo '{"error":"request failed"}'
}

# Поиск через SearXNG
search_searxng() {
    local query="$1"
    local encoded
    encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))" 2>/dev/null || echo "$query")
    
    curl -s "http://localhost:8889/search?q=${encoded}&format=json&categories=general" \
        --max-time 10 2>/dev/null || echo '{"error":"request failed"}'
}

# Поиск через TinyFish
search_tinyfish() {
    local query="$1"
    local key
    key=$(get_key "tinyfish")
    [ -z "$key" ] && echo '{"error":"no key"}' && return
    
    curl -s "https://api.search.tinyfish.ai?query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))")&location=US&language=en" \
        -H "X-API-Key: $key" \
        --max-time 15 2>/dev/null || echo '{"error":"request failed"}'
}

# Поиск через DuckDuckGo (HTML scrape — Instant Answer API не даёт результатов поиска)
search_duckduckgo() {
    local query="$1"
    local encoded
    encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))")
    # Используем DuckDuckGo HTML версию для получения результатов
    curl -s "https://html.duckduckgo.com/html/?q=${encoded}" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
        --max-time 15 2>/dev/null | python3 -c "
import sys, re
html = sys.stdin.read()
results = []
for m in re.finditer(r'<a rel=\"nofollow\" class=\"result__a\" href=\"([^\"]+)\">.*?<a[^>]+class=\"result__snippet\"[^>]*>(.*?)</a>', html, re.DOTALL):
    url, snippet = m.groups()
    snippet = re.sub(r'<[^>]+>', '', snippet).strip()
    if url and snippet:
        results.append({'url': url, 'snippet': snippet})
print(json.dumps({'results': results[:5]}))
" 2>/dev/null || echo '{"error":"request failed"}'
}

# Поиск через Firecrawl (web_fetch + extract)
search_firecrawl() {
    local query="$1"
    local key
    key=$(get_key "firecrawl")
    [ -z "$key" ] && echo '{"error":"no key"}' && return
    
    curl -s -X POST "https://api.firecrawl.dev/v1/search" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $key" \
        -d "{\"query\":\"$query\",\"limit\":5}" \
        --max-time 30 2>/dev/null || echo '{"error":"request failed"}'
}

# Поиск через Parallel Free
search_parallel_free() {
    local query="$1"
    curl -s -X POST "https://api.parallel.ai/v1/search" \
        -H "Content-Type: application/json" \
        -d "{\"query\":\"$query\",\"max_results\":5}" \
        --max-time 15 2>/dev/null || echo '{"error":"request failed"}'
}

# Запустить все запросы параллельно
PIDS=()
for provider in "${PROVIDERS[@]}"; do
    case "$provider" in
        tavily)     search_tavily "$QUERY" > "$OUTPUT_DIR/tavily.json" & PIDS+=("$!") ;;
        searxng)    search_searxng "$QUERY" > "$OUTPUT_DIR/searxng.json" & PIDS+=("$!") ;;
        tinyfish)   search_tinyfish "$QUERY" > "$OUTPUT_DIR/tinyfish.json" & PIDS+=("$!") ;;
        duckduckgo) search_duckduckgo "$QUERY" > "$OUTPUT_DIR/duckduckgo.json" & PIDS+=("$!") ;;
        firecrawl)  search_firecrawl "$QUERY" > "$OUTPUT_DIR/firecrawl.json" & PIDS+=("$!") ;;
        parallel-free) search_parallel_free "$QUERY" > "$OUTPUT_DIR/parallel-free.json" & PIDS+=("$!") ;;
        *)          echo "Unknown provider: $provider" >&2 ;;
    esac
done

# Ждать завершения всех запросов
for pid in "${PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
done

# Собрать результаты в один JSON
export SEARCH_OUTPUT_DIR="$OUTPUT_DIR"
export SEARCH_PROVIDERS=$(printf '%s\n' "${PROVIDERS[@]}")
export SEARCH_QUERY="$QUERY"

python3 << 'PYEOF'
import json, os, sys

results = {}
output_dir = os.environ.get('SEARCH_OUTPUT_DIR', '')
providers = os.environ.get('SEARCH_PROVIDERS', '').split('\n')

for provider in providers:
    if not provider:
        continue
    filepath = os.path.join(output_dir, f'{provider}.json')
    if os.path.exists(filepath):
        try:
            with open(filepath) as f:
                data = json.load(f)
            results[provider] = data
        except json.JSONDecodeError:
            results[provider] = {'error': 'invalid json'}

print(json.dumps({'query': os.environ.get('SEARCH_QUERY', ''), 'results': results}, indent=2, ensure_ascii=False))
PYEOF

# Очистка через trap (EXIT)
