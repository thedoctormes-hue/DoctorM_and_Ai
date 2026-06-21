---
type: backlog
id: BL-053
title: BL-011-testing.md
status: pending
author: system
created: 2026-05-24 21:11:36+00:00
updated: 2026-05-24 21:11:36+00:00
tags:
- backlog
- vpn
- migrated
related:
- ADR-010
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:30+00:00'
---# BL-011: Тестирование и QA

## Контекст
Сейчас тестов нет. При 60к пользователей и модульной архитектуре нужен полный стек тестирования.

## Цель
Покрыть проект тестами: unit, integration, e2e, load.

## Зачем
- Предотвращение регрессий
- Уверенность при рефакторинге
- Документация поведения

## Что сделать
- [ ] Unit тесты: бизнес-логика, утилиты, парсеры (pytest, >80% coverage)
- [ ] Integration тесты: БД, Redis, Telegram API (aioresponses, testcontainers)
- [ ] E2E тесты: сценарии пользователя (aiogram test client)
- [ ] Load тесты: 1000 RPS на webhook endpoint (locust)
- [ ] Моки: Telegram API, xray API, payment webhooks
- [ ] CI: тесты на каждый PR, merge только при green
- [ ] Coverage report: codecov или similar

## Критерии готовности
- [ ] Coverage > 70% для бизнес-логики
- [ ] Все критические сценарии покрыты e2e
- [ ] Load тест: 1000 RPS без деградации
- [ ] CI pipeline блокирует merge при failed tests

## Зависимости
- BL-003 (модульная архитектура)

## Назначение
- **Вес:** 3
- **Скиллы:** cascade, test-driven-development
- **Статус:** pending
- **Приоритет:** medium

## Примечания
Оценка: 4-5 дней
Stack: pytest + aioresponses + testcontainers + locust
