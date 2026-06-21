---
type: backlog
id: BL-033
title: 'BL-042: Demo Mode с Auto-Reset'
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
# BL-042: Demo Mode с Auto-Reset

## Контекст
Demo режим (demo.shtab-ai.ru) существует, но нет автоматического сброса данных, feature flags для управления функциональностью, guided tour для новых пользователей.

## Цель
Улучшить demo mode: realistic seed data, auto-reset (24h), feature flags, guided tour, demo analytics.

## Зачем
Чтобы demo выглядел как реальный продукт с живыми данными, привлекал новых пользователей и не требовал ручного обслуживания.

## Проект/контекст
Myrmex Control — demo environment.

## Что сделать
- [ ] Создать isolated demo environment на demo.shtab-ai.ru с separate database
- [ ] Генерировать realistic seed data через Faker (agents, projects, tasks, artifacts)
- [ ] Добавить relationships в seed data (agents → projects → tasks → artifacts)
- [ ] Распределить tasks по времени (past 30 days), разные статусы
- [ ] Реализовать auto-reset: scheduled (24h cron) + on-demand (admin dashboard)
- [ ] Добавить reset notification banner ("Demo resets in X hours")
- [ ] Внедрить feature flags (LaunchDarkly/Unleash или DB-backed)
- [ ] Создать guided tour: step-by-step walkthrough ключевых фич
- [ ] Добавить sample interactions ("Deploy a task", "Chat with agent")
- [ ] Настроить demo analytics (pages viewed, features tried, time spent)

## Критерии готовности
- [ ] Demo environment изолирована от production
- [ ] Seed data выглядит реалистично (relationships, time distribution)
- [ ] Auto-reset работает каждые 24h
- [ ] Feature flags переключают функциональность без редеплоя
- [ ] Guided tour проводит пользователя по ключевым фичам
- [ ] Demo analytics собирает данные

## Зависимости
- BL-036 — Dark Theme Design System (визуал demo)
- BL-028 — WebSocket Chat Panel (sample interactions)

## Назначение
- **Вес:** 3
- **Скиллы:** demo-mode, frontend-ui-engineering
- **Статус:** pending
- **Приоритет:** low

## Примечания
- Read-only mode или sandboxed changes
- Pre-computed data для быстродействия
- A/B testing через feature flags
- Performance: aggressive caching
