---
type: backlog
id: BL-015
title: 'BL-021: Автоматизация деплоя'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:23+00:00'
---
# BL-021: Автоматизация деплоя

> 🟡 P1 | Вес: 4 | Приоритет: medium | Статус: pending

## Контекст
Деплой полностью ручной: build → copy → restart. Нет бэкапа перед деплоем, нет smoke-test после, нет zero-downtime. `server-dist/` дублирует `dist/server/` — данные рассинхронизированы.

**Обнаружено:** deploy, infrastructure, skills (3 агента).

## Цель
Автоматизированный деплой с бэкапом, smoke-test и rollback.

## Зачем
Быстрый и безопасный деплой, минимизация downtime.

## Проект/контекст
myrmex-control → scripts/deploy.sh, scripts/rollback.sh

## Что сделать
- [ ] Создать `scripts/deploy.sh`:
  - Бэкап текущей версии (client + server + myrmex.json)
  - `npm run build`
  - Копирование в /var/www/myrmexcontrol/ и server-dist/
  - `systemctl restart myrmex-control`
  - Smoke-test: `curl -sf http://localhost:3000/api/version`
  - При провале — автоматический rollback
- [ ] Создать `scripts/rollback.sh`:
  - Восстановление из последнего бэкапа
  - `systemctl restart`
- [ ] Создать `scripts/health-check.sh`:
  - systemd status, API health, latency, version
- [ ] Убрать дублирование server-dist/ vs dist/server/ — определить единый источник

## Критерии готовности
- [ ] `scripts/deploy.sh` выполняет полный цикл деплоя
- [ ] Smoke-test после деплоя (curl /api/version)
- [ ] Автоматический rollback при провале
- [ ] `scripts/rollback.sh` восстанавливает предыдущую версию
- [ ] Дублирование server-dist/ устранено

## Зависимости
- BL-016 (бэкап), BL-017 (EnvironmentFile)

## Назначение
- **Вес:** 4
- **Скиллы:** ci-cd-and-automation, auto-deploy-check
- **Статус:** pending
- **Приоритет:** medium
- **Ответственный:** deploy-bot

---
*Summary: Создать скрипты deploy/rollback с бэкапом и smoke-test для автоматизированного деплоя → myrmex-control DevOps*
