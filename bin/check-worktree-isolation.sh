#!/bin/sh
# Guard: блокирует коммит и git add в главном общем checkout.
# Агенты обязаны работать в изолированном git-worktree (PAT-019 I-03).
#
# Режимы:
#   (без аргументов) — guard коммита (вызывается из pre-commit / lab-commit.sh)
#   add               — guard git add (вызывается из bin/git-add-guard.sh / B8.1)
DEFAULT_MAIN="/root/LabDoctorM/projects/DoctorM_and_Ai"
MODE="${1:-commit}"

MAIN_FILE="$(git rev-parse --show-toplevel 2>/dev/null)/bin/main-checkout.txt"
if [ -f "$MAIN_FILE" ]; then
  MAIN_CHECKOUT="$(head -1 "$MAIN_FILE" | tr -d '[:space:]')"
else
  MAIN_CHECKOUT="$DEFAULT_MAIN"
fi
[ -z "$MAIN_CHECKOUT" ] && MAIN_CHECKOUT="$DEFAULT_MAIN"

CURRENT="$(git rev-parse --show-toplevel 2>/dev/null)" || CURRENT=""
CURRENT_REAL="$(realpath "$CURRENT" 2>/dev/null || echo "$CURRENT")"
MAIN_REAL="$(realpath "$MAIN_CHECKOUT" 2>/dev/null || echo "$MAIN_CHECKOUT")"

if [ "$CURRENT_REAL" = "$MAIN_REAL" ]; then
  if [ "${LAB_ALLOW_MAIN_COMMIT:-}" = "1" ]; then
    echo "[isolation-guard] bypass: LAB_ALLOW_MAIN_COMMIT=1"
    exit 0
  fi
  if [ "$MODE" = "add" ]; then
    echo "BLOCKED by git-add guard (PAT-019 I-03 / B8.1):" >&2
    echo "  Вы пытаетесь 'git add' в главном общем checkout: $MAIN_REAL" >&2
    echo "  Агенты обязаны работать в изолированном git-worktree." >&2
    echo "  Используйте: bin/git-add-guard.sh <файлы>  (он заблокирует add в main)" >&2
    echo "  Создать worktree:" >&2
    echo "    git worktree add -b <agent>/<task> <path> main" >&2
    echo "  Bypass (только инфра/ЗавЛаб): LAB_ALLOW_MAIN_COMMIT=1 git add ..." >&2
  else
    echo "BLOCKED by worktree-isolation guard (PAT-019 I-03):" >&2
    echo "  Вы в главном общем checkout: $MAIN_REAL" >&2
    echo "  Агенты обязаны работать в изолированном git-worktree." >&2
    echo "  Создать worktree:" >&2
    echo "    git worktree add -b <agent>/<task> <path> main" >&2
    echo "  Bypass (только инфра/ЗавЛаб): LAB_ALLOW_MAIN_COMMIT=1 git commit ..." >&2
  fi
  exit 1
fi
exit 0
