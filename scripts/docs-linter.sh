#!/usr/bin/env bash
# docs-linter.sh — проверка канона документации лабы.
# Ловит, когда стандарт (ADR/PAT/RUL/QUALITY/SKILL) кладут в папку агента
# (workspaces/) вместо канона. Не трогает легитимные стандарты в projects/.
# WARN для доков в docs/ без заголовка (#). Не блокирует README проектов.
set -u

TOP="$(git rev-parse --show-toplevel 2>/dev/null)"
# работаем только в репо DoctorM_and_Ai (и его worktree-зеркалах)
case "$TOP" in
  */DoctorM_and_Ai*|*/DoctorM_and_Ai) : ;;
  *) exit 0 ;;
esac

CANON_ERR=0
CANON_WARN=0

is_standard() {
  case "$(basename "$1")" in
    ADR-*.md|RUL-*.md|PAT-*.md|QUALITY_STANDARDS.md|SKILL.md|SKILL-TEMPLATE.md) return 0 ;;
    *) return 1 ;;
  esac
}

while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    *.md)
      if is_standard "$f"; then
        # стандарт в папке агента — вне канона, блокируем
        case "$f" in
          *workspaces/*)
            echo "ERR: стандарт в папке агента (вне канона): $f"
            echo "     клади в projects/DoctorM_and_Ai/{adr,patterns,rules,docs,skills-canon}/"
            CANON_ERR=$((CANON_ERR+1))
            ;;
        esac
      fi
      # WARN: док в docs/ без заголовка
      case "$f" in
        docs/*.md)
          if [ -f "$f" ]; then
            first=$(grep -m1 . "$f" 2>/dev/null | head -c1)
            if [ "$first" != "#" ] && [ -n "$first" ]; then
              echo "WARN: док в docs/ без заголовка (#): $f"
              CANON_WARN=$((CANON_WARN+1))
            fi
          fi
          ;;
      esac
      ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep '\.md$')

if [ "$CANON_ERR" -gt 0 ]; then
  echo "docs-linter: НАЙДЕНО $CANON_ERR нарушений канона (блокирует коммит)"
  exit 1
fi
if [ "$CANON_WARN" -gt 0 ]; then
  echo "docs-linter: $CANON_WARN предупреждений (не блокирует)"
fi
echo "docs-linter: OK"
exit 0
