# ADR-043: TOP-5 Agent Configuration Improvements

**Date:** 2026-06-20
**Author:** Штрейкбрехер (streikbrecher)
**Status:** implemented
**Version:** 1.0

## Context

Аудит конфигурации OpenClaw агентов выявил критический баг маршрутизации и несколько возможностей для оптимизации. Цель — повысить безопасность, снизить затраты токенов и улучшить координацию между агентами.

## Decision

Внедрены 5 улучшений в `openclaw.json`:

### 1. Исправление mangust binding (КРИТИЧНО)
- **Проблема:** `accountId: default` вместо `accountId: mangust`
- **Риск:** Мангуст использовал default-бота без allowlist-защиты
- **Решение:** `accountId: mangust`

### 2. Loop Detection
- **Что:** `tools.loopDetection.enabled: true`
- **Пороги:** warning=10, critical=20, globalCircuitBreaker=30
- **Детекторы:** genericRepeat, knownPollNoProgress, pingPong — все включены
- **Источник инцидента:** INC-014 (hype-daily.service — await на синхронных заглушках)

### 3. Heartbeat Optimization
- **Что:** `isolatedSession: true` + `lightContext: true`
- **Эффект:** снижение токенов с ~100K до ~2-5K за heartbeat
- **Документация:** config-agents.md — "Reduces per-heartbeat token cost from ~100K to ~2-5K tokens"

### 4. Plan Tool
- **Что:** `tools.experimental.planTool: true`
- **Эффект:** агенты получают `update_plan` для многошаговых задач
- **Документация:** config-tools.md — "structured update_plan tool for non-trivial multi-step work tracking"

### 5. Sessions Spawn Attachments
- **Что:** `tools.sessions_spawn.attachments.enabled: true`
- **Лимиты:** 5MB total, 50 files, 1MB per file
- **Эффект:** агенты могут передавать файлы сабагентам через `sessions_spawn`

### Startup Context Fix (бонус)
- **Проблема:** `maxFileChars: 12000` превышал лимит 10000 — gateway не стартовал
- **Решение:** `maxFileChars: 10000`, `maxFileBytes: 16384`, `maxTotalChars: 6000`

## Consequences

**Положительные:**
- Мангуст использует своего бота с allowlist-защитой
- Защита от зацикливания агентов (loop detection)
- Экономия ~95% токенов на heartbeat (8 агентов × 2 раза/час)
- Структурированная работа над сложными задачами (planTool)
- Передача файлов между агентами (attachments)

**Риски:**
- Минимальные — все изменения обратимы через бэкап `openclaw.json.bak.20260620-094200`

## Verification

- `openclaw config validate` — PASS
- 8 unit-тестов валидации конфига — все PASS
- Gateway перезапущен, 9 агентов активны, 59 сессий

## References

- OpenClaw docs: `config-agents.md`, `config-tools.md`, `skills-config.md`
- Security: Valletta Software "OpenClaw Security 2026" guide
- Threat model: MITRE ATLAS mapping (THREAT-MODEL-ATLAS.md)
