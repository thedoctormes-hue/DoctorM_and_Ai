# Семантический поиск по знаниям лаборатории

**Дата создания:** 2026-06-22
**Статус:** в разработке (индексация)
**Ответственный:** КотОлизатор + Муравей

---

## Архитектура

```
.md файлы → lab-index-md.py → SQLite (chunks + embeddings)
                                    ↓
                              build-faiss.py → FAISS index + meta
                                    ↓
                              lab-search-proxy.py (порт 8081)
                                    ↓
                              ONNX Embedder (порт 8082)
                                    ↓
                              Qwen3-Embedding-0.6B (ONNX, FP16)
```

## Компоненты

### ONNX Embedder (порт 8082)
- **Модель:** Qwen3-Embedding-0.6B (ONNX, FP16, 2.3GB)
- **Сервис:** `/root/LabDoctorM/workspaces/antcat/bin/onnx-embedder.py`
- **systemd:** `systemctl status onnx-embedder`
- **Health:** `curl http://127.0.0.1:8082/health`
- **RAM:** ~2.9GB
- **Скорость:** ~250ms/запрос (прогретый)
- **Отказоустойчивость:** Type=notify, WatchdogSec=45, Restart=always

### Lab Search Proxy (порт 8081)
- **Сервис:** `/root/LabDoctorM/workspaces/antcat/bin/lab-search-proxy.py`
- **API:**
  - `GET /health` — статус
  - `POST /search` — семантический поиск
  - `POST /api/embeddings` — получение embeddings
- **FAISS индекс:** `/tmp/lab-faiss.index`
- **Метаданные:** `/tmp/lab-faiss-meta.pkl`

### База данных
- **SQLite:** `/root/.openclaw/memory/md-files.sqlite`
- **Таблица:** `chunks` (id, source, file_path, content_hash, text, embedding, indexed_at)

## Индексация

### Полная переиндексация
```bash
# Очистить базу
sqlite3 /root/.openclaw/memory/md-files.sqlite "DELETE FROM chunks;"
rm -f /tmp/lab-faiss.index /tmp/lab-faiss-meta.pkl

# Запустить индексацию
cd /root/LabDoctorM/workspaces/antcat/bin
python3 lab-index-md.py

# Построить FAISS
python3 build-faiss.py

# Перезапустить proxy
systemctl restart lab-search-proxy
```

### Ежедневная автоматическая переиндексация
- **Timer:** `onnx-reindex.timer` (каждый день в 03:00 UTC)
- **Service:** `onnx-reindex.service`
- **Статус:** `systemctl list-timers | grep onnx`

## Использование

### Поиск через API
```bash
curl -s -X POST http://127.0.0.1:8081/search \
    -H "Content-Type: application/json" \
    -d '{"query": "семантический поиск", "top_k": 5}'
```

### Получение embedding
```bash
curl -s http://127.0.0.1:8082/api/embeddings \
    -d '{"input": "текст"}'
```

## Что индексируется

Все `.md` файлы в `/root/LabDoctorM/`:
- `adr/` — архитектурные решения
- `patterns/` — паттерны
- `rules/` — правила
- `specs/` — спецификации
- `incidents/` — инциденты
- `docs/` — документация
- `lenses/` — линзы
- `insights/` — инсайты
- `projects/` — проекты
- `workspaces/*/memory/` — память агентов

**Не индексируется:** node_modules, .git, .cache, бинарные файлы

## Мониторинг

```bash
# ONNX
systemctl status onnx-embedder
journalctl -u onnx-embedder -f

# Proxy
systemctl status lab-search-proxy
curl http://127.0.0.1:8081/health

# Индексация
tail -f /tmp/lab-index-md.log

# Статистика
sqlite3 /root/.openclaw/memory/md-files.sqlite "SELECT COUNT(*) FROM chunks;"
python3 -c "import faiss; idx=faiss.read_index('/tmp/lab-faiss.index'); print(f'FAISS: {idx.ntotal} vectors')"
```

## Известные ограничения

- Скорость индексации: ~0.4 чанков/сек (CPU-only)
- RAM: ONNX использует ~2.9GB из 3GB лимита
- При перезапуске ONNX первый запрос медленный (~300ms)
- FAISS требует пересборки после каждой индексации

## История изменений

| Дата | Версия | Что изменилось |
|------|--------|----------------|
| 2026-06-22 | v4 | ONNX embedder с watchdog, Type=notify, systemd timer |
| 2026-06-22 | v3 | Базовая отказоустойчивость, Restart=always |
| 2026-06-22 | v2 | Оптимизации ONNX Runtime |
| 2026-06-22 | v1 | Первая версия, замена Ollama + bge-m3 |
