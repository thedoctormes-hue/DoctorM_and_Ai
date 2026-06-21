#!/bin/bash
# test-integration.sh — Интеграционные тесты: key-rotate + parallel
# НЕ делает реальных API-вызовов. Все curl-вызовы мокаются.
# Использование: bash test-integration.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_ROTATE="${SCRIPT_DIR}/../search-key-rotate.sh"
SEARCH_PARALLEL="${SCRIPT_DIR}/../search-parallel.sh"
TEST_DIR=$(mktemp -d /tmp/test-integration-XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

# ── Тестовый keys файл ────────────────────────────────────
TEST_KEYS_FILE="${TEST_DIR}/test-api-keys.json"
cat > "$TEST_KEYS_FILE" << 'EOF'
{
  "tavily": [
    "tvly-dev-AAAA-test-key-1",
    "tvly-dev-BBBB-test-key-2"
  ],
  "firecrawl": [
    "fc-AAAA-test-key-1"
  ],
  "tinyfish": [
    "tf-AAAA-test-key-1"
  ]
}
EOF

# ── Фреймворк ──────────────────────────────────────────────
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=()

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ $desc"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("$desc")
        echo "  ❌ $desc"
        echo "     expected: '$expected'"
        echo "     actual:   '$actual'"
    fi
}

assert_not_empty() {
    local desc="$1" value="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ $desc"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("$desc")
        echo "  ❌ $desc (value='$value')"
    fi
}

assert_valid_json() {
    local desc="$1" value="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$value" | jq empty 2>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ $desc"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("$desc")
        echo "  ❌ $desc (invalid JSON)"
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$haystack" | grep -qF "$needle"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ $desc"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("$desc")
        echo "  ❌ $desc"
    fi
}

# ── Тесты ──────────────────────────────────────────────────

test_key_rotate_then_parallel() {
    echo "→ test_key_rotate_then_parallel"
    # Получаем ключ через key-rotate (с мок-curl)
    local tavily_key
    tavily_key=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="${TEST_DIR}/state-1.json" bash -c '
        curl() {
            echo "{\"key\":{\"usage\":100,\"limit\":1000}}"
        }
        export -f curl
        source "'"$KEY_ROTATE"'"
        get_tavily_key
    ')
    assert_not_empty "Got Tavily key from rotate" "$tavily_key"
    
    # Используем этот ключ в parallel search (с мок-curl)
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"integration test\",\"answer\":\"mock answer\",\"results\":[]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SEARCH_PARALLEL"'"
    ' 2>/dev/null)
    assert_valid_json "Parallel search returns JSON" "$output"
}

test_all_providers_status() {
    echo "→ test_all_providers_status"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="${TEST_DIR}/state-2.json" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"key\":{\"usage\":50,\"limit\":1000}}"
            elif echo "$*" | grep -q "firecrawl"; then
                echo "100"
            else echo ""
            fi
        }
        export -f curl
        source "'"$KEY_ROTATE"'"
        status
    ')
    assert_contains "Status has Tavily" "$output" "Tavily"
    assert_contains "Status has Firecrawl" "$output" "Firecrawl"
    assert_contains "Status has TinyFish" "$output" "TinyFish"
}

test_parallel_all_providers() {
    echo "→ test_parallel_all_providers"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"test\",\"answer\":\"mock\",\"results\":[]}"
            elif echo "$*" | grep -q "localhost:8889"; then
                echo "{\"query\":\"test\",\"results\":[]}"
            elif echo "$*" | grep -q "tinyfish"; then
                echo "{\"query\":\"test\",\"results\":[]}"
            elif echo "$*" | grep -q "duckduckgo"; then
                echo "{\"Abstract\":\"test\",\"Results\":[]}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SEARCH_PARALLEL"'"
    ' 2>/dev/null)
    assert_valid_json "All providers return JSON" "$output"
    
    local provider_count
    provider_count=$(echo "$output" | jq '.results | keys | length')
    assert_eq "All 4 providers present" "4" "$provider_count"
}

test_tavily_key_consistency() {
    echo "→ test_tavily_key_consistency"
    local rotate_key file_key
    rotate_key=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="${TEST_DIR}/state-3.json" bash -c '
        curl() { echo "{\"key\":{\"usage\":100,\"limit\":1000}}"; }
        export -f curl
        source "'"$KEY_ROTATE"'"
        get_tavily_key
    ')
    file_key=$(jq -r '.tavily[0]' "$TEST_KEYS_FILE")
    assert_eq "Rotate key matches file key" "$file_key" "$rotate_key"
}

test_parallel_result_structure() {
    echo "→ test_parallel_result_structure"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"structure test\",\"answer\":\"mock\",\"results\":[{\"url\":\"https://test.com\",\"title\":\"T\",\"content\":\"c\",\"score\":0.5}]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SEARCH_PARALLEL"'"
    ' 2>/dev/null)
    
    local has_query has_results
    has_query=$(echo "$output" | jq 'has("query")')
    has_results=$(echo "$output" | jq 'has("results")')
    assert_eq "Has query field" "true" "$has_query"
    assert_eq "Has results field" "true" "$has_results"
}

test_end_to_end_search() {
    echo "→ test_end_to_end_search"
    # Полный цикл: status → get key → search → check result
    
    # 1. Status
    local status_output
    status_output=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="${TEST_DIR}/state-e2e.json" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"key\":{\"usage\":50,\"limit\":1000}}"
            elif echo "$*" | grep -q "firecrawl"; then echo "100"
            else echo ""
            fi
        }
        export -f curl
        source "'"$KEY_ROTATE"'"
        status
    ')
    assert_contains "E2E: status OK" "$status_output" "Статус"
    
    # 2. Search
    local search_output
    search_output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"e2e test\",\"answer\":\"e2e answer\",\"results\":[{\"url\":\"https://e2e.com\",\"title\":\"E2E\",\"content\":\"test\",\"score\":0.9}]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SEARCH_PARALLEL"'"
    ' 2>/dev/null)
    assert_valid_json "E2E: search returns JSON" "$search_output"
    
    # 3. Check result has data
    local result_count
    result_count=$(echo "$search_output" | jq '.results.tavily.results | length')
    assert_eq "E2E: found 1 result" "1" "$result_count"
}

test_rotation_fallback_on_exhausted() {
    echo "→ test_rotation_fallback_on_exhausted"
    # Key 0 exhausted (995/1000), key 1 ok (100/1000)
    local result
    result=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="${TEST_DIR}/state-fallback.json" bash -c '
        CALL_COUNT=0
        curl() {
            CALL_COUNT=$((CALL_COUNT + 1))
            if [ "$CALL_COUNT" -eq 1 ]; then
                echo "{\"key\":{\"usage\":995,\"limit\":1000}}"
            else
                echo "{\"key\":{\"usage\":100,\"limit\":1000}}"
            fi
        }
        export -f curl
        source "'"$KEY_ROTATE"'"
        get_tavily_key
    ')
    assert_eq "Falls back to second key" "tvly-dev-BBBB-test-key-2" "$result"
}

# ── Запуск ─────────────────────────────────────────────────
echo "========================================"
echo "  Интеграционные тесты"
echo "  (без реальных API-вызовов)"
echo "========================================"
echo ""

test_key_rotate_then_parallel
test_all_providers_status
test_parallel_all_providers
test_tavily_key_consistency
test_parallel_result_structure
test_end_to_end_search
test_rotation_fallback_on_exhausted

# ── Итог ──────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Итого: $TESTS_RUN тестов"
echo "  ✅ Пройдено: $TESTS_PASSED"
echo "  ❌ Провалено: $TESTS_FAILED"
echo "========================================"

if [ ${#FAILURES[@]} -gt 0 ]; then
    echo ""
    echo "  Проваленные тесты:"
    for f in "${FAILURES[@]}"; do
        echo "    - $f"
    done
fi

[ "$TESTS_FAILED" -eq 0 ]
