---
id: INC-2026-07-13-E1-gate-bypass
timestamp: "2026-07-13T00:00:00Z"
category: tech
type: other
severity: critical
status: retired
agent: unknown
title: INC-2026-07-13-E1 — Gate bypass in cmd_accept (GATE-функция не вызывается перед открытием)
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-2026-07-13-E1 — Gate bypass in cmd_accept (GATE-функция не вызывается перед открытием)

**Дата:** 2026-07-13
**Severity:** CRITICAL (торговля реальными деньгами, защита макро-состоянием не действует на пути accept)
**Компонент:** `src/bot/handlers.py` → `cmd_accept`
**Статус:** READ-ONLY инцидент (не исправлялся в рамках анализа)

## Описание

Команда `/accept` (`cmd_accept`) открывает позицию, опираясь на `gate_score`,
**сохранённый в рекомендации** (`rec.get("gate_score", 1)`), и НЕ вызывает GATE-функцию
(`src/bot/scheduler.py::_market_gate`) заново перед открытием.

Более того, даже если бы `gate_score` пришёл со значением HALT, метод
`risk_manager.assess` НЕ блокирует вход по `gate_score` — поле `allowed` зависит только от
PnL (circuit breaker) и корреляций (см. `src/core/risk_manager.py::assess`). `gate_score`
влияет лишь на `max_positions`, и то лишь при `gate_score < 0` (чего из rec никогда не
приходит — дефолт 1).

Итог: макро-фильтр (Fear & Greed) фактически НЕ защищает путь accept. Позиция может быть
открыта при HALT-состоянии рынка, если rec уже сгенерирован/лёг в кэш.

## Доказательство из кода

`src/bot/handlers.py:861-866` — единственная «gate-защита» в cmd_accept:
```python
        risk_report = risk_mgr.assess(
            gate_score=rec.get("gate_score", 1),
            daily_pnl_pct=_daily_pnl_pct,
            weekly_pnl_pct=_weekly_pnl_pct,
            open_positions=all_positions,
            candidate_correlations=candidate_correlations,
        )
```
Проверка: `grep _market_gate` в диапазоне строк 694-1139 (тело `cmd_accept`) — **пусто**.
GATE-функция импортируется/вызывается только в других командах (`handlers.py:140, 208, 378`).

`src/core/risk_manager.py::assess` — `allowed` НЕ зависит от gate:
```python
allowed = not cb_triggered and len(violations) == 0
```
`gate_score` используется только для `max_pos` (>=3→4, >=2→3, >=0→2, <0→1).

## Рекомендация по фиксу

1. В начале `cmd_accept` (до STEP 1 / открытия ордера) вызвать живьём:
   `from .scheduler import _market_gate; gate = _market_gate()`.
2. Если `gate["gate"] == "HALT"` → `await message.answer(...)` и `return` (НЕ открывать).
3. Передать живой `gate["gate"]` в `risk_mgr.assess` ИЛИ добавить в `assess` явный блок:
   `if gate == "HALT": allowed = False` (fail-closed на уровне risk manager).

## Связанные
- E1 в `ANALYSIS_2026-07-13_deepdive_v2.md`
- E2 (SL-SURVIVAL) `INC-2026-07-13-E2-sl-survival.md`

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
