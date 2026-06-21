---
type: backlog
id: BL-050
title: BL-008-zero-downtime-deploy.md
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
last_checked: '2026-06-20T01:00:29+00:00'
---# BL-008: Zero-downtime деплой и rollback

## Контекст
Бот управляется через systemd. При 60к пользователей каждая минута даунтайма = потерянные пользователи.

## Цель
Настроить blue-green деплoy с автоматическим откатом.

## Зачем
- Обновления без даунтайма
- Быстрый откат при багах
- Уверенность в релизах

## Проект/контекст
vpn-daemon → deploy

## Что сделать
- [ ] Blue-green deploy: два инстанса бота (порт 8080/8081), nginx upstream
- [ ] Health check endpoint: /health (проверка БД, Redis, xray)
- [ ] Автоматический откат: если health check fails 3 раза → switch upstream
- [ ] CI/CD pipeline: test → build → deploy staging → smoke test → deploy prod
- [ ] Миграции БД: отдельный шаг до деплоя (backward-compatible)
- [ ] Уведомление админу: deploy started / success / rollback
- [ ] Версионирование: semver, changelog, git tags

## Критерии готовности
- [ ] Деплой проходит без даунтайма
- [ ] Автоматический откат работает (тест с broken build)
- [ ] CI/CD pipeline полностью автоматизирован

## Зависимости
- BL-002 (PostgreSQL)
- BL-005 (Redis)

## Назначение
- **Вес:** 2
- **Скиллы:** cascade
- **Статус:** pending
- **Приоритет:** high

## Примечания
Оценка: 2-3 дня
Stack: GitHub Actions + systemd + nginx upstream
