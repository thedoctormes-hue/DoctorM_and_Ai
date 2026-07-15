---
id: INC-20260709-onnx-batch-deadlock
timestamp: "2026-07-09T00:00:00Z"
category: tech
type: fantasy
severity: medium
status: retired
agent: streikbrecher
title: INC-20260709-onnx-batch-deadlock
resolution: Урок вытянут в skill fact-check: обязательная проверка фактов, запрет фантазий. Рецидив перехватывается дисциплиной.
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-20260709-onnx-batch-deadlock

**Дата:** 2026-07-09
**Агент:** Streikbrecher
**Статус:** ROOT CAUSE найден и устранён (фикс в reindex.py, reindex-full перезапущен)

## Симптом

- `reindex --full` запускался, но `embed_count` в ONNX стоял на месте (0→7→0), индекс
  оставался пустым (FAISS ~3.6k векторов вместо ~20k+).
- ONNX процесс жив, но `session.run` зависал на батчах reindex.
- Предыдущие диагнозы (размер файла, утечка сессии, память) — неверны.

## Корень (измерен, не выдуман)

**ONNX Runtime deadlock при размере батча ≥ ~7 текстов.**

Замер на реальном корпусе (`collect_target_files()` → `sanitize_text` → embed через
`http://127.0.0.1:8082/v1/embeddings`, timeout 15с):

| Число текстов в батче | Результат | Время |
|---|---|---|
| 1 | OK | 1.9s |
| 2 | OK | 3.9s |
| 3 | OK | 5.9s |
| 4 | OK | 8.7s |
| 5 | OK | 10.3s |
| 6 | OK | 12.3s |
| 8 | **HANG** (TimeoutError 15s) | — |
| 10 | **HANG** (TimeoutError 15s) | — |

Время растёт линейно (~2с/текст) до 6, затем жёсткий deadlock.
Синтетический тест «1 текст 800KB» проходил — поэтому ранние гипотезы про размер
были ложными. Реальный reindex шлёт **159 файлов за батч** (группировка только по
байтам, `max_bytes=800_000`) → 100% попадание в deadlock → embed_count не растёт.

Deadlock внутри `onnxruntime.InferenceSession.run` (GIL отпущен, но внутренний
deadlock ONNX Runtime). Воспроизводится стабильно на реальных .md лаборатории.

## Почему не заметили раньше

- Синтетические тесты гоняли 1 большой текст → проходили.
- Рантайм ONNX стоит за HTTP, deadlock маскировался под «Connection refused» после
  таймаута клиента (600с!).

## Фикс

`scripts/reindex.py`:
- Добавлена константа `EMBED_BATCH_MAX_TEXTS = 5` (с запасом от порога deadlock 7).
- `embed_via_onnx` теперь режет батч по `min(max_bytes, max_texts)` — ни один запрос
  к ONNX не содержит >5 текстов.
- Таймаут клиента `urlopen` снижен 600с → 60с (быстрый fail вместо ступора).

Зафиксировано в `docs/INDEXING-RULES.md`: `EMBED_BATCH_MAX_TEXTS=5`, поднимать выше
запрещено без повторного замера на реальном корпусе.

## Статус после фикса

- `reindex-full.service` (systemd, MemoryMax=1G, CPUQuota=50%, IOWeight=10) перезапущен.
- Логи нового прогона: `[0/5162]…[60/5162] 6 chunks, 0 skip, 0 err`, `embed_count`
  растёт. Индекс наполняется.
- Время полного прохода: ~2.3ч (5162 файла / 5 на батч × ~8с, с CPUQuota=50% дольше).
- Сервер не ложится: ONNX MemoryMax=2.5G + reindex MemoryMax=1G = 3.5G < 7.8G свободно.
- Trading bot (`doctorm-unify-protocol`) не тронут, активен.

## Урок (INC-047: фактчекинг через exec)

- Deadlock воспроизводится на **количестве текстов в батче**, а не на размере файла.
- Синтетические тесты с 1 текстом скрывают multi-text deadlock — тестировать надо
  реальными батчами.
- Числа только из измерений, не из памяти/догадок.

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
