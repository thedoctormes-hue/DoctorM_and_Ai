---
type: backlog
id: BL-035
title: 'BL-044: Load Testing Infrastructure'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:27+00:00'
---
# BL-044: Load Testing Infrastructure

## Контекст
Нет нагрузочного тестирования. Неизвестно, как система поведёт себя под нагрузкой. Нет baseline производительности.

## Цель
Создать инфраструктуру нагрузочного тестирования: baseline, stress, spike, endurance тесты.

## Зачем
Чтобы убедиться, что Myrmex Control выдержит целевую нагрузку и определить breaking point.

## Проект/контекст
Myrmex Control — инфраструктура тестирования.

## Что сделать
- [ ] Настроить Locust или k6 для load testing
- [ ] Создать baseline load test (100 concurrent users)
- [ ] Создать stress test (увеличение до breaking point)
- [ ] Создать spike test (10x normal traffic)
- [ ] Создать endurance test (24h sustained load)
- [ ] Настроить WebSocket stress test (500+ concurrent connections)
- [ ] Реализовать database query performance testing (EXPLAIN ANALYZE)
- [ ] Настроить weekly performance tests в CI
- [ ] Создать performance dashboard с baseline comparison
- [ ] Добавить alerts при performance regression

## Критерии готовности
- [ ] Baseline load test установлен (100 concurrent users)
- [ ] Stress test определил breaking point
- [ ] Spike test показал graceful degradation
- [ ] Endurance test не выявил memory leaks
- [ ] WebSocket stress test стабилен при 500+ connections
- [ ] Weekly performance tests запускаются автоматически
- [ ] Performance dashboard показывает тренды

## Зависимости
- BL-032 — Monitoring Stack (метрики для анализа)
- BL-030 — E2E Kanban Tests (базовая инфраструктура тестов)

## Назначение
- **Вес:** 3
- **Скиллы:** tester, performance-optimization
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- Target: API latency p95 <500ms при baseline load
- WebSocket stability: <1% packet loss при 500 concurrent
- Database: identify N+1 queries, missing indexes
