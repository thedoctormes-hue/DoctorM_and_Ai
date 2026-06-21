---
type: backlog
id: BL-005
title: 'BL-004: Реализовать health check endpoint для агентов'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:21+00:00'
---
# BL-004: Реализовать health check endpoint для агентов

## Контекст
Нет единого способа проверить живость и состояние агентов. При проблемах приходится вручную проверять логи и процессы.

## Цель
Создать /api/health endpoint и agent_status.sh скрипт.

## Зачем
Мониторинг агентов в реальном времени без ручной проверки логов.

## Проект/контекст
муравейник/мониторинг

## Что сделать
- [ ] Создать agent_status.sh — проверка процессов, uptime, last_activity
- [ ] Добавить health endpoint в dashboard API
- [ ] Реализовать статусы: healthy, degraded, dead
- [ ] Добавить метрики: tasks_completed, errors_last_hour, avg_response_time
- [ ] Интегрировать с glory_board.sh

## Критерии готовности
- [ ] agent_status.sh возвращает JSON со статусом каждого агента
- [ ] /api/health доступен и отвечает < 100мс
- [ ] Статусы корректно отображаются в dashboard
- [ ] Метрики обновляются в реальном времени

## Зависимости
- нет

## Назначение
- **Вес:** 2
- **Скиллы:** cascade-brainstorm
- **Статус:** pending
- **Приоритет:** low

## Примечания
Использовать /proc для проверки процессов. Last activity — из decision_log.jsonl.
