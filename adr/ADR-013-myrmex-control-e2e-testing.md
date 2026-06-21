---
type: adr
id: ADR-013
title: 'ADR-013: Myrmex Control — E2E тестирование (Playwright)'
status: accepted
author: system
created: 2026-05-24 21:07:07+00:00
updated: 2026-05-24 21:07:07+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- adr
- migrated
code_refs:
- projects/myrmex-control/e2e-tests/
freshness_score: 97
last_checked: '2026-06-20T01:00:15+00:00'
---

# ADR-013: Myrmex Control — E2E тестирование (Playwright)

## Контекст

Myrmex Control v2.0 — SPA с 16+ страницами. Нужны E2E тесты для проверки:
- Авторизации
- Навигации (все страницы)
- Функциональности (CRUD, фильтры, перспективы)
- Двух перспектив (руководитель лаборатории / пользователь)

## Решение

14 тестовых файлов в `e2e-tests/`:


## Критические решения

1. **`networkidle` зависает** — заменён на `waitForTimeout(1500)` в `clickSidebar()`
2. **Локаль** — форсируется EN через `localStorage.setItem('myrmex_lang', 'en')`
3. **Таймауты** — test 60s, expect 15s
4. **Асинхронные страницы** — нужны `waitFor` вместо `toContainText`

## Альтернативы
- **Playwright E2E:** полное покрытие UI — ✅ выбран
- **Unit-тесты только:** быстрее, но нет покрытия UI — отклонён

## Статус

- ✅ Все 14 файлов написаны
- ✅ Auth helpers настроены
- ⏳ Запуск и фикс падающих тестов

## Связанные артефакты

- ADR-010 — Playwright networkidle hangs → решение: waitForTimeout + waitForSelector
- ADR-012 — Dual Auth: E2E тесты используют access_token из login response
- ADR-009 — SPA requires dual auth, E2E helpers адаптированы

## Связанные инсайты

- #112: Playwright networkidle hangs on SPA
