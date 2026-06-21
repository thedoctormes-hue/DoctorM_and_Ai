---
id: ADR-024
type: adr
title: 'ADR-024: Channel Config Evolution — MUST Language, Block Streaming, maxOutputTokens'
status: accepted
author: streikbrecher
created: '2026-06-11T00:00:00+00:00'
updated: '2026-06-11T00:00:00+00:00'
confidence: outdated
source: agent
last_verified: 2026-06-17
code_refs:
- /root/.qwen/settings.json
tags:
- adr
- channels
- telegram
- config
- language
- streaming
freshness_score: 99
last_checked: '2026-06-20T01:00:16+00:00'
---

# ADR-024: Channel Config Evolution — MUST Language, Block Streaming, maxOutputTokens

## Контекст

Аудит конфигурации всех 6 Telegram-каналов лаборатории выявил три проблемы:

1. **Язык ответов.** В `channel instructions` было `Язык: русский` — декларативный формат без MUST-директивы. Системный промпт Qwen Code на английском, первое сообщение сессии тоже на английском ("This is the Qwen Code..."). Модель видела конфликт и выбирала английский. `output-language.md` загружается как `Context from` блок (низкий приоритет) — недостаточно для перебивания системного промпта.

2. **blockStreaming: off.** Потоковая отправка ответов отключена. Пользователь ждёт полного ответа без обратной связи — для сложных задач 30-60 секунд пустого экрана. Документация Qwen Code рекомендует включать.

3. **maxOutputTokens: 2000.** Лимит 2000 токенов — мало для фулстак-разработки (генерация кода + тесты + документация). Ответы обрезаются.

## Решение

Три изменения в `settings.json` для всех 6 каналов (kotolizator, antcat, bestia, streikbrecher, raven, owl):

### 1. MUST-директива языка в channel instructions

Добавлено в `instructions` каждого канала:
```
You MUST always respond in Русский regardless of the user's input language. This is mandatory.
```

MUST-директива в `channel instructions` — часть системного промпта (высший приоритет). Это перебивает английский системный промпт Qwen Code и английское первое сообщение сессии.

### 2. Block Streaming включён

| Параметр | Было | Стало | Дефолт из документации |
|---|---|---|---|
| blockStreaming | off | on | — |
| blockStreamingChunk.minChars | 200 | 400 | 400 |
| blockStreamingChunk.maxChars | 800 | 1000 | 1000 |
| blockStreamingCoalesce.idleMs | 1000 | 1500 | 1500 |

Значения приведены к дефолтам из документации Qwen Code. Наши предыдущие значения (minChars: 200, idleMs: 1000) давали слишком мелкие блоки и быстрый сброс — спам короткими сообщениями.

### 3. maxOutputTokens увеличен

| Параметр | Было | Стало |
|---|---|---|
| maxOutputTokens | 2000 | 4000 |

Увеличен лимит для полноценной генерации кода, тестов, документации без обрезки.

## Последствия

**Плюсы:**
- Первый ответ в каждой сессии гарантированно на русском
- Ответы приходят прогрессивно (как в ChatGPT) — UX улучшается
- Агенты генерируют полные ответы без искусственной обрезки
- Параметры blockStreaming соответствуют рекомендациям документации

**Минусы / риски:**
- blockStreaming может давать больше сообщений в чат — но это ожидаемое поведение
- maxOutputTokens: 4000 увеличивает время генерации и потребление токенов — приемлемо для нашего сценария
- Изменения вступят в силу после рестарта каналов (`qwen channel stop && qwen channel start`)

## Альтернативы

| Вариант | Плюсы | Минусы | Почему отклонён |
|---|---|---|---|
| Только output-language.md | Не трогает settings.json | Низкий приоритет, не решает проблему | Не работает для первого ответа |
| blockStreaming: on, наши значения | Быстрее включить | minChars: 200 = спам, idleMs: 1000 = частые сбросы | Документация рекомендует другие значения |
| maxOutputTokens: 8000 | Ещё больше пространства | Избыточно, рост времени генерации | 4000 достаточно для 90% задач |

## Связанные артефакты

- `~/.qwen/settings.json` — основной файл конфигурации
- `~/.qwen/output-language.md` — сохраняет силу как дополнительный слой
- QWEN.md → Context API → `/openapi.json` — документация параметров

## Примечания

- Изменения применены к ВСЕМ 6 каналам одновременно
- Рестарт каналов запланирован на позже (по решению ЗавЛаба)
- Предыдущие значения не сохранялись — откат через git при необходимости
