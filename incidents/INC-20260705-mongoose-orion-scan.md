---
title: "mongoose cron task Orion Scan failed"
date: 2026-07-05
status: resolved
severity: medium
resolved: 2026-07-08 by mangust (authorization: ЗавЛаб «чини")
resolution: >
  Корень — отсутствующий vault-ключ + 2-символьный мусор в `free-api-hunter/.env`.
  `orion-scan.sh` резолвит ключ env > vault `vault/free-api-hunter/openrouter/api.key` > `.env`.
  Vault-файл отсутствовал, `.env` содержал мусор → 401 Missing Authentication header для всех 21 модели.
  Исправлено: валидный лабораторный OpenRouter-ключ (тот же аккаунт, что и в openclaw.json)
  записан в `vault/free-api-hunter/openrouter/api.key` и в `free-api-hunter/.env` (перезапись мусора).
  Полный `orion-scan.sh` подтверждённо отработал: 21 найдено, 9 работают, 401 устранён.
  Зависший failed-cron d2701905-a310-4777-bcf8-3448b6c24304 — см. примечание (удаляется через API/остановку mongoose).
---

## Проблема

mongoose создал крон-задачу "Orion Scan — бесплатные модели OpenRouter" в OpenClaw. Задача завершилась с ошибкой:

- `model_not_found`: 5 моделей (nemotron-3-nano, lfm-2.5-1.2b, nemotron-3-super, gpt-oss-20b, north-mini-code)
- `rate_limit`: cohere/north-mini-code

## Причина

1. Модели были удалены/переименованы на OpenRouter
2. Лимиты для бесплатных моделей исчерпаны
3. mongoose использует устаревший список моделей

## Статус

- Задача `d2701905-a310-4777-bcf8-3448b6c24304` имеет статус `failed`
- mongoose — OpenClaw-агент лаборатории, не запущен
- Задачу нельзя удалить через openclaw CLI (требуется API или остановка mongoose)

## Решение

1. Проверить конфигурацию mongoose как OpenClaw-агента (настройки в openclaw.json / воркспейсе агента)
2. Обновить конфигурацию mongoose (список моделей или расписание)
3. Или попросить ЗавЛаба удалить задачу через API

## Контекст

- mongoose управляет кронами через OpenClaw API
- Скрипт: `/root/LabDoctorM/projects/free-api-hunter/scripts/orion-scan.sh`
