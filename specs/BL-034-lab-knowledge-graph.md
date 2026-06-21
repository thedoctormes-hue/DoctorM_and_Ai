---
type: backlog
id: BL-034
title: 'BL-043: Lab Knowledge Graph'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:27+00:00'
---
# BL-043: Lab Knowledge Graph

## Контекст
Нет единого индекса всех сущностей лаборатории (агенты, проекты, задачи, артефакты, скиллы, серверы). Навигация между сущностями только через прямые ссылки. Нет графа знаний.

## Цель
Создать unified JSON index всех сущностей и interactive knowledge graph с навигацией, аналитикой и контекстом по клику.

## Зачем
Чтобы пользователь мог визуально исследовать лабораторию, видеть связи между сущностями и получать полный контекст по клику на любой узел.

## Проект/контекст
Myrmex Control — полный стек.

## Что сделать
- [ ] Создать unified JSON index schema: entities + relationships
- [ ] Реализовать auto-rebuild index при каждом изменении
- [ ] Построить interactive graph visualization (D3.js/Cytoscape.js)
- [ ] Добавить node types (agents, projects, tasks, artifacts, skills) с разными цветами/формами
- [ ] Реализовать context on click: detail panel, related entities, history timeline
- [ ] Добавить graph analytics: centrality, cluster detection, path finding, impact analysis
- [ ] Настроить Neo4j или PostgreSQL с recursive CTEs
- [ ] Создать GraphQL API для graph queries
- [ ] Добавить real-time updates через WebSocket
- [ ] Реализовать export: PNG, SVG, JSON

## Критерии готовности
- [ ] Unified JSON index содержит все сущности
- [ ] Interactive graph визуализирует связи
- [ ] Context on click показывает полный контекст
- [ ] Graph analytics работает (centrality, clusters, path finding)
- [ ] GraphQL API возвращает связанные сущности
- [ ] Real-time updates при изменениях

## Зависимости
- BL-035 — Artifact CRUD (сущности как артефакты)
- BL-028 — WebSocket (real-time updates)

## Назначение
- **Вес:** 5
- **Скиллы:** lab-map, api-and-interface-design
- **Статус:** pending
- **Приоритет:** low

## Примечания
- Incremental updates (delta queries)
- Shareable links с view-only access
- Search and filter по node type, relationship type, date range
