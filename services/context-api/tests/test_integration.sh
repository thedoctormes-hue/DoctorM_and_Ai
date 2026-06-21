#!/bin/bash
# Интеграционный тест: полный цикл AGENT=antcat
# Проверяет что session_startup.sh + Context API работают согласованно
# Запуск: bash tests/test_integration.sh
set -uo pipefail

SCRIPT="/root/.qwen/session_startup.sh"
API_URL="http://127.0.0.1:8100"
PASS=0
FAIL=0

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [ "$actual" = "$expected" ]; then
        echo "✅ PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $label (expected='$expected', actual='$actual')"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_empty() {
    local value="$1" label="$2"
    if [ -n "$value" ]; then
        echo "✅ PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $label (empty)"
        FAIL=$((FAIL + 1))
    fi
}

# ── Шаг 1: Context API доступен ─────────────────────
echo "=== Шаг 1: Context API доступен ==="
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$API_URL/health" 2>/dev/null || echo "000")
assert_eq "$API_STATUS" "200" "Context API здоров"

# ── Шаг 2: API /identity/antcat работает ───────────
echo "=== Шаг 2: /identity/antcat через API ==="
ANTCAT_RESPONSE=$(curl -s --connect-timeout 3 "$API_URL/api/v1/identity/antcat" 2>/dev/null || echo "")
ANTCAT_AGENT=$(echo "$ANTCAT_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('agent',''))" 2>/dev/null || echo "")
assert_eq "$ANTCAT_AGENT" "antcat" "API возвращает agent=antcat"

# ── Шаг 3: API /identity/myrmex — 404 ──────────────
echo "=== Шаг 3: /identity/myrmex → 404 ==="
MYRMEX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$API_URL/api/v1/identity/myrmex" 2>/dev/null || echo "000")
assert_eq "$MYRMEX_STATUS" "404" "myrmex больше не резолвится"

# ── Шаг 3b: Старые алиасы → 404 ───────────────────
echo "=== Шаг 3b: Старые алиасы → 404 ==="
for alias in ant kot streik cat sova; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$API_URL/api/v1/identity/$alias" 2>/dev/null || echo "000")
    assert_eq "$STATUS" "404" "алиас $alias не резолвится"
done

# ── Шаг 4: session_startup.sh + API — полный цикл ──
echo "=== Шаг 4: Полный цикл session_startup.sh + API ==="
OUTPUT=$(AGENT=antcat bash "$SCRIPT" 2>&1 || true)
assert_not_empty "$OUTPUT" "session_startup.sh возвращает контекст"

# Проверяем что контекст содержит ключевые файлы
if echo "$OUTPUT" | grep -q "IDENTITY.md"; then
    echo "✅ PASS: Контекст содержит IDENTITY.md"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Контекст не содержит IDENTITY.md"
    FAIL=$((FAIL + 1))
fi

if echo "$OUTPUT" | grep -q "SOUL.md"; then
    echo "✅ PASS: Контекст содержит SOUL.md"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Контекст не содержит SOUL.md"
    FAIL=$((FAIL + 1))
fi

# ── Шаг 5: IDENTITY.md содержит kanban agent: antcat
echo "=== Шаг 5: IDENTITY.md проверка ==="
IDENTITY_CONTENT=$(echo "$OUTPUT" | awk '/^## IDENTITY\.md/{found=1; next} /^## /{found=0} found{print}' || true)
if echo "$IDENTITY_CONTENT" | grep -qi "kanban agent"; then
    KANBAN_VALUE=$(echo "$IDENTITY_CONTENT" | grep -i "kanban agent" | head -1)
    if echo "$KANBAN_VALUE" | grep -qi "myrmex"; then
        echo "❌ FAIL: kanban agent содержит myrmex"
        FAIL=$((FAIL + 1))
    else
        echo "✅ PASS: kanban agent не содержит myrmex ($KANBAN_VALUE)"
        PASS=$((PASS + 1))
    fi
else
    echo "⚠️ SKIP: kanban agent строка не найдена в выводе"
fi

# ── Шаг 6: Все канонические имена работают ─────────
echo "=== Шаг 6: Все канонические имена через API ==="
for agent in raven owl bestia antcat kotolizator streikbrecher; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$API_URL/api/v1/identity/$agent" 2>/dev/null || echo "000")
    assert_eq "$STATUS" "200" "каноническое имя $agent работает"
done

# ── Итог ───────────────────────────────────────────
echo ""
echo "=============================="
echo "Результат: $PASS passed, $FAIL failed"
echo "=============================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
