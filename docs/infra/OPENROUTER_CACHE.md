---
description: "OpenRouter Response Caching Standard для LabDoctorM"
type: guide
last_reviewed: 2026-05-08
last_code_change: 2026-05-08
status: active
---
# OpenRouter Response Caching Standard для LabDoctorM

## 💰 Что это даёт

- **Первый запрос** → платный (обычная цена)
- **Повторяющиеся запросы** → бесплатные + мгновенные (300ms вместо 9s)

## 🛠️ Как внедрять

### 1. Добавить заголовки запроса

```python
headers = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "X-Cache-Control": "max-age=3600"  # 1 час
}
```

### 2. Проверять cache status

```python
cache_status = resp.headers.get("x-cache-status")
if cache_status == "HIT":
    logger.info("Cache HIT — запрос бесплатный!")
elif cache_status == "MISS":
    logger.info("Cache MISS — первый запрос, платный")
```

### 3. Детерминировать запросы

**Для cache HIT запрос должен быть ИДЕНТИЧЕН:**

```python
payload = {
    "model": model_id,
    "messages": [{"role": "user", "content": "ШАБЛОН_ЗАПРОСА"}],
    "temperature": 0,  # ← ВАЖНО: фиксировать температуру
    "max_tokens": 500
}
```

## 🚫 НЕЛЬЗЯ менять между запросами

- `temperature`
- `messages` (порядок, содержимое)
- `model`
- `max_tokens`
- `top_p`, `frequency_penalty`, `presence_penalty`

## ✅ Шаблоны Golden Set

Создавать константы для повторяющихся запросов:

```python
# llmevangelist/prompts.py
DAILY_STATUS_PROMPT = """Сделай краткий отчёт о статусе лаборатории:
- Используемые модели
- Активные проекты  
- Рекомендации"""

TOP_MODELS_PROMPT = """Найди топ-3 лучшие FREE модели на данный момент
с учётом цены/качества"""
```

## 📊 Мониторинг

Логировать эффективность:

```python
# В stats
cache_hits = 0
cache_misses = 0

# Вычислять экономию
savings = cache_hits * avg_request_cost
```

## 📍 Где применить

| Проект | Файл | Статус |
|--------|------|--------|
| LLMevangelist | `main.py` `fetch_model_response()` | ⏳ ПРИОРИТЕТ |
| Protocol | `assistant.py` | ⏳ |
| OpenClaw | `assistant.py` | ✅ |
| VPNDaemonRobot | `main.py` | ⏳ |

## 🎯 Метрики успеха

- **Cache HIT rate** > 70%
- **Экономия токенов** > $50/месяц
- **Скорость ответов** < 500ms для повторов

---

**Принят: 2026-05-03**  
**Ответственный: КотОлизатОр**