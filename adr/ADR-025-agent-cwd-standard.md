---
id: ADR-025
title: Стандарт рабочего пространства агента в OpenClaw
type: adr
status: accepted
created: '2026-06-13'
updated: '2026-06-17'
author: antcat
related:
- ADR-003
- ADR-028
source: agent
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:17+00:00'
---

# ADR-025: Стандарт рабочего пространства агента в OpenClaw

## Контекст

В OpenClaw рабочее пространство агента — директория `/root/LabDoctorM/workspaces/<agent_id>/`. Именно из этой директории OpenClaw автоматически загружает **файлы контекста** (см. `concepts/context.md`).

Ранее в Qwen Code использовался каталог `projects/<agent_id>/` в качестве cwd — тогда туда записывались файлы типа `CHECKPOINT.md`, `SESSION_HANDOFF.md`, `SOUL-compact.md`. При миграции в OpenClaw эти файлы переместились в `workspaces/`, а `projects/<agent_id>/` оставилось только с файлом-маркером `.openclaw/workspace-state.json`.

## Решение (OpenClaw)

**Рабочее пространство агента (`workspaces/<agent_id>/`) содержит только системные файлы, которые OpenClaw инжектирует в контекст модели:**

- `AGENTS.md` — карта пространства, правила, инструкции
- `SOUL.md` — душа агента (личность, тон, принципы)
- `IDENTITY.md` — метаданные агента
- `TOOLS.md` — локальные заметки по инструментам
- `USER.md` — информация о пользователе
- `HEARTBEAT.md` — периодические проверки
- `MEMORY.md` — долгосрочная память (загружается в main session)
- `SOUL-compact.md` — компактная версия души (обязательно)
- `SESSION_HANDOFF.md` — передача смены (опционально)
- `CHECKPOINT.md` — чекпоинт (генерируется автоматически)

**`projects/<agent_id>/` теперь служит только для хранения мета-файла состояния:**

- `.openclaw/workspace-state.json` — файл-маркер (`setupCompletedAt`). Используется OpenClaw при bootstrap. Других файлов в `projects/` нет.

**Запрещено хранить в рабочем пространстве:**

- Отчёты, аналитика, логи → `/root/LabDoctorM/.qwen/artifacts/` или `/var/lib/<agent>/`
- Скрипты и утилиты → `/root/LabDoctorM/shared/scripts/` или директория проекта
- `__pycache__/`, `.pytest_cache/`, `.ruff_cache/` — игнорируются автоматом
- Досье, каркасы, SESSION_LOG — не относятся к workspace
- Аудиофайлы (.ogg, .wav, .mp3) — не инжектируются в контекст
- Бэкапы (.bak) — использовать git для истории

**Артефакты агентов хранятся в:**

- `/root/LabDoctorM/.qwen/artifacts/` — общие артефакты (инсайты, аудиты)
- `/var/lib/<agent>/` — персистентные данные агента (отчёты патруля и т.д.)

## Последствия

**Положительные:**

- workspace агентов чисты и предсказуемы
- нет мусора в `git status`
- единый источник истины — `workspaces/<agent>/`
- `projects/<agent>/` можно безопасно удалить после проверки зависимостей

**Отрицательные:**

- потребовалась миграция из Qwen-эпохи
- скрипты, писавшие в `projects/<agent>/`, нужно перенаправить

## Статус

Принят. Обновлён 17.06.2026 для OpenClaw. Миграция выполнена: мусор удалён, структура приведена в соответствие.
