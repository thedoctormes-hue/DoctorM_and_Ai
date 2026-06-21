---
type: backlog
id: BL-024
title: 'BL-033: Cost Tracking для AI API'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:25+00:00'
---
# BL-033: Cost Tracking для AI API

## Контекст
Нет отслеживания затрат на AI API вызовы (OpenRouter, OpenAI, Anthropic). Невозможно понять, сколько стоит каждый агент, проект или задача. Нет бюджетов и алертов при превышении.

## Цель
Реализовать систему отслеживания затрат на AI API с budget management, cost attribution и алертами.

## Зачем
Чтобы контролировать расходы на AI API, оптимизировать использование моделей и предотвращать неожиданные счета.

## Проект/контекст
Myrmex Control — backend (FastAPI) + модуль аналитики.

## Что сделать
- [ ] Создать provider abstraction layer для мультипровайдерной поддержки
- [ ] Реализовать token counting (tiktoken) перед API вызовами
- [ ] Создать cost tracking: per-request cost = tokens * model price
- [ ] Реализовать cost attribution: by agent, project, task, user
- [ ] Добавить budget management: daily/monthly budgets с alerts на 50/80/100%
- [ ] Реализовать semantic caching (30-50% reduction в API calls)
- [ ] Добавить rate limiting: provider limits + application limits + priority queue
- [ ] Создать дашборд затрат с графиками трендов
- [ ] Настроить balance monitoring с forecasting

## Критерии готовности
- [ ] Cost tracking работает для всех AI API вызовов
- [ ] Budget alerts срабатывают при достижении порогов
- [ ] Semantic caching снижает количество API calls на 30%+
- [ ] Дашборд показывает затраты по агентам/проектам/задачам
- [ ] Rate limiting корректно ограничивает запросы

## Зависимости
- BL-015 — Rate limiting (расширить на AI API)
- BL-029 — Health Score (метрики для дашборда)

## Назначение
- **Вес:** 3
- **Скиллы:** metrics-storyteller, performance-optimization
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- Fallback chain: primary model → fallback → local model
- Streaming responses для лучшего UX
- Retry с exponential backoff
