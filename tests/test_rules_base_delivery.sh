#!/bin/bash
# test_rules_base_delivery.sh — E2E: проверка доставки правил из rules-base.md
# через session_startup.sh каждому лаборанту
#
# Запуск: bash tests/test_rules_base_delivery.sh

set -euo pipefail

LAB_ROOT="/root/LabDoctorM"
MYRMEX_JSON="$LAB_ROOT/projects/myrmex-control/server-dist/myrmex.json"
STARTUP="$LAB_ROOT/.qwen/scripts/session_startup.sh"
RULES_FILE="$LAB_ROOT/docs/rules-base.md"

PASSED=0
FAILED=0
TOTAL=0

red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

assert_contains() {
  local description="$1"
  local haystack="$2"
  local needle="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$haystack" | grep -qF "$needle"; then
    green "  ✅ $description"
    PASSED=$((PASSED + 1))
  else
    red "  ❌ $description"
    FAILED=$((FAILED + 1))
  fi
}

assert_file_contains() {
  local description="$1"
  local file="$2"
  local needle="$3"
  TOTAL=$((TOTAL + 1))
  if grep -qF "$needle" "$file"; then
    green "  ✅ $description"
    PASSED=$((PASSED + 1))
  else
    red "  ❌ $description"
    FAILED=$((FAILED + 1))
  fi
}

echo "══════════════════════════════════════════"
echo "  Тест: доставка rules-base → лаборанты"
echo "══════════════════════════════════════════"
echo ""

# ─── 1. rules-base.md содержит правило ─────────────────────────────────────
echo "1. rules-base.md — содержание"
assert_file_contains "БЕЗ ТАБЛИЦ в rules-base.md" "$RULES_FILE" "БЕЗ ТАБЛИЦ"
assert_file_contains "секция 1 существует" "$RULES_FILE" "## 1. Язык и тон"
assert_file_contains "секция 3 существует" "$RULES_FILE" "## 3. Коммиты"
echo ""

# ─── 2. session_startup.sh инжектит обе секции ───────────────────────────
echo "2. session_startup.sh — инжекция секций"
STARTUP_CONTENT=$(cat "$STARTUP")
assert_contains "секция 1 инжектится" "$STARTUP_CONTENT" "секция 1"
assert_contains "секция 3 инжектится" "$STARTUP_CONTENT" "секция 3"
echo ""

# ─── 3. Каждый лаборант получает правило при старте ───────────────────────
echo "3. Доставка лаборантам (session_startup.sh)"
AGENTS=$(jq -r '.agents[] | .id' "$MYRMEX_JSON")

for agent_id in $AGENTS; do
  agent_dir=$(jq -r --arg id "$agent_id" '.agents[] | select(.id == $id) | .dir // .id' "$MYRMEX_JSON")
  agent_cwd="$LAB_ROOT/projects/$agent_dir"

  if [ ! -d "$agent_cwd" ]; then
    echo "  ⏭️  $agent_id — нет CWD (не лаборант)"
    continue
  fi

  output=$(cd "$agent_cwd" && bash "$STARTUP" 2>&1)
  assert_contains "$agent_id: правило БЕЗ ТАБЛИЦ доставлено" "$output" "БЕЗ ТАБЛИЦ"
  assert_contains "$agent_id: секция 1 в выводе" "$output" "секция 1"
  assert_contains "$agent_id: секция 3 в выводе" "$output" "секция 3"
done
echo ""

# ─── 4. Секции не содержат Markdown-таблиц (irony check) ─────────────────
echo "4. rules-base.md сам без таблиц"
RULES_CONTENT=$(cat "$RULES_FILE")
TOTAL=$((TOTAL + 1))
if echo "$RULES_CONTENT" | grep -qE '^\|.*\|.*\|$'; then
  red "  ❌ rules-base.md содержит Markdown-таблицы!"
  FAILED=$((FAILED + 1))
else
  green "  ✅ rules-base.md без Markdown-таблиц"
  PASSED=$((PASSED + 1))
fi
echo ""

# ─── Итог ─────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════"
if [ "$FAILED" -eq 0 ]; then
  green "  $PASSED/$TOTAL passed"
else
  red "  $PASSED/$TOTAL passed, $FAILED failed"
fi
echo "══════════════════════════════════════════"

exit "$FAILED"
