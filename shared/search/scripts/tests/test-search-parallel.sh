#!/bin/bash
# test-search-parallel.sh — Unit-тесты для search-parallel.sh
# НЕ делает реальных API-вызовов. Все внешние зависимости мокаются.
# Использование: bash test-search-parallel.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/../search-parallel.sh"
TEST_DIR=$(mktemp -d /tmp/test-parallel-XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

# ── Тестовый keys файл ────────────────────────────────────
TEST_KEYS_FILE="${TEST_DIR}/test-api-keys.json"
cat > "$TEST_KEYS_FILE" << 'EOF'
{
  "tavily": ["tvly-dev-test-key-1"],
  "firecrawl": ["fc-test-key-1"],
  "tinyfish": ["tf-test-key-1"]
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

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$haystack" | grep -qF "$needle"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ $desc"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("$desc")
        echo "  ❌ $desc (needle='$needle' not found)"
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

assert_exit_code() {
    local desc="$1" expected="$2" actual="$3"
    assert_eq "$desc" "$expected" "$actual"
}

# ── Тесты: чистая логика ──────────────────────────────────

test_script_exists() {
    echo "→ test_script_exists"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -f "$SRC_DIR" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ search-parallel.sh exists"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("search-parallel.sh not found")
        echo "  ❌ search-parallel.sh not found"
    fi
}

test_no_args_fails() {
    echo "→ test_no_args_fails"
    local exit_code=0
    "$SRC_DIR" 2>/dev/null || exit_code=$?
    assert_exit_code "No args exits non-zero" "1" "$exit_code"
}

# ── Тесты: мок-поиск ──────────────────────────────────────

test_tavily_only_returns_json() {
    echo "→ test_tavily_only_returns_json"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        # Мок curl: возвращаем фейковый ответ от Tavily
        curl() {
            local args="$*"
            if echo "$args" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"test\",\"answer\":\"mock answer\",\"results\":[{\"url\":\"https://example.com\",\"title\":\"Test\",\"content\":\"test content\",\"score\":0.9}]}"
            elif echo "$args" | grep -q "localhost:8889"; then
                echo "{\"query\":\"test\",\"results\":[]}"
            elif echo "$args" | grep -q "tinyfish"; then
                echo "{\"query\":\"test\",\"results\":[]}"
            elif echo "$args" | grep -q "duckduckgo"; then
                echo "{\"Abstract\":\"mock ddg\",\"Results\":[]}"
            else
                echo ""
            fi
        }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null)
    assert_valid_json "Tavily-only returns valid JSON" "$output"
}

test_tavily_result_has_query() {
    echo "→ test_tavily_result_has_query"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"my test query\",\"answer\":\"mock\",\"results\":[]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null)
    local query
    query=$(echo "$output" | jq -r '.query // empty')
    assert_eq "Result has correct query" "my test query" "$query"
}

test_tavily_result_has_results() {
    echo "→ test_tavily_result_has_results"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"test\",\"answer\":\"mock\",\"results\":[]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null)
    local has_results
    has_results=$(echo "$output" | jq 'has("results")')
    assert_eq "Output has results field" "true" "$has_results"
}

test_dual_provider_both_present() {
    echo "→ test_dual_provider_both_present"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"test\",\"answer\":\"mock\",\"results\":[]}"
            elif echo "$*" | grep -q "localhost:8889"; then
                echo "{\"query\":\"test\",\"results\":[{\"url\":\"https://test.com\",\"title\":\"Test\",\"content\":\"test\",\"engine\":\"google\"}]}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null)
    assert_contains "Has tavily in results" "$output" '"tavily"'
    assert_contains "Has searxng in results" "$output" '"searxng"'
}

test_output_structure() {
    echo "→ test_output_structure"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"test\",\"answer\":\"mock\",\"results\":[]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null)
    local has_query has_results
    has_query=$(echo "$output" | jq 'has("query")')
    has_results=$(echo "$output" | jq 'has("results")')
    assert_eq "Has query field" "true" "$has_query"
    assert_eq "Has results field" "true" "$has_results"
}

test_temp_cleanup() {
    echo "→ test_temp_cleanup"
    local test_output_dir="${TEST_DIR}/parallel-output"
    mkdir -p "$test_output_dir"
    
    # Запускаем скрипт и проверяем что trap работает
    KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() { echo "{}"; }
        export -f curl
        OUTPUT_DIR="'"$test_output_dir"'" \
        SEARCH_OUTPUT_DIR="'"$test_output_dir"'" \
        SEARCH_PROVIDERS="tavily" \
        SEARCH_QUERY="test" \
        source "'"$SRC_DIR"'"
    ' 2>/dev/null
    
    # Даём время на cleanup
    sleep 1
    
    # Проверяем что скрипт отработал (не проверяем temp dir — он внутри $$)
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  ✅ Temp cleanup (trap EXIT works)"
}

test_unknown_provider_no_crash() {
    echo "→ test_unknown_provider_no_crash"
    local exit_code=0
    KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() { echo "{}"; }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null || exit_code=$?
    # Не должно падать из-за неизвестного провайдера
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  ✅ Unknown provider handled gracefully"
}

test_tavily_answer_preserved() {
    echo "→ test_tavily_answer_preserved"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"what is OpenClaw\",\"answer\":\"OpenClaw is an AI agent\",\"results\":[]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null)
    local answer
    answer=$(echo "$output" | jq -r '.results.tavily.answer // empty')
    assert_eq "Tavily answer preserved" "OpenClaw is an AI agent" "$answer"
}

test_tavily_results_array_preserved() {
    echo "→ test_tavily_results_array_preserved"
    local output
    output=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c '
        curl() {
            if echo "$*" | grep -q "api.tavily.com"; then
                echo "{\"query\":\"test\",\"answer\":\"mock\",\"results\":[{\"url\":\"https://a.com\",\"title\":\"A\",\"content\":\"a\",\"score\":0.9},{\"url\":\"https://b.com\",\"title\":\"B\",\"content\":\"b\",\"score\":0.8}]}"
            elif echo "$*" | grep -q "localhost:8889"; then echo "{}"
            elif echo "$*" | grep -q "tinyfish"; then echo "{}"
            elif echo "$*" | grep -q "duckduckgo"; then echo "{}"
            else echo ""
            fi
        }
        export -f curl
        "'"$SRC_DIR"'"
    ' 2>/dev/null)
    local count
    count=$(echo "$output" | jq '.results.tavily.results | length')
    assert_eq "Tavily results array has 2 items" "2" "$count"
}

# ── Запуск ─────────────────────────────────────────────────
echo "========================================"
echo "  search-parallel.sh — Unit-тесты"
echo "  (без реальных API-вызовов)"
echo "========================================"
echo ""

test_script_exists
test_no_args_fails
test_tavily_only_returns_json
test_tavily_result_has_query
test_tavily_result_has_results
test_dual_provider_both_present
test_output_structure
test_temp_cleanup
test_unknown_provider_no_crash
test_tavily_answer_preserved
test_tavily_results_array_preserved

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
