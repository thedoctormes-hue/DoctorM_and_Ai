---
type: backlog
id: BL-029
title: 'BL-038: OpenAPI 3.1 + Webhook System'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:26+00:00'
---
# BL-038: OpenAPI 3.1 + Webhook System

## Контекст
API Myrmex Control не имеет формализованной спецификации. Нет документации для внешних интеграций, нет webhook системы для уведомлений о событиях.

## Цель
Создать OpenAPI 3.1 спецификацию с авто-генерацией из FastAPI, interactive docs, SDK generation и webhook систему.

## Зачем
Чтобы внешние сервисы могли интегрироваться с Myrmex Control через документированный API и получать real-time уведомления через webhooks.

## Проект/контекст
Myrmex Control — backend (FastAPI) + модуль API.

## Что сделать
- [ ] Настроить OpenAPI 3.1 auto-generation из FastAPI endpoints
- [ ] Добавить Swagger UI (/docs) и ReDoc (/redoc) с code examples
- [ ] Валидировать spec через Spectral (naming conventions, descriptions)
- [ ] Настроить API versioning: /api/v1/ (support 2 versions simultaneously)
- [ ] Реализовать webhook system: task.created, task.completed, agent.status_changed, deploy.started
- [ ] Добавить HMAC-SHA256 signature verification для webhooks
- [ ] Решить retry logic с exponential backoff + dead letter queue (10 failures)
- [ ] Создать webhook management UI (subscriptions, delivery logs, replay)
- [ ] Настроить auto-generate SDK (Python, JS) через OpenAPI Generator
- [ ] Добавить API security: API keys, OAuth 2.0, JWT, rate limiting, IP whitelisting

## Критерии готовности
- [ ] OpenAPI spec покрывает все endpoints
- [ ] Swagger UI и ReDoc работают с code examples
- [ ] Webhook delivery с HMAC verification работает
- [ ] Retry logic корректно обрабатывает failures
- [ ] SDK для Python и JS генерируется автоматически
- [ ] Rate limiting возвращает 429 с Retry-After

## Зависимости
- BL-011 — JWT (auth infrastructure)
- BL-015 — Rate limiting (расширить на API keys)

## Назначение
- **Вес:** 4
- **Скиллы:** api-and-interface-design, docs-writer-api
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- Audit logging всех API requests
- Webhook management UI в dashboard
- Export API changelog с breaking changes
