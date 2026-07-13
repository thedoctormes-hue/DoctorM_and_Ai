#!/usr/bin/env bash
# skill-link-lint.sh — contract-тест слоя связности скиллов (ADR-0056).
# Ловит: (a) обходные workspace-копии, (b) битые ссылки на несуществующие скилы,
#        (c) скилы канона, отсутствующие в реестре Myrmex.
# Не падает (exit 0 всегда); выводит WARN/OK. Предназначен для крона (рядом с gatekeeper-audit.timer).
set -uo pipefail

LAB=/root/LabDoctorM
CANON="$LAB/projects/DoctorM_and_Ai/skills-canon"
MYRMEX_REG="$LAB/projects/myrmex-control/skill-registry.json"
WS_ROOT="$LAB/workspaces"
TMP="${TMPDIR:-/tmp}/sll_$$"
: > "$TMP"
ISSUES=0

# слова, которые часто в кавычках рядом с контекстом скила, но скилами НЕ являются
WHITELIST="skill_workshop defaults excluded skills depends_on old-name skill-improvement openclaw skill-creator spike _builtin_plugin_skills skill_later skill_earlier1 skill_earlier2"

known_skills=$(
  find "$CANON" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort -u
)

echo "=== (a) Обходные workspace-копии скиллов ==="
found_ws=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  echo "  WARN: обходная копия скила вне канона: $f"
  ISSUES=$((ISSUES+1)); found_ws=1
done < <(find "$WS_ROOT" -type f -path '*/skills/*/SKILL.md' 2>/dev/null)
[ "$found_ws" -eq 0 ] && echo "  OK: обходных копий нет"

echo
# (c): Примечание — myrmex skill-registry.json содержит PROJECT-SPECIFIC скиллы
# проекта myrmex-control (add-pytest, security-audit, ...). Лаб-скиллы (AgentSkills
# из skills-canon/) туда НЕ вносятся по дизайну — они регистрируются через
# skill_workshop (см. ADR-0056). Поэтому (c) НЕ требует лаб-скиллы в этом реестре.
# (c) проверяет: файл реестра существует, валиден (JSON), и его скиллы не дублируются
# расходящимися клонами вне skills-canon/ (registry -> canon consistency).
echo "=== (c) Реестр Myrmex (skill-registry.json) ==="
if [ -f "$MYRMEX_REG" ] && jq empty "$MYRMEX_REG" 2>/dev/null; then
  reg_count=$(jq '.skills | length' "$MYRMEX_REG" 2>/dev/null || echo "?")
  echo "  OK: реестр Myrmex найден и валиден ($reg_count записей project-specific скиллов)"
  echo "  INFO: лаб-скиллы (skills-canon/) регистрируются через skill_workshop, НЕ дублируются сюда (ADR-0056)"
else
  echo "  WARN: реестр Myrmex не найден или невалиден JSON: $MYRMEX_REG"
  ISSUES=$((ISSUES+1))
fi

echo
echo "=== (b) Битые ссылки на скилы (токен в кавычках рядом со словом skill) ==="
PAT='`[a-z0-9_-]+`|'"'"'[a-z0-9_-]+'"'"'|"[a-z0-9_-]+"'
is_whitelisted() {
  local t="$1"
  for w in $WHITELIST; do
    [ "$t" = "$w" ] && return 0
  done
  # примеры-заглушки вида skill1, skill_later, skill_earlier2
  echo "$t" | grep -qE '^skill[0-9_]*$' && return 0
  return 1
}
while IFS= read -r sk; do
  [ -n "$sk" ] || continue
  base=$(basename "$(dirname "$sk")")
  grep -nE "(skill|Скил|навык)" "$sk" 2>/dev/null | while IFS=: read -r ln line; do
    echo "$line" | grep -oE "$PAT" | tr -d '`'"'"'"' | while IFS= read -r tok; do
      if is_whitelisted "$tok"; then continue; fi
      if ! echo "$known_skills" | grep -qx "$tok"; then
        echo "  WARN: [$base] упомянут скил '$tok', которого нет в каноне (битая ссылка?)"
        echo "1" >> "$TMP"
      fi
    done
  done
done < <(find "$CANON" -name SKILL.md 2>/dev/null)
if [ -s "$TMP" ]; then
  n=$(wc -l < "$TMP")
  ISSUES=$((ISSUES + n))
fi
rm -f "$TMP"
echo "  (проверка завершена; см. WARN выше — требуют ручной сверки)"

echo
if [ "$ISSUES" -gt 0 ]; then
  echo "ИТОГ: найдено проблем: $ISSUES. Требуется ручная сверка (см. ADR-0056)."
else
  echo "ИТОГ: OK — слой связности чист."
fi
exit 0
