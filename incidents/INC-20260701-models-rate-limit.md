---
id: INC-20260701-models-rate-limit
timestamp: "2026-07-01T00:00:00Z"
category: tech
type: config_error
severity: high
status: resolved
agent: dominika
title: LLM Models Rate Limited
date: "2026-07-01T07:18:00+00:00"
author: Доминика
tags: [models, openrouter, rate-limit, cron]
---

# Инцидент: LLM Models Rate Limited

## Симптомы
- Все cron задачи сегодня не выполняются
- LLM модели не отвечают (rate limited)
- Агент получает: "All models are temporarily rate-limited"

## Диагностика
1. Файл `/root/.openclaw/models.json` отсутствовал
2. OpenRouter API отвечает, но бесплатные модели перегружены
3. Приоритетные модели в конфиге:
   - `nvidia/nemotron-3-nano-30b-a3b:free` — исчерпан
   - `openrouter/owl-alpha` — возможно также перегружен

## Решение
1. Восстановлен файл `models.json`
2. Обновлён список моделей:
   - Удалены перегруженные `nvidia/nemotron-*` модели
   - Добавлены более стабильные бесплатные модели:
     - `openrouter/owl-alpha` (priority 1)
     - `openai/gpt-oss-20b:free` (priority 2)
     - `qwen/qwen3-next-80b-a3b-instruct:free` (priority 3)
     - `nvidia/nemotron-nano-9b-v2:free` (priority 4)
3. Убраны дубликаты и модели без приоритета

## Время восстановления
~10 минут (07:18 MSK)

## Рекомендации
- Добавить health-check для моделей в cron
- Настроить fallback на Cohere при rate-limit
- Рассмотреть paid тарифы для критичных задач

## Связанные артефакты
- `projects/DoctorM_and_Ai/incidents/INC-20260701-models-rate-limit.md`
- `workspaces/dominika/memory/2026-07-01.md`
