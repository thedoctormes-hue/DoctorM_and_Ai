---
type: backlog
id: BL-052
title: BL-010-cicd-deploy.md
status: pending
author: system
created: 2026-05-24 21:11:36+00:00
updated: 2026-05-24 21:11:36+00:00
tags:
- backlog
- vpn
- migrated
related:
- ADR-010
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:30+00:00'
---# BL-010: Zero-downtime deploy и CI/CD

## Контекст
Бот управляется через systemd, деплой ручной. При 60к пользователей каждая минута даунтайма = потерянные пользователи.

## Цель
Настроить blue-green деплой с автоматическим откатом, полный CI/CD pipeline.

## Зачем
- Обновления без даунтайма
- Быстрый откат при багах
- Автоматизация рутины

## Что сделать
- [ ] Blue-Green deploy: 2 инстанса (port 8080/8081), nginx upstream
- [ ] Health check каждого инстанса: /health → 200 OK
- [ ] Автоматический откат: health fail → switch upstream
- [ ] GitHub Actions: test → build → deploy staging → smoke → deploy prod
- [ ] Notifications в Telegram: deploy started/success/rollback
- [ ] Тегирование релизов (semver), changelog
- [ ] Миграции БД через Alembic (BL-002)

## Критерии готовности
- [ ] Деплой без даунтайма подтверждён
- [ ] Автооткат работает (тест с broken build)
- [ ] CI/CD полностью автоматизирован

## Зависимости
- BL-002 (PostgreSQL)

## Назначение
- **Вес:** 3
- **Скиллы:** cascade, ci-cd-and-automation
- **Статус:** in_progress
- **Приоритет:** high

## Прогресс
- [x] GitHub Actions workflow создан (.github/workflows/deploy.yml)
- [x] scripts/deploy.sh blue-green скрипт
- [x] Health check endpoint уже есть (health.py)
- [ ] Настроить blue-green в systemd
- [ ] Автооткат при health fail
- [ ] Telegram notifications

## Примечания
Оценка: 2-3 дня
Blue-green: max 1 процесс пишет БД
