---
type: backlog
id: BL-022
title: 'BL-030: E2E тесты для Kanban Drag-and-Drop'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:24+00:00'
---
# BL-030: E2E тесты для Kanban Drag-and-Drop

## Контекст
Kanban board — ключевой элемент интерфейса, но нет E2E тестов для drag-and-drop функциональности. Текущее покрытие: 174 теста, нет гарантий что drag-and-drop работает корректно после изменений.

## Цель
Написать комплексные E2E тесты для Kanban drag-and-drop через Playwright, доведя общее покрытие к 200+ тестам.

## Зачем
Чтобы предотвратить регрессии в критической функциональности Kanban и обеспечить стабильную работу drag-and-drop при любых изменениях.

## Проект/контекст
Myrmex Control — frontend тесты (Playwright).

## Что сделать
- [ ] Настроить Playwright в проекте (конфигурация, CI integration)
- [ ] Написать тест: drag task из "To Do" в "In Progress" → проверка state change в UI и API
- [ ] Написать тест: drag task в "Done" → проверка completion timestamp и notifications
- [ ] Написать тест: multi-select и bulk move → проверка обновления всех tasks
- [ ] Написать тест: drag в невалидную колонку → проверка rejection с visual feedback
- [ ] Написать тест: concurrent drag двумя пользователями → проверка conflict resolution
- [ ] Настроить MSW (Mock Service Worker) для симуляции WebSocket updates в тестах
- [ ] Добавить visual regression тесты (Playwright screenshots)
- [ ] Интегрировать в CI: E2E тесты на merge to main

## Критерии готовности
- [ ] Все 6 сценариев drag-and-drop покрыты тестами
- [ ] Тесты проходят стабильно (flaky rate <5%)
- [ ] Visual regression тесты настроены
- [ ] CI pipeline запускает E2E тесты на merge to main
- [ ] Общее количество тестов >= 200

## Зависимости
- BL-021 — Deploy Automation (CI pipeline для запуска тестов)

## Назначение
- **Вес:** 3
- **Скиллы:** test-driven-development, browser-testing-with-devtools
- **Статус:** pending
- **Приоритет:** high

## Примечания
- Использовать @dnd-kit для Kanban (уже используется в проекте)
- Target: <5 min для полного test suite
- Параллельный запуск через pytest-xdist
