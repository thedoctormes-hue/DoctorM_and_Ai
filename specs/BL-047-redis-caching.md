---
type: backlog
id: BL-047
title: BL-005-redis-caching.md
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
---# BL-005: Redis кэширование и FSM Storage

## Контекст
Текущий бот использует MemoryStorage для FSM и не имеет кэширования. При 60к пользователей это отказоустойчивость и производительность.

## Цель
Внедрить Redis: FSM Storage, кэширование сессий, rate limiting, очереди задач.

## Зачем
- MemoryStorage теряет состояния при рестарте
- Нет кэширования — каждый запрос идёт в файлы/БД
- Нет rate limiting — уязвимость к абузу

## Проект/контекст
vpn-daemon → Redis

## Что сделать
- [ ] Установить и настроить Redis 7+ (maxmemory, eviction policy)
- [ ] Заменить MemoryStorage на RedisStorage (aiogram)
- [ ] Кэширование тарифов, конфигов серверов, статусов нод (TTL 5-15 мин)
- [ ] Rate limiting middleware: 30 msg/sec global, 1 msg/sec per user
- [ ] LRU кэш для hot data (in-memory, 1000 entries)
- [ ] Cache invalidation при изменениях через pub/sub
- [ ] Мониторинг: Redis INFO, hit rate, memory usage

## Критерии готовности
- [ ] FSM состояния сохраняются при рестарте
- [ ] Cache hit rate > 80% для тарифов/конфигов
- [ ] Rate limiting работает (тест с 60 запросами/сек → throttle)

## Зависимости
- BL-002 (PostgreSQL)

## Назначение
- **Вес:** 2
- **Скиллы:** cascade
- **Статус:** pending
- **Приоритет:** high

## Примечания
Оценка: 2-3 дня
