---
id: ADR-038
type: adr
title: Agent-to-Agent Connectivity — настройка связи между агентами
status: accepted
author: Доминика
created: '2026-06-18'
updated: '2026-06-18'
confidence: outdated
source: cross-analysis
freshness_score: 99
last_checked: '2026-06-20T01:00:18+00:00'
---

# ADR-038: Agent-to-Agent Connectivity — настройка связи между агентами

## Статус

Принято

## Контекст

Агенты лаборатории должны обмениваться сообщениями и координировать работу. Для этого требуется настроить межагентную связь в OpenClaw.

## Решение

В `openclaw.json` включить:

```json
{
  "tools": {
    "agentToAgent": {
      "enabled": true
    },
    "sessions": {
      "visibility": "all"
    }
  }
}
```

- `agentToAgent.enabled=true` — разрешает агентам отправлять сообщения друг другу
- `sessions.visibility=all` — все сессии видны всем агентам
- Связь через `sessions_send` с указанием `agentId` или `sessionKey`
- Для надёжной доставки использовать `sessionKey` (не `agentId`, который бьёт в `:main`)

## Последствия

- Агенты могут координировать работу без участия ЗавЛаба
- Требуется контроль доступа (не все агенты должны писать всем)
- Необходим мониторинг межагентного трафика

## Связанные

- ADR-031: Разделение проектов и агентов
- ADR-037: Agent Registry
