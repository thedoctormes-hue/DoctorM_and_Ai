---
name: shell-death
description: Shell death после git checkout — session_init.sh cd в несуществующий worktree.
type: insight
status: active
verified: 2026-06-17
source: insight_shell_death_root_cause.md
---

# 💀 Shell Death После Git Checkout

## Проблема

session_init.sh пытается `cd` в worktree директорию, которой не существует (удалён или не создан). Shell умирает, сессия не стартует.

## Текущее состояние (подтверждено 2026-06-17)

`/root/LabDoctorM/.qwen/hooks/session_init.sh` содержит логику:
1. Определяет агента из CWD
2. Ищет worktree в `/root/LabDoctorM/worktrees/<agent>/`
3. Делает `cd "$VALID_CWD"` без проверки существования

## Правила

- Перед `cd` в worktree — проверять существование директории
- Если worktree удалён — не падать, а сообщать об ошибке
- Worktree создаются/удаляются оркестратором

## Связанное

- session_init.sh hook
- worktree isolation (INSIGHT-worktree-isolation.md)
