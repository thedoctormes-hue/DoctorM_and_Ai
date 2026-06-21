---
name: branch-discipline
description: Ветки ТОЛЬКО от main, scope агента в имени, не от чужих веток.
type: insight
status: active
verified: 2026-06-17
source: feedback_branch_discipline.md
---

# 🌿 Branch Discipline

## Правила
- Создавать ветки ТОЛЬКО от `main`
- Имя ветки = `agent-id/feature-name` (например: `bestia/techno-racer-v2`)
- Никогда не создавать ветки от чужих веток
- Никогда не коммитить из чужих веток

## Почему это важно
- Коммиты из чужой ветки попадают не туда
- ЗавЛаб в ярости при нарушении

## Как применять
- Перед `git checkout -b` ВСЕГДА `git checkout main`
- Перед первым коммитом проверять `git branch --show-current`
- Проверить `git log --oneline -1` после создания ветки
