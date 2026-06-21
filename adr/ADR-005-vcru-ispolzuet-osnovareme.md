---
type: adr
id: ADR-005
title: 'ADR-005: vc.ru использует osnova-remember куки + auth-refresh-toke'
status: accepted
author: system
created: 2026-05-24 17:16:12+00:00
updated: 2026-05-24 17:16:12+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- adr
- migrated
code_refs:
- projects/hype-pilot/browser/auth.py
freshness_score: 97
last_checked: '2026-06-20T01:00:14+00:00'
---

# ADR-005: vc.ru использует osnova-remember куки + auth-refresh-token в

## Статус
proposed

## Контекст
vc.ru использует osnova-remember куки + auth-refresh-token в localStorage для авторизации. API v2.1 требует валидную сессию,  Bearer токен не работает. page.evaluate не решает проблему — браузер отправляет те же куки.

## Решение
<!-- Опиши принятое решение -->

## Последствия
- ✅ Позитивные
- ⚠️ Негативные

## Альтернативы

- **Текущий:** ..., ...


## Связанные инсайты
- ins_049

## Связанные артефакты
- Нет

## Примечания
Создано автоматически из инсайта #49 (скор: 9/10)
