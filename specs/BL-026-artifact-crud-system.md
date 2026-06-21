---
type: backlog
id: BL-026
title: 'BL-035: Artifact CRUD System с Frontmatter'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:25+00:00'
---
# BL-035: Artifact CRUD System с Frontmatter

## Контекст
Артефакты (BL, INC, PAT, RUL, ADR, Skills, Agents) хранятся как Markdown файлы, но нет единой системы управления. Нет frontmatter схемы, bidirectional links, dependency graph. Поиск только через grep.

## Цель
Создать единую систему управления артефактами с YAML frontmatter, CRUD операциями, bidirectional links и dependency graph.

## Зачем
Чтобы артефакты стали первоклассными сущностями Myrmex Control с навигацией, связями, историей и полнотекстовым поиском.

## Проект/контекст
Myrmex Control — полный стек (FastAPI + React).

## Что сделать
- [ ] Определить frontmatter schema: id, type, title, status, created, updated, author, tags, links[]
- [ ] Реализовать template-based CRUD для каждого типа артефакта
- [ ] Создать bidirectional link system: BL-002 в ADR-005 auto-links back
- [ ] Реализовать soft delete (archive) + hard delete (admin only)
- [ ] Создать dependency graph visualization (D3.js/Cytoscape.js)
- [ ] Добавить impact analysis при изменении артефакта
- [ ] Настроить Meilisearch для full-text search
- [ ] Создать REST API для CRUD + GraphQL для complex queries
- [ ] Реализовать lifecycle: draft → review → approved → active → deprecated → archived

## Критерии готовности
- [ ] CRUD операции работают для всех 7 типов артефактов
- [ ] Bidirectional links работают корректно
- [ ] Dependency graph визуализирует связи
- [ ] Full-text search находит артефакты по frontmatter + content
- [ ] Lifecycle transitions работают корректно
- [ ] GraphQL API возвращает связанные артефакты

## Зависимости
- BL-027 — Mission Statement (BL artifact reference)

## Назначение
- **Вес:** 5
- **Скиллы:** artifact-specialist, api-and-interface-design
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- Git-based versioning для history
- Auto-create artifacts из events (failed deploy → INC, new pattern → PAT)
- Import/Export: CSV/JSON bulk, PDF export
