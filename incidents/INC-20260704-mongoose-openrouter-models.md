---
id: INC-20260704-mongoose-openrouter-models
timestamp: "2026-07-04T00:00:00Z"
category: tech
type: bug
severity: medium
status: resolved
agent: unknown
title: mongoose падает из-за obsolete OpenRouter моделей
date: 2026-07-04
resolved: "2026-07-08 by mangust (authorization: ЗавЛаб «чини\")"
resolution: >
Первопричина та же, что у INC-20260705: невалидный ключ OpenRouter в цепочке orion-scan/mongoose
---

## Проблема

 mongoose (OpenClaw-агент) падает с ошибками API OpenRouter:
- `model_not_found`: `nvidia/nemotron-3-nano-30b-a12b:free`
- `model_not_found`: `google/gemma-4-31b-it:free`
- `rate_limit`: `cohere/north-mini-code:free`

## Возможные причины

1. Модели были удалены/переименованы на OpenRouter
2. Лимиты для бесплатных моделей исчерпаны
3. Конфигурация mongoose использует устаревшие модели

## Решение

1. Найти конфигурацию mongoose (код/настройки)
2. Обновить список моделей на рабочие (проверить openrouter.ai/models)
3. Перезапустить сервис

## Контекст

- mongoose является OpenClaw-агентом
- Это OpenClaw-агент (токен в `/root/.openclaw/secrets/telegram/mongoose/botToken`)
- Требуется проверить конфигурацию mongoose (OpenClaw-агент) для обновления моделей
