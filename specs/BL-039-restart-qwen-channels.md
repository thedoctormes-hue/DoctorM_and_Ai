---
type: backlog
id: BL-039
title: 'BL-048: Перезапуск qwen-channels'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:28+00:00'
---

# BL-048: Перезапуск qwen-channels

## Контекст
Обновлены instructions в settings.json для трёх сервисов (kotolizator, antcat, bestia). Изменения: убрано "ЕБШ автоматически" из конца всех instructions.

## Цель
Перезапустить `qwen-channels.service` чтобы изменения вступили в силу.

## Зачем
Обеспечить актуальные instructions для всех каналов.

## Проект/контекст
LabDoctorM — инфраструктура Qwen Code сервисов.

## Что сделать
- [ ] systemctl restart qwen-channels

## Критерии готовности
- [ ] Сервис qwen-channels запущен без ошибок

## Назначение
- **Вес:** 1
- **Скиллы:** deploy-bot
- **Статус:** pending
- **Приоритет:** low
