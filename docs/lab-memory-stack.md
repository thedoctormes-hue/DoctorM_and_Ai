# Lab Memory Stack — единый утверждённый стек семантического поиска

**Дата:** 2026-06-24
**Статус:** Активен
**ADR:** ADR-0052

## Обзор

Lab Memory Stack — это система семантического поиска по всем .md артефактам лаборатории LabDoctorM. Все 8 агентов используют единый скрипт и единый индекс.

## Архитектура

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

## Компоненты

### 1. Единый скрипт поиска

- **Путь:** `/root/LabDoctorM/shared/lab_search.py`
- **Использование:** `python3 /root/LabDoctorM/shared/lab_search.py search "запрос" --limit 5`
- **Каждый агент:** symlink `bin/lab_search.py → /root/LabDoctorM/shared/lab_search.py`
- **Скилл:** `/root/LabDoctorM/shared/skills/labsearch/SKILL.md` (symlink в каждом агенте)

### 2. FAISS-индекс

- **Путь:** `/root/.openclaw/memory/lab-faiss.index`
- **Метаданные:** `/root/.openclaw/memory/lab-faiss-meta.pkl`
- **База данных:** `/root/.openclaw/memory/md-files.sqlite` (226 MB)
- **Векторы:** 12700+ (растёт), dim=768
- **Тип:** IndexFlatIP, загружается через mmap (`IO_FLAG_READ_ONLY`)
- **RSS на агент:** ~0 (page cache ядра)

### 3. ONNX-эмбеддер

- **Скрипт:** `/root/LabDoctorM/workspaces/antcat/bin/onnx-embedder.py`
- **Модель:** EmbeddingGemma-300m (INT8, 768d)
- **Порт:** 8082
- **systemd:** `onnx-embedder.service` (Restart=on-failure, OOMScoreAdjust=-1000, MemoryMax=700M)
- **RSS:** ~250 MB (один процесс на всех агентов)

### 4. Переиндексация

- **Скрипт:** `/root/LabDoctorM/shared/reindex.py`
- **Режимы:** инкрементальная (по изменённым файлам) или полная
- **Hot-reload:** атомарная замена через `os.rename()`
- **Батчинг:** эмбеддинги запасаются батчами по 32 для снижения ONNX-запросов

## Потребление RAM

- ONNX-модель: ~250 MB (один раз на всех)
- FAISS-индекс: ~0 RSS (mmap, page cache)
- meta.pkl: ~24 MB на агент (загружается в процесс)
- Python overhead: ~10 MB на агент
- **Итого на агент:** ~35 MB RSS
- **Итого система:** ~250 + (35 × 8) ≈ 530 MB

## Отказоустойчивость

- ONNX упал → systemd перезапускает через 5 сек
- ONNX недоступен → fallback на grep по файлам
- FAISS-индекс повреждён → fallback на grep + memory_search
- Агент упал → остальные 7 продолжают работать (нет единой точки отказа)

## Как обновить индекс

```bash
# Инкрементальная переиндексация (только изменённые файлы)
python3 /root/LabDoctorM/shared/reindex.py

# Полная переиндексация (все файлы)
python3 /root/LabDoctorM/shared/reindex.py --full

# Конкретные файлы
python3 /root/LabDoctorM/shared/reindex.py --files path/to/a.md path/to/b.md
```

## Как проверить здоровье

```bash
python3 /root/LabDoctorM/shared/lab_search.py health
```

Ожидаемый вывод:
```json
{
  "faiss_loaded": true,
  "onnx_available": true,
  "vectors": 12738,
  "dim": 768,
  "meta_entries": 12738
}
```

## Что удалено (очистка 2026-06-24)

- `lab-search-proxy` (порт 8081) — убит, systemd-юнит удалён
- Старые скрипты индексации в `antcat/bin/` (build-faiss.py, index-*.sh, write-*.py и т.д.)
- Старые systemd-сервисы индексации (lab-index, incremental-reindex, system-lab-* slices)
- Дублирующиеся скиллы `lab-search`, `lab-semantic-search` в каждом агенте
- Устаревшая документация: lab-search-proxy-manual.md, semantic-search.md, experiment-native-memory-search.md
- Устаревшие ADR: 0042-onnx-semantic-search.md, 2026-06-22-api-hub-search-system.md, 2026-06-22-semantic-search-md-indexer.md
