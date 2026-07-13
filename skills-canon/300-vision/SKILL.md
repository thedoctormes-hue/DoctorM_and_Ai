---
name: 300-vision
description: "Анализ изображений через Cohere vision (command-a-plus). Счётчик 300, ротация 4 ключей, замкнутый fallback. OCR, описание, диаграммы, код."
version: "1.0.0"
status: active
user-invocable: true
metadata: {"openclaw":{"requires":{"bins":["python3","base64"]}}}
triggers:
  phrases:
    - "300 vision"
    - "300 вижн"
    - "анализируй изображение"
    - "опиши изображение"
    - "что на картинке"
    - "что на скриншоте"
    - "распознай текст"
    - "прочитай изображение"
    - "vision"
    - "image analysis"
    - "describe image"
    - "analyze image"
    - "read text from image"
    - "ocr"
  patterns:
    - "(опиши|проанализируй|распознай|прочитай) (картинку|изображение|скриншот|фото)"
    - "(что|что на) (картинке|изображении|скриншоте)"
    - "300 (vision|вижн)"
    - "(vision|image analysis) (image|screenshot)"
  scope:
    - анализ изображений
    - OCR
    - описание изображений
    - анализ скриншотов
    - чтение диаграмм
    - чтение кода с изображений
---

# 300 Vision — анализ изображений через Cohere Vision

Использует Cohere `command-a-plus-05-2026` (436K context, vision) для анализа изображений через `/v2/chat` API.

## Возможности

- **OCR** — распознавание текста со скриншотов, документов, фото
- **Описание** — подробное описание изображений
- **Диаграммы** — анализ графиков, схем, диаграмм
- **Код** — чтение и анализ кода со скриншотов

## Workflow

1. Получить изображение от пользователя (путь к файлу или URL)
2. Если URL — скачать: `curl -sL -o /tmp/vision_input.jpg "<url>"`
3. Запустить скрипт (аргументы ПОЗИЦИОННЫЕ, не флаги): `{baseDir}/scripts/vision.sh <image_path> [prompt] [lang]` — $1=путь к файлу (обяз.), $2=свой промпт (опц.), $3=язык: ru|en|auto (по умолч. auto)
4. Скрипт вернёт результат и обновит счётчик
5. Сообщить результат и статус счётчика

## Команды

```bash
# Анализ изображения (автоопределение языка; $3=lang по умолч. auto)
{baseDir}/scripts/vision.sh /path/to/image.jpg

# Анализ на русском ($3=lang; $2 оставляем пустым, т.к. свой промпт не нужен)
{baseDir}/scripts/vision.sh /path/to/image.jpg "" ru

# Свой промпт ($2=prompt; язык игнорируется, т.к. задан свой промпт)
{baseDir}/scripts/vision.sh /path/to/image.jpg "Какая версия Python на скриншоте?"

# Свой промпт + явный язык
{baseDir}/scripts/vision.sh /path/to/image.jpg "What Python version is on the screenshot?" en

# Статус счётчика
{baseDir}/scripts/vision.sh --status

# Сброс счётчика (только для админа)
{baseDir}/scripts/vision.sh --reset
```

## Счётчик и ротация

- **Начальное значение:** 300 вызовов (`remaining` в state-JSON; с запасом от реальных ~400)
- **После каждого УСПЕШНОГО вызова:** `remaining` `-1` (на ошибке НЕ уменьшается)
- **Ротация:** key1 → key2 → key3 → key4 → key1 (замкнутый fallback по 4 ключам)
- **При ошибке (любой non-200 ответ ИЛИ пустой результат):** переход на следующий ключ, `remaining` НЕ уменьшается
- **Счётчики в state-JSON** (файл `references/vision-state.json`, создаётся автоматически):
  - `remaining` — остаток вызовов (декремент только при успехе)
  - `total_used` / `total_success` — инкремент только при успехе (всегда равны между собой)
  - `key_errors[]` — инкремент для ключа при каждой неудаче (реально работает)
  - `total_fail` — **НЕ инкрементируется скриптом**, всегда = 0 (не полагайся на это поле)
  - `key_usage[]` — счётчик использований по ключам

## Endpoint

- URL: `https://api.cohere.com/v2/chat`
- Method: POST
- Headers: `Authorization: Bearer <key>`, `Content-Type: application/json`

## Формат запроса

```json
{
  "model": "command-a-plus-05-2026",
  "messages": [{"role": "user", "content": [
    {"type": "text", "text": "<промпт>"},
    {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,<base64_data>"}}
  ]}],
  "max_tokens": 2000
}
```

## Извлечение результата

Ответ в `message.content[?].text` где `type == "text"`.

## Обработка ошибок (по коду `vision.sh`)

⚠️ **Факт по коду:** `vision.sh` НЕ классифицирует ошибки. Он проверяет только `http_code == "200"` и непустой результат. Любой non-200 ответ ИЛИ пустой результат → ротация на следующий ключ (`current_key_index` сдвигается, `key_errors[key_idx] += 1`). Никакого различия 401/429/5xx, экспоненциальной задержки и спец-логов (`[WARN]`/`[ERROR] Key N...`) в коде НЕТ.

- **Ротация** по 4 ключам: key1 → key2 → key3 → key4 → key1 (на каждой неудаче — следующий).
- **Если все 4 ключа вернули non-200/пусто** → в stderr: `ERROR: All 4 keys failed`, exit 1. Счётчик НЕ меняется.
- **Если `remaining <= 0` на старте** → stdout: `LIMIT_EXHAUSTED`, exit 1.
- **При успехе** → stdout: `VISION_SUCCESS` + текст результата.

**Что делать при сбое всех ключей:** проверить валидность ключей в конфигурации, затем `vision.sh --status` / `vision.sh --reset`. Счётчик сбрасывается только вручную через `--reset` (автосброса нет).

## Ограничения

- 1 вызов Cohere за одно изображение
- Скорость: ~1-3 секунды на изображение
- Максимальный размер: ~10MB (base64)
- Не подходит для видео

## Файлы

- `scripts/vision.sh` — основной скрипт (анализ + счётчик + ротация, inline Python для генерации тела запроса)
- `references/vision-state.json` — состояние счётчика (создаётся автоматически)
