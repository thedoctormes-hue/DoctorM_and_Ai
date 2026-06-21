---
name: git-identity-race
description: "Git identity в общем репо — race condition между агентами. Решение: lab-commit.sh + pre-commit hook."
type: insight
status: active
verified: 2026-06-17
source: feedback_git_identity_shared_repo.md
---

# 🔐 Git Identity Race Condition

## Проблема
В общем репозитории `/root/LabDoctorM` несколько агентов коммитят одновременно. Локальный `git config user.name/email` переписывается между командами — коммиты уходят под чужой личностью.

## Решение (подтверждено 2026-06-17)
- `scripts/lab-commit.sh` — обёртка, задаёт автора через `GIT_AUTHOR_*`/`GIT_COMMITTER_*` env (процесс-локально → race-free)
- `.githooks/pre-commit` — верифицирует итогового автора по белому списку (`.qwen/git-authors.json`)
- Маппинг агентов: 8 агентов с email `@labdoctorm.ru`

## Правила
- Коммить ТОЛЬКО через `scripts/lab-commit.sh`
- НЕ ставить `git config user.*` вручную
- После коммита проверять `git log -1 --format='%an <%ae>'`
- НЕ переписывать историю (rebase/amend) в общем активном репо

## Связанное
- ADR-027-git-identity-race.md
- git-authors.json
