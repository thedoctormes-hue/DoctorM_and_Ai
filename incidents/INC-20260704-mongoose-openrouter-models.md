---
title: "mongoose падает из-за obsolete OpenRouter моделей"
date: 2026-07-04
status: resolved
severity: medium
resolved: 2026-07-08 by mangust (authorization: ЗавЛаб «чини")
resolution: >
  Первопричина та же, что у INC-20260705: невалидный ключ OpenRouter в цепочке orion-scan/mongoose
  (vault отсутствовал, `.env` содержал 2-символьный мусор → 401).
  Ошибки model_not_found/rate_limit на конкретных моделях (nemotron-3-nano, gemma-4-31b и т.п.)
  были вторичны — скан падал на auth ещё до проверки моделей.
  После записи валидного ключа в vault + `.env` полный скан отработал (9/21 моделей живы).
  Список моделей в mongoose при этом не требовал обновления — он берётся динамически из /api/v1/models.
---

## Проблема

 mongoose (внешний сервис) падает с ошибками API OpenRouter:
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

- mongoose не является OpenClaw-агентом
- Это отдельный сервис (Go-бот с токеном в `/root/.openclaw/secrets/telegram/mongoose/botToken`)
- Требуется доступ к коду mongoose для обновления моделей
