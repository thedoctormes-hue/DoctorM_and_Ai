# Research Lab — Reference

## Архитектура маршрутизации

```
Запрос → searxng-gateway MCP (searxng-gateway__deep_research / __search_web)  ← КАНОН
    │
    └── (backend) Оркестратор search-orchestrator.sh → SearXNG localhost:8889 (= backend searxng-gateway)
            │
            ├── factual (факты, новости) → Tavily (через SearXNG engines=tavily)
            ├── content (контент страницы) → Firecrawl scrape (через SearXNG engines=firecrawl)
            ├── dynamic (JS/SPA сайты) → TinyFish fetch (через SearXNG engines=tinyfish)
            ├── broad (метапоиск) → SearXNG (бесконечный, локальный)
            ├── verify → Tavily × SearXNG кросс-проверка (URL intersection)
            ├── deep_research → ВСЕ провайдера параллельно + агрегация
            └── fallback → СЛЕДУЮЩИЙ провайдер в цепочке (РЕАЛИЗОВАНО В КОДЕ)
```

> Fallback реализован функцией `run_chain`: при сбое/429/пустом ответе
> провайдера оркестратор автоматически переходит к следующему.
> См. `_meta.provider_used` / `_meta.fell_back` в ответе.

## Провайдеры

| Провайдер | Ключей | Лимит/мес | Уникальная сила | Когда использовать |
|-----------|--------|-----------|-----------------|-------------------|
| **Tavily** | 5 | 5000 кредитов | AI-synthesized ответы | Факты, новости, быстрые ответы |
| **Firecrawl** | 5 | 5000 кредитов | Полный скрапинг страниц | Контент статей, документация, batch |
| **TinyFish** | 5 | Бесплатно | JS-рендеринг, бот-обход | JS/SPA сайты, динамический контент |
| **SearXNG** | 0 | Бесконечный | Метапоиск 70+ движков | Fallback, широкий поиск, кросс-проверка |

## Уровни надёжности

```
Уровень 1 (КАНОН): MCP-тул `searxng-gateway__deep_research` / `__search_web`
    ↓ при падении MCP-сервера
Уровень 2 (backend/fallback): оркестратор `search-orchestrator.sh` → шлёт в
                       SearXNG localhost:8889 (= backend searxng-gateway),
                       15 ключей, 4 провайдера, ротация + ГАРАНТИРОВАННЫЙ fallback
    ↓ при падении САМОГО оркестратора (процесс недоступен)
Уровень 3 (fallback): прямой запрос к локальному SearXNG (localhost:8889)
    ↓ при ошибке
Уровень 4 (аварийный): сообщить пользователю "Поиск недоступен"
```

## Ротация ключей

Циклическая per-провайдер: каждый запрос использует следующий ключ по кругу.
При 429/ошибке → пропустить ключ, попробовать следующий (до N попыток).
Все ключи провайдера исчерпаны → `run_chain` переходит к следующему провайдеру
(цепочка выше), в конце — SearXNG (локальный, не тратит квоту).

## Режим verify (обязателен для критичных фактов)

`verify_research` прогоняет запрос через Tavily и SearXNG, извлекает URL
результатов каждого, считает пересечение. Результат содержит
`_meta.verification`:

```json
{
  "verification": {
    "cross_checked_with": ["tavily", "searxng"],
    "tavily_urls": 8,
    "searxng_urls": 24,
    "overlapping_urls": ["https://...", "..."],
    "overlap_count": 3,
    "threshold": 2,
    "url_overlap_verified": true,
    "answer_grounding": 0.92,
    "answer_status": "verified" | "answer_ungrounded" | "unverified_synthesis" | "single_source_unverified" | "both_sources_unavailable"
  }
}
```

Если `verified = false` → поле `answer` помечается префиксом
`[UNVERIFIED_SYNTHESIS]`. Агент ОБЯЗАН цитировать `results`, а не `answer`.

## Профили агентов

| Агент | Профиль | Провайдеры |
|-------|---------|------------|
| raven (Researcher) | Deep | Все |
| dominika (Scout) | Standard+ | Firecrawl + TinyFish |
| mangust (Analyst) | Standard | Tavily + Firecrawl + SearXNG |
| streikbrecher (Dev) | Standard+ | Tavily + Firecrawl GitHub |
| antcat (Builder) | Quick+ | Tavily + SearXNG + GitHub |
| kotolizator (Orch) | Quick | Tavily + SearXNG |
| bestia (Operator) | Quick | Tavily + SearXNG |
| owl (Auditor) | Standard | Tavily + SearXNG + Firecrawl |

## Формат отчёта (Markdown)

```markdown
# Исследование: <тема>

**Дата:** YYYY-MM-DD
**Уровень:** Deep
**Confidence:** High/Medium/Low

## Краткий ответ
<1-3 предложения>

## Детальный анализ
<структурированный текст с цитированием>

## Источники
1. [Название](URL) — ключевой факт

## Фактчекинг
- Утверждение → 3 источника → High
```

## Формат отчёта (JSON)

```json
{
  "query": "<запрос>",
  "date": "YYYY-MM-DD",
  "level": "Deep",
  "confidence": "High",
  "summary": "<краткий ответ>",
  "findings": [{"fact": "...", "sources": [...], "confidence": "High"}],
  "sources": [{"title": "...", "url": "...", "key_fact": "..."}],
  "contradictions": []
}
```

## Продвинутая обработка (v1.3)

Поверх маршрутизации оркестратор применяет 6 слоёв (модуль `lib/process.py`):

1. **Кэш** — `data/cache/`, TTL 1ч (recency-темы) / 24ч, проверка по mtime-age, `_meta.cached`.
2. **Фрешнес** — `published_date`, `age_days`, `freshness_score` (half-life 180 дней).
3. **Мерж/дедуп** — нормализация URL, `provider_count`, `_confidence` (0.4 + доля провайдеров + фрешнес).
4. **Противоречия** — `_meta.contradictions` при расхождении версий/годов (`version_conflict` / `year_spread`).
5. **Адаптивная маршрутизация** — `config/.provider-stats.json`, reorder fallback-цепочки по успехам.
6. **Декомпозиция** — `deep_research` дробит сложный запрос («A vs B»), мержит подрезультаты (`_meta.decomposed`).

Приоритет достоверности результата (по убыванию):
пересечение провайдеров (`provider_count`) → фрешнес → наличие `contradictions`-флага.

## Файлы и скрипты

- Оркестратор: `/root/LabDoctorM/projects/free-api-hunter/scripts/search-orchestrator.sh`
- Модуль обработки: `/root/LabDoctorM/projects/free-api-hunter/scripts/lib/process.py`
- Тесты: `/root/LabDoctorM/projects/free-api-hunter/tests/test-providers.sh`
- Логи: `/root/LabDoctorM/projects/free-api-hunter/logs/`
- Конфиг ключей: `/root/LabDoctorM/projects/free-api-hunter/config/search-keys.yaml`
