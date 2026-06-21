---
type: backlog
id: BL-020
title: 'BL-028: WebSocket Chat Panel для коммуникации с агентами'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:24+00:00'
---
# BL-028: WebSocket Chat Panel для коммуникации с агентами

## Контекст
Сейчас нет real-time канала связи с агентами (Кот, Муравей) из интерфейса. Пользователь не может отправлять сообщения агентам и получать ответы в реальном времени прямо из dashboard.

## Цель
Реализовать WebSocket-based chat panel для двусторонней коммуникации с агентами прямо из интерфейса Myrmex Control.

## Зачем
Чтобы пользователь мог общаться с агентами в реальном времени без переключения на Telegram/CLI, видеть статус агентов и историю переписки.

## Проект/контекст
Myrmex Control — frontend (React) + backend (FastAPI). Новый модуль: Chat Panel.

## Что сделать
- [ ] Создать FastAPI WebSocket endpoint `/ws/agents/{agent_id}` для чата
- [ ] Создать broadcast endpoint `/ws/status` для статусов всех агентов
- [ ] Реализовать React компонент AgentChat с split-pane layout (список агентов / чат / контекст)
- [ ] Добавить heartbeat-систему: агенты пингуют каждые 15s, offline после 30s
- [ ] Реализовать message persistence: Redis (100 последних) + PostgreSQL (история)
- [ ] Добавить командную палитру с `/` командами (/status, /assign, /deploy, /logs)
- [ ] Валидация JWT при WebSocket handshake
- [ ] Rate limiting: max 10 msg/sec на пользователя

## Критерии готовности
- [ ] WebSocket endpoint принимает и отправляет сообщения в реальном времени
- [ ] AgentChat компонент отображает список агентов, чат и контекст
- [ ] Heartbeat корректно показывает online/busy/offline статусы
- [ ] История сообщений сохраняется и восстанавливается при переподключении
- [ ] JWT валидация работает — неавторизованные не могут подключиться
- [ ] Rate limiting блокирует спам (>10 msg/sec)

## Зависимости
- BL-011 — JWT инфраструктура (используется для WebSocket auth)
- BL-015 — Rate limiting (расширить на WebSocket)

## Назначение
- **Вес:** 4
- **Скиллы:** frontend-ui-engineering, api-and-interface-design, security-and-hardening
- **Статус:** pending
- **Приоритет:** high

## Примечания
- JSON message protocol: `{type, agent_id, timestamp, payload, status}`
- Fallback на SSE если WebSocket недоступен
- Типы сообщений: chat, status, event, error
