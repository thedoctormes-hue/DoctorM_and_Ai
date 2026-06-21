---
description: "Аудит: myrmexcontrol + demo"
type: guide
last_reviewed: 2026-05-09
last_code_change: 2026-05-09
status: active
---
# Аудит: myrmexcontrol + demo

**Дата:** 2026-05-09
**Аудитор:** Аудитор сайтов лаборатории ЗавЛаб
**Общая оценка:** 3/10

---

## myrmexcontrol.shtab-ai.ru

**URL:** https://myrmexcontrol.shtab-ai.ru
**Стек:** React 19 + Vite + Express (Node.js)
**Статус:** ⚠️ Деплой сломан — отдаёт index.html размером 493 байта
**SSL:** ✅ Let's Encrypt (до 07.08.2026)
**Время отклика:** 0.10с

### Критические проблемы

- Домен показывает тот же контент, что и demo.shtab-ai.ru — баг деплоя
- API на порту 3000 отдаёт HTML на /api/* маршрутах (SPA fallback перехватывает всё)
- Нет health endpoint для проверки работоспособности сервера

### Что работает

- SSL сертификат валиден
- Security headers настроены: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy (4 из 6)

### Что не работает

- Нет HSTS header (Strict-Transport-Security)
- Нет Content-Security-Policy
- Нет SEO-тегов (description, og:title, og:description, robots)
- Нет sitemap.xml и robots.txt

---

## demo.shtab-ai.ru

**URL:** https://demo.shtab-ai.ru
**Стек:** React 19 + Vite + Express (Node.js)
**Статус:** ⚠️ Деплой сломан — отдаёт index.html размером 493 байта
**SSL:** ✅ Let's Encrypt (до 07.08.2026)
**Время отклика:** 0.13с

### Критические проблемы

- Домен показывает тот же контент, что и myrmexcontrol.shtab-ai.ru — баг деплоя
- API на порту 8169 возвращает `{"error":"Internal server error"}` на все запросы
- Nginx проксирует API на http://127.0.0.1:8169, но Node.js сервер возвращает 500

### Что работает

- SSL сертификат валиден
- Мобильная адаптация декларирована (viewport ✅)

### Что не работает

- Нет security headers вообще (0 из 6)
- Нет HSTS header
- Нет Content-Security-Policy
- Нет SEO-тегов
- Нет sitemap.xml и robots.txt

---

## Общие проблемы двух проектов

### Безопасность

- Ни один из сайтов не имеет HSTS или Content-Security-Policy
- demo не имеет ни одного security header
- Оба домена показывают идентичный контент — конфигурация Nginx требует проверки

### SEO

- Нет Open Graph тегов (og:title, og:description, og:image) — плохое превью при шеринге
- Нет description в head
- Нет robots.txt и sitemap.xml
- Нет twitter card тегов

### Мобильная адаптация

- Viewport настроен, но реальная адаптивность зависит от билда
- При сломанном деплое мобильная версия не проверяема

---

## Рекомендации

### Приоритет 1 — Критический: Исправить деплой

- Разобраться почему `/var/www/demo/` и `/var/www/myrmexcontrol/` содержат одинаковые файлы
- Проверить скрипты деплоя из QWEN.md
- myrmex-control должен деплоиться в `/var/www/myrmexcontrol/`
- myrmex-demo должен деплоиться в `/var/www/demo/`
- Исправить API на порту 8169 (demo) — выяснить причину 500 ошибки
- Добавить /api/health endpoint в myrmex-control Express сервер

### Приоритет 2 — Высокий: Добавить security headers

- Добавить Strict-Transport-Security на оба домена
- Добавить Content-Security-Policy на оба домена
- Добавить Permissions-Policy на оба домена
- Для demo — добавить все базовые security headers (сейчас 0)

### Приоритет 3 — Средний: SEO и мониторинг

- Добавить Open Graph теги
- Добавить description и author в head
- Создать robots.txt и sitemap.xml
- Настроить проверку доступности через watchdog
