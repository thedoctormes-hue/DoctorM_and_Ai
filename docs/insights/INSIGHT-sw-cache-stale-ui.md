---
name: sw-cache-stale-ui
description: Service Worker кэширует старый бандл — UI показывает устаревший контент.
type: insight
status: active
verified: 2026-06-17
source: insight_sw_cache_stale_ui.md
---

# 📦 Service Worker Cache — Stale UI

## Проблема
Service Worker кэширует старый бандл. После деплоя пользователи видят устаревший UI.

## Текущее состояние (подтверждено 2026-06-17)
- `snablab/frontend/public/sw.js` — CACHE_NAME = 'snablab-v7'
- При деплое нужно обновлять CACHE_NAME

## Правила
- При удалении/изменении контента — обновлять CACHE_NAME
- Никогда не использовать cache-first для index.html
- После деплоя: rsync --delete + инвалидация кэша

## Связанное
- feedback_sw_cache_first.md
