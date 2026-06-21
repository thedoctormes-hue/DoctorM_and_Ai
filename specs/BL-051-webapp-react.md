---
type: backlog
id: BL-051
title: BL-009-webapp-react.md
status: pending
author: system
created: 2026-05-24 21:11:36+00:00
updated: 2026-05-24 21:11:36+00:00
tags:
- backlog
- vpn
- migrated
related:
- ADR-013
source: manual
last_verified: 2026-06-17
freshness_score: 99
last_checked: '2026-06-20T01:00:30+00:00'
---# BL-009: Telegram Web App — React фронтенд

## Контекст
Inline клавиатуры — ограниченно. Для 60к пользователей нужен полноценный UI: конфиги, тарифы, статистика, настройки.

## Цель
Создать Telegram Web App (React) как основной интерфейс пользователя.

## Зачем
- Богатый UI: таблица конфигов, графики трафика, управление подписками
- Лучше UX чем inline клавиатуры
- Масштабируемость интерфейса

## Проект/контекст
vpn-daemon → webapp

## Что сделать
- [ ] React + Vite + TypeScript Web App
- [ ] Telegram Web App SDK интеграция (initData, theme, haptic)
- [ ] Экраны:
  - Главная: статус подписки, активные конфиги, кнопка подключения
  - Конфиги: список, QR, VLESS ссылки, копирование
  - Тарифы: выбор плана, оплата
  - Профиль: настройки, реферальная программа
- [ ] FastAPI backend: REST API + Telegram initData auth
- [ ] Адаптивный дизайн (мобиль-first)
- [ ] Dark/light theme (автоматически из Telegram)

## Критерии готовности
- [ ] Web App открывается из бота
- [ ] Все экраны работают
- [ ] Авторизация через Telegram initData
- [ ] API защищён, rate limited

## Зависимости
- BL-002 (PostgreSQL)
- BL-003 (модульная архитектура)
- BL-004 (платёжная система)

## Назначение
- **Вес:** 5
- **Скиллы:** cascade, frontend-ui-engineering
- **Статус:** in_progress
- **Приоритет:** high

## Прогресс
- [x] Структура React проекта (src/pages, components, hooks, types)
- [x] package.json + vite.config.ts + tailwind.config.js
- [x] Telegram WebApp SDK типы (telegram.d.ts)
- [x] Главная страница (Home.tsx) — статус подписки, навигация
- [x] Конфиги страница (Configs.tsx) — QR, копирование ссылок
- [x] FastAPI backend API (api/web_app.py) — /configs, /subscription
- [ ] Авторизация через initData
- [ ] Экран тарифов и оплата
- [ ] Экран профиля
- [ ] Адаптивный дизайн

## Примечания
Оценка: 7-10 дней
Stack: React 18 + Vite + TypeScript + FastAPI
Деплой: /var/www/myrmexcontrol/dist/client/
