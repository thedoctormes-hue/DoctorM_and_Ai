---
id: 2026-06-28-0815-faiss-sqlite-desync
timestamp: "2026-06-28T08:15:00Z"
category: tech
type: data_loss
severity: critical
status: closed
agent: unknown
title: "INC-031: Рассинхронизация FAISS ↔ SQLite"
---

# INC-031: Рассинхронизация FAISS ↔ SQLite

**Дата:** 2026-06-28 08:15 UTC
**Агент:** Доминика (Scout)
**Статус:** resolved (2026-06-28 14:35 UTC)
**Критичность:** high

## Проблема

FAISS индекс (15232 вектора) рассинхронизирован с SQLite (4542 чанка). 4690 векторов в FAISS ссылаются на несуществующие чанки → lab_search.py может возвращать мусор или пропускать существующие.

## Цепочка событий

1. 27.06 21:32 — успешный reindex (29071 chunks → 15232 unique vectors)
2. 28.06 02:00 — incremental reindex стёр часть чанков из-за timeout
3. 28.06 07:44 — следующий reindex успел обработать только 4542 из 5088 файлов
4. FAISS не пересобран после изменения SQLite

## Корневые причины

1. Reindex timer (30 мин) имеет таймаут 5 минут — не может завершить работу
2. Нет lock-file — два reindex могут запуститься одновременно
3. Reindex incremental делает DELETE+INSERT вместо UPSERT — теряет чанки при прерывании

## Лечение

1. Пересобрать FAISS из текущих чанков (fix-faiss agent)
2. Увеличить таймаут до 3600s (fix-systemd agent)
3. Добавить lock-file (fix-systemd agent)
4. ThreadingHTTPServer + retry в reindex.py (fix-onnx-retry agent)
5. Удалить опасный reindex-full.timer (fix-systemd agent)

## Связанное

- INC-030 ($--full` reindex убил 14K чанков 26.06)
- INCAI problems root cause analysis 28.06
