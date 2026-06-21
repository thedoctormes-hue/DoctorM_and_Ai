#!/usr/bin/env bash
# test-bootstrap-files.sh — проверка наличия bootstrap-файлов у всех агентов
# Запуск: bash tests/test-bootstrap-files.sh

set -euo pipefail

PASS=***
FAIL=0
WORKSPACE_ROOT="/root/LabDoctorM/workspaces"

# Обязательные bootstrap-файлы (из loadWorkspaceBootstrapFiles)
BOOTSTRAP_FILES=("AGENTS.md" "SOUL.md" "TOOLS.md" "IDENTITY.md" "USER.md" "HEARTBEAT.md" "MEMORY.md")

# Все агенты
AGENTS=("antcat" "bestia" "dominika" "kotolizator" "mangust" "owl" "raven" "streikbrecher")

# Известные не-bootstrap файлы, которые НЕ должны существовать
NONBOOT_GIT=("CHECKPOINT.md" "SESSION_HANDOFF.md" "SOUL-compact.md")
NONBOOT_OTHER=("TEST_VOICE.md" "github-profile.md" "SESSION_STANDARD.md" "migrate_agents.py" "embed_bench.py")

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -f "$path" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — файл не найден: $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_exists() {
  local desc="$1" path="$2"
  if [ ! -f "$path" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — файл всё ещё существует: $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_empty() {
  local desc="$1" path="$2"
  if [ -s "$path" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — файл пустой: $path"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Тесты bootstrap-файлов всех агентов ==="
echo ""

# 1. Проверка наличия bootstrap-файлов у каждого агента
echo "[1] Bootstrap-файлы у всех агентов"
for agent in "${AGENTS[@]}"; do
  echo "  --- $agent ---"
  for file in "${BOOTSTRAP_FILES[@]}"; do
    assert_file_exists "$file существует" "$WORKSPACE_ROOT/$agent/$file"
    if [ -f "$WORKSPACE_ROOT/$agent/$file" ]; then
      assert_not_empty "$file не пустой" "$WORKSPACE_ROOT/$agent/$file"
    fi
  done
done

# 2. Проверка что не-bootstrap файлы удалены
echo ""
echo "[2] Не-bootstrap файлы удалены"
for agent in "${AGENTS[@]}"; do
  echo "  --- $agent ---"
  for file in "${NONBOOT_GIT[@]}"; do
    assert_file_not_exists "$file отсутствует" "$WORKSPACE_ROOT/$agent/$file"
  done
done

# 3. Проверка что TEST_VOICE.md и github-profile.md удалены
echo ""
echo "[3] Мусорные файлы удалены"
for agent in "${AGENTS[@]}"; do
  for file in "${NONBOOT_OTHER[@]}"; do
    if [ -f "$WORKSPACE_ROOT/$agent/$file" ]; then
      echo "  ❌ $agent/$file — всё ещё существует"
      FAIL=$((FAIL + 1))
    fi
  done
done
echo "  ✅ мусорные файлы не найдены"

# 4. Проверка что AGENTS.md содержит секцию закрытия сессии
echo ""
echo "[4] AGENTS.md содержит секцию закрытия сессии"
for agent in "${AGENTS[@]}"; do
  if grep -q "Закрытие сессии" "$WORKSPACE_ROOT/$agent/AGENTS.md" 2>/dev/null; then
    echo "  ✅ $agent — секция закрытия сессии есть"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $agent — секции закрытия сессии НЕТ"
    FAIL=$((FAIL + 1))
  fi
done

# 5. Проверка что AGENTS.md содержит git-правила
echo ""
echo "[5] AGENTS.md содержит git-правила"
for agent in "${AGENTS[@]}"; do
  if grep -q "lab-commit.sh" "$WORKSPACE_ROOT/$agent/AGENTS.md" 2>/dev/null; then
    echo "  ✅ $agent — git-правила есть"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $agent — git-правил НЕТ"
    FAIL=$((FAIL + 1))
  fi
done

# 6. Проверка что MEMORY.md содержит инциденты (для агентов с инцидентами)
echo ""
echo "[6] MEMORY.md содержит инциденты"
AGENTS_WITH_INCIDENTS=("bestia" "antcat" "owl" "raven" "streikbrecher")
for agent in "${AGENTS_WITH_INCIDENTS[@]}"; do
  if grep -q "INC-" "$WORKSPACE_ROOT/$agent/MEMORY.md" 2>/dev/null; then
    echo "  ✅ $agent — инциденты в MEMORY.md"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $agent — инцидентов в MEMORY.md НЕТ"
    FAIL=$((FAIL + 1))
  fi
done

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
