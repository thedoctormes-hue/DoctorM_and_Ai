---
name: mcp-tiering
description: "Управление MCP серверами через уровни: core (обязательные), optional (по запросу), excluded (отключённые). Автоматическое переключение по окружению. Use when: нужно настроить MCP серверы, переключить уровни доступа, управлять tier.yml. NOT for: управление конкретным MCP сервером (используйте прямые команды mcp)."
version: 2.0.0
category: infrastructure
location: user
owner: "LabDoctorM"
last-reviewed: "2026-05-25"
---

# mcp-tiering v2.0

Управление MCP серверами через уровни: core (обязательные), optional (по запросу), excluded (отключённые). Объединяет mcp-tiering + tier-control.

## Triggers

- "настрой mcp tiering"
- "управление mcp серверами"
- "tier.yml"
- "mcp tier control"
- "tier control"
- "управление mcp уровнями"
- "изменить tier сервера"
- "mcp access control"

## Структура tier.yml

```yaml
version: "1.0"
project: "myrmex-control"
tiers:
  core:
    - filesystem
    - git
    - fetch
  optional:
    - postgres
    - linear
  excluded:
    - debug-profiler
```

## Операции

**Добавить сервер в tier:**
```bash
./scripts/tier-control.sh add <server> <tier>
```

**Убрать сервер из tier:**
```bash
./scripts/tier-control.sh remove <server> <tier>
```

**Переместить сервер между tiers:**
```bash
./scripts/tier-control.sh switch <server> <from_tier> <to_tier>
```

**Список серверов в tier:**
```bash
./scripts/tier-control.sh list <tier>
```

**Применить конфигурацию:**
```bash
./scripts/apply-tiers.py
```

## Автопереключение по окружению

- dev/staging → core + optional
- prod → core only

## Быстрые алиасы

```bash
alias mcp-prod='./scripts/apply-tiers.py && mcp list'
alias mcp-dev='./scripts/tier-control.sh list optional && mcp enable-all optional'
```

## Tools

- `yq` — YAML редактирование
- `mcp enable/disable` — управление серверами
- `python yaml` — парсинг конфигурации

## Artifacts

> ⚠️ DEPRECATED — файлы были частью системы `.qwen/`. После миграции на OpenClaw не используются.

- `tier.yml` → удалён
- `tier-control.sh` → удалён
- `apply-tiers.py` → удалён

## Why

Предотвращает перегрузку и конфликты MCP серверов, экономит память и ускоряет старт приложений. Разные окружения требуют разных наборов MCP серверов.
