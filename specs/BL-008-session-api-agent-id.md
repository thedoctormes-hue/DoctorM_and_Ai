---
type: backlog
id: BL-008
title: Session Startup — API Agent ID Bug
status: done
author: system
created: '2026-05-15'
updated: '2026-05-15'
tags:
- backlog
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:22+00:00'
---

# Session Startup: API Agent ID Bug

## Проблема

В `session_startup.sh` для Context API используется `AGENT_ID`, который берется из myrmex.json. Но:

- В myrmex.json: `"id": "streik"` (alias)
- В директории: `streikbrecher` (kanban_id)
- Context API требует: `streikbrecher` (каноническое имя)

**Результат:** Для агента streikbrecher Context API возвращает 404 "Unknown agent alias: streik"

## Баг в коде

```bash
# session_startup.sh строка ~140:
CTX_RESPONSE="$(curl -sf "$CTX_API/api/v1/identity/$AGENT_ID?compact=true" 2>/dev/null)"
```

`AGENT_ID` — это id из myrmex.json (например, "streik", "kot", "ant"), а не каноническое имя.

## Решение

Использовать `AGENT_DIR` (kanban_id) для API:

```bash
CTX_AGENT="${AGENT_DIR:-$AGENT_ID}"
CTX_RESPONSE="$(curl -sf "$CTX_API/api/v1/identity/$CTX_AGENT?compact=true" 2>/dev/null)"
```

Или добавить каноническое имя в myrmex.json.

## Агенты в myrmex.json

| id | dir | aliases | Кто |
|----|-----|---------|-----|
| zavlab | zavlab | LabDoctorM | ЗавЛаб |
| kot | kotolizator | cat, kot, kotolizator | Кот |
| ant | antcat | ant, antcat, myrmex | Муравей |
| bestia | bestia | beast, bestia | Бестия |
| streik | streikbrecher | streik, streikbrecher | Штрейкбрехер |
| raven | raven | raven | Ворон |
| owl | owl | owl, sova | Сова |

## Статус

- [ ] Исправить session_startup.sh
- [ ] Протестировать для всех агентов
- [ ] Проверить, не ломает ли это другие части системы

## Приоритет

Low — работает через AGENT_DIR, но лучше исправить для консистентности.
