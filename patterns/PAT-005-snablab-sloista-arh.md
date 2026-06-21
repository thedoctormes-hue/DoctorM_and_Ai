---
type: pattern
id: PAT-005
title: 'PAT-005: СнабЛаб: слоистая архитектура API → Service'
status: active
author: system
created: 2026-05-24 17:16:12+00:00
updated: 2026-05-24 17:16:12+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- pattern
- migrated
code_refs:
- projects/snablab/backend/src/
freshness_score: 94
last_checked: '2026-06-20T01:00:32+00:00'
---

# PAT-005: СнабЛаб: слоистая архитектура API → Service → DB Models с ра

## Название
СнабЛаб: слоистая архитектура API → Service → DB Models с ра

## Категория
architecture

## Контекст
СнабЛаб: слоистая архитектура API → Service → DB Models с разделением на модули. Каждый endpoint делегирует бизнес-логику сервису. Pydantic schemas для валидации. Alembic для миграций. Паттерн повторяется для всех 7 доменов.

## Решение
<!-- Опиши решение подробнее -->

## Примеры
```
# Добавь пример кода
```

## Критерии применимости
- [ ] условие 1

## Связанные инсайты
- ins_101

## Связанные артефакты

- ADR-007 — СнабЛаб v0.1.0 FastAPI backend (архивирован, но описывает контекст)
- ADR-006 — СнабЛаб парсер КП (архивирован, часть той же архитектуры)

## Примечания
Создано автоматически из инсайта #101 (скор: 9/10)
