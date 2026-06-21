#!/bin/bash
# search-key-rotate.sh — Автоматическая ротация API ключей поисковых провайдеров
# Использование: source search-key-rotate.sh && get_tavily_key && get_firecrawl_key
# Хранилище ключей: /root/.openclaw/.api-keys.json (массивы строк)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/tests/lib/key-rotate-functions.sh"

# CLI
case "${1:-}" in
    tavily)    get_tavily_key ;;
    firecrawl) get_firecrawl_key ;;
    tinyfish)  get_tinyfish_key ;;
    status)    status ;;
    *)
        echo "Использование: $0 {tavily|firecrawl|tinyfish|status}"
        echo ""
        echo "  tavily    — получить рабочий ключ Tavily"
        echo "  firecrawl — получить рабочий ключ Firecrawl"
        echo "  tinyfish  — получить ключ TinyFish (round-robin)"
        echo "  status    — показать статус всех ключей"
        exit 1
        ;;
esac
