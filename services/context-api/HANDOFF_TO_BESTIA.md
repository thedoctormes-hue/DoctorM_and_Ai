# Context API — передача Бестии

**От:** Ворон 🐦‍⬛
**Для:** Бестия 🐾
**Дата:** 2026-05-22
**Приоритет:** средний (не горит, но готово к тестированию)

## Что это

Context API — Python/FastAPI микросервис для выдачи контекста лаборантам по API вместо загрузки файлов. Расположен в `projects/myrmex-control/context-api/`.

## Что сделано Вороном

- ✅ FastAPI сервер с 6 эндпоинтами
- ✅ 44 теста, все зелёные
- ✅ systemd сервис `context-api` зарегистрирован (порт 8100)
- ✅ Myrmex не затронут (874 теста зелёные)
- ✅ Документация: README.md + INTEGRATION.md

## Что нужно Бестии

### 1. Запустить и проверить

```bash
# Запуск
systemctl start context-api
systemctl status context-api

# Проверка
curl http://127.0.0.1:8100/health
curl http://127.0.0.1:8100/api/v1/context/core | head -5
curl "http://127.0.0.1:8100/api/v1/memory/search?q=vpn" | python3 -m json.tool | head -10

# Тесты
cd /root/LabDoctorM/projects/myrmex-control/context-api
pytest tests/ -v
```

### 2. Проверить интеграцию с Myrmex

- Myrmex работает на порту 3000
- Context API на порту 8100
- Убедиться что оба сервиса работают одновременно
- Проверить что Myrmex не сломался после запуска Context API

### 3. Проверить автозапуск

```bash
# Включить автозапуск при загрузке
systemctl enable context-api

# Проверить
systemctl is-enabled context-api
```

### 4. Проверить логи

```bash
journalctl -u context-api -f
```

## Эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка |
| GET | `/api/v1/context/{name}` | Контекст (core, staff, projects, rules) |
| GET | `/api/v1/project/{name}` | Проект |
| GET | `/api/v1/memory/{topic}` | Файл памяти |
| GET | `/api/v1/memory/search?q=` | Поиск по памяти |
| GET | `/api/v1/insights/recent` | Инсайты |

## Важно

- Это **отдельный микросервис**, не модуль Myrmex
- Myrmex (Node.js) и Context API (Python) работают независимо
- Муравей потом интегрирует через прокси — но это потом
- Сейчас задача — просто убедиться что сервис стабильно работает

## Контакты

Вопросы → Ворон (projects/raven/)
