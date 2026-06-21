---
type: backlog
id: BL-007
title: 'BL-006: Реализовать автоматический rollback при деплое'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:22+00:00'
---
# BL-006: Реализовать автоматический rollback при деплое

## Контекст
При деплое сервисов (systemctl restart) нет автоматического rollback. Если новый код сломан — сервис лежит до ручного вмешательства.

## Цель
Добавить auto-rollback в deploy скрипты с проверкой health после рестарта.

## Зачем
Минимизировать downtime при неудачных деплоях — автоматический откат за 30 секунд.

## Проект/контекст
муравейник/деплой

## Что сделать
- [ ] Создать auto_deploy.sh с этапами: backup → deploy → health_check → rollback_on_fail
- [ ] Реализовать health_check для каждого сервиса (systemctl is-active + curl)
- [ ] Добавить rollback через git checkout HEAD~1 + systemctl restart
- [ ] Уведомление в Telegram при rollback
- [ ] Логирование всех деплоев в deploy_log.jsonl

## Критерии готовности
- [ ] При провале health check — автоматический откат < 30с
- [ ] Telegram уведомление с причиной rollback
- [ ] Deploy log содержит все операции
- [ ] Работает для Python и React проектов

## Зависимости
- BL-004 — health check endpoint

## Назначение
- **Вес:** 4
- **Скиллы:** cascade-brainstorm, council
- **Статус:** pending
- **Приоритет:** high

## Примечания
Rollback только для systemd сервисов. React проекты — через бэкап папки.
