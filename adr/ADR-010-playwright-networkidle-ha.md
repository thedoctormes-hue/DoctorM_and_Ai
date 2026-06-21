---
type: adr
id: ADR-010
title: 'ADR-010: Playwright networkidle hangs on SPA with lazy-loaded chunks'
status: accepted
author: system
created: 2026-05-24 17:16:11+00:00
updated: 2026-05-24 17:16:11+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- adr
- migrated
code_refs:
- projects/myrmex-control/e2e-tests/helpers.js
freshness_score: 97
last_checked: '2026-06-20T01:00:14+00:00'
---

# ADR-010: Playwright networkidle hangs on SPA with lazy-loaded chunks

## Статус
accepted

## Контекст
При использовании `waitUntil: 'networkidle'` в Playwright на SPA с lazy-loaded чанками страница зависает бесконечно. Это происходит потому что networkidle ждёт 0 сетевых соединений в течение 500ms, а SPA постоянно создаёт новые соединения для загрузки чанков.

## Решение
Использовать `waitUntil: 'domcontentloaded'` вместо `networkidle` для SPA. Если нужна гарантия загрузки контента — добавить явный `waitForTimeout(1500)` или `waitForSelector()` для целевого элемента.

## Последствия
- ✅ Позитивные: страницы загружаются без зависаний, тесты стабильнее
- ⚠️ Негативные: нужно явно указывать ожидание для динамического контента

## Альтернативы

- **domcontentloaded + waitForTimeout:** Просто, предсказуемо, Фиксированный таймаут может быть избыточным
- **domcontentloaded + waitForSelector:** Точное ожидание элемента, Нужно знать селектор целевого элемента
- **networkidle (текущий):** Автоматически ждёт загрузку, Зависает на SPA


## Связанные инсайты
- ins_112

## Связанные артефакты

- ADR-013 — Myrmex Control E2E: использует waitForTimeout вместо networkidle
- `/root/LabDoctorM/projects/lab-playwright-expert/browser.py`

## Примечание
Принято 19.05.2026 в рамках аудита артефактов.
