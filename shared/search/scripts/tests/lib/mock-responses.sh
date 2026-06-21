#!/bin/bash
# mock-responses.sh — Фиксированные mock-ответы для тестов
# Использование: source mock-responses.sh, затем export -f curl

MOCK_TAVILY_OK='{"key":{"usage":100,"limit":1000}}'
MOCK_TAVILY_EXHAUSTED='{"key":{"usage":995,"limit":1000}}'
MOCK_TAVILY_HALF='{"key":{"usage":500,"limit":1000}}'
MOCK_FIRECRAWL_OK='100'
MOCK_FIRECRAWL_EXHAUSTED='5'

# Глобальный счётчик для последовательных ответов
MOCK_COUNTER_FILE="/tmp/mock-counter-$$"

mock_curl() {
    local args="$*"
    local counter=0
    
    # Читаем счётчик
    if [ -f "$MOCK_COUNTER_FILE" ]; then
        counter=$(cat "$MOCK_COUNTER_FILE")
    fi
    counter=$((counter + 1))
    echo "$counter" > "$MOCK_COUNTER_FILE"
    
    # Определяем ответ по URL
    if echo "$args" | grep -q "api.tavily.com/usage"; then
        if [ "$counter" -eq 1 ]; then
            echo "$MOCK_TAVILY_EXHAUSTED"
        else
            echo "$MOCK_TAVILY_HALF"
        fi
    elif echo "$args" | grep -q "api.firecrawl.dev"; then
        if [ "$counter" -eq 1 ]; then
            echo "$MOCK_FIRECRAWL_EXHAUSTED"
        else
            echo "$MOCK_FIRECRAWL_OK"
        fi
    else
        echo ""
    fi
}

mock_reset_counter() {
    rm -f "$MOCK_COUNTER_FILE"
}

export -f mock_curl mock_reset_counter MOCK_TAVILY_OK MOCK_TAVILY_EXHAUSTED MOCK_TAVILY_HALF MOCK_FIRECRAWL_OK MOCK_FIRECRAWL_EXHAUSTED