#!/bin/bash
# Тесты session_startup.sh v7.0 — проверяем канонические имена агентов
# Запуск: bash tests/test_session_startup.sh
set -uo pipefail

SCRIPT="/root/.qwen/session_startup.sh"
PASS=0
FAIL=0

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if echo "$haystack" | grep -q "$needle"; then
        echo "✅ PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $label (expected '$needle' in output)"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" label="$3"
    if ! echo "$haystack" | grep -qi "$needle"; then
        echo "✅ PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $label (did NOT expect '$needle' in output)"
        FAIL=$((FAIL + 1))
    fi
}

# ── Тест 1: AGENT=antcat — базовая загрузка ──────
echo "=== Тест 1: AGENT=antcat загружает IDENTITY.md ==="
OUTPUT=$(AGENT=antcat bash "$SCRIPT" 2>&1 || true)
assert_contains "$OUTPUT" "antcat" "AGENT=antcat загружает контекст из antcat"

# ── Тест 2: Канонические имена в case-блоке ──────
echo "=== Тест 2: Канонические имена в case-блоке ==="
SCRIPT_CONTENT=$(cat "$SCRIPT")
assert_contains "$SCRIPT_CONTENT" "antcat)" "antcat — case-блок"
assert_contains "$SCRIPT_CONTENT" 'AGENT_DIR="/root/LabDoctorM/projects/antcat"' "antcat → директория"
assert_contains "$SCRIPT_CONTENT" "kotolizator)" "kotolizator — case-блок"
assert_contains "$SCRIPT_CONTENT" 'AGENT_DIR="/root/LabDoctorM/projects/kotolizator"' "kotolizator → директория"
assert_contains "$SCRIPT_CONTENT" "streikbrecher)" "streikbrecher — case-блок"
assert_contains "$SCRIPT_CONTENT" 'AGENT_DIR="/root/LabDoctorM/projects/streikbrecher"' "streikbrecher → директория"
assert_contains "$SCRIPT_CONTENT" "owl)" "owl — case-блок"
assert_contains "$SCRIPT_CONTENT" "raven)" "raven — case-блок"
assert_contains "$SCRIPT_CONTENT" "bestia)" "bestia — case-блок"

# ── Тест 3: Старые алиасы ОТСУТСТВУЮТ ────────────
echo "=== Тест 3: Старые алиасы отсутствуют ==="
assert_not_contains "$SCRIPT_CONTENT" "myrmex" "myrmex не упоминается"
assert_not_contains "$SCRIPT_CONTENT" "muravay" "muravay не упоминается"

# ── Тест 4: Kanban session start URL ──────────────
echo "=== Тест 4: Kanban session start URL ==="
assert_contains "$SCRIPT_CONTENT" "agent=\${AGENT}" "Kanban URL использует AGENT переменную"

# ── Тест 5: Дефолтный агент — без myrmex/muravay ──
echo "=== Тест 5: Дефолтный агент !== myrmex/muravay ==="
assert_not_contains "$SCRIPT_CONTENT" 'AGENT="${AGENT:-myrmex}"' "Дефолтный агент не myrmex"
assert_not_contains "$SCRIPT_CONTENT" 'AGENT="${AGENT:-muravay}"' "Дефолтный агент не muravay"

# ── Тест 6: Старые алиасы в case отсутствуют ──────
echo "=== Тест 6: Старые алиасы отсутствуют в case ==="
assert_not_contains "$SCRIPT_CONTENT" "    ant)" "ant отсутствует — только antcat"
assert_not_contains "$SCRIPT_CONTENT" "    kot)" "kot отсутствует — только kotolizator"
assert_not_contains "$SCRIPT_CONTENT" "    streik)" "streik отсутствует — только streikbrecher"
assert_not_contains "$SCRIPT_CONTENT" "    cat)" "cat отсутствует"
assert_not_contains "$SCRIPT_CONTENT" "    sova)" "sova отсутствует — только owl"

# ── Итог ───────────────────────────────────────────
echo ""
echo "=============================="
echo "Результат: $PASS passed, $FAIL failed"
echo "=============================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
