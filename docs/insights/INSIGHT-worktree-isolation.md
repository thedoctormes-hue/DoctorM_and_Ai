---
name: worktree-isolation
description: Каждый агент работает в своём git worktree — физическая изоляция веток.
type: insight
status: active
verified: 2026-06-17
source: project_worktree_isolation.md
---

# 🌳 Worktree Изоляция Агентов

## Принцип
Один агент = один worktree = одна ветка. С 07.06.2026 вместо общего worktree с переключением веток.

## Текущее состояние (подтверждено 2026-06-17)
- `/root/LabDoctorM` → main (root)
- `.worktrees/antcat/` → antcat/session
- `.worktrees/bestia/` → bestia/session
- `.worktrees/kotolizator/` → kotolizator/session
- `.worktrees/owl/` → owl/session
- `.worktrees/raven/` → raven/session
- `.worktrees/streikbrecher/` → streikbrecher/session

## Почему это важно
- Исключает race condition на git index
- Каждый агент видит только свои изменения
- Коммиты не пересекаются
- ЗавЛаб/оркестратор мержит feature-ветки в main

## Правила
- Агент запускается в своём worktree
- Не переключаться на чужой worktree
- Не коммитить в main напрямую (кроме ЗавЛаба)
