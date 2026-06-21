---
type: backlog
id: BL-025
title: 'BL-034: Blue-Green Deployment с Auto-Rollback'
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
# BL-034: Blue-Green Deployment с Auto-Rollback

## Контекст
Текущий деплой — ручной через systemctl restart. Нет blue-green deployment, нет auto-rollback при сбоях. Риск downtime при каждом деплое.

## Цель
Реализовать blue-green deployment с автоматическим rollback при неудачном health check.

## Зачем
Чтобы исключить downtime при деплое и автоматически откатывать неудачные релизы.

## Проект/контекст
Myrmex Control — CI/CD + инфраструктура.

## Что сделать
- [ ] Настроить GitHub Actions pipeline: PR → main → release
- [ ] Реализовать blue-green deployment: новый version alongside old
- [ ] Настроить auto-rollback при health check failure
- [ ] Создать preview deployments для каждого PR
- [ ] Настроить environment promotion: dev → staging → production
- [ ] Реализовать one-click rollback из дашборда
- [ ] Добавить Telegram notifications при pipeline failure
- [ ] Настроить secrets management: GitHub Secrets + Vault

## Критерии готовности
- [ ] Blue-green deployment работает без downtime
- [ ] Auto-rollback срабатывает при health check failure (<2 min)
- [ ] Preview deployments создаются для каждого PR
- [ ] One-click rollback работает
- [ ] Telegram notifications приходят при failures
- [ ] PR pipeline <5 min

## Зависимости
- BL-006 — Auto-rollback (базовая реализация)
- BL-021 — Deploy Automation
- BL-004 — Health checks (для verification)

## Назначение
- **Вес:** 4
- **Скиллы:** ci-cd-and-automation, shipping-and-launch
- **Статус:** pending
- **Приоритет:** high

## Примечания
- Secrets: GitHub Secrets для CI, Vault для production
- Preview auto-cleanup на merge
- Cache dependencies для ускорения pipeline
