---
type: backlog
id: BL-044
title: BL-002-json-to-postgres.md
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
last_checked: '2026-06-20T01:00:28+00:00'
---# BL-002: Миграция с JSON на PostgreSQL

## Контекст
Текущий бот хранит все данные в JSON файлах (clients.json, users.json, servers.json). При 60к пользователей это 18+ MB на каждый файл, полный парсинг на каждую операцию, конфликты записи при параллельных запросах.

## Цель
Перейти на PostgreSQL для всех персистентных данных без даунтайма.

## Зачем
JSON файлы — узкое место #1. При 1000+ пользователей — секунды на каждую операцию. При 2+ админах — потеря данных.

## Проект/контекст
vpn-daemon → PostgreSQL

## Что сделать
- [ ] Установить PostgreSQL 16 + настроить (shared_buffers, work_mem, WAL)
- [ ] Создать схему: users, clients, servers, subscriptions, payments, audit_log
- [ ] Написать DDL с индексами и партиционированием
- [ ] Реализовать dual-write: JSON + PG одновременно (период миграции 2 недели)
- [ ] Backfill: скрипт переноса существующих данных из JSON в PG
- [ ] Переключить бота на PG как primary source
- [ ] Убрать JSON fallback после стабилизации (1 неделя monitoring)
- [ ] Настроить бэкапы (pg_dump + WAL archiving)

## Критерии готовности
- [ ] Все операции CRUD работают через PostgreSQL
- [ ] Время ответа < 50ms для 95% запросов
- [ ] Нет потери данных при параллельных операциях
- [ ] Бэкапы настроены и проверены

## Зависимости
- Нет

## Назначение
- **Вес:** 4
- **Скиллы:** cascade
- **Статус:** in_progress
- **Приоритет:** critical

## Прогресс
- [x] SQLAlchemy модели (database.py)
- [x] Репозитории (repositories.py)
- [x] Dual-write адаптер (storage.py)
- [x] Migration скрипты (init_db.py, backfill_postgres.py)
- [x] Конфиг PostgreSQL (postgresql.conf)
- [x] Backup скрипт (pg_backup.sh + systemd)
- [x] DATABASE_URL в .env
- [x] Интеграция в main.py ✓
- [x] Создание структуры modules/vpn, modules/admin ✓
- [x] ClientService, LinkService классы ✓
- [x] DashboardService класс ✓
- [x] main.py уменьшен до ~100 строк ✓
- [ ] Тестирование в продакшене
- [ ] Полная миграция handlers в модули
- [ ] Переключение на PG-only (USE_POSTGRES=true)

**BL-003 Модульная архитектура - в работе:**
- [x] Создана структура пакетов src/bot/modules/
- [x] Созданы modules/vpn/__init__.py, client_service.py, link_service.py
- [x] Созданы modules/admin/__init__.py, dashboard_service.py
- [x] Создан config.py модуль
- [x] main.py уменьшен до ~100 строк (было 1000+)

## Примечания
Zero-downtime миграция: dual-write → backfill → switch → cleanup
Оценка: 3-5 дней работы
