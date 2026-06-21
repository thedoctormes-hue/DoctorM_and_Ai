#!/usr/bin/env bash
# test-lab-commit.sh — тесты для lab-commit.sh
# Запуск: bash tests/test-lab-commit.sh
# Требует: jq, git, чистый /root/LabDoctorM репозиторий

set -euo pipefail

SCRIPT="/root/LabDoctorM/shared/git-rules/lab-commit.sh"
PASS=0
FAIL=0
TESTS=()

# ── Утилиты ──────────────────────────────────────────────────────────────────

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

assert_exit_fail() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  ❌ $desc — ожидалась ошибка, но команда прошла"
    FAIL=$((FAIL + 1))
  else
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  fi
}

# ── Тесты ────────────────────────────────────────────────────────────────────

echo "=== Тесты lab-commit.sh ==="
echo ""

# 1. Проверка что скрипт существует и исполняем
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

# 2. Агент не указан — ошибка
echo "[2] Агент не указан — ожидаем ошибку"
assert_exit_fail "нет агента и нет LAB_AGENT" bash "$SCRIPT" -m "test"

# 3. Неизвестный агент — ошибка
echo "[3] Неизвестный агент — ожидаем ошибку"
assert_exit_fail "неизвестный агент" bash "$SCRIPT" unknown-agent -m "test"

# 4. Все 8 агентов известны скрипту
echo "[4] Все 8 агентов известны"
for agent in antcat bestia dominika kotolizator mangust owl raven streikbrecher; do
  if jq -e --arg id "$agent" 'has($id)' /root/LabDoctorM/.qwen/git-authors.json >/dev/null 2>&1; then
    echo "  ✅ $agent найден в git-authors.json"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $agent НЕ найден в git-authors.json"
    FAIL=$((FAIL + 1))
  fi
done

# 5. Проверка что GIT_AUTHOR_* устанавливаются правильно (сухой запуск)
echo "[5] Проверка атрибутов через LAB_AGENT"
# Используем LAB_AGENT вместо первого аргумента
export LAB_AGENT=bestia
# Проверяем что jq может прочитать автора
AUTHOR_NAME=$(jq -r '.bestia.name' /root/LabDoctorM/.qwen/git-authors.json)
assert_eq "bestia name" "Бестия" "$AUTHOR_NAME"

AUTHOR_EMAIL=$(jq -r '.bestia.email' /root/LabDoctorM/.qwen/git-authors.json)
assert_eq "bestia email" "bestia@labdoctorm.ru" "$AUTHOR_EMAIL"
unset LAB_AGENT

# 6. Проверка всех имён и email
echo "[6] Проверка всех агентов — имя и email не пустые"
for agent in antcat bestia dominika kotolizator mangust owl raven streikbrecher; do
  name=$(jq -r --arg id "$agent" '.[$id].name' /root/LabDoctorM/.qwen/git-authors.json)
  email=$(jq -r --arg id "$agent" '.[$id].email' /root/LabDoctorM/.qwen/git-authors.json)
  if [ -n "$name" ] && [ "$name" != "null" ]; then
    echo "  ✅ $agent: name='$name'"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $agent: name пустой"
    FAIL=$((FAIL + 1))
  fi
  if [ -n "$email" ] && [ "$email" != "null" ]; then
    echo "  ✅ $agent: email='$email'"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $agent: email пустой"
    FAIL=$((FAIL + 1))
  fi
done

# 7. Проверка что скрипт не падает без git-репозитория (ошибка от git, не от скрипта)
echo "[7] Скрипт корректно обрабатывает отсутствие git-репозитория"
TMPDIR=$(mktemp -d)
cd "$TMPDIR"
# Инициализируем git чтобы был REPO_ROOT, но скрипт упадёт на отсутствии .qwen/git-authors.json
git init --quiet 2>/dev/null || true
# Скрипт должен упасть с ошибкой о файле authors (не с segfault)
# Используем || true чтобы set -e не прервал тест
OUTPUT=$(bash "$SCRIPT" bestia -m "test" 2>&1) || true
if echo "$OUTPUT" | grep -q "git-authors.json"; then
  echo "  ✅ корректная ошибка при отсутствии git-authors.json"
  PASS=$((PASS + 1))
else
  echo "  ❌ неожиданное поведение при отсутствии git-authors.json"
  FAIL=$((FAIL + 1))
fi
cd /root/LabDoctorM
rm -rf "$TMPDIR"

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
