#!/usr/bin/env bash
#
# git-hygiene-linter.sh — read-only аудит «грязных деревьев» во всех git-репозиториях лаборатории.
# Саб-брат incident-linter (ADR-0056 enforcement). Находит незакоммиченный/untracked мусор,
# который агенты оставляют в своих workspace и проектах, и пишет сводку.
#
# НИЧЕГО НЕ КОММИТИТ, НЕ УДАЛЯЕТ, НЕ ПУШИТ — только читает и докладывает.
#
# Использование:
#   git-hygiene-linter.sh [--lab ROOT] [--strict] [--quiet]
#     --strict : exit 1 при наличии грязных деревьев (для алертов/гейтов)
#     --quiet  : только итоговые числа
#
# Автор: Сова (owl) — аудит-тулинг, 2026-07-13
#
set -uo pipefail

LAB_ROOT="/root/LabDoctorM"
STRICT=0
QUIET=0

# исключения при поиске репозиториев
EXCLUDE=("/.ops/" "/vault/" "node_modules" "/.github/")

usage() { grep -E '^#' "$0" | sed 's/^#\s\?//' | head -30; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --lab) LAB_ROOT="$2"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

# собрать все .git директории (не файлы worktree)
mapfile -t GITDIRS < <(find "$LAB_ROOT" -maxdepth 5 -name '.git' -type d 2>/dev/null | sort)

is_excluded() {
  local p="$1" s
  for s in "${EXCLUDE[@]}"; do
    case "$p" in *"$s"*) return 0 ;; esac
  done
  return 1
}

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SEP="================================================================"
REPOS=0
DIRTY=0
declare -a DIRTY_REPORT=()

# маппинг workspace -> агент-владелец; иначе "shared"
agent_for() {
  local repo="$1"
  if [[ "$repo" == "$LAB_ROOT/workspaces/"* ]]; then
    local rel="${repo#$LAB_ROOT/workspaces/}"
    local agent="${rel%%/*}"
    echo "$agent"
  else
    echo "shared"
  fi
}

for g in "${GITDIRS[@]}"; do
  is_excluded "$g" && continue
  repo="$(dirname "$g")"
  [ -d "$repo/.git" ] || continue
  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  ahead=0; behind=0
  if git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    ahead=$(git -C "$repo" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$repo" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
  fi
  status="$(git -C "$repo" status --porcelain 2>/dev/null)"
  REPOS=$((REPOS+1))
  if [ -z "$status" ]; then
    continue
  fi
  DIRTY=$((DIRTY+1))
  owner="$(agent_for "$repo")"
  nlines=$(printf '%s\n' "$status" | grep -c .)
  block="## $repo
owner: $owner | branch: $branch | ahead: $ahead | behind: $behind | changed_files: $nlines
\`\`\`
$status
\`\`\`"
  DIRTY_REPORT+=("$block")
done

if [ "$QUIET" -eq 0 ]; then
  echo "$SEP"
  echo " GIT HYGIENE LINTER REPORT"
  echo " Generated : $NOW"
  echo " Lab root  : $LAB_ROOT"
  echo " Repos     : $REPOS"
  echo " Dirty     : $DIRTY"
  echo "$SEP"
  if [ "$DIRTY" -gt 0 ]; then
    for b in "${DIRTY_REPORT[@]}"; do echo "$b"; echo; done
  else
    echo " Все репозитории чисты. Грязных деревьев нет."
    echo
  fi
  echo "$SEP"
fi

echo " SUMMARY"
echo "   repos_scanned : $REPOS"
echo "   dirty_trees   : $DIRTY"
echo "$SEP"

if [ "$STRICT" -eq 1 ] && [ "$DIRTY" -gt 0 ]; then
  exit 1
fi
exit 0
