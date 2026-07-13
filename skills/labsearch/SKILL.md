---
name: labsearch
description: "Семантический поиск по артефактам лаборатории (ADR, паттерны, правила, инциденты, спеки). Спроси на естественном языке «как у нас принято делать X» — получи релевантные артефакты до начала работы. Используй при поиске внутренних стандартов, паттернов и решений."
version: "2.0.0"
author: "ЗавЛаб"
last_reviewed: "2026-06-24"
status: active
metadata: {"clawdbot":{"emoji":"🔎","requires":{"bins":["python3"]}}}
user-invocable: true
triggers:
  phrases:
    - "как у нас принято"
    - "найди артефакт"
    - "lab search"
    - "семантический поиск"
    - "есть ли ADR"
    - "есть ли правило"
    - "найди инцидент"
    - "найди паттерн"
    - "найди спеку"
    - "как мы делаем"
    - "лабораторный реестр"
    - "лабпоиск"
  patterns:
    - "как обычно делаем + [тема]"
    - "есть ли правило/паттерн по"
    - "не уверен в подходе"
    - "с чего начать + проект лаборатории"
    - "был ли похожий инцидент"
    - "ADR + [тема]"
    - "найди в реестре"
  scope:
    - начало работы по любому проекту лаборатории
    - поиск существующих решений перед новым
    - проверка инцидентов и паттернов
    - вопросы «как у нас принято»
---

# Lab Search — семантический слой артефактов

Перед задачей в зоне лаборатории спроси реестр: как тут принято, какие решения/правила/инциденты уже есть. Цель — делать с первого раза, а не через ошибки.

## Архитектура

- **Движок:** in-process FAISS (mmap, `IO_FLAG_READ_ONLY`) + ONNX-эмбеддер
- **Модель:** EmbeddingGemma-300m (INT8, 768d)
- **ONNX:** `http://127.0.0.1:8082` (systemd: `onnx-embedder.service`)
- **Индекс:** `/root/.openclaw/memory/lab-faiss.index` (in-process FAISS, mmap, IO_FLAG_READ_ONLY)
- **Метаданные:** `/root/.openclaw/memory/lab-faiss-meta.json`
- **Единый скрипт:** `/root/LabDoctorM/projects/lab-memory/scripts/lab_search.py`
- **ADR:** ADR-0052

## Когда использовать

- Начинаешь работу по проекту лаборатории — проверь, есть ли ADR/правило/паттерн по теме.
- Столкнулся с проблемой — поищи инцидент (INC) с похожим случаем.
- Не уверен в принятом подходе — спроси, вместо догадки.

## Алгоритм поиска (с fallback)

```
1. Попробовать lab_search.py (in-process FAISS + ONNX)
2. Если упал (timeout, ошибка, score < 0.3) → fallback на grep
3. Если grep ничего не нашёл → сообщить пользователю
```

```bash
# Шаг 1: Основной (единый скрипт для всех агентов)
python3 /root/LabDoctorM/projects/lab-memory/scripts/lab_search.py search "<запрос>" --limit 5

# Шаг 2: Fallback — grep
grep -r -l "<ключевые_слова>" /root/LabDoctorM/adr/ /root/LabDoctorM/docs/ /root/LabDoctorM/projects/*/docs/ 2>/dev/null | head -10
```

> ⚠️ **НЕ** использовать нативный `memory_search` — он сломан (ADR-0054, issue #94125).

## Обработка ошибок

### ONNX timeout / недоступен
- ONNX endpoint (`http://127.0.0.1:8082`) не отвечает → подождать 5с и повторить (max 3 попытки)
- Если после 3 попыток всё ещё недоступен → fallback на grep (Шаг 2 алгоритма)
- Проверить статус сервиса: `systemctl status onnx-embedder.service`
- Перезапустить если нужно: `systemctl restart onnx-embedder.service`

### Index corruption / ошибка чтения
- `lab_search.py` падает с ошибкой → проверить целостность файлов: `ls -la /root/.openclaw/memory/lab-faiss.index /root/.openclaw/memory/lab-faiss-meta.json`
- Если файлы повреждены → запустить переиндексацию: `python3 /root/LabDoctorM/projects/lab-memory/scripts/reindex.py`
- Если переиндексация не помогает → fallback на grep

### Низкий score (все результаты < 0.3)
- Переформулировать запрос (синонимы, ключевые слова)
- Попробовать fallback на grep
- Если grep тоже ничего → сообщить пользователю «артефакты не найдены»

### Скрипт не найден
- Единый скрипт: `/root/LabDoctorM/projects/lab-memory/scripts/lab_search.py`
- Если отсутствует → проверить git статус проекта `lab-memory`

## Границы

Артефакты — зона Ворона (owl). Этот skill **только читает** реестр. Правки контента — не здесь.
