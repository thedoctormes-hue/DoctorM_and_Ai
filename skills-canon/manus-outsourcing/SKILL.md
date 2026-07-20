---
name: manus-outsourcing
description: "Аутсорсинг задач через Manus API v2. Используй когда нужна презентация, сложное исследование, генерация изображений/диаграмм, документы (PPTX/PDF/XLSX), веб-скрапинг. 5 аккаунтов Manus, ~300 кредитов на аккаунт (live total_credits; ежедневного пополнения 1500 НЕТ — FABRICATED). Выгрузка результатов — только локально, вручную (Яндекс Диск в коде не подключён)."
version: 2.0.0
last_reviewed: "2026-07-20"
date: 2026-06-26
author: Dominika (Scout)
status: active
user-invocable: true
tags: [manus, outsourcing, presentation, research, documents]
metadata:
  openclaw:
    requires:
      bins: ["python3", "curl", "jq"]
    primaryEnv: "YANDEX_DISK_PASS"
---

# Manus Outsourcing Skill v2

Аутсорсинг задач через Manus API v2. Manus = 5 аккаунтов, на каждом наблюдалось ~300 кредитов в поле `total_credits` (live). Ежедневного пополнения на 1500 кредитов НЕТ — значение `refresh_credits:1500` помечено FABRICATED в `MANUS_API_v2_VERIFIED.md`. Используется для задач, которые агентам OpenClaw тяжело делать: презентации, сложные исследования, генерация медиа, документы.

## Когда применять

- Нужна презентация (PPTX, PDF)
- Сложное исследование из нескольких источников
- Генерация изображений, диаграмм, графиков
- Документы (XLSX, PDF, Markdown)
- Веб-скрапинг сложных JS-сайтов
- Анализ больших объёмов данных

- Анализ больших объёмов данных

## Границы применимости
- Manus = асинхронный, 15–60 сек на задачу; НЕ для real-time ответов
- ~300 кредитов на аккаунт (live `total_credits`); ежедневного пополнения 1500 НЕТ (FABRICATED)
- Файлы в sandbox Manus живут 48ч — скачать сразу
- Результаты НЕ выгружаются на Яндекс Диск автоматически (модуль не подключён) — только локально
- Redis — hard dependency для CLI `run`/`usage` (выбор аккаунта, rate-limit)
- Файлы >512MB — не поддерживается

## Чек-лист качества
- [ ] Задача относится к профилю Manus (презентация/исследование/медиа/документы/скрапинг)
- [ ] Конкретная формулировка первого сообщения (меньше кредитов)
- [ ] `python3 cli.py usage` — проверен остаток кредитов ДО запуска
- [ ] Результат скачан локально сразу (`--wait --download`)
- [ ] При сбое ключей — ротация/смена аккаунта, exponential backoff при 429
- [ ] План Б при исчерпании: локальные альтернативы (pptx/pandoc/image_generate/diagram-maker)

## Анти-паттерны
- ❌ Задачи real-time / простые вопросы (спроси LLM)
- ❌ Доверие полю `refresh_credits:1500` (помечено FABRICATED)
- ❌ Ожидание авто-выгрузки на Яндекс Диск (модуль не подключён)
- ❌ Запуск без проверки Redis (`redis-cli ping` = PONG)
- ❌ Повторный вызов при 429 без backoff (исчерпание кредитов)
- ❌ Файлы >512MB

## Когда НЕ использовать

- Простые вопросы (спроси у LLM)
- Задачи требующие real-time ответа (Manus асинхронный, 15-60 сек)
- Задачи с очень большими файлами (>512MB)

## Архитектура

```
Агент → CLI (cli.py) → ManusClient (manus_client.py) → Manus API v2
                     ↕
              Webhook Server (webhook_handler.py) ← Manus Events
                     ↓
              Yandex Disk (yandex_disk.py) — НЕ подключён к потоку результатов (выгрузка вручную)
```

**Примечание по Yandex Disk:** модуль `yandex_disk.py` существует, но НЕ импортируется в `cli.py`/`manus_client.py`/`webhook_handler.py` — автоматической выгрузки результатов на Диск в коде нет (проверено).

**Код:** `/root/LabDoctorM/projects/free-api-hunter/scripts/manus-outsourcing/`

## Быстрый старт (CLI)

### Отправить задачу и дождаться результата

```bash
cd /root/LabDoctorM/projects/free-api-hunter/scripts/manus-outsourcing

# Отправить и ждать завершения, скачать результат
python3 cli.py run "Создай презентацию на 10 слайдов про бесплатные API для медицины" \
  --wait --download --timeout 300
```

### Посмотреть результат существующей задачи

```bash
python3 cli.py result <task_id>
```

### Загрузить файл в Manus storage

```bash
python3 cli.py upload ./data/brief.pdf
# → File ID: file-a1b2c3d4e5
```

### Создать проект

```bash
python3 cli.py project "Анализ рынка" "Сделать SWOT-анализ конкурентов"
# → Project ID: proj-9z8y7x6w5v
```

### Проверить баланс кредитов

```bash
python3 cli.py usage
```

### Проверить статус задачи

```bash
python3 cli.py status <task_id>
```

## CLI Reference

### `run` — Отправить задачу

```
python3 cli.py run <message> [options]

Options:
  --wait            Ждать завершения задачи (polling через task.listMessages)
  --download        Скачать вложения после завершения
  --title TEXT      Название задачи
  --timeout SEC     Таймаут ожидания (default: 300)
```

### `result` — Получить результат

```
python3 cli.py result <task_id>
```

Выводит output_text и список вложений.

### `upload` — Загрузить файл

```
python3 cli.py upload <filepath>
```

Двухэтапная загрузка: получение upload_url → PUT байтов. Возвращает file_id.

### `project` — Создать проект

```
python3 cli.py project <name> [instruction]
```

### `usage` — Баланс кредитов

```
python3 cli.py usage
```

### `status` — Статус задачи

```
python3 cli.py status <task_id>
```

## Программное использование (Python API)

```python
import asyncio
from manus_client import ManusClient

async def main():
    client = ManusClient()

    # Создать задачу (create_task возвращает raw-JSON ответ API;
    # реальный ключ ID задачи — "task_id", а не "id")
    task = await client.create_task("Сделать дайджест новостей ИИ")
    task_id = task["task_id"]

    # Дождаться завершения
    await client.wait_for_completion(task_id, timeout=180)

    # Получить результат
    result = await client.get_result(task_id)
    print(result["text"])

    # Скачать вложения
    if result["attachments"]:
        files = await client.download_attachments(task_id, "./output")
        print(f"Скачано: {len(files)}")

asyncio.run(main())
```

## Методы ManusClient

| Метод | Описание |
|-------|----------|
| `create_task(message, instructions="", title="")` | Создать задачу |
| `wait_for_completion(task_id, timeout=300, poll_interval=3)` | Ждать завершения (polling через task.listMessages с exponential backoff) |
| `get_result(task_id)` | Извлечь output_text и attachments |
| `download_attachments(task_id, output_dir="output")` | Скачать вложения в output_dir/manus-output/{task_id}/ |
| `create_project(name, instruction="")` | Создать проект (POST /v2/project.create) |
| `upload_file(filepath)` | Загрузить файл (двухэтапный: upload_url → PUT) |
| `confirm_action(task_id)` | Подтвердить действие агента (waiting state) |
| `list_messages(task_id, order="desc", limit=10)` | Получить сообщения задачи |
| `get_task_detail(task_id)` | Получить детали задачи |
| `get_credits()` | Получить баланс кредитов |

## Webhook Server (опционально)

Для production-режима с автоматическим получением результатов:

```bash
export MANUS_WEBHOOK_URL="https://ваш.домен/webhook/manus"
cd /root/LabDoctorM/projects/free-api-hunter/scripts/manus-outsourcing
python3 webhook_handler.py
```

**Что делает webhook-сервер:**
- При старте регистрирует webhook через `webhook.create`
- Кэширует публичный ключ для проверки подписи
- `task_created` → сохраняет в Redis (TTL 1ч)
- `task_completed` → вызывает get_result + download_attachments
- `task_failed` → логирует ошибку
- `GET /webhook/status` → статус сервера

**Endpoints:**
- `POST /webhook/manus` → принимает события от Manus
- `GET /webhook/health` → health check
- `GET /webhook/status` → webhook_id, uptime, redis status
- `GET /webhook/task/{id}` → статус задачи из Redis

## Конфигурация

**Ключи Manus:** `projects/free-api-hunter/config/manus-keys.json`

```json
{
  "accounts": [
    {"id": "manus-1", "key": "sk-gY-...", "balance": 1303},
    {"id": "manus-2", "key": "sk-pMP...", "balance": 300},
    {"id": "manus-3", "key": "sk-H8e...", "balance": 394},
    {"id": "manus-4", "key": "sk-exo...", "balance": 300},
    {"id": "manus-5", "key": "sk-380...", "balance": 300}
  ]
}
```

**Выбор аккаунта:** least-used (ключ с наибольшим балансом) через Redis.

## Rate Limits

| Endpoint | Лимит |
|----------|-------|
| task.create / task.sendMessage | 10 req/min |
| task.listMessages | 100 req/min |
| task.confirmAction / project.create / file.upload / webhook.create | 40 req/min |

## Стоимость

| Тип задачи | Примерная стоимость |
|---|---|
| Простой вопрос | 10-30 кредитов |
| Исследование (5-7 источников) | 80-150 кредитов |
| Презентация 10 слайдов | 300-400 кредитов |
| Документ/отчёт | 50-100 кредитов |
| Изображение/диаграмма | 30-50 кредитов |

**Лимит кредитов:** ~300 кредитов на аккаунт (наблюдалось live в `total_credits`; пула ежедневного пополнения на 1500 кредитов НЕТ — помечено FABRICATED в `MANUS_API_v2_VERIFIED.md`). 5 аккаунтов ≈ 1500 кредитов суммарно в пуле, но это НЕ ежедневный лимит — кредиты расходуются из пула и могут уходить в минус.

## Загрузка на Яндекс Диск (ВРУЧНУЮ — не автоматическая)

⚠️ **Важно:** код скилла НЕ загружает результаты на Яндекс Диск автоматически. Модуль `yandex_disk.py` существует, но НЕ подключён к потоку `get_result`/`download_attachments` (проверено: нет импорта `YandexDisk` в `cli.py`/`manus_client.py`/`webhook_handler.py`). Все артефакты скачиваются **локально** (`output_dir/manus-output/{task_id}/`).

Если нужна выгрузка на Диск — сделай это вручную, например через скилл `yandex-suite` (WebDAV PUT):

```
/colony/shared/YYYY-MM-DD_manus-<описание>.<расширение>
```

Используй скилл `yandex-suite` для загрузки (WebDAV PUT).

## Обработка ошибок

| Ошибка HTTP | Код | Что делать |
|---|---|---|
| 429 | rate_limited | Exponential backoff: 1с→2с→4с→8с. Если retries > 5 → сменить ключ |
| 401 | unauthorized | Ключ невалиден → сменить на следующий |
| 404 | not_found | Task не существует → вернуть ошибку |
| 410 | gone | Файл удалён (48ч) → запросить повторно |

**Важно:** Файлы в sandbox Manus живут только 48 часов. Скачать нужно сразу.

## План B (при исчерпании кредитов)

Если все 5 аккаунтов исчерпали кредиты (суммарно ~1500 в пуле, без ежедневного пополнения — `usage` покажет остаток):

1. **Подождать сброса лимита** — кредиты обновляются каждые 24ч. Проверить через `python3 cli.py usage`
2. **Использовать альтернативные инструменты:**
   - Презентации → `python-pptx` локально (без кредитов)
   - Документы → `pandoc`, `wkhtmltopdf` локально
   - Изображения → `image_generate` (встроенный инструмент OpenClaw)
   - Исследования → `searxng-gateway__search_web` (веб) / `searxng-gateway__deep_research` (deep research); контент конкретных URL — `web_fetch`
   - Диаграммы → `diagram-maker` скил
3. **Приоритизация:** если задача срочная → эскалировать ЗавЛабу (возможно ручное выделение кредитов)
4. **Кэширование результатов:** скачанные файлы на Яндекс Диске не удаляются — проверь `/colony/shared/` прежде чем заказывать повторно

## Redis dependency (CLI и Webhook)

Redis — **hard dependency** не только для webhook-сервера, но и для CLI-команд `run`/`usage`. Проверено в коде:
- `cli.py` импортирует `redis.asyncio` в команде `run` (строки ~55-56) и в команде `usage` (~195-196);
- `account_manager.py` хранит балансы (`manus:credits`), последнее использование (`manus:last_used`), token-bucket (`manus:tokens`) и backoff (`manus:backoff`) в Redis;
- выбор аккаунта (least-used / макс. баланс) и rate-limit реализованы через Redis.

Без Redis:
- CLI `run` — не может выбрать аккаунт / проверить баланс / соблюсти rate-limit → падает;
- CLI `usage` — не может прочитать кэш балансов → падает;
- Webhook-сервер: кэширование `task_created` невозможно, статусы (`GET /webhook/task/{id}`) недоступны, события теряются.

**Проверка Redis:** `redis-cli ping` → должен вернуть `PONG`
**Установка если отсутствует:** `apt-get install redis-server && systemctl enable --now redis-server`

Для получения результатов без webhook-сервера используй polling-режим (`--wait` флаг в CLI) — но учти, что выбор аккаунта в `run`/`usage` всё равно требует Redis.

## Формулировка задачи

**Правило:** Чем конкретнее первое сообщение — тем меньше кредитов потратит Manus.

Плохо:
> "Расскажи про бесплатные API для медицины"

Хорошо:
> "Создай презентацию на 10 слайдов о бесплатных API для медицины. Данные: 15 API в 5 категориях (прилагается JSON). Включи: графики роста рынка ($500M→$5B к 2030), сравнительную таблицу по категориям, рекомендации для разработчиков. Формат: PPTX + markdown заметки. Стиль: профессиональный, синие тона."

## Документация

- Исследование API: `projects/free-api-hunter/docs/manus-api-research-2026-06-25.md`
- Воркфлоу аутсорсинга: `projects/free-api-hunter/docs/manus-outsourcing-workflow-2026-06-25.md`
- Пошаговый воркфлоу: `projects/free-api-hunter/docs/manus-skill-workflow-step-by-step.md`
- Спецификация скилла: `projects/free-api-hunter/docs/manus-outsourcing-skill-spec.md`
- Архитектура webhook: `scripts/manus-outsourcing/docs/webhook-architecture.md`
- Конфиг ключей: `projects/free-api-hunter/config/manus-keys.json`

---

_Скилл обновлён 26.06.2026 для Manus API v2 с CLI, webhook и полным Python API._
