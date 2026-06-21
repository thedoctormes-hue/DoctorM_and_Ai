---
description: "📋 Спецификации задач лаборатории"
type: spec
last_reviewed: 2026-05-12
last_code_change: 2026-05-12
status: active
---
# 📋 Спецификации задач лаборатории

> Единственный источник правды о задачах. Каждая задача — полная спецификация.

## Структура
- `BL-000-template.md` — шаблон (не удалять!)
- `BL-XXX-название.md` — спецификация задачи

## Правила
- Каждая задача = отдельный `.md` файл
- Имя: `BL-<номер>-<kebab-case>.md`
- Обязательно: вес, исполнитель, скиллы
- Исполнитель назначается по балансу веса (Кот ↔ Муравей)
- ЗавЛаб — только IRL-задачи + генерация идей

## Распределение
- Суммарный вес незавершённых задач у каждого агента должен быть равным
- Новая задача → тому, у кого меньше суммарный вес
- При равном весе — по очереди
- При появлении 3-го участника → делятся на трёх

## Статусы
- `pending` — ожидает выполнения
- `in_progress` — в работе
- `done` — выполнена
- `blocked` — заблокирована
- `active` — реализовано, поддерживается

## Myrmex Control (зона ответственности Муравья 🐜)

| BL | Название | Статус |
|----|----------|--------|
| BL-013 | CSP TWA Fix | done |
| BL-014 | Input Validation (Zod) | done |
| BL-015 | Rate Limiting Auth | pending |
| BL-016 | Backup Automation | → BL-060 |
| BL-017 | Environment Config | pending |
| BL-019 | TWA Security Hardening | done |
| BL-022 | Async I/O Cache | done |
| BL-026 | Change Password | done |
| BL-031 | Security Hardening | pending |
| BL-048 | Freshness Chain | pending |
| BL-052 | Server Metrics | done |
| BL-053 | Kanban Smart v2 | active |
| BL-054 | Metrics History & Visualization | active |
| BL-055 | Webhooks System | active |
| BL-056 | Sessions Management | active |
| BL-057 | Knowledge Graph | active |
| BL-058 | Analytics Dashboard | active |
| BL-059 | File Exchange | active |
| BL-060 | Backup Automation | active |
| BL-061 | Deploy Blue/Green | active |
| BL-062 | Artifacts v2 | active |
