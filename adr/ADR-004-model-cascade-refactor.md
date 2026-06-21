---
type: adr
id: ADR-004
title: 'ADR-004: Рефакторинг каскада моделей OpenRouter'
status: accepted
author: system
created: 2026-05-24 17:16:12+00:00
updated: 2026-05-24 17:16:12+00:00
last_verified: 2026-06-04 00:00:00+00:00
confidence: outdated
source: manual
tags:
- adr
- migrated
code_refs:
- projects/owl/settings.json
freshness_score: 97
last_checked: '2026-06-20T01:00:13+00:00'
---

# ADR-004: Рефакторинг каскада моделей OpenRouter

Дата: 2026-05-16
Статус: Принято
Автор: Штрейкбрехер

## Контекст

Исследование Ворона (raven) выявило критические проблемы в settings.json:
- 3 несуществующих ID моделей в fallback и agentOverrides
- Платная модель в конце fallback-цепочки
- Завышенный таймаут для free-моделей
- Зависимость ролей от конкретных моделей через agentOverrides

## Решение

### Новый fallback-список (5 моделей, все free):
1. deepseek/deepseek-v4-flash:free — ctx=1M
2. openai/gpt-oss-20b:free — ctx=128K
3. minimax/minimax-m2.5:free — ctx=200K
4. openai/gpt-oss-120b:free — ctx=128K
5. nvidia/nemotron-3-super-120b-a12b:free — ctx=1M

### Убрано:
- agentOverrides (все роли используют общий каскад)
- model из каналов сотрудников (kotolizator, antcat, bestia, streikbrecher, raven)
- inclusionai/ling-2.6-flash:free (не существует)
- mistralai/mistral-nemo (платная)
- tencent/hy3-preview:free (не существует)

### Параметры:
- timeout: 120000 → 60000
- maxRetries: 3 → 2

### Дешёвая модель для кодинга:
- qwen/qwen3-coder-next — $0.11/1M prompt, ctx=262K, поддерживает tools

## Верификация

Все модели проверены через OpenRouter API:
- Существование подтверждено
- Цена = 0 для всех fallback-моделей
- Поддержка tools для агентской работы

## Тесты

- test_settings_validation.sh — 63 теста
- Все тесты .qwen — 184 теста, 0 падений
