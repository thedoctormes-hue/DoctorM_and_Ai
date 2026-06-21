---
type: backlog
id: BL-028
title: 'BL-037: Skill Registry System'
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
# BL-037: Skill Registry System

## Контекст
53+ скиллов управляются через разрозненные конфигурации. Нет единого реестра, версионирования, dependency management и автообнаружения. Сложно понять, какие скиллы доступны и какие зависят от других.

## Цель
Создать единую систему управления скиллами с skill.yaml манифестами, semantic versioning, dependency graph и trigger-based discovery.

## Зачем
Чтобы управлять 53+ скиллами как единым целым: версионирование, зависимости, автообнаружение, аналитика использования.

## Проект/контекст
Myrmex Control — модуль управления скиллами.

## Что сделать
- [ ] Определить skill.yaml манифест: name, version, description, author, triggers, dependencies, permissions
- [ ] Реализовать central registry с категоризациями (testing, security, deployment, etc.)
- [ ] Добавить semantic versioning (MAJOR.MINOR.PATCH)
- [ ] Реализовать dependency graph (DAG, no circular deps) с auto-install
- [ ] Добавить conflict detection для overlapping triggers
- [ ] Реализовать trigger-based discovery с fuzzy matching
- [ ] Добавить context-aware ranking при поиске скиллов
- [ ] Создать skill analytics: usage tracking, success rate, recommendations
- [ ] Решить skill lifecycle: creation → testing → activation → updates

## Критерии готовности
- [ ] Все 53+ скиллов имеют skill.yaml манифесты
- [ ] Dependency graph визуализирует зависимости
- [ ] Auto-install зависимостей работает
- [ ] Trigger-based discovery находит скиллы по описанию задачи
- [ ] Skill analytics показывает usage и success rate
- [ ] Conflict detection предупреждает о конфликтах

## Зависимости
- BL-035 — Artifact CRUD (скиллы как артефакты типа SKILL)

## Назначение
- **Вес:** 4
- **Скиллы:** skill-architect, api-and-interface-design
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- Capability model: skills declare capabilities, agents request capabilities
- Sandbox environment для тестирования скиллов
- Auto-update для PATCH, manual для MINOR/MAJOR
