#!/bin/bash
# Тесты кастомных скилов лаборатории
# Проверяет: наличие файлов, валидность frontmatter, перекрёстные ссылки, конфигурацию

set -euo pipefail

SKILLS_DIR="$HOME/.openclaw/skills"
CONFIG="$HOME/.openclaw/openclaw.json"
PASS=0
FAIL=0
WARN=0

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { PASS=$((PASS+1)); echo -e "  ${GREEN}✅ PASS${NC}: $1"; }
fail() { FAIL=$((FAIL+1)); echo -e "  ${RED}❌ FAIL${NC}: $1"; }
warn() { WARN=$((WARN+1)); echo -e "  ${YELLOW}⚠️ WARN${NC}: $1"; }

echo "=== Тесты кастомных скилов лаборатории ==="
echo ""

# ─────────────────────────────────────────────
echo "--- Группа 1: Наличие файлов ---"

# Все 7 кастомных скилов
CUSTOM_SKILLS=("accepting-work" "finishing-session" "gitlab" "registering-incident" "labsearch" "research" "starting-session")

for skill in "${CUSTOM_SKILLS[@]}"; do
  if [ -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
    pass "SKILL.md существует: $skill"
  else
    fail "SKILL.md отсутствует: $skill"
  fi
done

# Старые имена НЕ должны существовать
OLD_NAMES=("accept" "finish" "incident" "sstart")
for old in "${OLD_NAMES[@]}"; do
  if [ -d "$SKILLS_DIR/$old" ]; then
    fail "Старая директория всё существует: $old (должна быть переименована)"
  else
    pass "Старая директория удалена: $old"
  fi
done

echo ""
echo "--- Группа 2: Валидность frontmatter ---"

for skill in "${CUSTOM_SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$f" ]; then
    fail "$skill: нельзя проверить frontmatter (файл отсутствует)"
    continue
  fi

  # Проверить обязательные поля
  for field in "name:" "description:" "version:" "author:" "last_reviewed:" "status:"; do
    if grep -q "^$field" "$f"; then
      pass "$skill: поле $field присутствует"
    else
      fail "$skill: поле $field отсутствует"
    fi
  done

  # Проверить что name совпадает с директорией
  name_val=$(grep '^name:' "$f" | head -1 | sed 's/^name: *//')
  if [ "$name_val" = "$skill" ]; then
    pass "$skill: name совпадает с директорией"
  else
    fail "$skill: name='$name_val' ≠ директория='$skill'"
  fi

  # Проверить что status = active
  status_val=$(grep '^status:' "$f" | head -1 | sed 's/^status: *//')
  if [ "$status_val" = "active" ]; then
    pass "$skill: status=active"
  else
    warn "$skill: status='$status_val' (ожидалось active)"
  fi

  # Проверить version (формат X.Y.Z)
  ver=$(grep '^version:' "$f" | head -1 | sed 's/^version: *["'\'']//' | sed 's/["'\'']*$//')
  if echo "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    pass "$skill: version формат корректный ($ver)"
  else
    warn "$skill: version формат возможно некорректный ($ver)"
  fi
done

echo ""
echo "--- Группа 3: Размер SKILL.md ---"

for skill in "${CUSTOM_SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    if [ "$lines" -le 200 ]; then
      pass "$skill: $lines строк (≤200)"
    elif [ "$lines" -le 500 ]; then
      warn "$skill: $lines строк (>200, ≤500 — можно разгрузить)"
    else
      fail "$skill: $lines строк (>500 — нужно разгрузить)"
    fi
  fi
done

echo ""
echo "--- Группа 4: Перекрёстные ссылки ---"

# accepting-work ссылается на finishing-session
if grep -q "finishing-session" "$SKILLS_DIR/accepting-work/SKILL.md"; then
  pass "accepting-work ссылается на finishing-session"
else
  fail "accepting-work НЕ ссылается на finishing-session"
fi

# finishing-session ссылается на starting-session
if grep -q "starting-session" "$SKILLS_DIR/finishing-session/SKILL.md"; then
  pass "finishing-session ссылается на starting-session"
else
  fail "finishing-session НЕ ссылается на starting-session"
fi

# Проверить что НЕТ ссылок на старые имена
for skill in "${CUSTOM_SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  if [ -f "$f" ]; then
    for old in "session-end" "session-start"; do
      if grep -q "$old" "$f"; then
        fail "$skill: ссылка на старое имя '$old'"
      else
        pass "$skill: нет ссылки на '$old'"
      fi
    done
  fi
done

echo ""
echo "--- Группа 5: Конфигурация ---"

# Проверить JSON валидность
if python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
  pass "openclaw.json валиден"
else
  fail "openclaw.json НЕ валиден"
fi

# Проверить что все кастомные скилы в defaults
for skill in "${CUSTOM_SKILLS[@]}"; do
  if python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
if '$skill' in d['agents']['defaults']['skills']:
    exit(0)
else:
    exit(1)
" 2>/dev/null; then
    pass "$skill в agents.defaults.skills"
  else
    fail "$skill НЕ в agents.defaults.skills"
  fi
done

# Проверить что старых имён НЕТ в defaults
for old in "${OLD_NAMES[@]}"; do
  if python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
if '$old' in d['agents']['defaults']['skills']:
    exit(1)
else:
    exit(0)
" 2>/dev/null; then
    pass "$old НЕ в agents.defaults.skills"
  else
    fail "$old всё ещё в agents.defaults.skills"
  fi
done

echo ""
echo "--- Группа 6: Дополнительные файлы ---"

# research имеет REFERENCE.md
if [ -f "$SKILLS_DIR/research/REFERENCE.md" ]; then
  pass "research: REFERENCE.md существует"
else
  fail "research: REFERENCE.md отсутствует"
fi

# labsearch имеет REFERENCE.md
if [ -f "$SKILLS_DIR/labsearch/REFERENCE.md" ]; then
  pass "labsearch: REFERENCE.md существует"
else
  fail "labsearch: REFERENCE.md отсутствует"
fi

# labsearch имеет скрипт
if [ -f "$SKILLS_DIR/labsearch/scripts/lab_search.py" ]; then
  pass "labsearch: scripts/lab_search.py существует"
else
  fail "labsearch: scripts/lab_search.py отсутствует"
fi

echo ""
echo "--- Группа 7: QUALITY_STANDARDS и ADR ---"

if [ -f "/root/LabDoctorM/projects/DoctorM_and_Ai/QUALITY_STANDARDS.md" ]; then
  pass "QUALITY_STANDARDS.md существует"
else
  fail "QUALITY_STANDARDS.md отсутствует"
fi

if [ -f "/root/LabDoctorM/adr/ADR-000-template.md" ]; then
  pass "adr/ADR-000-template.md существует"
else
  fail "adr/ADR-000-template.md отсутствует"
fi

if [ -f "/root/LabDoctorM/adr/ADR-001-custom-skills-restructure.md" ]; then
  pass "adr/ADR-001 существует"
else
  fail "adr/ADR-001 отсутствует"
fi

# ─────────────────────────────────────────────
echo ""
echo "=== Результаты ==="
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"
echo -e "  ${YELLOW}WARN: $WARN${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}❌ $FAIL тестов провалено${NC}"
  exit 1
else
  echo -e "${GREEN}✅ Все тесты пройдено ($WARN предупреждений)${NC}"
  exit 0
fi
