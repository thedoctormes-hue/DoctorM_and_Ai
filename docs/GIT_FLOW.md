---
description: "GIT FLOW"
type: guide
last_reviewed: 2026-06-21
last_code_change: 2026-06-18
status: active
---

# Git Flow — Лаборатория

## Структура веток

```
main          ← чистовик, всегда стабилен
  └── agent-name/feature-name  ← черновики для работы (agent-name = имя папки в projects/)
```

## Правила именования

| Агент | Префикс | Пример |
|---|---|---|
| Муравей | `antcat/` | `antcat/disable-agents-page` |
| Бестия | `bestia/` | `bestia/snablab-bot-go` |
| Котолизатор | `kotolizator/` | `kotolizator/git-basics` |
| Сова | `owl/` | `owl/lab-vault-project-scoping` |
| Штреикбрехер | `streikbrecher/` | `streikbrecher/lab-vault-treatment` |
| Ворон | `raven/` | `raven/consilium-evolution` |

## Жизненный цикл ветки

```
1. Создать от main:     git checkout -b agent-name/feature-name main
2. Работать:            git add ... && git commit -m "type(scope): описание"
3. Мерж в main:         git checkout main && git merge agent-name/feature-name
4. Удалить ветку:       git branch -d agent-name/feature-name
```

## Формат коммитов

```
type(scope): краткое описание

Типы: feat, fix, test, refactor, chore, docs
Scope: имя папки агента (antcat, bestia, kotolizator, owl, streikbrecher, raven) или lab
```

Примеры:
- `feat(antcat): добавить артефакты в myrmex-control`
- `fix(owl): Bearer приоритетнее cookie`
- `chore(lab): организация Git — уборка мусора`

## Что НЕ коммитить

- `CHECKPOINT.md` — чекпоинты (в .gitignore)
- `.qwen/artifacts/` — артефакты runtime (в .gitignore)
- `SESSION_HANDOFF.md` — файлы смены (в .gitignore)
- `ARTIFACT_CHANGELOG.md` — генерируемый (в .gitignore)
- `projects/hype-pilot/inbox/approved_posts/` — посты (в .gitignore)

## Когда мержить

- Работа завершена и протестирована
- Коммиты в feature-ветке чистые (без "WIP" и "fix typo")
- Нет конфликтов с main

## Когда удалять ветку

- Сразу после мержа в main
- Если ветка не нужна (эксперимент не удался)

## Регулярная уборка

- Удалять ветки, которые уже в main
- Удалять worktree после завершения работы
- Проверять `git status` перед началом работы
