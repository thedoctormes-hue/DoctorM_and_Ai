---
type: backlog
id: BL-017
title: 'BL-024: Мониторинг и алертинг'
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
# BL-024: Мониторинг и алертинг

> 🟢 P2 | Вес: 4 | Приоритет: medium | Статус: pending

## Контекст
Мониторинг ограничивается journald + error.log. Нет Prometheus метрик, нет алертинга (Telegram/email), нет health check для внешних мониторингов. Watchdog проверяет только TCP порт 22.

**Обнаружено:** infrastructure, metrics, incidents, deploy (4 агента).

## Цель
Prometheus-совместимые метрики, Telegram-алерты, детальный health check.

## Зачем
Раннее обнаружение проблем, быстрое реагирование на инциденты.

## Проект/контекст
myrmex-control → src/server/api/health.ts, src/server/watchdog.ts

## Что сделать
- [ ] Добавить `/api/metrics` endpoint с Prometheus-форматом:
  - `http_requests_total` (counter)
  - `http_request_duration_seconds` (histogram)
  - `myrmex_active_sessions` (gauge)
  - `myrmex_db_file_bytes` (gauge)
- [ ] Сделать `/api/health` публичным (без requireAuth) для внешних мониторингов
- [ ] Добавить реальные проверки в health: `process.memoryUsage()`, `process.uptime()`, disk space
- [ ] Добавить Telegram-алертинг при: падении сервера, смене статуса сервера, ошибках 500
- [ ] Улучшить watchdog: HTTP health check вместо TCP ping, retry с backoff
- [ ] Добавить `app.set('trust proxy', 1)` для корректного IP за nginx

## Критерии готовности
- [ ] `/api/metrics` возвращает Prometheus-формат
- [ ] `/api/health` доступен без авторизации
- [ ] Telegram-алерт при downtime сервера
- [ ] Watchdog проверяет HTTP, не только TCP

## Зависимости
- BL-021 (deploy automation)

## Назначение
- **Вес:** 4
- **Скиллы:** metrics-storyteller, incident-commander
- **Статус:** pending
- **Приоритет:** medium
- **Ответственный:** metrics-storyteller

---
*Summary: Добавить Prometheus метрики и Telegram-алерты для мониторинга production → myrmex-control monitoring*
