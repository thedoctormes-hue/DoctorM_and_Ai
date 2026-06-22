# Research Lab — Reference

## Архитектура маршрутизации

```
Запрос → Оркестратор → Провайдер
    │
    ├── factual (факты, новости) → Tavily (ротация 5 ключей)
    ├── content (контент страницы) → Firecrawl scrape (ротация 5 ключей)
    ├── dynamic (JS/SPA сайты) → TinyFish fetch (ротация 5 ключей)
    ├── broad (метапоиск) → SearXNG (бесконечный)
    ├── deep_research → ВСЕ 4 провайдера параллельно + дедуп
    └── fallback → SearXNG (если всё упало)
```

## Провайдеры

| Провайдер | Ключей | Лимит/мес | Уникальная сила | Когда использовать |
|-----------|--------|-----------|-----------------|-------------------|
| **Tavily** | 5 | 5000 кредитов | AI-synthesized ответы | Факты, новости, быстрые ответы |
| **Firecrawl** | 5 | 5000 кредитов | Полный скрапинг страниц | Контент статей, документация, batch |
| **TinyFish** | 5 | Бесплатно | JS-рендеринг, бот-обход | JS/SPA сайты, динамический контент |
| **SearXNG** | 0 | Бесконечный | Метапоиск 70+ движков | Fallback, широкий поиск, кросс-проверка |

## Уровни надёжности

```
Уровень 1 (основной): api-hub оркестратор → 15 ключей, 4 провайдера, ротация
    ↓ при ошибке
Уровень 2 (fallback): нативный web_search → Tavily, 1 ключ
    ↓ при ошибке
Уровень 3 (аварийный): сообщить пользователю "Поиск недоступен"
```

## Ротация ключей

Циклическая per-провайдер: каждый запрос использует следующий ключ по кругу.
При 429/ошибке → пропустить ключ, попробовать следующий (до 5 попыток).
Все 5 ключей исчерпаны → fallback на SearXNG.

```bash
# Проверка всех ключей
bash /root/LabDoctorM/projects/api-hub/scripts/search-check-keys.sh
```

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

## Файлы и скрипты

- Оркестратор: `/root/LabDoctorM/projects/api-hub/scripts/search-orchestrator.sh`
- Параллельный поиск: `/root/LabDoctorM/projects/api-hub/scripts/search-parallel.sh`
- Проверка ключей: `/root/LabDoctorM/projects/api-hub/scripts/search-check-keys.sh`
- Конфиг ключей: `/root/LabDoctorM/projects/api-hub/config/search-keys.yaml`
- Документация: `/root/LabDoctorM/projects/api-hub/docs/search-architecture.md`
- Тесты: `/root/LabDoctorM/projects/api-hub/tests/test-providers.sh`
- Логи: `/root/LabDoctorM/projects/api-hub/logs/`
