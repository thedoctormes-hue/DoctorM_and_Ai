---
description: "Lab Insights Engine — система обработки инсайтов"
type: guide
last_reviewed: 2026-06-21
last_code_change: 2026-06-21
status: deprecated
---
# Lab Insights Engine v2.1

> ⚠️ **DEPRECATED** — система была построена на Qwen Code hooks. После миграции на OpenClaw (июнь 2026) не используется. Документация сохранена как справочник.

## Статус

- **Была активна:** май–июнь 2026
- **Текущий статус:** deprecated (не работает на OpenClaw)
- **Замена:** OpenClaw skills + artifact-pulse + ручная консолидация инсайтов

## Обзор (исторический)

Insights Engine — подсистема Jingle, которая перехватывала действия Qwen Code, извлекала из них знания и распределяла по слоям памяти.

## Архитектура (историческая)

Источник → Извлечение → Фильтрация → Классификация → Очередь → Эволюция → Слои

Компоненты:
- PostToolUse hook → insight_catcher.sh → insights_queue.json → self_evolve.sh → слои (memory/skills/backlog/rules/agents)
- SessionEnd hook → session_finalize.sh — быстрая обработка безопасных слоёв (<5s)
- systemd timer (каждые 30 мин) → insights_maintenance.sh — полный maintenance + обработка pending
- decision_engine.py — классификатор инсайтов (рус + англ)
- adaptive_router.py — обучаемый роутер (epsilon-greedy bandit, eps=0.1)
- resolution_strategy.py — разрешение конфликтов между слоями
- decision_log.py — лог решений в JSONL

## Слои (исторические)

- memory — знания, паттерны, архитектура, инсайты
- skills — инструменты, утилиты, скрипты
- backlog — задачи, баги, техдолг
- rules — безопасность, законы, запреты
- agents — поведение сотрудников, роли

## Миграция на OpenClaw

После миграции на OpenClaw (июнь 2026) функциональность Insights Engine заменена:

| Было (Qwen Code) | Стало (OpenClaw) |
|---|---|
| PostToolUse hook | OpenClaw skills + heartbeat |
| insight_catcher.sh | Ручной сбор инсайтов агентами |
| self_evolve.sh | artifact-pulse |
| insights_queue.json | artifact-pulse/insights/ |
| systemd timer | OpenClaw cron |

## См. также

- [artifact-pulse](../projects/artifact-pulse/) — текущая система мониторинга артефактов
- [OpenClaw docs](https://docs.openclaw.ai) — документация OpenClaw
