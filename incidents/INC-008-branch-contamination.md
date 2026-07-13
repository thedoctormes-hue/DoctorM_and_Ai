---
id: INC-008
timestamp: "2026-06-04T00:00:00Z"
category: tech
type: incident
severity: high
status: closed
agent: owl
title: "INC-008: Контаминация веток — Штрейкбрехер запущен на чужой ветке OWL"
author: streikbrecher
created: "2026-06-05T06:11:00+00:00"
updated: "2026-06-05T06:11:00+00:00"
tags: [incident, git, branch-contamination, owl, streikbrecher]
code_refs:
description: При старте сессии session_startup.sh не переключил на ветку Штрейкбрехера из-за мёртвого worktree. Агент оказался на owl/artifact-system-v4 с чужими незакоммиченными изменениями.
related: [INC-009]
source: agent
last_verified: 2026-06-17
---

## Описание
При старте сессии агента «Штрейкбрехер» скрипт `session_startup.sh` не переключил рабочую директорию на ветку Штрейкбрехера. Worktree `/root/LabDoctorM/worktrees/streikbrecher/` существует как директория, но **не зарегистрирован в `git worktree list`**. Скрипт проверяет только `[ -d "$WT_DIR" ]` — этого недостаточно. В результате агент оказался на ветке `owl/artifact-system-v4` с незакоммиченными изменениями OWL.

## Severity
🟠 **HIGH** — риск загрязнения чужих веток, нарушения границ ответственности агентов.

## Хронология

- **2026-06-04 23:18** — OWL создаёт коммит `541939c6` на `owl/artifact-system-v4`, оставляет незакоммиченные изменения (4 modified, 3 untracked)
- **2026-06-05 ~06:11** — ЗавЛаб запускает `session_startup.sh streikbrecher`
- **2026-06-05 ~06:11** — Скрипт находит worktree по `[ -d ]`, но он мёртв (не в `git worktree list`)
- **2026-06-05 ~06:11** — Штрейкбрехер стартует на `owl/artifact-system-v4` с чужими изменениями
- **2026-06-05 ~06:12** — ЗавЛаб указывает: «Это не твоя ветка!»
- **2026-06-05 ~06:12** — Штрейкбрехер откатывает чужие изменения, переключается на `streikbrecher/main`
- **2026-06-05 ~06:13** — Расследование, создание инцидента

## Корневые причины

### 1. Мёртвый worktree `streikbrecher`
- Директория существует на диске, но не зарегистрирована в git
- `git worktree list` показывает только корневой репозиторий
- `session_startup.sh` проверяет только `[ -d "$WT_DIR" ]` — этого недостаточно

### 2. OWL оставил грязный working directory
- 4 файла с незакоммиченными изменениями: `artifact_stats.json`, `ARTIFACT_CHANGELOG.md`, `metrics-history.json`, `myrmex.json`
- 3 untracked файла: `constraints_latest.json`, `health_latest.json`, `links_latest.json`
- Нарушение ADR-012: агент не завершил сессию чисто

### 3. `session_startup.sh` не верифицирует ветку
- Нет проверки `git rev-parse --abbrev-ref HEAD` после переключения
- Нет аборта если ветка не соответствует агенту
- Нет fallback при битом worktree

## Доказательства

**Reflog:**

```
dd217d7e HEAD@{0}: checkout: moving from raven/explore-2026-06-05 to streikbrecher/main
541939c6 HEAD@{1}: checkout: moving from owl/artifact-system-v4 to raven/explore-2026-06-05
541939c6 HEAD@{3}: commit: fix(artifacts): исправить циклические зависимости и ошибки статусов
```

**Worktree list (только корневой):**

```
/root/LabDoctorM  dd217d7e [streikbrecher/main]
```

## Действия

- [x] Штрейкбрехер откатил чужие изменения и переключился на `streikbrecher/main`
- [x] Создан инцидент INC-008
- [ ] Удалить мёртвый worktree: `rm -rf /root/LabDoctorM/worktrees/streikbrecher`
- [ ] Создать корректный worktree: `git worktree add worktrees/streikbrecher streikbrecher/main`
- [ ] Доработать `session_startup.sh`: проверка через `git worktree list`, верификация ветки, fallback на `git checkout`
- [ ] Зафиксировать правило: агент обязан заканчивать сессию чисто (commit/stash)

## Критерии устранения

- [x] Штрейкбрехер на своей ветке
- [ ] Мёртвый worktree удалён, новый создан
- [ ] `session_startup.sh` доработан
- [ ] Правило завершения сессии зафиксировано

## Статус
open

## Ответственный
Совет (координация), OWL (очистка ветки), Штрейкбрехер (верификация)

## Адресат
@soviet — на ревью и утверждение плана исправлений

## Связанные артефакты
- ADR-012 — Git Flow (правила ветвления)
- `.qwen/scripts/session_startup.sh`
