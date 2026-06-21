# 🏗 Инфраструктура лаборатории

Документация по инфраструктуре: конфиги, серверы, системные утилиты.
Это **не скиллы** — справочник для агентов и людей.

## Содержимое

| Файл | Описание |
|------|----------|
| [`vpn-servers.yml`](vpn-servers.yml) | Список VPN-серверов (единственный источник правды для vpnscan, dpi-bypass) |
| [`ram-guardian.md`](ram-guardian.md) | Контроль ACP/MCP процессов, лимит памяти |
| [`mcp-tiering.md`](mcp-tiering.md) | Управление MCP серверами через уровни (core/optional/excluded) |
| [`response-cache.md`](response-cache.md) | Кеширование ответов OpenRouter для экономии токенов |

## Отличие от скиллов

- **Скиллы** (`/root/.qwen/skills/*/SKILL.md`) — исполняемые workflow с frontmatter, triggers, requiredTools
- **Инфраструктура** (`docs/infra/`) — конфиги и справочная документация

Перенесены из `skills/` в `docs/infra/` потому что описывают системную конфигурацию, а не выполняют действия.
