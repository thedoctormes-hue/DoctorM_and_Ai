#!/usr/bin/env bash
# test-create-worktree.sh — тесты для create-worktree.sh
# Запуск: bash tests/test-create-worktree.sh
# Требует: jq, git, /root/LabDoctorM репозиторий

set -euo pipefail

SCRIPT="/root/LabDoctorM/shared/git-rules/create-worktree.sh"
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

assert_dir_exists() {
  local desc="$1" path="$2"
  if [ -d "$path" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — директория не существует: $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_dir_not_exists() {
  local desc="$1" path="$2"
  if [ ! -d "$path" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — директория всё ещё существует: $path"
    FAIL=$((FAIL + 1))
  fi
}

cleanup_worktree() {
  local path="$1"
  if [ -d "$path" ]; then
    git -C "$CABINET_ROOT" worktree remove --force "$path" 2>/dev/null || rm -rf "$path"
  fi
}

# Создаём тестовый репозиторий для worktree
CABINET_ROOT="/tmp/test-cabinet-root"
CABINET_NAME="testcab"
CABINET_PATH="$CABINET_ROOT/$CABINET_NAME"
WORKTREE_BASE="/tmp/test-worktrees"

rm -rf "$CABINET_ROOT" "$WORKTREE_BASE"
mkdir -p "$CABINET_ROOT" "$WORKTREE_BASE"

# Инициализируем тестовый репозиторий
git init --quiet "$CABINET_PATH"
git -C "$CABINET_PATH" commit --allow-empty --quiet -m "initial commit"

# Подменяем путь к projects/snablab через симлинк на тестовый репозиторий
# Но скрипт принимает путь к кабинету — используем тестовый путь
# Однако скрипт ищет .git в каталоге — наш тестовый репозиторий подходит

echo "=== Тесты create-worktree.sh ==="
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

# 2. Нет аргументов — ошибка
echo "[2] Нет аргументов — ожидаем ошибку"
assert_exit_fail "нет аргументов" bash "$SCRIPT"

# 3. Только один аргумент — ошибка
echo "[3] Только один аргумент — ожидаем ошибку"
assert_exit_fail "один аргумент" bash "$SCRIPT" bestia

# 4. Неизвестный агент — ошибка
echo "[4] Неизвестный агент — ожидаем ошибку"
assert_exit_fail "неизвестный агент" bash "$SCRIPT" unknown-agent "$CABINET_PATH"

# 5. Не-git директория — ошибка
echo "[5] Не-git директория — ожидаем ошибку"
TMPDIR=$(mktemp -d)
assert_exit_fail "не-git директория" bash "$SCRIPT" bestia "$TMPDIR"
rm -rf "$TMPDIR"

# 6. Успешное создание worktree
echo "[6] Успешное создание worktree для bestia"
WORKTREE_PATH="$WORKTREE_BASE/bestia/$CABINET_NAME"
rm -rf "$WORKTREE_PATH"
assert_exit_ok "создание worktree" bash "$SCRIPT" bestia "$CABINET_PATH"
assert_dir_exists "worktree директория создана" "$WORKTREE_PATH"
assert_dir_exists "bin директория создана" "$WORKTREE_PATH/bin"

# 7. Повторное создание — скрипт обрабатывает существующий worktree
echo "[7] Повторное создание того же worktree — скрипт обрабатывает корректно"
assert_exit_ok "повторное создание не падает" bash "$SCRIPT" bestia "$CABINET_PATH"

# 8. Проверка что lab-commit.sh скопирован
echo "[8] lab-commit.sh скопирован в worktree"
assert_dir_exists "lab-commit.sh в worktree" "$WORKTREE_PATH/bin/lab-commit.sh"

# 9. Проверка что .qwen/git-authors.json скопирован
echo "[9] .qwen/git-authors.json скопирован в worktree"
assert_dir_exists "git-authors.json в worktree" "$WORKTREE_PATH/.qwen/git-authors.json"

# 10. Проверка что CABINET.md создан
echo "[10] CABINET.md создан в worktree"
assert_dir_exists "CABINET.md в worktree" "$WORKTREE_PATH/CABINET.md"

# 11. Проверка имени ветки
echo "[11] Проверка имени ветки"
BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "")
if echo "$BRANCH" | grep -q "^bestia/work-"; then
  echo "  ✅ ветка создана с правильным именем: $BRANCH"
  PASS=$((PASS + 1))
else
  echo "  ❌ ветка имеет неожиданное имя: '$BRANCH'"
  FAIL=$((FAIL + 1))
fi

# 12. Очистка
echo "[12] Очистка тестовых данных"
rm -rf "$CABINET_ROOT" "$WORKTREE_BASE"
assert_dir_not_exists "тестовые данные удалены" "$CABINET_ROOT"

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
