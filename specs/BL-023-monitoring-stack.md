---
type: backlog
id: BL-023
title: 'BL-032: Monitoring Stack — Prometheus + Grafana + Loki'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:25+00:00'
---
# BL-032: Monitoring Stack — Prometheus + Grafana + Loki

## Контекст
Мониторинг ограничен journalctl. Нет централизованного сбора метрик, визуализации и алертинга. Невозможно отследить тренды производительности и быстро реагировать на инциденты.

## Цель
Развернуть полный мониторинг стек: Prometheus (метрики), Grafana (визуализация), Loki (логи) с алертингом через Telegram.

## Зачем
Чтобы видеть состояние системы в реальном времени, получать алерты о сбоях, отслеживать SLA и принимать решения на основе данных.

## Проект/контекст
Myrmex Control — инфраструктурный модуль.

## Что сделать
- [ ] Развернуть Prometheus для сбора метрик
- [ ] Настроить Grafana с дашбордами: API latency, error rate, request rate, agent health
- [ ] Развернуть Loki для агрегации логов
- [ ] Создать /health, /health/deep, /health/ready endpoints в FastAPI
- [ ] Настроить systemd watchdog (WatchdogSec) для всех сервисов
- [ ] Реализовать alerting pipeline: P1/P2/P3/P4 severity levels
- [ ] Настроить Telegram бот для P1/P2 алертов
- [ ] Реализовать SLA tracking: 99.9% API, 99.5% dashboard
- [ ] Настроить error budget alerts (50%, 75%, 100%)

## Критерии готовности
- [ ] Prometheus собирает метрики со всех сервисов
- [ ] Grafana дашборды показывают ключевые метрики в реальном времени
- [ ] Loki агрегирует логи со всех сервисов
- [ ] Health check endpoints возвращают корректные статусы
- [ ] Telegram алерты приходят при сбоях (тестировано)
- [ ] SLA dashboard показывает текущий uptime

## Зависимости
- BL-004 — Health checks (endpoints)
- BL-024 — Monitoring & Alerting (базовая настройка)

## Назначение
- **Вес:** 4
- **Скиллы:** incident-commander, metrics-storyteller
- **Статус:** pending
- **Приоритет:** high

## Примечания
- OpenTelemetry для distributed tracing
- External uptime monitoring (UptimeRobot) каждые 60s
- Incident post-mortem template в /incidents/
