---
type: adr
id: ADR-011
title: 'ADR-011: Frontend build output (dist/) != server static path (client/'
status: archived
author: system
created: 2026-05-24 17:16:12+00:00
updated: 2026-05-24 17:16:12+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- adr
- migrated
freshness_score: 97
last_checked: '2026-06-20T01:00:15+00:00'
---

# ADR-011: Frontend build output (dist/) != server static path (client/

## Статус
proposed

## Контекст
Frontend build output (dist/) != server static path (client/) — must copy dist/client/* to client/ after rebuild. Server reads static from server-dist/../client/

## Решение
<!-- Опиши принятое решение -->

## Последствия
- ✅ Позитивные
- ⚠️ Негативные

## Альтернативы

- **Текущий:** ..., ...


## Связанные инсайты
- ins_109

## Связанные артефакты
- Нет

## Примечания
Создано автоматически из инсайта #109 (скор: 9/10)

## Архивировано
