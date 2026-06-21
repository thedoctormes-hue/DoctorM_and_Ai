#!/bin/bash
# test_session_full_e2e.sh — Полный E2E аудит системы лаборантов
#
# Проверяет:
#   1. rules-base.md — структура, БЕЗ ТАБЛИЦ, без таблиц (irony)
#   2. session_startup.sh — инжекция секций 1+3
#   3. Git hooks — через pre-commit framework (common-dir)
#   4. git-guardian.sh — commit-msg валидация (реальная защита)
#   5. Доставка rules-base каждому лаборанту через startup
#   6. Worktrees — ветка, HEAD=main, git user, worktreeConfig, clean
#   7. myrmex.json — конфигурация (dir, aliases)
#
# Запуск: bash tests/test_session_full_e2e.sh

set -euo pipefail

LAB_ROOT="/root/LabDoctorM"
MYRMEX_JSON="$LAB_ROOT/projects/myrmex-control/server-dist/myrmex.json"
STARTUP="$LAB_ROOT/.qwen/scripts/session_startup.sh"
RULES_FILE="$LAB_ROOT/docs/rules-base.md"
GUARDIAN="$LAB_ROOT/scripts/git-guardian.sh"

NON_LABORANTS="zavlab"

PASSED=0; FAILED=0; TOTAL=0

red()   { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

assert() {
  local desc="$1"; local result="$2"; local expected="$3"
  if [ "$result" = "skip" ]; then
    TOTAL=$((TOTAL + 1)); yellow "  ⏭️  $desc"; return
  fi
  TOTAL=$((TOTAL + 1))
  if [ "$result" = "$expected" ]; then
    green "  ✅ $desc"; PASSED=$((PASSED + 1))
  else
    red "  ❌ $desc (expected=$expected actual=$result)"; FAILED=$((FAILED + 1))
  fi
}

# Резолв agent_dir из myrmex.json
agent_dir() {
  jq -r --arg id "$1" '.agents[] | select(.id == $id) | .dir // .id' "$MYRMEX_JSON"
}

echo "══════════════════════════════════════════════════════════════"
echo "  ПОЛНЫЙ E2E АУДИТ СИСТЕМЫ ЛАБОРАНТОВ"
echo "══════════════════════════════════════════════════════════════"
echo ""

AGENTS=$(jq -r '.agents[] | .id' "$MYRMEX_JSON")

# ═══ 1. rules-base.md ════════════════════════════════════════════════════
echo "1. rules-base.md"
TOTAL=$((TOTAL + 1))
if grep -qF "## 1. Язык и тон" "$RULES_FILE"; then green "  ✅ секция 1"; PASSED=$((PASSED + 1)); else red "  ❌ секция 1"; FAILED=$((FAILED + 1)); fi

TOTAL=$((TOTAL + 1))
if grep -qF "БЕЗ ТАБЛИЦ" "$RULES_FILE"; then green "  ✅ БЕЗ ТАБЛИЦ"; PASSED=$((PASSED + 1)); else red "  ❌ БЕЗ ТАБЛИЦ"; FAILED=$((FAILED + 1)); fi

TOTAL=$((TOTAL + 1))
if grep -qF "## 3. Коммиты" "$RULES_FILE"; then green "  ✅ секция 3"; PASSED=$((PASSED + 1)); else red "  ❌ секция 3"; FAILED=$((FAILED + 1)); fi

TOTAL=$((TOTAL + 1))
if cat "$RULES_FILE" | grep -qE '^\|.*\|.*\|$'; then red "  ❌ rules-base содержит таблицы!"; FAILED=$((FAILED + 1)); else green "  ✅ без таблиц"; PASSED=$((PASSED + 1)); fi
echo ""

# ═══ 2. session_startup.sh ════════════════════════════════════════════════
echo "2. session_startup.sh — секции"
S=$(cat "$STARTUP")
assert "секция 1 инжектится" "$(echo "$S" | grep -qF 'секция 1' && echo pass || echo fail)" "pass"
assert "секция 3 инжектится" "$(echo "$S" | grep -qF 'секция 3' && echo pass || echo fail)" "pass"
echo ""

# ═══ 3. Git hooks через pre-commit framework ═════════════════════════════
echo "3. Git hooks (pre-commit framework → git-guardian.sh)"
assert "git-guardian.sh существует" "$([ -f "$GUARDIAN" ] && echo pass || echo fail)" "pass"
assert "git-guardian.sh исполняемый" "$([ -x "$GUARDIAN" ] && echo pass || echo fail)" "pass"
assert ".git/hooks/pre-commit (framework)" "$([ -f "$LAB_ROOT/.git/hooks/pre-commit" ] && echo pass || echo fail)" "pass"
assert ".git/hooks/commit-msg (framework)" "$([ -f "$LAB_ROOT/.git/hooks/commit-msg" ] && echo pass || echo fail)" "pass"
assert ".git/hooks/pre-push (framework)" "$([ -f "$LAB_ROOT/.git/hooks/pre-push" ] && echo pass || echo fail)" "pass"
assert ".git/hooks/post-commit (framework)" "$([ -f "$LAB_ROOT/.git/hooks/post-commit" ] && echo pass || echo fail)" "pass"
echo ""

# ═══ 4. git-guardian.sh commit-msg валидация ═════════════════════════════
echo "4. git-guardian.sh — commit-msg валидация"
TMP=$(mktemp)

for msg in \
  "feat(autoexpert): добавить парсер" \
  "fix(monitoring): исправить алерт" \
  "test(raven): добавить smoke-тест" \
  "docs(owl): обновить ADR-012" \
  "refactor(snablab): упростить запросы" \
  "chore(ci): обновить github actions"; do
  echo "$msg" > "$TMP"
  TOTAL=$((TOTAL + 1))
  if bash "$GUARDIAN" commit-msg "$TMP" 2>/dev/null; then
    green "  ✅ PASS: $msg"; PASSED=$((PASSED + 1))
  else
    red "  ❌ FAIL: $msg"; FAILED=$((FAILED + 1))
  fi
done

for msg in "fix: исправить всё" "feat: добавить тест" "обновить код"; do
  echo "$msg" > "$TMP"
  TOTAL=$((TOTAL + 1))
  if bash "$GUARDIAN" commit-msg "$TMP" 2>/dev/null; then
    red "  ❌ UNBLOCKED: $msg"; FAILED=$((FAILED + 1))
  else
    green "  ✅ BLOCKED: $msg"; PASSED=$((PASSED + 1))
  fi
done

rm -f "$TMP"
echo ""

# ═══ 5. Доставка rules-base лаборантам ══════════════════════════════════
echo "5. Доставка rules-base лаборантам"

for aid in $AGENTS; do
  adir=$(agent_dir "$aid")
  acwd="$LAB_ROOT/projects/$adir"

  if echo "$NON_LABORANTS" | grep -qw "$aid"; then
    assert "$aid: (не лаборант)" "skip" "pass"; continue
  fi

  if [ ! -d "$acwd" ]; then
    assert "$aid: CWD не найден ($acwd)" "fail" "pass"; continue
  fi

  ok=$(cd "$acwd" && bash "$STARTUP" 2>&1 | grep -cF "БЕЗ ТАБЛИЦ")
  assert "$aid: БЕЗ ТАБЛИЦ" "$([ "$ok" -ge 1 ] && echo pass || echo fail)" "pass"

  s1=$(cd "$acwd" && bash "$STARTUP" 2>&1 | grep -cF "секция 1")
  assert "$aid: секция 1" "$([ "$s1" -ge 1 ] && echo pass || echo fail)" "pass"

  s3=$(cd "$acwd" && bash "$STARTUP" 2>&1 | grep -cF "секция 3")
  assert "$aid: секция 3" "$([ "$s3" -ge 1 ] && echo pass || echo fail)" "pass"

  wt=$(cd "$acwd" && bash "$STARTUP" 2>&1 | grep -cF "WORKTREE_DIR=/")
  assert "$aid: WORKTREE_DIR" "$([ "$wt" -ge 1 ] && echo pass || echo fail)" "pass"
done
echo ""

# ═══ 6. Worktrees ════════════════════════════════════════════════════════
echo "6. Worktrees, ветки, git config"

for aid in $AGENTS; do
  adir=$(agent_dir "$aid")
  wt="$LAB_ROOT/worktrees/$adir"

  if echo "$NON_LABORANTS" | grep -qw "$aid"; then
    assert "$aid: (не лаборант)" "skip" "pass"; continue
  fi

  if [ ! -d "$wt" ]; then
    assert "$aid: worktree отсутствует ($wt)" "fail" "pass"; continue
  fi

  branch=$(git -C "$wt" branch --show-current 2>/dev/null)
  # Ветка должна начинаться с agent_dir (kotolizator/* для kot)
  assert "$aid: ветка ($branch)" \
    "$(echo "$branch" | grep -qE "^${adir}/" && echo pass || echo fail)" "pass"

  head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
  main=$(git -C "$wt" rev-parse origin/main 2>/dev/null)
  assert "$aid: HEAD = main" "$([ "$head" = "$main" ] && echo pass || echo fail)" "pass"

  gname=$(git -C "$wt" config user.name 2>/dev/null || echo "")
  assert "$aid: user.name ($gname)" "$([ -n "$gname" ] && echo pass || echo fail)" "pass"

  wtc=$(git -C "$wt" config extensions.worktreeConfig 2>/dev/null || echo "")
  assert "$aid: worktreeConfig" "$([ "$wtc" = "true" ] && echo pass || echo fail)" "pass"

  dirty=$(git -C "$wt" status --porcelain 2>/dev/null | wc -l)
  assert "$aid: clean ($dirty)" "$([ "$dirty" -eq 0 ] && echo pass || echo fail)" "pass"
done
echo ""

# ═══ 7. myrmex.json ══════════════════════════════════════════════════════
echo "7. myrmex.json"
for aid in $AGENTS; do
  adir=$(agent_dir "$aid")

  if echo "$NON_LABORANTS" | grep -qw "$aid"; then
    assert "$aid: (не лаборант)" "skip" "pass"; continue
  fi

  assert "$aid: projects/$adir" "$([ -d "$LAB_ROOT/projects/$adir" ] && echo pass || echo fail)" "pass"
  assert "$aid: worktrees/$adir" "$([ -d "$LAB_ROOT/worktrees/$adir" ] && echo pass || echo fail)" "pass"
done
echo ""

# ═══ 8. Нет хаоса — .githooks не должен содержать дублирующие hooks ═════
echo "8. Нет хаоса"
# .githooks/commit-msg не должен существовать (защита через git-guardian.sh)
assert ".githooks/commit-msg не существует (нет дубля)" \
  "$([ ! -f /root/LabDoctorM/.githooks/commit-msg ] && echo pass || echo fail)" "pass"

# Не должно быть дублирующих kot worktree
assert "worktrees/kot не существует (нет дубля Кота)" \
  "$([ ! -d /root/LabDoctorM/worktrees/kot ] && echo pass || echo fail)" "pass"

# Нет orphan веток от нашей сессии
assert "kot/worktree ветка не существует" \
  "$(! git branch --list kot/worktree | grep -q . && echo pass || echo fail)" "pass"
echo ""

# ═══ Итог ════════════════════════════════════════════════════════════════
echo "══════════════════════════════════════════════════════════════"
if [ "$FAILED" -eq 0 ]; then
  green "  ✅ $PASSED/$TOTAL passed — система в норме"
else
  red "  ❌ $PASSED/$TOTAL passed, $FAILED failed"
fi
echo "══════════════════════════════════════════════════════════════"

exit "$FAILED"
