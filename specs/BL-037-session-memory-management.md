---
type: backlog
id: BL-037
title: 'BL-046: Session & Memory Management'
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
# BL-046: Session & Memory Management

## Контекст
Управление сессиями агентов и их памятью не систематизировано. Нет единой архитектуры памяти (short-term, long-term, working). Сессии не архивируются автоматически.

## Цель
Реализовать систему управления сессиями и памятью агентов с session lifecycle, memory consolidation и context navigation.

## Зачем
Чтобы агенты сохраняли контекст между сессиями, пользователь мог навигировать по истории, и система автоматически консолидировала важные инсайты.

## Проект/контекст
Myrmex Control — backend + модуль контекста.

## Что сделать
- [ ] Реализовать session lifecycle: Create → Active → Idle → Archived (24h inactivity)
- [ ] Создать memory architecture: short-term, long-term, working memory
- [ ] Реализовать memory consolidation: периодическое summary сессий в long-term memory
- [ ] Добавить context navigation: breadcrumbs, bookmarks, timeline view
- [ ] Реализовать session search по content, date, agent, tags
- [ ] Добавить context preview (hover → preview без навигации)
- [ ] Настроить vector embeddings для semantic search (pgvector/ChromaDB)
- [ ] Создать REST API для context operations

## Критерии готовности
- [ ] Session lifecycle работает с auto-archive
- [ ] Memory consolidation сохраняет инсайты
- [ ] Context navigation (breadcrumbs, bookmarks, timeline) работает
- [ ] Semantic search находит релевантный контекст
- [ ] Session search работает по всем параметрам

## Зависимости
- BL-043 — Knowledge Graph (связи между сущностями)
- BL-028 — WebSocket (real-time sync)

## Назначение
- **Вес:** 4
- **Скиллы:** context-session-specialist
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- Graph database: Neo4j или SQLite с recursive CTEs
- Real-time sync через WebSocket
- Fast context switch между сессиями
