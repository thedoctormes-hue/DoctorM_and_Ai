---
type: backlog
id: BL-030
title: 'BL-039: File Exchange — Inbox/Outbox System'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:26+00:00'
---
# BL-039: File Exchange — Inbox/Outbox System

## Контекст
Inbox/Outbox существует как файловая структура, но нет real-time уведомлений, auto-cleanup, quota management и интеграции с агентами. Файлы накапливаются без очистки.

## Цель
Реализовать полноценную систему обмена файлами с Inbox/Outbox, real-time уведомлениями, auto-cleanup и интеграцией с агентами.

## Зачем
Чтобы агенты и пользователи могли обмениваться файлами через dashboard с автоматической обработкой и очисткой.

## Проект/контекст
Myrmex Control — полный стек.

## Что сделать
- [ ] Реализовать Inbox/Outbox с message queue pattern
- [ ] Настроить S3-compatible storage (MinIO local, AWS S3 production)
- [ ] Добавить metadata для каждого файла: sender, receiver, type, size, timestamp, status, tags
- [ ] Реализовать real-time notifications через WebSocket + desktop notifications
- [ ] Добавить digest mode (hourly/daily вместо instant)
- [ ] Решить auto-cleanup: retention policies (30d), archive before delete (7d recovery)
- [ ] Добавить hash-based duplicate detection
- [ ] Реализовать quota management: per-agent, alert 80%, block 100%
- [ ] Создать agent auto-process: subscribe to file types, trigger on new file
- [ ] Добавить drag-and-drop upload с progress bars
- [ ] Реализовать preview для images/PDFs/text

## Критерии готовности
- [ ] Inbox/Outbox работает для всех агентов
- [ ] Real-time notifications приходят при новых файлах
- [ ] Auto-cleanup удаляет старые файлы по retention policy
- [ ] Duplicate detection работает (hash-based)
- [ ] Quota management блокирует uploads при 100%
- [ ] Agent auto-process триггерится на новые файлы
- [ ] Drag-and-drop upload с progress bars работает

## Зависимости
- BL-028 — WebSocket Chat Panel (WebSocket infrastructure)
- BL-023 — Data Cleanup (базовая очистка)

## Назначение
- **Вес:** 3
- **Скиллы:** file-exchange, frontend-ui-engineering
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- Priority levels: urgent, normal, low
- Batch operations: zip support, multiple files
- Keyboard shortcuts для navigation
