#!/bin/sh
# Безопасная замена `git add` в DoctorM_and_Ai (B8.1, PAT-019 I-03).
# Блокирует `git add` в главном общем checkout, иначе делегирует в git add.
#
# Использование: bin/git-add-guard.sh <файлы...>   (аргументы как у git add)
# Bypass (только инфра/ЗавЛаб): LAB_ALLOW_MAIN_COMMIT=1 bin/git-add-guard.sh <файлы...>
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/check-worktree-isolation.sh" add || exit $?
exec git add "$@"
