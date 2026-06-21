#!/bin/bash
# test-search-key-rotate.sh — Unit-тесты для search-key-rotate.sh
# НЕ делает реальных API-вызовов. Все внешние зависимости мокаются.
# Использование: bash test-search-key-rotate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib/key-rotate-functions.sh"
TEST_DIR=$(mktemp -d /tmp/test-key-rotate-XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

# ── Тестовый keys файл ────────────────────────────────────
TEST_KEYS_FILE="${TEST_DIR}/test-api-keys.json"
cat > "$TEST_KEYS_FILE" << 'EOF'
{
  "tavily": [
    "tvly-dev-AAAA-test-key-1",
    "tvly-dev-BBBB-test-key-2",
    "tvly-dev-CCCC-test-key-3"
  ],
  "firecrawl": [
    "fc-AAAA-test-key-1",
    "fc-BBBB-test-key-2"
  ],
  "tinyfish": [
    "tf-AAAA-test-key-1",
    "tf-BBBB-test-key-2",
    "tf-CCCC-test-key-3"
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

# ── Тесты: чистая логика (без API) ────────────────────────

test_get_key_count_tavily() {
    echo "→ test_get_key_count_tavily"
    local count
    count=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c "source '${LIB_DIR}'; get_key_count 'tavily'")
    assert_eq "Tavily key count = 3" "3" "$count"
}

test_get_key_count_firecrawl() {
    echo "→ test_get_key_count_firecrawl"
    local count
    count=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c "source '${LIB_DIR}'; get_key_count 'firecrawl'")
    assert_eq "Firecrawl key count = 2" "2" "$count"
}

test_get_key_count_tinyfish() {
    echo "→ test_get_key_count_tinyfish"
    local count
    count=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c "source '${LIB_DIR}'; get_key_count 'tinyfish'")
    assert_eq "TinyFish key count = 3" "3" "$count"
}

test_get_key_by_idx_0() {
    echo "→ test_get_key_by_idx_0"
    local key
    key=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c "source '${LIB_DIR}'; get_key_by_idx 'tavily' 0")
    assert_eq "First Tavily key" "tvly-dev-AAAA-test-key-1" "$key"
}

test_get_key_by_idx_1() {
    echo "→ test_get_key_by_idx_1"
    local key
    key=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c "source '${LIB_DIR}'; get_key_by_idx 'tavily' 1")
    assert_eq "Second Tavily key" "tvly-dev-BBBB-test-key-2" "$key"
}

test_get_key_by_idx_last() {
    echo "→ test_get_key_by_idx_last"
    local key
    key=$(KEYS_FILE="$TEST_KEYS_FILE" bash -c "source '${LIB_DIR}'; get_key_by_idx 'tavily' 2")
    assert_eq "Last Tavily key" "tvly-dev-CCCC-test-key-3" "$key"
}

test_state_init_creates_file() {
    echo "→ test_state_init_creates_file"
    local sf="${TEST_DIR}/state-init.json"
    rm -f "$sf"
    KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; init_state"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -f "$sf" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ State file created"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("State file not created")
        echo "  ❌ State file not created"
    fi
}

test_state_init_valid_json() {
    echo "→ test_state_init_valid_json"
    local sf="${TEST_DIR}/state-json.json"
    rm -f "$sf"
    KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; init_state"
    TESTS_RUN=$((TESTS_RUN + 1))
    if jq empty "$sf" 2>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ State file is valid JSON"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("State file is not valid JSON")
        echo "  ❌ State file is not valid JSON"
    fi
}

test_state_init_default_indices() {
    echo "→ test_state_init_default_indices"
    local sf="${TEST_DIR}/state-idx.json"
    rm -f "$sf"
    KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; init_state"
    local tavily_idx firecrawl_idx tinyfish_idx
    tavily_idx=$(jq -r '.tavily_idx' "$sf")
    firecrawl_idx=$(jq -r '.firecrawl_idx' "$sf")
    tinyfish_idx=$(jq -r '.tinyfish_idx' "$sf")
    assert_eq "tavily_idx = 0" "0" "$tavily_idx"
    assert_eq "firecrawl_idx = 0" "0" "$firecrawl_idx"
    assert_eq "tinyfish_idx = 0" "0" "$tinyfish_idx"
}

test_set_idx_updates() {
    echo "→ test_set_idx_updates"
    local sf="${TEST_DIR}/state-set.json"
    echo '{"tavily_idx":0,"firecrawl_idx":0,"tinyfish_idx":0}' > "$sf"
    KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; set_idx 'tavily' 2"
    local idx
    idx=$(jq -r '.tavily_idx' "$sf")
    assert_eq "set_idx updates tavily_idx to 2" "2" "$idx"
}

test_get_idx_returns_value() {
    echo "→ test_get_idx_returns_value"
    local sf="${TEST_DIR}/state-get.json"
    echo '{"tavily_idx":1,"firecrawl_idx":0,"tinyfish_idx":2}' > "$sf"
    local idx
    idx=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; get_idx 'tavily'")
    assert_eq "get_idx returns 1" "1" "$idx"
}

# ── Тесты: ротация с мок-API ─────────────────────────────

test_tavily_selects_first_available() {
    echo "→ test_tavily_selects_first_available"
    local result
    result=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="${TEST_DIR}/state-first.json" bash -c '
        curl() { echo "{\"key\":{\"usage\":100,\"limit\":1000}}"; }
        export -f curl
        source "'"${LIB_DIR}"'"
        get_tavily_key')
    assert_eq "Selects first key with enough credits" "tvly-dev-AAAA-test-key-1" "$result"
}

test_tinyfish_round_robin() {
    echo "→ test_tinyfish_round_robin"
    local sf="${TEST_DIR}/state-rr.json"
    echo '{"tavily_idx":0,"firecrawl_idx":0,"tinyfish_idx":0}' > "$sf"
    
    local key1 key2 key3 key4
    key1=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; get_tinyfish_key")
    key2=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; get_tinyfish_key")
    key3=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; get_tinyfish_key")
    key4=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="$sf" bash -c "source '${LIB_DIR}'; get_tinyfish_key")
    
    assert_eq "RR: first → key 0" "tf-AAAA-test-key-1" "$key1"
    assert_eq "RR: second → key 1" "tf-BBBB-test-key-2" "$key2"
    assert_eq "RR: third → key 2" "tf-CCCC-test-key-3" "$key3"
    assert_eq "RR: fourth → key 0 (wrap)" "tf-AAAA-test-key-1" "$key4"
}

test_firecrawl_rotation() {
    echo "→ test_firecrawl_rotation"
    local result
    result=$(KEYS_FILE="$TEST_KEYS_FILE" STATE_FILE="${TEST_DIR}/state-fc.json" bash -c '
        curl() { echo "{\"success\":true,\"data\":{\"remainingCredits\":100}}"; }
        export -f curl
        source "'"${LIB_DIR}"'"
        get_firecrawl_key')
    assert_eq "Firecrawl returns first key" "fc-AAAA-test-key-1" "$result"
}

# ── Тесты: CLI ─────────────────────────────────────────────

test_cli_usage_no_args() {
    echo "→ test_cli_usage_no_args"
    local output exit_code=0
    output=$("${SCRIPT_DIR}/../search-key-rotate.sh" 2>&1) || exit_code=$?
    assert_eq "No args exits non-zero" "1" "$exit_code"
    assert_contains "Usage message" "$output" "Использование"
}

test_cli_invalid_arg() {
    echo "→ test_cli_invalid_arg"
    local exit_code=0
    "${SCRIPT_DIR}/../search-key-rotate.sh" invalid_provider 2>/dev/null || exit_code=$?
    assert_eq "Invalid arg exits non-zero" "1" "$exit_code"
}

test_cli_tinyfish_returns_key() {
    echo "→ test_cli_tinyfish_returns_key"
    local key
    key=$("${SCRIPT_DIR}/../search-key-rotate.sh" tinyfish 2>/dev/null)
    assert_contains "TinyFish key format" "$key" "sk-tinyfish-"
}

# ── Тесты: файл ключей ────────────────────────────────────

test_keys_file_valid() {
    echo "→ test_keys_file_valid"
    TESTS_RUN=$((TESTS_RUN + 1))
    if jq empty "$TEST_KEYS_FILE" 2>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✅ Test keys file is valid JSON"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES+=("Test keys file is not valid JSON")
        echo "  ❌ Test keys file is not valid JSON"
    fi
}

test_keys_file_has_all_providers() {
    echo "→ test_keys_file_has_all_providers"
    local providers
    providers=$(jq 'keys | join(",")' "$TEST_KEYS_FILE")
    assert_contains "Has tavily" "$providers" "tavily"
    assert_contains "Has firecrawl" "$providers" "firecrawl"
    assert_contains "Has tinyfish" "$providers" "tinyfish"
}

# ── Запуск ─────────────────────────────────────────────────
echo "========================================"
echo "  search-key-rotate.sh — Unit-тесты"
echo "  (без реальных API-вызовов)"
echo "========================================"
echo ""

test_get_key_count_tavily
test_get_key_count_firecrawl
test_get_key_count_tinyfish
test_get_key_by_idx_0
test_get_key_by_idx_1
test_get_key_by_idx_last
test_state_init_creates_file
test_state_init_valid_json
test_state_init_default_indices
test_set_idx_updates
test_get_idx_returns_value
test_tavily_selects_first_available
test_tinyfish_round_robin
test_firecrawl_rotation
test_cli_usage_no_args
test_cli_invalid_arg
test_cli_tinyfish_returns_key
test_keys_file_valid
test_keys_file_has_all_providers

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