---
type: backlog
id: BL-045
title: BL-003-modular-architecture.md
status: pending
author: system
created: 2026-05-24 21:11:36+00:00
updated: 2026-05-24 21:11:36+00:00
tags:
- backlog
- vpn
- migrated
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:29+00:00'
---# BL-003: Модульная архитектура бота

## Контекст
Весь код бота в одном файле main.py (973 строки). При масштабировании добавлять фичи в монолит станет невозможно.

## Цель
Разбить монолит на модули: auth, vpn, payment, notification, admin, analytics.

## Зачем
Поддерживаемость, тестируемость, возможность параллельной работы нескольких разработчиков.

## Проект/контекст
vpn-daemon → модульная структура

## Что сделать
- [ ] Создать структуру пакетов:
  ```
  src/bot/
  ├── __init__.py
  ├── main.py (entry point, <200 строк)
  ├── config.py
  ├── database.py
  ├── cache.py
  ├── modules/
  │   ├── auth/ (регистрация, авторизация, роли)
  │   ├── vpn/ (создание, удаление, конфиги, QR)
  │   ├── payment/ (тарифы, оплата, продление)
  │   ├── notification/ (уведомления, рассылки)
  │   ├── admin/ (управление, статистика)
  │   └── analytics/ (метрики, отчёты)
  ├── middleware/ (rate limit, auth, logging)
  └── utils/ (helpers, xray integration)
  ```
- [ ] Реализовать dependency injection для модулей
- [ ] Перенести текущую логику в модули (strangler fig pattern)
- [ ] Написать тесты для каждого модуля
- [ ] Feature flags для безопасного раскатывания

## Критерии готовности
- [ ] main.py < 200 строк (только инициализация)
- [ ] Каждый модуль независимо тестируемый
- [ ] Все существующие функции работают
- [ ] Покрытие тестами > 60%

## Зависимости
- BL-002 (PostgreSQL) — модули зависят от БД

## Назначение
- **Вес:** 3
- **Скиллы:** cascade
- **Статус:** in_progress
- **Приоритет:** high

## Прогресс
- [x] Создана структура пакетов src/bot/modules/
- [x] Созданы modules/vpn/__init__.py, client_service.py, link_service.py
- [x] Созданы modules/admin/__init__.py, dashboard_service.py
- [x] Создан config.py модуль
- [x] main.py уменьшен до ~100 строк (было 1000+)
- [x] Написаны tests/test_client_service.py
- [x] Написаны tests/test_link_service.py
- [ ] Перенести остальные handlers (cleanup, status, add_client)
- [ ] Feature flags для безопасного раскатывания

## Примечания
Strangler fig pattern: постепенная миграция без остановки сервиса
Оценка: 5-7 дней
