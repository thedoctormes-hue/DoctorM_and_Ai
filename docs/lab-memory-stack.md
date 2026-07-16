# Lab Memory Stack — единый утверждённый стек семантического поиска

> ⚠️ **НЕАКТУАЛЬНО / SUPERSEDED.** Этот документ описывает пре-ALM стек (FAISS/ONNX/lab_search.py). С 15.07.2026 единственный рабочий и канонический стек семантической памяти — **AnythingLLM (ALM)**. Доступ строго через MCP `memory-gateway__search_memory` (бэкенд ALM/AnythingLLM). Прямые вызовы `lab_search.py` / `labsearch` / `onnx-embedder :8082` / `mcp-memory :8087` / native `memory_search` — ЗАПРЕЩЕНЫ.

**Дата:** 2026-06-24
**Статус:** Устарел (SUPERSEDED)
**ADR:** ADR-0052

---

## Обзор (исторический)

Lab Memory Stack — это система семантического поиска по всем .md артефактам лаборатории LabDoctorM. Все 8 агентов использовали единый скрипт и единый индекс.

## Архитектура (историческая)

```
Агент (Node.js / Python)
  │
  ├── lab_search.py search "запрос"    ← единый скрипт (symlink на shared/)
  │     │
  │     ├── faiss.read_index(mmap)     ← in-process, 0 RSS (page cache)
  │     ├── numpy FAISS search         ← ~2 мс
  │     └── ONNX embed via HTTP        ← ~80 мс roundtrip
  │
  ├── fallback: grep -r                 ← если ONNX упал
  └── fallback: memory_search           ← если grep ничего не нашёл
```

## Компоненты (исторические)

### 1. Единый скрипт поиска (УДАЛЁН)
- **Путь:** `/root/LabDoctorM/shared/lab_search.py`
- **Использование:** `python3 /root/LabDoctorM/shared/lab_search.py search "запрос" --limit 5`
- **Каждый агент:** symlink `bin/lab_search.py → /root/LabDoctorM/shared/lab_search.py`
- **Скилл:** `/root/LabDoctorM/shared/skills/labsearch/SKILL.md` (symlink в каждом агенте)

### 2. FAISS-индекс (УДАЛЁН)
- **Путь:** `/root/.openclaw/memory/lab-faiss.index`
- **Метаданные:** `/root/.openclaw/memory/lab-faiss-meta.pkl`
- **База данных:** `/root/.openclaw/memory/md-files.sqlite` (226 MB)
- **Векторы:** 12700+ (растёт), dim=768
- **Тип:** IndexFlatIP, загружается через mmap (`IO_FLAG_READ_ONLY`)
- **RSS на агент:** ~0 (page cache ядра)

### 3. ONNX-эмбеддер (УДАЛЁН)
- **Скрипт:** `/root/LabDoctorM/workspaces/antcat/bin/onnx-embedder.py`
- **Модель:** EmbeddingGemma-300m (INT8, 768d)
- **Порт:** 8082
- **systemd:** `onnx-embedder.service` (Restart=on-failure, OOMScoreAdjust=-1000, MemoryMax=700M)
- **RSS:** ~250 MB (один процесс на всех агентов)

### 4. Переиндексация (УДАЛЕНА)
- **Скрипт:** `/root/LabDoctorM/shared/reindex.py`
- **Режимы:** инкрементальная (по изменённым файлам) или полная
- **Hot-reload:** атомарная замена через `os.rename()`
- **Батчинг:** эмбеддинги запасаются батчами по 32 для снижения ONNX-запросов

## Канонический путь (актуальный)

Семантическая память — ТОЛЬКО через MCP `memory-gateway` (инструмент `memory-gateway__search_memory`, бэкенд ALM/AnythingLLM). См. `APPEND_SYSTEM.md`.

## Что удалено (очистка 2026-07-14)

- `lab-search-proxy` (порт 8081) — убит, systemd-юнит удалён. Заменён на `lab_search.py` (in-process FAISS + ONNX на 8082, ADR-0052)
- Старые скрипты индексации в `antcat/bin/` (build-faiss.py, index-*.sh, write-*.py и т.д.)
- Старые systemd-сервисы индексации (lab-index, incremental-reindex, system-lab-* slices)
- Дублирующиеся скиллы `lab-search`, `lab-semantic-search` в каждом агенте
- Устаревшая документация: lab-search-proxy-manual.md, semantic-search.md, experiment-native-memory-search.md
- Устаревшие ADR: 0042-onnx-semantic-search.md, 2026-06-22-api-hub-search-system.md, 2026-06-22-semantic-search-md-indexer.md
