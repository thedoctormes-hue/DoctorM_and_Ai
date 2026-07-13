---
id: 2026-06-28-bestia-stale
timestamp: "2026-06-28T00:00:00Z"
category: process
type: other
severity: medium
status: open
agent: bestia
title: INC-20260628-BESTIA-STALE
---

# INC-20260628-BESTIA-STALE

**Дата:** 2026-06-28 09:21 UTC
**Агент:** bestia
**Статус:** 🔴 Требует внимания

## Описание

Heartbeat-state.json агента bestia не обновлялся с **2026-06-20 17:02 UTC** — 8 дней без активности.

## Наблюдения

- Все Docker контейнеры работают (9/9)
- Gateway жив (pid=300610, :18789)
- Owl активен (последний heartbeat 09:10 UTC)
- Bestia — нет активных main-сессий

## Возможные причины

1. Процесс bestia не запущен / упал
2. Heartbeat для bestia не настроен
3. Агент намеренно остановлен

## Рекомендация

Проверить запущен ли процесс bestia. Если агент больше не нужен — документировать остановку. Если нужен — перезапустить.
