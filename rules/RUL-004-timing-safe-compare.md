---
type: rule
id: RUL-004
title: 'RUL-004: Timing-safe сравнение для секретов'
status: active
author: system
created: 2026-05-24 21:07:07+00:00
updated: 2026-05-24 21:07:07+00:00
tags:
- rule
- migrated
code_refs: []
related:
- INC-013
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:31+00:00'
---# RUL-004: Timing-safe сравнение для секретов

## Категория
security

## Описание
Сравнение секретов (токенов, хешей, паролей) через `===` или `!==` уязвимо к timing attack. Злоумышленник может определить корректность части хеша по времени ответа.

## Обязательно
- [ ] Все сравнения секретов через `crypto.timingSafeEqual()` (Node.js) или аналог
- [ ] Запрет использования `===`/`!==` для сравнения хешей/токенов
- [ ] При обнаружении уязвимости — немедленное исправление

## Исключения
Нет.

## Наказание за нарушение
**block** — код не проходит security review.

## Связанные артефакты
- INC-001 — Timing attack в TWA-авторизации
- BL-019 — TWA security hardening

## Примечание
Инцидент INC-001: TWA-авторизация сравнивала hash через `!==`. Исправлено на `timingSafeEqual` в `src/server/auth.ts`.
