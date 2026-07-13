---
name: manus-outsourcing
description: "Аутсорсинг задач через Manus API v2. Используй когда нужна презентация, сложное исследование, генерация изображений/диаграмм, документы (PPTX/PDF/XLSX), веб-скрапинг. 5 аккаунтов Manus, 1500 кредитов/день. Результаты автоматически загружаются на Яндекс Диск."
version: 2.0.0
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

Аутсорсинг задач через Manus API v2. Manus = 5 бесплатных аккаунтов с 300 кредитами/день каждый. Используется для задач, которые агентам OpenClaw тяжело делать: презентации, сложные исследования, генерация медиа, документы.

## Когда использовать

- Нужна презентация (PPTX, PDF)
- Сложное исследование из нескольких источников
- Генерация изображений, диаграмм, графиков
- Документы (XLSX, PDF, Markdown)
- Веб-скрапинг сложных JS-сайтов
- Анализ больших объёмов данных

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
              Yandex Disk (yandex_disk.py)
```

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

    # Создать задачу
    task = await client.create_task("Сделать дайджест новостей ИИ")
    task_id = task["id"]

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

**Лимит:** 300 кредитов/день на аккаунт. 5 аккаунтов = 1500 кредитов/день.

## Загрузка на Яндекс Диск

Все артефакты из Manus загружаются на Диск:

```
/colony/shared/YYYY-MM-DD_manus-<описание>.<расширение>
```

Используй скилл `colony-disk-exchange` для загрузки (WebDAV PUT).

## Обработка ошибок

| Ошибка HTTP | Код | Что делать |
|---|---|---|
| 429 | rate_limited | Exponential backoff: 1с→2с→4с→8с. Если retries > 5 → сменить ключ |
| 401 | unauthorized | Ключ невалиден → сменить на следующий |
| 404 | not_found | Task не существует → вернуть ошибку |
| 410 | gone | Файл удалён (48ч) → запросить повторно |

**Важно:** Файлы в sandbox Manus живут только 48 часов. Скачать нужно сразу.

## План B (при исчерпании кредитов)

Если все 5 аккаунтов исчерпали дневной лимит (1500 кредитов):

1. **Подождать сброса лимита** — кредиты обновляются каждые 24ч. Проверить через `python3 cli.py usage`
2. **Использовать альтернативные инструменты:**
   - Презентации → `python-pptx` локально (без кредитов)
   - Документы → `pandoc`, `wkhtmltopdf` локально
   - Изображения → `image_generate` (встроенный инструмент OpenClaw)
   - Исследования → `web_search` + `web_fetch` (бесплатно)
   - Диаграммы → `diagram-maker` скил
3. **Приоритизация:** если задача срочная → эскалировать ЗавЛабу (возможно ручное выделение кредитов)
4. **Кэширование результатов:** скачанные файлы на Яндекс Диске не удаляются — проверь `/colony/shared/` прежде чем заказывать повторно

## Webhook Server — Redis dependency

Redis — **hard dependency** для webhook-сервера. Без Redis:
- Кэширование событий `task_created` невозможно
- Статус задач (`GET /webhook/task/{id}`) недоступен
- Сервер запустится, но события будут теряться

**Проверка Redis:** `redis-cli ping` → должен вернуть `PONG`
**Установка если отсутствует:** `apt-get install redis-server && systemctl enable --now redis-server`

Для работы без Redis используй polling-режим (`--wait` флаг в CLI) — он не требует Redis.

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
