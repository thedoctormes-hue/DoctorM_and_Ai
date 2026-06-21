---
type: adr
id: ADR-020
title: 'ADR-004: Playwright: text=Войти не работает в document.querySele'
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
- projects/myrmex-control/e2e-tests/
freshness_score: 97
last_checked: '2026-06-20T01:00:16+00:00'
---

# ADR-004: Playwright: text=Войти не работает в document.querySelector

## Статус
proposed

## Контекст
Playwright: text=Войти не работает в document.querySelector — это Playwright-специфичный селектор. В DOM использовать CSS/XPath. Модальные оверлеи блокируют клики — нужен force=True или закрытие оверлея.

## Решение
<!-- Опиши принятое решение -->

## Последствия
- ✅ Позитивные
- ⚠️ Негативные

## Альтернативы

- **Текущий:** ..., ...


## Связанные инсайты
- ins_050

## Связанные артефакты
- Нет

## Примечания
Создано автоматически из инсайта #50 (скор: 9/10)
