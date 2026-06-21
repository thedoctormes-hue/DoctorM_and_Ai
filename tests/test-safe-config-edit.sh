#!/usr/bin/env bash
# test-safe-config-edit.sh — тесты для safe-config-edit.sh
# Запуск: bash tests/test-safe-config-edit.sh
# Требует: jq, /root/.openclaw/openclaw.json

set -euo pipefail

SCRIPT="/root/LabDoctorM/scripts/safe-config-edit.sh"
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

assert_exit_ok() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — команда завершилась с ошибкой"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -f "$path" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — файл не существует: $path"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Тесты safe-config-edit.sh ==="
echo ""

# 1. Скрипт существует и исполняем
echo "[1] Скрипт существует и исполняем"
if [ -x "$SCRIPT" ]; then
  echo "  ✅ $SCRIPT существует и исполняем"
  PASS=$((PASS + 1))
else
  echo "  ❌ $SCRIPT не найден или не исполняем"
  FAIL=$((FAIL + 1))
  echo "Прерываю — скрипт не найден"
  exit 1
fi

# 2. Конфиг существует и валиден
echo "[2] Конфиг openclaw.json существует и валиден"
assert_file_exists "openclaw.json существует" "$CONFIG"
if jq empty "$CONFIG" 2>/dev/null; then
  echo "  ✅ openclaw.json — валидный JSON"
  PASS=$((PASS + 1))
else
  echo "  ❌ openclaw.json — невалидный JSON"
  FAIL=$((FAIL + 1))
fi

# 3. Флаг --check работает без редактирования
echo "[3] Флаг --check — проверка без редактирования"
assert_exit_ok "--check проходит" bash "$SCRIPT" --check

# 4. Скрипт завершается без ошибок
echo "[4] Скрипт завершается без ошибок при --check"
assert_exit_ok "скрипт завершается" bash "$SCRIPT" --check

# 5. Проверка что конфиг содержит обязательные секции
echo "[5] Конфиг содержит обязательные секции"
for section in "hooks" "agents" "channels"; do
  if jq -e "has(\"$section\")" "$CONFIG" >/dev/null 2>&1; then
    echo "  ✅ секция '$section' присутствует"
    PASS=$((PASS + 1))
  else
    echo "  ❌ секция '$section' отсутствует"
    FAIL=$((FAIL + 1))
  fi
done

# 6. Проверка что hooks содержат все 4 хука
echo "[6] Все 4 хука включены"
for hook in "session-memory" "command-logger" "compaction-notifier" "boot-md"; do
  if jq -e ".hooks.internal.entries[\"$hook\"].enabled" "$CONFIG" >/dev/null 2>&1; then
    echo "  ✅ хук '$hook' включён"
    PASS=$((PASS + 1))
  else
    echo "  ❌ хук '$hook' НЕ включён"
    FAIL=$((FAIL + 1))
  fi
done

# 7. Проверка что скрипт не портит конфиг (dry-run)
echo "[7] Скрипт не портит конфиг (dry-run через --check)"
BEFORE=$(md5sum "$CONFIG" | awk '{print $1}')
bash "$SCRIPT" --check >/dev/null 2>&1 || true
AFTER=$(md5sum "$CONFIG" | awk '{print $1}')
assert_eq "конфиг не изменён после --check" "$BEFORE" "$AFTER"

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
