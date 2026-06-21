---
type: backlog
id: BL-009
title: 'BL-007: Реализовать версионирование для memory файлов'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:22+00:00'
---
# BL-007: Реализовать версионирование для memory файлов

## Контекст
Memory файлы (user_profile.md, feedback_*.md, session_*.md) перезаписываются без истории изменений. При ошибке или некорректном обновлении — данные потеряны.

## Цель
Добавить версионирование для memory/ через git auto-commit.

## Зачем
Восстановить предыдущую версию memory после некорректного обновления.

## Проект/контекст
муравейник/memory

## Что сделать
- [ ] Создать memory_snapshot.sh — git add + git commit с timestamp
- [ ] Рехранить версии в отдельной ветке memory-versions
- [ ] Добавить auto-snapshot при каждом изменении memory/ (hook)
- [ ] Реализовать memory_diff.sh — сравнение версий
- [ ] Добавить очистку старых снапшотов (> 30 дней)

## Критерии готовности
- [ ] Каждое изменение memory/ → автоматический снапшот
- [ ] Ветка memory-versions содержит историю
- [ ] memory_diff.sh показывает diff между версиями
- [ ] Старые снапшоты (>30д) удаляются

## Зависимости
- нет

## Назначение
- **Вес:** 3
- **Скиллы:** cascade-brainstorm
- **Статус:** pending
- **Приоритет:** medium

## Примечания
Auto-commit не должен шуметь — только в memory-versions ветке, не в main.
