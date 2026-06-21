#!/usr/bin/env bash
# projects-registry.sh — генератор реестра проектов лаборатории.
# Источник правды: projects.json (зеркало myrmex.json).
# Сверяет реестр с файловой системой, считает факты, пересобирает PROJECTS_AUDIT.md.
# Использование: bin/projects-registry.sh [--check]
#   (без аргументов) — пересобрать PROJECTS_AUDIT.md
#   --check          — только показать дрейф, ничего не писать (exit 1 если дрейф есть)
set -uo pipefail

LAB="/root/LabDoctorM"
PROJECTS_DIR="$LAB/projects"
REGISTRY="$LAB/projects.json"
OUT="$LAB/PROJECTS_AUDIT.md"
TODAY="$(date +%Y-%m-%d)"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# agent-workspace папки (не проекты с кодом) — по факту IDENTITY+SOUL, без кода
AGENT_DIRS="antcat bestia dominika kotolizator mangust owl raven streikbrecher"

# --- 1. Реестр: имена папок из projects.json ---
mapfile -t REG_PATHS < <(python3 -c "
import json
for p in json.load(open('$REGISTRY'))['projects']:
    print(p['path'].split('/')[-1])
")

# --- 2. Факт: папки проектов (исключая agent-workspaces и служебное) ---
mapfile -t FACT_DIRS < <(
  for d in "$PROJECTS_DIR"/*/; do
    n="$(basename "$d")"
    case " $AGENT_DIRS " in *" $n "*) continue;; esac
    case "$n" in audit-results) continue;; esac
    echo "$n"
  done | sort
)

# --- 3. Дрейф ---
DRIFT=0
DRIFT_MSG=""
for f in "${FACT_DIRS[@]}"; do
  found=0
  for r in "${REG_PATHS[@]}"; do [ "$f" = "$r" ] && found=1 && break; done
  [ $found -eq 0 ] && DRIFT_MSG+="  - В ФС есть, в реестре НЕТ: $f"$'\n' && DRIFT=1
done
for r in "${REG_PATHS[@]}"; do
  [ -d "$PROJECTS_DIR/$r" ] || { DRIFT_MSG+="  - В реестре есть, в ФС НЕТ: $r"$'\n'; DRIFT=1; }
done

if [ $CHECK_ONLY -eq 1 ]; then
  if [ $DRIFT -eq 1 ]; then
    echo "ДРЕЙФ РЕЕСТРА:"; printf '%s' "$DRIFT_MSG"; exit 1
  fi
  echo "Реестр синхронен с ФС ✓"; exit 0
fi

# --- 4. Факты по проекту: README, тесты, последняя правка кода ---
project_facts() {
  local dir="$PROJECTS_DIR/$1"
  local rd="нет" tests=0 code=0
  for x in README.md readme.md README.MD; do [ -f "$dir/$x" ] && rd="есть" && break; done
  tests=$(grep -rh "func Test\|def test_\|it(\|test(" "$dir" --include='*_test.go' --include='*_test.py' --include='*.test.js' --include='*.test.ts' --include='*.spec.ts' 2>/dev/null | wc -l)
  code=$(find "$dir" -maxdepth 4 \( -name '*.py' -o -name '*.go' -o -name '*.js' -o -name '*.ts' -o -name '*.tsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l)
  echo "$rd|$tests|$code"
}

# --- 5. Генерация отчёта ---
{
echo "---"
echo "description: \"Аудит проектов лаборатории (автогенерация)\""
echo "type: reference"
echo "generated_by: bin/projects-registry.sh"
echo "last_reviewed: $TODAY"
echo "---"
echo
echo "# Проекты лаборатории — реестр ($TODAY)"
echo
echo "> Автогенерация из \`projects.json\`. Не править руками — запусти \`bin/projects-registry.sh\`."
echo
echo "## Дрейф реестра"
echo
if [ $DRIFT -eq 1 ]; then
  printf '%s' "$DRIFT_MSG"
else
  echo "Расхождений нет — реестр синхронен с файловой системой ✓"
fi
echo
echo "## Проекты"
echo
python3 -c "
import json
ps=sorted(json.load(open('$REGISTRY'))['projects'], key=lambda p:(p.get('status','z'),p['name']))
for p in ps:
    print(f\"{p.get('icon','📁')} {p['name']} — {p.get('owner','?')} — {p.get('status','?')}\")
"
echo
echo "## Факты по файловой системе"
echo
echo "Проект — README — тестов — файлов кода"
echo
for d in "${FACT_DIRS[@]}"; do
  IFS='|' read -r rd tests code <<< "$(project_facts "$d")"
  flag=""
  [ "$rd" = "нет" ] && [ "$code" -gt 0 ] && flag=" ⚠️ код без README"
  echo "- $d — README: $rd — тестов: $tests — кода: $code$flag"
done
echo
echo "## Agent-workspaces (не проекты)"
echo
echo "$AGENT_DIRS" | tr ' ' '\n' | sed 's/^/- /'
echo
echo "## Статистика"
echo
echo "- Проектов в реестре: ${#REG_PATHS[@]}"
echo "- Папок-проектов в ФС: ${#FACT_DIRS[@]}"
echo "- Agent-workspaces: $(echo $AGENT_DIRS | wc -w)"
echo "- Дрейф: $([ $DRIFT -eq 1 ] && echo "ЕСТЬ ⚠️" || echo "нет ✓")"
} > "$OUT"

echo "Реестр пересобран: $OUT"
[ $DRIFT -eq 1 ] && echo "⚠️ Обнаружен дрейф — см. секцию 'Дрейф реестра'"
exit 0
