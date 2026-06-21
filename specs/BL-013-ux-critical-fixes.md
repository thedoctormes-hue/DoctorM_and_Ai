---
type: backlog
id: BL-013
title: 'BL-018: Критические UX-исправления'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:58+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:23+00:00'
---
# BL-018: Критические UX-исправления

> 🟡 P1 | Вес: 3 | Приоритет: high | Статус: pending

## Контекст
Найдено 3 критических UX-бага: дублирование toast-систем (Notifications + ToastContainer), навигация через `window.location.href` вместо `useNavigate()` (полная перезагрузка SPA), нативный `confirm()` вместо ConfirmDialog.

**Обнаружено:** ui-ux (3 критических, 8 средних проблем).

## Цель
Убрать дублирование, исправить навигацию, заменить нативный confirm.

## Зачем
Корректная работа SPA, единообразный UI, предотвращение потери состояния.

## Проект/контекст
myrmex-control → src/client/app/App.tsx, src/client/shared/ui/

## Что сделать
- [ ] **Удалить дублирующую toast-систему**: `ToastContainer.tsx`, `useToast.tsx` — удалить. Оставить только `Notifications.tsx`
- [ ] **Заменить window.location.href на useNavigate()** в App.tsx:
  ```typescript
  const navigate = useNavigate();
  // вместо: window.location.href = path
  ```
- [ ] **Заменить нативный confirm() на ConfirmDialog** в Projects.tsx, Files.tsx, Library.tsx
- [ ] **Добавить ARIA-атрибуты** на навигацию: `aria-label`, `aria-current="page"` для NavLink
- [ ] Исправить `text-muted` → `text-muted-foreground` в Analytics, HealthScore

## Критерии готовности
- [ ] ToastContainer и useToast удалены
- [ ] Навигация не вызывает перезагрузку страницы
- [ ] Все confirm() заменены на ConfirmDialog
- [ ] ARIA-атрибуты на навигации
- [ ] Нет CSS-классов `text-muted` (не определён в Tailwind)

## Зависимости
- Нет

## Назначение
- **Вес:** 3
- **Скиллы:** frontend-ui-engineering, browser-testing-with-devtools
- **Статус:** pending
- **Приоритет:** high
- **Ответственный:** telegram_webapp_developer

---
*Summary: Убрать дублирование toast, исправить навигацию на useNavigate, заменить confirm на ConfirmDialog → myrmex-control UX*
