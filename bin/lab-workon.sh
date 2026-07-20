#!/usr/bin/env bash
# lab-workon.sh — поднять изолированный worktree + ветку для агента в репозитории.
#
# Назначение: когда агент берёт WRITE-задачу в репозитории, одной командой
# поднять ему собственный worktree (изоляция незакомиченных файлов) на
# собственной ветке <agent>/... (изоляция истории + прохождение guard'а ADR-0059).
#
# Использование:
#   lab-workon.sh <agent> <repo> [branch]
#     <agent>  — id агента (из git-authors.json), напр. raven
#     <repo>   — имя репозитория в projects/, напр. mcp-tools
#     [branch] — опционально: имя ветки (по умолчанию <agent>/work-<YYYYMMDD>)
#
# Результат: worktree в workspaces/<agent>/<repo> на ветке <branch> (от origin/main),
#            готовый к коммитам через lab-commit.sh <agent>.
#
# Идемпотентно: если worktree уже есть — просто сообщает путь, не пересоздаёт.
set -eu

LAB=/root/LabDoctorM
agent="${1:-}"
repo="${2:-}"
branch="${3:-}"

if [ -z "$agent" ] || [ -z "$repo" ]; then
  echo "Использование: lab-workon.sh <agent> <repo> [branch]" >&2
  exit 1
fi

# --- валидация агента (против git-authors.json) ---
AUTHORS=""
[ -f "$LAB/projects/$repo/git-authors.json" ] && AUTHORS="$LAB/projects/$repo/git-authors.json"
[ -z "$AUTHORS" ] && [ -f "$LAB/projects/DoctorM_and_Ai/git-authors.json" ] && \
  AUTHORS="$LAB/projects/DoctorM_and_Ai/git-authors.json"
if [ -z "$AUTHORS" ] || ! command -v jq >/dev/null 2>&1 || \
   ! jq -e --arg id "$agent" 'has($id)' "$AUTHORS" >/dev/null 2>&1; then
  echo "lab-workon: неизвестный агент '$agent' (нет в git-authors.json)" >&2
  exit 1
fi

repo_dir="$LAB/projects/$repo"
if [ ! -e "$repo_dir/.git" ]; then
  echo "lab-workon: репозиторий '$repo' не найден (нет projects/$repo/.git)" >&2
  exit 1
fi

# --- ветка (по умолчанию датированная, всегда с префиксом <agent>/) ---
if [ -z "$branch" ]; then
  branch="${agent}/work-$(date +%Y%m%d)"
fi
case "$branch" in
  "$agent"/*) ;;
  *) branch="${agent}/${branch}" ;;
esac

wt="$LAB/workspaces/$agent/$repo"

# --- уже существует? ---
if git -C "$repo_dir" worktree list --porcelain 2>/dev/null | grep -qFx "worktree $wt"; then
  echo "lab-workon: worktree уже существует: $wt"
  echo "  переходи: cd $wt"
  exit 0
fi
if [ -e "$wt" ]; then
  echo "lab-workon: путь $wt уже занят (не worktree). Разберись вручную." >&2
  exit 1
fi

# --- база для новой ветки ---
base="origin/main"
if ! git -C "$repo_dir" rev-parse --verify "$base" >/dev/null 2>&1; then
  base="main"
fi
git -C "$repo_dir" fetch origin main >/dev/null 2>&1 || true   # освежить main (best-effort)

mkdir -p "$(dirname "$wt")"

if git -C "$repo_dir" rev-parse --verify "$branch" >/dev/null 2>&1 || \
   git -C "$repo_dir" rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
  git -C "$repo_dir" worktree add "$wt" "$branch"
else
  git -C "$repo_dir" worktree add -b "$branch" "$wt" "$base"
fi

echo "✅ worktree готов: $wt"
echo "   ветка:   $branch (от $base)"
echo "   перейти: cd $wt"
echo "   коммитить: bash $LAB/projects/$repo/bin/lab-commit.sh $agent -m \"feat(scope): ...\""
echo "   удалить после мержа: git worktree remove $wt && git -C $repo_dir branch -d $branch"
