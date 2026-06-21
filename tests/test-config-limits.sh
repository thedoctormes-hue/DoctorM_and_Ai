#!/usr/bin/env bash
# test-config-limits.sh — тесты для проверки лимитов конфигурации OpenClaw
# Запуск: bash tests/test-config-limits.sh
# Проверяет: maxTotalChars, maxFileChars, toolResultMaxChars, memoryFlush.model

set -euo pipefail

CONFIG="/root/.openclaw/openclaw.json"
PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — expected: '$expected', got: '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

assert_gte() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$actual" -ge "$expected" ] 2>/dev/null; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — expected >= '$expected', got: '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Тесты конфигурации OpenClaw ==="
echo ""

# 1. Конфиг существует и валиден
echo "[1] Конфиг валиден"
if jq empty "$CONFIG" 2>/dev/null; then
  echo "  ✅ openclaw.json — валидный JSON"
  PASS=$((PASS + 1))
else
  echo "  ❌ openclaw.json — невалидный JSON"
  FAIL=$((FAIL + 1))
  echo "Прерываю — конфиг невалиден"
  exit 1
fi

# 2. startupContext.maxTotalChars >= 5000
echo "[2] startupContext.maxTotalChars >= 5000"
VAL=$(jq -r '.agents.defaults.startupContext.maxTotalChars // empty' "$CONFIG")
assert_gte "maxTotalChars >= 5000" "5000" "$VAL"

# 3. startupContext.maxFileChars >= 3000
echo "[3] startupContext.maxFileChars >= 3000"
VAL=$(jq -r '.agents.defaults.startupContext.maxFileChars // empty' "$CONFIG")
assert_gte "maxFileChars >= 3000" "3000" "$VAL"

# 4. contextLimits.toolResultMaxChars >= 30000
echo "[4] contextLimits.toolResultMaxChars >= 30000"
VAL=$(jq -r '.agents.defaults.contextLimits.toolResultMaxChars // empty' "$CONFIG")
assert_gte "toolResultMaxChars >= 30000" "30000" "$VAL"

# 5. compaction.memoryFlush.model — не пустая строка
echo "[5] compaction.memoryFlush.model задана"
VAL=$(jq -r '.agents.defaults.compaction.memoryFlush.model // empty' "$CONFIG")
if [ -n "$VAL" ]; then
  echo "  ✅ memoryFlush.model = '$VAL'"
  PASS=$((PASS + 1))
else
  echo "  ❌ memoryFlush.model не задана"
  FAIL=$((FAIL + 1))
fi

# 6. compaction.memoryFlush.model — использует бесплатную модель (:free)
echo "[6] memoryFlush.model — бесплатная модель (:free)"
if echo "$VAL" | grep -q ':free'; then
  echo "  ✅ модель бесплатная: '$VAL'"
  PASS=$((PASS + 1))
else
  echo "  ❌ модель не бесплатная: '$VAL'"
  FAIL=$((FAIL + 1))
fi

# 7. contextInjection = continuation-skip
echo "[7] contextInjection = continuation-skip"
VAL=$(jq -r '.agents.defaults.contextInjection // empty' "$CONFIG")
assert_eq "contextInjection" "continuation-skip" "$VAL"

# 8. memorySearch.provider задана
echo "[8] memorySearch.provider задана"
VAL=$(jq -r '.agents.defaults.memorySearch.provider // empty' "$CONFIG")
if [ -n "$VAL" ] && [ "$VAL" != "none" ]; then
  echo "  ✅ memorySearch.provider = '$VAL'"
  PASS=$((PASS + 1))
else
  echo "  ❌ memorySearch.provider не задана"
  FAIL=$((FAIL + 1))
fi

# 9. memorySearch.model задана
echo "[9] memorySearch.model задана"
VAL=$(jq -r '.agents.defaults.memorySearch.model // empty' "$CONFIG")
if [ -n "$VAL" ]; then
  echo "  ✅ memorySearch.model = '$VAL'"
  PASS=$((PASS + 1))
else
  echo "  ❌ memorySearch.model не задана"
  FAIL=$((FAIL + 1))
fi

# 10. gateway.bind = loopback
echo "[10] gateway.bind = loopback"
VAL=$(jq -r '.gateway.bind // empty' "$CONFIG")
assert_eq "gateway.bind" "loopback" "$VAL"

# 11. channels.telegram.dmPolicy = allowlist
echo "[11] channels.telegram.dmPolicy = allowlist"
VAL=$(jq -r '.channels.telegram.dmPolicy // empty' "$CONFIG")
assert_eq "dmPolicy" "allowlist" "$VAL"

# 12. Количество агентов >= 8
echo "[12] Количество агентов >= 8"
VAL=$(jq -r '.agents.list | length' "$CONFIG")
assert_gte "agents count >= 8" "8" "$VAL"

# ── Итог ─────────────────────────────────────────────────────────────────────

echo ""
echo "=== Итого ==="
echo "  ✅ Пройдено: $PASS"
echo "  ❌ Провалено: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "  🔴 ТЕСТЫ НЕ ПРОЙДЕНЫ"
  exit 1
else
  echo "  🟢 ВСЕ ТЕСТЫ ПРОЙДЕНЫ"
  exit 0
fi
