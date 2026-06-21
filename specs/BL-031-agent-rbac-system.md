---
type: backlog
id: BL-031
title: 'BL-040: Agent RBAC System'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:26+00:00'
---
# BL-040: Agent RBAC System

## Контекст
Нет системы управления доступом для агентов. Все агенты имеют одинаковые права. Невозможно ограничить доступ агента к определённым проектам или ресурсам.

## Цель
Реализовать Role-Based Access Control (RBAC) с 5 базовыми ролями, custom roles, resource-level и field-level permissions.

## Зачем
Чтобы контролировать доступ агентов и пользователей к ресурсам, обеспечить безопасность и подготовиться к multi-user SaaS модели.

## Проект/контекст
Myrmex Control — backend (FastAPI) + frontend (React).

## Что сделать
- [ ] Определить 5 базовых ролей: Admin, Manager, Developer, Viewer, Agent
- [ ] Создать permissions matrix: роль × ресурс × действие
- [ ] Реализовать custom roles с конфигурируемыми permissions
- [ ] Добавить resource-level permissions (доступ к конкретному проекту/задаче)
- [ ] Добавить field-level permissions (чтение/запись отдельных полей)
- [ ] Реализовать time-based permissions (temporary access с expiration)
- [ ] Интегрировать Casbin policy engine
- [ ] Создать permission check middleware для всех API endpoints
- [ ] Добавить role management UI (drag-and-drop permission assignment)
- [ ] Реализовать audit trail всех permission changes

## Критерии готовности
- [ ] 5 базовых ролей работают корректно
- [ ] Custom roles создаются и настраиваются
- [ ] Resource-level permissions ограничивают доступ
- [ ] Field-level permissions работают
- [ ] Time-based permissions истекают автоматически
- [ ] Audit trail логирует все изменения
- [ ] Role management UI работает

## Зависимости
- BL-011 — JWT (auth infrastructure)
- BL-031 — Security Hardening (расширение RBAC)

## Назначение
- **Вес:** 4
- **Скиллы:** hr_agent, security-and-hardening
- **Статус:** pending
- **Приоритет:** high

## Примечания
- Role inheritance: роли могут наследовать друг друга
- Integration с LDAP/OAuth для enterprise
- Capacity planning и team management
