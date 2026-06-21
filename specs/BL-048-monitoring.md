---
type: backlog
id: BL-048
title: BL-006-monitoring.md
status: pending
author: system
created: 2026-05-24 21:11:36+00:00
updated: 2026-05-24 21:11:36+00:00
tags:
- backlog
- vpn
- migrated
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:29+00:00'
---# BL-006: Мониторинг, алерты и observability

## Контекст
Сейчас мониторинга нет. При 60к пользователей нужно знать о проблемах до того, как пользователи напишут в поддержку.

## Цель
Внедрить полный стек мониторинга: метрики, логи, алерты.

## Зачем
- Обнаружение проблем до эскалации
- Понимание нагрузки и планирование масштабирования
- SLA tracking

## Проект/контекст
vpn-daemon → monitoring

## Что сделать
- [ ] Prometheus + Grafana на сервере
- [ ] Метрики бота: RPS, latency, error rate, active users, FSM states
- [ ] Метрики xray: bandwidth per node, connected clients, uptime
- [ ] Системные метрики: CPU, RAM, disk, network
- [ ] Логирование: structured JSON logs → journald → Loki
- [ ] Алерты в Telegram: downtime, error rate > 5%, disk > 80%, node down
- [ ] Health check endpoint для бота и xray
- [ ] Dashboard в Grafana: обзор, детали по серверам, бизнес-метрики

## Критерии готовности
- [ ] Все метрики собираются и отображаются
- [ ] Алерты приходят в Telegram в течение 60 сек
- [ ] Dashboard покрывает: инфраструктуру, бота, бизнес

## Зависимости
- Нет

## Назначение
- **Вес:** 3
- **Скиллы:** cascade
- **Статус:** in_progress
- **Приоритет:** high

## Прогресс
- [x] Docker-compose.monitoring.yml создан (Prometheus, Grafana, Loki, Promtail)
- [x] prometheus.yml конфиг
- [x] Grafana datasource.yml и dashboard.json
- [x] promtail.yml конфиг
- [x] metrics.py модуль для Prometheus метрик
- [x] health.py health check endpoint
- [x] telegram_alerts.py алерты в Telegram
- [ ] Запустить стек Docker
- [ ] Настроить алерты в Alertmanager
- [ ] Интегрировать метрики в main.py

## Примечания
Оценка: 3-4 дня
Stack: Prometheus + Grafana + Loki + Alertmanager
