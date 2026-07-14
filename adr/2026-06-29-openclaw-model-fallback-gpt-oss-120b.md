# ADR: Замена gpt-oss-20b на gpt-oss-120b в fallback-цепочке OpenClaw

- **Дата:** 2026-06-29
- **Статус:** accepted
- **Автор:** Сова
- **Проект:** DoctorM_and_Ai (OpenClaw config)

## Контекст

Модель `openai/gpt-oss-20b:free` использовалась как fallback в цепочке OpenClaw. При включённом reasoning модель не справлялась с форматом ответов Harmony (OpenAI-совместимый формат):
- 29 ошибок Darkbloom у 3 агентов (antcat, dominika, main)
- отклонение множественных tool_calls
- ошибки компакции памяти (memoryFlush)

## Решение

Замена fallback-модели:
- удалить `openai/gpt-oss-20b:free` из fallbacks, compaction.memoryFlush, intention-hint
- добавить `openai/gpt-oss-120b:free` на позицию #2 в fallbacks и как compaction-модель
- gpt-oss-120b корректно обрабатывает Harmony response format с reasoning

## Последствия

- устранены ошибки Darkbloom/Harmony
- выше стоимость токенов (120b vs 20b), но модель free-tier
- лучше качество reasoning на сложных задачах
- если 120b станет недоступен — потребуется новый fallback

## Ссылки

- `560b501` — replace gpt-oss-20b with gpt-oss-120b to fix Darkbloom/Harmony compaction errors
