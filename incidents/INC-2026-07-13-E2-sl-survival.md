---
id: INC-2026-07-13-E2-sl-survival
timestamp: "2026-07-13T00:00:00Z"
category: tech
type: bug
severity: high
status: retired
agent: unknown
title: INC-2026-07-13-E2 — SL-SURVIVAL не переустанавливает SL при sl_after is None
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-2026-07-13-E2 — SL-SURVIVAL не переустанавливает SL при sl_after is None

**Дата:** 2026-07-13
**Severity:** HIGH (позиция остаётся без защиты после Partial-TP; неограниченный риск)
**Компонент:** `src/bot/handlers.py` → `cmd_accept` (блок SL-SURVIVAL)
**Статус:** READ-ONLY инцидент (не исправлялся в рамках анализа)

## Описание

После установки Partial-TP выполняется проверка «выживаемости» SL (блок SL-SURVIVAL):
`find_sl_stop_order(symbol, sl)`. Если SL подтверждённо отсутствует (`sl_after is None`),
код лишь логирует ошибку и отправляет предупреждение оператору — **НЕ вызывает
`set_trading_stop` для восстановления SL**.

Известно (комментарий в коде), что переключение `tpslMode=Partial` может сбросить SL.
Таким образом, при сбросе SL после Partial-TP позиция остаётся БЕЗ защиты, а бот лишь
пишет «проверьте позицию вручную». При реальной торговле это неограниченный риск на длинной
позиции.

Контраст: выше по коду, в блоке SL VERIFICATION (при `sl_status == "ABSENT"`), применяется
idempotent `set_trading_stop(...)` с аварийным закрытием позиции, если переустановка не
удалась. Этот защитный паттерн в SL-SURVIVAL НЕ продублирован.

## Доказательство из кода

`src/bot/handlers.py:1035-1047`:
```python
                # SL-SURVIVAL: confirm SL stop order still present after Partial-TP call
                if sl_result.get("ret_code") == 0:
                    sl_after = find_sl_stop_order(symbol, sl)
                    if sl_after == SL_VERIFY_UNKNOWN:
                        logger.error("sl_survival_unknown", symbol=symbol)
                        await message.answer(
                            f"🔴 ВНИМАНИЕ: не удалось проверить SL после установки Partial-TP "
                            f"по {symbol} (ошибка API). Проверьте позицию вручную."
                        )
                    elif sl_after is None:
                        logger.error("sl_survival_failed", symbol=symbol)
                        await message.answer(
                            f"🔴🔴🔴 ВНИМАНИЕ: SL слетел после установки Partial-TP "
                            f"по {symbol}! Проверьте позицию вручную — SL мог быть "
                            f"сброшен вызовом tpslMode=Partial."
                        )
```
В ветке `elif sl_after is None:` **отсутствует** вызов `set_trading_stop(symbol, float(tp), float(sl))`.

Для сравнения — корректный паттерн из SL VERIFICATION (`handlers.py` ~строки 920-960):
```python
re = set_trading_stop(symbol, float(tp), float(sl))
if re.get("ret_code") == 0:
    await message.answer("✅ SL переустановлен для {symbol}. Позиция не закрыта.")
else:
    raise RuntimeError(re.get("ret_msg", "set_trading_stop failed"))
# ... при неудаче — аварийное close_position(...)
```

## Рекомендация по фиксу

В ветке `elif sl_after is None:` добавить ту же логику, что в SL VERIFICATION ABSENT:
```python
try:
    re = set_trading_stop(symbol, float(tp), float(sl))
    if re.get("ret_code") == 0:
        await message.answer("✅ SL переустановлен (SL-SURVIVAL).")
    else:
        raise RuntimeError(re.get("ret_msg", "set_trading_stop failed"))
except Exception as reset_err:
    logger.error("sl_survival_reset_failed", symbol=symbol, error=str(reset_err))
    # fail-closed: аварийно закрыть позицию, как в SL VERIFICATION
    report = close_position(symbol)
    _backfill_real_close(symbol)
    await message.answer(f"🔴 {symbol}: SL сброшен и не восстановлен — позиция закрыта аварийно.")
```

## Связанные
- E2 в `ANALYSIS_2026-07-13_deepdive_v2.md`
- E1 (Gate bypass) `INC-2026-07-13-E1-gate-bypass.md`

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
