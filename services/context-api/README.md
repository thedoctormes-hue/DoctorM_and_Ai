# Context API v1.2.0 — Сервис контекста лаборатории

> ⚠️ **DEPRECATED** — сервис выведен из эксплуатации (порт 8100 не отвечает; семантический поиск живёт через onnx-embedder:8082 / MCP memory:8087). Код сохранён для истории; не поднимать без решения ЗавЛаба.

## Что это

HTTP-сервис для загрузки контекста лаборантов LabDoctorM. Заменяет ручное чтение файлов через API-запросы с кешированием, rate limiting и метриками.

**Версия:** 1.2.0
**Автор:** Ворон 🐦‍⬛
**Стек:** Python 3 + FastAPI + uvicorn
**Порт:** 8100

## Быстрый старт

```bash
# Запуск сервиса
systemctl start context-api

# Или вручную
cd /root/LabDoctorM/services/context-api
python3 -m uvicorn main:app --host 127.0.0.1 --port 8100

# Проверка
curl http://127.0.0.1:8100/health

# Тесты
python3 -m pytest tests/ -v
```

## Архитектура

```
session_startup.sh ──→ Context API (:8100) ──→ Файлы на диске
                            │
                    ┌───────┼───────┐
                    │       │       │
                 Кеш   Метрики  Rate Limiter
                 (TTL)  (in-mem) (sliding window)
                            │
                    ┌───────┼───────┐
                    │               │
               Myrmex Proxy   Direct File
              (context-index)   (fallback)
```

**Fallback:** При недоступности API, `session_startup.sh` читает файлы напрямую из `/root/LabDoctorM/projects/*/`.

## API Endpoints

### Системные

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Health check |
| GET | `/metrics` | Метрики запросов, кеша, rate limiter |
| GET | `/openapi.json` | OpenAPI спецификация |

### Идентичность агентов

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/identity/{agent}` | Файлы идентичности (compact=true по умолчанию) |
| GET | `/api/v1/identity/{agent}?compact=false` | Полная загрузка (IDENTITY + SOUL + SOUL-deep + CHECKPOINT + HANDOFF) |

**Агенты:** `raven`, `owl`, `bestia`, `antcat`, `kotolizator`, `streikbrecher`
**Источник имён:** `myrmex.json` (единственный источник правды). Только канонические имена, без алиасов.

### Базовый контекст

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/context/{name}` | Контекст по имени |

**Имена:** `core`, `staff`, `projects`, `rules`, `rules-base`, `rules-operational`

### Проекты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/project/{name}` | Секция проекта из QWEN-projects.md |

**Проекты:** `snablab`, `myrmex`, `kotolizator`, `kdl`, `playwright`, `hype`, `raven`, `autoexpert`, `gastro`, `cheque`, `stenographer`, `protocol`, `mail-daemon`, `llm-evangelist`

### Память

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/memory/{topic}` | Файл памяти по теме |
| GET | `/api/v1/memory/search?q={query}` | Поиск по памяти (мин. 2 символа, макс. 10 результатов) |

### Инсайты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/insights/recent?limit=5` | Последние инсайты (1-20) |

### ADR и паттерны

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/adr` | Список ADR (центральные + проектные) |
| GET | `/api/v1/adr/{id}` | ADR по ID (plain text) |
| GET | `/api/v1/patterns` | Список паттернов |
| GET | `/api/v1/patterns/{id}` | Паттерн по ID (plain text) |

### Сессии

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/sessions/recent?limit=5` | Последние сессии (1-20) |
| GET | `/api/v1/sessions/{id}` | Сессия по ID (plain text) |

### Context Index (Myrmex proxy)

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/context-index` | Полный context index из Myrmex |
| GET | `/api/v1/context-index/adr` | ADR индекс (фильтры: project, status) |
| GET | `/api/v1/context-index/specs` | Specs индекс (фильтры: project, status) |
| GET | `/api/v1/context-index/patterns` | Patterns индекс |
| GET | `/api/v1/context-index/sessions` | Sessions индекс |
| GET | `/api/v1/context-index/memory` | Memory индекс |
| GET | `/api/v1/agents/{agent_id}/context-profile` | Профиль контекста агента |

## Параметры пагинации

Контекстные эндпоинты поддерживают пагинацию:

```
GET /api/v1/context/core?offset=10&limit=50
GET /api/v1/memory/snablab?offset=0&limit=100
```

- `offset` — начальная строка (по умолчанию 0, min 0)
- `limit` — количество строк (по умолчанию 500, min 1, max 2000)

## Кеширование

- **Тип:** In-memory TTL кеш
- **Размер:** 256 записей
- **TTL:** 120 секунд
- **Инвалидация:** Автоматическая по TTL, ручная через `cache.invalidate(key)`

## Rate Limiting

- **Алгоритм:** Sliding window
- **Лимит:** 120 запросов в минуту на клиент
- **Ответ при превышении:** HTTP 429 с заголовком `Retry-After: 60`
- **Исключение:** `/health` — rate limiting не применяется (требование для LB)

## Структура файлов

```
services/context-api/
├── main.py              # FastAPI приложение, middleware
├── common.py            # Кеш, метрики, rate limiter, чтение файлов
├── README.md            # Этот файл
├── context-api.service  # systemd unit
├── routers/
│   ├── health.py        # /health
│   ├── context.py       # /api/v1/context/*, /project/*, /memory/*, /insights/*
│   ├── identity.py      # /api/v1/identity/*
│   ├── sessions.py      # /api/v1/sessions/*
│   ├── adr.py           # /api/v1/adr/*
│   ├── patterns.py      # /api/v1/patterns/*
│   └── myrmex_proxy.py  # /api/v1/context-index/*, /agents/*/context-profile
└── tests/
    ├── conftest.py      # Фикстуры, сброс кеша и rate limiter
    └── test_api.py      # Тесты всех эндпоинтов
```

## Интеграция с лаборантами

Каждый лаборант при старте сессии вызывает:

```bash
AGENT=<name> bash /root/.qwen/session_startup.sh
```

Скрипт:
1. Проверяет доступность Context API
2. Если API доступен — загружает контекст через HTTP
3. Если API недоступен — читает файлы напрямую (fallback)

## Отказоустойчивость

| Сценарий | Поведение |
|----------|-----------|
| API доступен | Контекст из API (кешированный) |
| API недоступен | Fallback на локальные файлы |
| Файл пустой | Игнорируется (не включается в ответ) |
| Файл с невалидным UTF-8 | Игнорируется, ошибка в логах |
| Файл не существует | Игнорируется |
| Rate limit превышен | HTTP 429 |
| Myrmex недоступен | HTTP 502/503 для proxy-эндпоинтов |

## Тестирование

```bash
# Все тесты
python3 -m pytest tests/ -v

# Конкретный класс
python3 -m pytest tests/test_api.py::TestIdentity -v

# Edge cases
python3 -m pytest tests/test_api.py::TestEdgeCasesEmptyFiles -v
```

**Покрытие:** 170+ тестов, все эндпоинты, edge cases, безопасность, кеширование, context-index, agent context-profile.

## Безопасность

- Path traversal защита через `validate_id()` — только буквы, цифры, дефисы, подчёркивания
- API key через переменную окружения `CONTEXT_API_KEY`
- CORS ограничен явными origins (localhost:3000, 127.0.0.1:3000)
- Rate limiting 120 req/min per client
- Нет stacktrace leak в error responses
- Systemd hardening: NoNewPrivileges, ProtectSystem, MemoryMax, CPUQuota

## Настройка путей к файлам правил

Context API ожидает `rules.md` по пути `/root/.qwen/rules.md`. Источник истины — `/root/LabDoctorM/docs/rules.md`. Симлинк:

```bash
ln -s /root/LabDoctorM/docs/rules.md /root/.qwen/rules.md
```

## Troubleshooting

**API не отвечает:**
```bash
systemctl status context-api
journalctl -u context-api -n 50
```

**Порт занят:**
```bash
ss -tlnp | grep 8100
```

**Сброс кеша (перезапуск):**
```bash
systemctl restart context-api
```
