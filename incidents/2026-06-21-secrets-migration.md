---
id: 2026-06-21-secrets-migration
timestamp: "2026-06-21T00:00:00Z"
category: tech
type: bug
severity: low
status: closed
agent: antcat
title: "INC-20260621: Миграция plaintext secrets на SecretRef"
---

# INC-20260621: Миграция plaintext secrets на SecretRef

**Дата:** 2026-06-21 22:00–22:40 UTC
**Серьёзность:** Low (плановая работа)
**Статус:** Завершён

## Описание

Миграция 22 plaintext секретов из openclaw.json на SecretRef с file provider.

## Что сделано

- Добавлена секция `secrets.providers.local-secrets` (file provider → ~/.openclaw/secrets.json)
- Преобразован secrets.json из плоского формата во вложенный JSON
- 15 plaintext полей заменены на SecretRef в openclaw.json
- 4 models.json агентов мигрированы (antcat, bestia, owl, raven)

## Результат

- plaintext: 22 → 2 (openrouter env var + .env TINYFISH_API_KEY)
- unresolved: 20 → 4 (models.json — требуют regenerate)

## Бэкапы

- openclaw.json.bak.secrets-migration
- openclaw.json.bak.secrets-provider
- secrets.json.bak.flat.*
- agents/*/agent/models.json.bak

## Урок

File provider требует вложенный JSON формат для secrets.json. Плоский формат с `/` в ключах не работает с JSON Pointer.
