---
type: backlog
id: BL-014
title: 'BL-020: Синхронизация документации'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:23+00:00'
---
# BL-020: Синхронизация документации

> 🟡 P1 | Вес: 3 | Приоритет: medium | Статус: pending

## Контекст
Версии рассинхронизированы: package.json 1.2.0, CHANGELOG 1.1.0, myrmex.json 0.1.0, /api/version 1.0.0. README.ru.md и README.zh.md отстают от EN. OpenAPI спецификация версия 0.1.0 вместо 1.2.0. 14 страниц в коде, но только 9 описаны в README. ADR-003 описывает cookie-sessions, а реально JWT.

**Обнаружено:** docs (18 проблем), artifacts (версионные расхождения).

## Цель
Все версии приведены к 1.2.0. API Reference полный. Структура проекта актуальная.

## Зачем
Корректная документация = быстрый onboarding и доверие пользователей.

## Проект/контекст
myrmex-control → README.md, README.ru.md, README.zh.md, CHANGELOG.md, docs/

## Что сделать
- [ ] Привести все версии к 1.2.0: README.ru.md, README.zh.md, SECURITY.md, openapi.yaml, myrmex.json _meta.version
- [ ] Добавить CHANGELOG для v1.2.0 (TWA auth, pagination, animations, Agents/Servers/Settings pages)
- [ ] Обновить API Reference: добавить /api/agents, /api/settings, HealthScore
- [ ] Обновить структуру проекта в README: 14 страниц, FSD, 13 UI-компонентов
- [ ] Переписать ADR-003: JWT + refresh rotation + TOTP + TWA вместо cookie-sessions
- [ ] Обновить GET /api/version: читать из package.json
- [ ] Переместить PUBLISH_PACK.md → docs/marketing/publish-pack.md

## Критерии готовности
- [ ] Все файлы показывают версию 1.2.0
- [ ] CHANGELOG.md содержит запись для v1.2.0
- [ ] API Reference покрывает все ~38 эндпоинтов
- [ ] ADR-003 соответствует реальному коду
- [ ] /api/version возвращает актуальную версию

## Зависимости
- Нет

## Назначение
- **Вес:** 3
- **Скиллы:** documentation-and-adrs, create-readme
- **Статус:** pending
- **Приоритет:** medium
- **Ответственный:** docs-writer

---
*Summary: Привести все версии документации к 1.2.0 и дополнить API Reference новыми эндпоинтами → myrmex-control docs*
