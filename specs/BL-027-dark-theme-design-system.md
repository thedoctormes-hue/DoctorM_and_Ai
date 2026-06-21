---
type: backlog
id: BL-027
title: 'BL-036: Dark Theme Design System'
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
# BL-036: Dark Theme Design System

## Контекст
UI Myrmex Control не имеет единой дизайн-системы. Нет тёмной темы, нет консистентной цветовой палитры, нет микро-анимаций. Визуально выглядит как прототип.

## Цель
Создать полную дизайн-систему с тёмной темой, semantic colors, микро-анимациями и консистентными компонентами.

## Зачем
Чтобы Myrmex Control выглядел как современный production-quality продукт, готовый к монетизации.

## Проект/контекст
Myrmex Control — frontend (React + Tailwind).

## Что сделать
- [ ] Определить color palette: bg #0D1117, surface #161B22, border #30363D, text #E6EDF3, accent #58A6FF
- [ ] Определить semantic colors: success #3FB950, warning #D29922, error #F85149, info #58A6FF
- [ ] Настроть typography: Inter + JetBrains Mono, scale 12/14/16/20/24/32px
- [ ] Реализовать micro-interactions: 150-300ms transitions, ease-out/in
- [ ] Добавить skeleton loading для всех асинхронных компонентов
- [ ] Реализовать Command Palette (Cmd+K) с fuzzy search
- [ ] Настроить Kanban через @dnd-kit с плавными анимациями
- [ ] Добавить toast notifications (top-right, auto-dismiss 5s, stack max 5)
- [ ] Реализовать collapsible sidebar с localStorage persistence
- [ ] Добавить reduced-motion support (prefers-reduced-motion)

## Критерии готовности
- [ ] Все компоненты используют единую дизайн-систему
- [ ] Тёмная тема применена ко всем страницам
- [ ] Микро-анимации работают плавно (150-300ms)
- [ ] Command Palette открывается по Cmd+K и ищет по commands/pages/agents
- [ ] Kanban drag-and-drop работает с анимациями
- [ ] Reduced-motion отключает все анимации

## Зависимости
- BL-018 — UX Critical Fixes (базовые UX улучшения)

## Назначение
- **Вес:** 3
- **Скиллы:** frontend-ui-engineering, creative-director
- **Статус:** pending
- **Приоритет:** medium

## Примечания
- CSS Grid 12-column layout, breakpoints: <768 / 768-1024 / >1024
- Recharts с custom dark theme
- Code splitting: React.lazy() + Suspense
- Target: <200KB gzipped initial load
