---
type: backlog
id: BL-016
title: 'BL-023: Очистка myrmex.json и синхронизация данных'
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
# BL-023: Очистка myrmex.json и синхронизация данных

> 🟢 P2 | Вес: 3 | Приоритет: medium | Статус: pending

## Контекст
myrmex.json содержит 83% тестовых данных: 4 из 6 проектов — probe/test, 4 из 4 задач — тестовые, 12 из 18 changelog записей — от test/probe/t источников. Схема (myrmex.schema.json), данные (myrmex.json), TypeScript типы (types.ts) и demo-data рассинхронизированы. Нет общего ID между myrmex.json и projects.json.

**Обнаружено:** artifacts, data (2 агента, критические проблемы качества данных).

## Цель
myrmex.json содержит только реальные данные. Схема, типы и данные синхронизированы.

## Зачем
Корректная работа dashboard, достоверные метрики.

## Проект/контекст
myrmex-control → myrmex.json, myrmex.schema.json, src/shared/types.ts

## Что сделать
- [ ] Удалить тестовые проекты: "Test Project", "Deploy Test", "Тестовый", "😈демон", "Probe Project" (×2)
- [ ] Удалить тестовые задачи: "Updated via API probe", "Тест", "Вызвать демона", "Probe task"
- [ ] Удалить тестовые library записи: "тест", "probe-skill"
- [ ] Очистить changelog от source=test/probe/t записей
- [ ] Привести myrmex.schema.json в соответствие с фактической структурой
- [ ] Синхронизировать TypeScript типы с myrmex.json
- [ ] Добавить валидацию myrmex.json по схеме при старте сервера
- [ ] Создать скрипт `scripts/cleanup-test-data.sh`

## Критерии готовности
- [ ] Нет тестовых проектов/задач/library в myrmex.json
- [ ] Changelog содержит только реальные записи
- [ ] Схема соответствует данным
- [ ] Валидация при старте: если данные не соответствуют схеме — warning

## Зависимости
- Нет

## Назначение
- **Вес:** 3
- **Скиллы:** data-scientist
- **Статус:** pending
- **Приоритет:** medium
- **Ответственный:** data-scientist

---
*Summary: Очистить myrmex.json от тестовых данных и синхронизировать схему/типы/данные → myrmex-control data quality*
