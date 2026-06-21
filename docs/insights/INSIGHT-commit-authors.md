---
name: commit-authors
description: Git commit authors должны соответствовать белому списку из git-authors.json.
type: insight
status: active
verified: 2026-06-17
source: feedback_commit_authors.md
---

# 👤 Git Commit Authors

## Проблема

Коммиты от неизвестных авторов могут попасть в общий репозиторий, нарушая политику безопасности.

## Правило

- Все авторы фиксируются в `/root/LabDoctorM/.qwen/git-authors.json`.
- `lab-commit.sh` проверяет, что `GIT_AUTHOR_EMAIL` присутствует в этом списке.
- Если автора нет — commit отклоняется, выводится сообщение.

## Почему это важно

- Защита от «кражи кода» и от случайных коммитов чужих лиц.
- ЗавЛаб требует, чтобы каждое изменение было привязано к конкретному агенту.
