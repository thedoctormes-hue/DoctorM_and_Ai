---
id: README
category: tech
type: registry
severity: critical
status: active
agent: owl
title: 📋 Реестр инцидентов лаборатории
description: 📋 Реестр инцидентов лаборатории
last_reviewed: 2026-06-21
---

# 📋 Реестр инцидентов лаборатории

Единый каталог всех инцидентов: `projects/DoctorM_and_Ai/incidents/`

## Активные инциденты

Нет активных инцидентов. Все инциденты закрыты или решены.

## Решённые инциденты (resolved)

- INC-001 — Timing attack в TWA-авторизации (решён в BL-019)
- INC-004 — Утечка секретов в GitHub
- INC-008 — Контаминация веток (Штрейкбрехер на чужой ветке)
- INC-010 — Бестия использует таблицы
- INC-011 — Муравей повторно использует таблицы
- INC-012 — Дубль snablab-bot
- INC-013 — Приватный ключ WireGuard в git
- INC-015 — Cookies браузер-профилей в git
- INC-016 — GitHub PAT в .git/config
- INC-017 — Мангуст использовал таблицы
- INC-018 — Сова выдала фантазии за факты
- INC-019 — Сова использовала таблицы в Telegram
- INC-022 — Сова удалила workspace без проверки allowlist
- INC-023 — Сова зациклилась на рестарте gateway
- INC-025 — Darkbloom/Harmony multiple tool_calls

## Закрытые инциденты (closed)

- INC-002 — Security finding (не подтверждён)
- INC-003 — СнабЛаб frontend
- INC-005 — Context Hijacking Attack
- INC-006 — Agent Identity File Integrity Check
- INC-007 — Руководство по ротации секретов
- INC-009 — Хаос в Git
- INC-024 — WorkspaceVanishedError
- INC-20260619171500 — Нарушение протокола приёмки работы

## Правила

1. Новый инцидент → создать файл `INC-XXX-краткое-описание.md`
2. Обязательные поля frontmatter: `id`, `title`, `status`, `date`, `severity`
3. Статусы: `open` | `resolved` | `closed`
4. Критичность: `critical` | `high` | `medium` | `low`
5. При решении — обновить статус и добавить секцию `## Резолюция`
