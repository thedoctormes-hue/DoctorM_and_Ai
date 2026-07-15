---
id: INC-001
timestamp: "2026-05-12T00:00:00Z"
category: process
type: incident
severity: medium
status: retired
agent: unknown
title: "INC-001: Timing attack в TWA-авторизации"
author: system
created: "2026-05-24T21:07:07+00:00"
updated: "2026-05-24T21:07:07+00:00"
confidence: outdated
source: manual
last_verified: 2026-06-17
code_refs: []
tags: [incident, migrated]
freshness_score: 98
last_checked: "2026-06-20T01:00:18+00:00"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-001: Timing attack в TWA-авторизации

## Дата
2026-05-12

## Критичность
P2 — средняя

## Описание
TWA-авторизация уязвима к timing attack — сравнение hash через `!==` позволяет определить корректность части хеша по времени ответа.

## Воздействие
- Возможность перебора hash через timing-анализ
- Компрометация аккаунтов администраторов

## Решение
Заменить обычное сравнение на `timingSafeEqual` в `src/server/auth.ts`.

## Статус
✅ Решено в BL-019 (см. `specs/BL-019-twa-security-hardening.md`)

## Связанные артефакты
- `specs/BL-019-twa-security-hardening.md`
- `memory/rules/security.md`
