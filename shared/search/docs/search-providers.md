# Поисковые провайдеры Deep Research Lab

## Обзор

Скрипт `search-parallel.sh` поддерживает 6 поисковых провайдеров. Все ключи хранятся в `/root/.openclaw/.api-keys.json` (chmod 600).

## Провайдеры

### 1. SearXNG ✅ (основной, self-hosted)

- **Endpoint:** `http://localhost:8889/search?q={query}&format=json&categories=general`
- **Метод:** GET
- **Ключ:** не требуется (self-hosted)
- **Лимит:** бесконечный
- **Результатов:** ~15-36 на запрос
- **Примечание:** локальный индекс, работает без ограничений

### 2. Tavily ✅

- **Endpoint:** `https://api.tavily.com/search`
- **Метод:** POST
- **Ключ:** `api-keys.json → tavily[0..4]` (5 ключей × 1000 credits = 5000/мес)
- **Заголовок:** `Content-Type: application/json`
- **Body:** `{"api_key":"...","query":"...","max_results":5,"include_answer":true}`
- **Лимит:** 5000 credits/мес
- **Результатов:** 5 на запрос

### 3. Firecrawl ✅

- **Endpoint:** `https://api.firecrawl.dev/v1/search`
- **Метод:** POST
- **Ключ:** `api-keys.json → firecrawl[0..4]` (5 ключей × 1000 credits = 5000/мес)
- **Заголовки:** `Content-Type: application/json`, `Authorization: Bearer {key}`
- **Body:** `{"query":"...","limit":5}`
- **Лимит:** 5000 credits/мес
- **Результатов:** 5 на запрос

### 4. TinyFish ✅

- **Endpoint:** `https://api.search.tinyfish.ai?query={query}&location=US&language=en`
- **Метод:** GET
- **Ключ:** `api-keys.json → tinyfish[0..4]` (5 ключей)
- **Заголовок:** `X-API-Key: {key}`
- **Лимит:** неизвестен (free tier)
- **Результатов:** ~9 на запрос
- **Документация:** https://docs.tinyfish.ai

### 5. DuckDuckGo ⚠️ (проблема)

- **Endpoint (Instant Answer):** `https://api.duckduckgo.com/?q={query}&format=json&no_html=1`
- **Endpoint (HTML scrape):** `https://html.duckduckgo.com/html/?q={query}`
- **Метод:** GET
- **Ключ:** не требуется
- **Статус:** ❌ HTML scrape возвращает 403 (требует JS)
- **Альтернатива:** SerpAPI, Serper

### 6. Parallel Free ⚠️ (нет ключа)

- **Endpoint:** `https://api.parallel.ai/v1/search`
- **Метод:** POST
- **Ключ:** требуется (не получен)
- **Статус:** ❌ `{"code":16,"message":"No API key provided"}`

## Ротация ключей

Скрипт `search-key-rotate.sh` автоматически переключается на следующий ключ при ошибке 429 (rate limit). Ключ в `api-keys.json` — массив, ротация по кругу.

## Итого

| Провайдер | Статус | Ключей | Лимит | Результатов |
|-----------|--------|--------|-------|------------|
| SearXNG | ✅ | 0 | ∞ | 15-36 |
| Tavily | ✅ | 5 | 5000/мес | 5 |
| Firecrawl | ✅ | 5 | 5000/мес | 5 |
| TinyFish | ✅ | 5 | ? | 9 |
| DuckDuckGo | ❌ | 0 | ∞ | 0 (403) |
| Parallel Free | ❌ | 0 | ? | 0 (нет ключа) |

**Рабочих: 4/6**
