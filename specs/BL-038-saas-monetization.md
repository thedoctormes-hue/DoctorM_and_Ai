---
type: backlog
id: BL-038
title: 'BL-047: SaaS Monetization — Pricing Tiers'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:27+00:00'
---
# BL-047: SaaS Monetization — Pricing Tiers

## Контекст
Myrmex Control — бесплатный внутренний инструмент. Нет монетизации, pricing tiers, billing системы. Для перехода к SaaS модели нужна инфраструктура.

## Цель
Подготовить инфраструктуру для SaaS монетизации: 4 pricing tiers, feature gating, usage-based billing.

## Зачем
Чтобы Myrmex Control мог стать коммерческим продуктом и генерировать доход.

## Проект/контекст
Myrmex Control — полный стек.

## Что сделать
- [ ] Определить 4 pricing tiers: Free (3 agents), Pro $29/mo (20), Team $99/mo (100), Enterprise (custom)
- [ ] Реализовать feature gating по tier
- [ ] Добавить usage-based overage billing
- [ ] Создать 14-day free trial для Pro tier
- [ ] Реализовать annual discount (20%)
- [ ] Настроить SaaS метрики tracking: MRR, churn, LTV:CAC, NPS
- [ ] Создать open-core model: open-source basic, monetize advanced
- [ ] Подготовить integration marketplace

## Критерии готовности
- [ ] 4 pricing tiers настроены
- [ ] Feature gating работает
- [ ] Usage-based billing функционирует
- [ ] Free trial работает (14 days, no credit card)
- [ ] SaaS метрики собираются

## Зависимости
- BL-040 — RBAC System (roles для разных tiers)
- BL-033 — Cost Tracking (billing infrastructure)
- BL-031 — Security Hardening (SSO для Enterprise)

## Назначение
- **Вес:** 4
- **Скиллы:** commercial-agent
- **Статус:** pending
- **Приоритет:** low

## Примечания
- Target: churn <5% monthly (Pro), <3% (Team)
- LTV:CAC >3:1
- NPS >50
- Launch platforms: Product Hunt, Hacker News, Indie Hackers
