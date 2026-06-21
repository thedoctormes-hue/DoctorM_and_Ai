---
type: backlog
id: BL-054
title: BL-012-documentation.md
status: pending
author: system
created: 2026-05-24 21:11:36+00:00
updated: 2026-05-24 21:11:36+00:00
tags:
- backlog
- vpn
- migrated
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:30+00:00'
---# BL-012: Документация проекта

## Контекст
Документации нет. При 60к пользователей и команде разработки это критично.

## Цель
Создать полный комплект документации: README, API docs, ADR, runbooks, onboarding.

## Зачем
- Онбординг новых разработчиков
- Поддержка и  troubleshooting
- Архитектурная преемственность

## Что сделать
- [ ] README.md: описание проекта, быстрый старт, архитектура
- [ ] API docs: OpenAPI/Swagger для FastAPI endpoints
- [ ] ADR: архитектурные решения (PostgreSQL, Redis, модульность)
- [ ] Runbooks: деплой, откат, миграции, инцидент-менеджмент
- [ ] Onboarding guide: структура проекта, настройка окружения
- [ ] User docs: FAQ, гайды подключения

## Критерии готовности
- [ ] README покрывает все разделы
- [ ] API docs генерируются автоматически
- [ ] Runbooks проверены (выполнить по шагам)

## Зависимости
- Все предыдущие спеки

## Назначение
- **Вес:** 1
- **Скиллы:** cascade, documentation-and-adrs
- **Статус:** pending
- **Приоритет:** low

## Примечания
Оценка: 2-3 дня
Формат: Markdown в /docs, OpenAPI через FastAPI
