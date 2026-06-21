---
type: backlog
id: BL-021
title: 'BL-029: Agent Health Score Dashboard'
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
# BL-029: Agent Health Score Dashboard

## Контекст
Нет единой метрики здоровья агентов. Пользователь не может быстро понять, какие агенты работают нормально, а какие требуют внимания.

## Цель
Реализовать Health Score (0-100) для каждого агента с визуализацией на дашборде.

## Зачем
Чтобы мгновенно видеть состояние всех агентов, получать алерты при деградации и принимать решения о перезапуске/перераспределении задач.

## Проект/контекст
Myrmex Control — модуль метрик и мониторинга.

## Что сделать
- [ ] Определить формулу Health Score: uptime (30%) + task success rate (30%) + response time (20%) + error rate (20%)
- [ ] Создать систему сбора метрик из всех действий агентов (structured JSON logging)
- [ ] Реализовать materialized views для агрегации метрик (refresh каждые 5 мин)
- [ ] Создать AgentCard компонент с цветовым индикатором здоровья
- [ ] Добавить Health Score на главный дашборд (summary cards)
- [ ] Реализовать staleness detection: alert если агент >24h без задач или >1h без check-in
- [ ] Добавить burndown charts (sprint, release, per-agent)

## Критерии готовности
- [ ] Health Score рассчитывается корректно для каждого агента (0-100)
- [ ] Дашборд показывает цветовые индикаторы (зелёный/жёлтый/красный)
- [ ] Staleness alerts срабатывают при заданных порогах
- [ ] Burndown charts обновляются в реальном времени
- [ ] Метрики собираются без потери данных

## Зависимости
- BL-024 — Monitoring & Alerting (базовая инфраструктура)
- BL-004 — Health checks (данные для uptime метрики)

## Назначение
- **Вес:** 3
- **Скиллы:** metrics-storyteller, data-scientist
- **Статус:** pending
- **Приоритет:** high

## Примечания
- Использовать Recharts или Victory для React-визуализации
- Gantt chart для timeline задач по агентам
- Heatmap для активности по часам/дням
