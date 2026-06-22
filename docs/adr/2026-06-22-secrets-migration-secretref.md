# ADR-0044: Миграция plaintext secrets на SecretRef

**Дата:** 2026-06-21
**Статус:** Accepted
**Автор:** Штрейкбрехер (Streikbrecher)
**Связанные коммиты:** `0af1ddb4`
**Инцидент:** INC-20260621

## Контекст

В `openclaw.json` хранилось 22 plaintext-секретов (API-ключи, пароли). Это нарушает безопасность: при компрометации git-репозитория все ключи утекают. Требуется вынести секреты из конфига в защищённое хранилище.

## Решение

Миграция на **SecretRef** с **file provider** (`~/.openclaw/secrets.json`):

- Добавлена секция `secrets.providers.local-secrets` (file provider)
- `secrets.json` преобразован из плоского формата во вложенный JSON (требование JSON Pointer)
- 15 plaintext-полей в `openclaw.json` заменены на SecretRef
- 4 `models.json` агентов мигрированы (antcat, bestia, owl, raven)

**Результат:** plaintext 22 → 2 (openrouter env var + .env TINYFISH_API_KEY).

**Бэкапы:** `openclaw.json.bak.secrets-migration`, `secrets.json.bak.flat.*`.

## Последствия

- Секреты больше не хранятся в git в открытом виде
- File provider требует вложенный JSON-формат (плоский с `/` в ключах несовместим с JSON Pointer)
- 2 unresolved secrets требуют regenerate (models.json агентов)

## Альтернативы

- HashiCorp Vault (отвергнуто: избыточно для текущего масштаба)
- Environment-only (отвергнуто: не все агенты поддерживают env)
