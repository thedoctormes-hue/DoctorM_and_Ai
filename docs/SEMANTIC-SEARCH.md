---
description: "SEMANTIC SEARCH"
type: guide
last_reviewed: 2026-06-23
last_code_change: 2026-06-23
status: active
---

# Семантический поиск по лаборатории

**Статус:** Этапы 1-4 в работе (индексация .md файлов ~20%)
**Дата:** 2026-06-23
**Автор:** Муравей (antcat)

## ⚠️ Критическое ограничение: размерность embedding

**2026-06-23 — Эксперимент показал:**

- **384d модели (MiniLM-L6-v2) НЕ пригодны** для семантического поиска по нашим данным
  - Из 10 запросов выдавали только 3 уникальных результата
  - Frontmatter чанков доминирует над семантикой
  - Высокий score (0.89) — ложное преимущество, модель не различает контекст
- **1024d — минимально рабочая размерность** для наших данных
- **Рекомендация:** использовать только модели с embedding dim >= 1024

**Источник:** `workspaces/antcat/docs/mission-semantic-stack-v2.md`

---

## Архитектура

```
Агенты OpenClaw → memory_search tool
                       │
                       ▼
              OpenClaw memorySearch engine
              (provider: openai-compatible)
              (baseUrl: http://127.0.0.1:8081)
                       │
                       ▼
              lab-search-proxy (port 8081)
              ┌─────────────────────────────┐
              │ /v1/embeddings → Ollama      │
              │ /search        → FAISS+FTS5  │
              │ /health        → status       │
              │ /reindex       → rebuild      │
              └─────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  FAISS   │ │  SQLite  │ │  Ollama  │
    │  index   │ │  chunks  │ │  bge-m3  │
    │  23 MB   │ │  5777+   │ │  CPU     │
    └──────────┘ └──────────┘ └──────────┘
```

---

## Компоненты

### 1. lab-embedder.py — генерация эмбеддингов (memory chunks)

- **Модель:** `bge-m3-cpu` (CPU-оптимизированная, ~1.2 GB)
- **Режим:** batch (batch-size=30)
- **Resumable:** пропускает уже обработанные чанки
- **RAM protection:** пауза при нехватке RAM
- **Логирование:** systemd journal

```bash
systemctl status lab-embedder
journalctl -u lab-embedder -f
```

### 2. lab-index-md.py — индексация .md файлов

Сканирует директории (adr, patterns, rules, specs, incidents, docs, projects, workspaces), читает .md файлы, генерирует эмбеддинги.

- **Resumable:** пропускает неизменённые файлы (по SHA-256)
- **Фильтрация:** пропускает node_modules, .git, .pytest_cache
- **Chunking:** разбивает большие файлы на чанки по ~500 символов
- **БД:** `/root/.openclaw/memory/md-files.sqlite`

```bash
# Запуск полной индексации
python3 workspaces/antcat/bin/lab-index-md.py

# Инкрементальная (только изменённые)
python3 workspaces/antcat/bin/lab-index-md.py
```

### 3. build-faiss.py — построение FAISS-индекса

Сканирует все SQLite базы, извлекает эмбеддинги, строит FAISS IndexFlatIP.

```bash
python3 workspaces/antcat/bin/build-faiss.py
# /tmp/lab-faiss.index (23 MB, 5777 векторов)
# /tmp/lab-faiss-meta.pkl (4.0 MB)
```

### 4. lab-search-proxy.py — HTTP API

HTTP-прокси на порту 8081.

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | статус сервиса |
| POST | `/v1/embeddings` | генерация эмбеддингов |
| POST | `/search` | семантический поиск |
| POST | `/reindex` | пересборка индекса |

```bash
# Health
curl http://127.0.0.1:8081/health

# Embeddings
curl -X POST http://127.0.0.1:8081/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"input": "запрос"}'

# Поиск
curl -X POST http://127.0.0.1:8081/search \
  -H "Content-Type: application/json" \
  -d '{"query": "системная интеграция", "top_k": 5}'

# Пересборка FAISS
curl -X POST http://127.0.0.1:8081/reindex
```

### 5. test-lab-search.py — тесты

25 тестов: health, embeddings, search, FAISS, systemd, конфигурация.

```bash
python3 workspaces/antcat/bin/test-lab-search.py
```

---

## Данные

### SQLite-чанки (OpenClaw memory)

| Агент | Чанков | Статус |
|-------|--------|--------|
| ant | 724 | ✅ |
| antcat | 646 | ✅ |
| bestia | 623 | ✅ |
| dominika | 642 | ✅ |
| kotolizator | 626 | ✅ |
| mangust | 676 | ✅ |
| owl | 590 | ✅ |
| raven | 619 | ✅ |
| streikbrecher | 631 | ✅ |
| **Итого** | **5777** | **100%** |

### SQLite-чанки (.md файлы)

| Источник | Файлов | Чанков | Статус |
|----------|--------|--------|--------|
| adr | 36 | ~150 | 🔄 |
| patterns | 20 | ~80 | 🔄 |
| rules | 8 | ~30 | 🔄 |
| specs | 56 | ~200 | 🔄 |
| incidents | 20 | ~80 | 🔄 |
| docs | 98 | ~400 | 🔄 |
| lenses | 10 | ~40 | 🔄 |
| insights | 1 | ~5 | 🔄 |
| projects | ~3300 | ~2500 | 🔄 |
| workspaces | ~224 | ~200 | 🔄 |
| **Итого** | **~734** | **~3700** | **~20%** |

### FAISS-индекс

- **Тип:** IndexFlatIP (cosine similarity)
- **Размерность:** 1024
- **Векторов:** 5777 (memory) + ~3700 (.md) = ~9500 (после завершения)
- **Размер:** 23 MB (memory) + ~15 MB (.md) = ~38 MB (после завершения)

---

## Конфигурация

### systemd units

- `/etc/systemd/system/lab-embedder.service` — генерация эмбеддингов
- `/etc/systemd/system/lab-search-proxy.service` — HTTP API

### Ollama

```ini
OLLAMA_NUM_THREADS=4
OLLAMA_NUM_PARALLEL=1
OLLAMA_KEEP_ALIVE=-1
OLLAMA_MAX_LOADED_MODELS=1
```

### OpenClaw (openclaw.json)

```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "openai-compatible",
        "model": "bge-m3",
        "remote": {
          "baseUrl": "http://127.0.0.1:8081"
        },
        "fallback": "none"
      }
    }
  }
}
```

---

## Команды управления

```bash
# Статус
systemctl status lab-embedder lab-search-proxy

# Логи
journalctl -u lab-embedder -f
journalctl -u lab-search-proxy -f

# Перезапуск
systemctl restart lab-search-proxy

# Пересборка FAISS
python3 workspaces/antcat/bin/build-faiss.py

# Индексация .md файлов
python3 workspaces/antcat/bin/lab-index-md.py

# Тесты
python3 workspaces/antcat/bin/test-lab-search.py
```

---

## Структура файлов

```
/root/LabDoctorM/
├── workspaces/antcat/bin/
│   ├── lab-embedder.py       # генерация эмбеддингов (memory)
│   ├── lab-index-md.py       # индексация .md файлов
│   ├── lab-search-proxy.py   # HTTP API (порт 8081)
│   ├── build-faiss.py        # построение FAISS-индекса
│   └── test-lab-search.py    # тесты (25 tests)
├── docs/
│   ├── SEMANTIC-SEARCH.md    # этот файл
│   └── SEMANTIC-SEARCH-PLAN.md # план развёртывания
└── /etc/systemd/system/
    ├── lab-embedder.service
    └── lab-search-proxy.service
```

---

## Следующие шаги

1. **Этап 4:** Завершение индексации .md файлов (~10-15 мин)
2. **Этап 5:** Инкрементальная переиндексация по хешам + cron

---

## Известные проблемы

1. **2 чанка не обработались embedder** — дубликат в owl/raven. Решение: ручная вставка.
2. **embedder завершился с 2 ошибками** — не критично, чанки дозаполнены.
3. **FAISS не персистентен** — при перезапуске сервера нужна пересборка (~30 сек).
4. **Индексация .md медленная** — ~4 чанка/сек. Причина: batch-обработка через Ollama.

---

## Метрики

| Показатель | Значение |
|---|---|
| Memory чанки | 5777/5777 (100%) |
| .md чанки | ~420/~3700 (~11%) |
| FAISS векторов | 5777 |
| Размер FAISS | 23 MB |
| Модель | bge-m3-cpu |
| Порт прокси | 8081 |
| Тесты | 25/25 passed |
