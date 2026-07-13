---
id: workspaces__antcat__incidents__2026-07-13-170300
timestamp: "2026-07-13T17:03:00Z"
category: tech
type: bug
severity: high
status: closed
agent: antcat
title: INC-2026-07-13-170300 — Gateway MCP client не переживает restart сервера памяти
---

# INC-2026-07-13-170300 — Gateway MCP client не переживает restart сервера памяти

- **Дата:** 2026-07-13 17:03 MSK
- **Тип:** Инцидент / простой семантической памяти лаборатории
- **Серьёзность:** high (память упала лаборайд-wide на ~4 минуты)
- **Агент:** antcat (Муравей)

## Что произошло

В рамках валидации on-demand паттерна для MCP-памяти был выполнен
`systemctl restart mcp-memory` (прод 8087) — одобренный ЗавЛабом
«тест живучести» (restart сервера → вызов `memory__lab_memory_search`
через шлюз).

После перезапуска сервера MCP-клиент шлюза (streamable-http)
стал возвращать на КАЖДЫЙ вызов:

```
Streamable HTTP error: Error POSTing to endpoint:
{"jsonrpc":"2.0","id":"server-error","error":{"code":-32600,"message":"Session not found"}}
```

Два повторных вызова + `openclaw mcp reload` + ожидание 45s —
бессильны. Сервер 8087 при этом жив (`openclaw mcp probe` →
`memory: 3 tools`, raw curl отвечает корректно).

## Корень (root cause)

MCP-клиент шлюза **кэширует session ID** и НЕ переустанавливает
сессию при рестарте/недоступности сервера. После restart сервера
его in-memory сессии стираются → клиент шлёт старый session ID →
«Session not found». Клиент НЕ делает re-`initialize()` при app-level
ошибке сессии, поэтому не самовосстанавливается.

## Влияние

`memory__lab_memory_search` (MCP-backed путь семпамяти) недоступен
ДЛЯ ВСЕХ агентов лаборатории, пока живой MCP-клиент шлюза не
пересоздан. In-process FAISS-путь (`lab_search.py`) не затронут.

## Фикс

`systemctl restart openclaw-gateway` (root-bus; CLI `openclaw gateway
restart` не сработал — нет доступа к user-bus systemd из CLI-окружения).
Новый процесс шлюза (PID 1547088) поднял свежий MCP-клиент →
новая сессия к 8087 → `memory__lab_memory_search` снова вернул
3 результата. Память восстановлена.

## Уроки (PAT-05 / red line)

1. **Idle-shutdown и boot-on-hit на проде MCP-памяти НЕБЕЗОПАСНЫ** с
   текущим клиентом шлюза. Любой down/up сервера = permanent
   «Session not found» до рестарта шлюза. Единственный безопасный
   режим прода — **always-on** (вариант В).
2. On-demand паттерн (доказан сервер-сайд на прототипе 8091/8092:
   boot ~3s, idle-shutdown освобождает ~305MB, реальный поиск работает)
   требует **фикса на стороне клиента шлюза**: re-init сессии при
   transport/session-loss. Это отдельный воркстрим (флаг Owl/Сове
   или gateway-команде) — не в зоне mcp-tools.
3. `openclaw gateway restart` из CLI не работает без user-bus; для
   рестарта шлюза использовать `systemctl restart openclaw-gateway`
   (root). Red line: рестарт шлюза — только по явному согласованию
   (ЗавЛаб одобрил через «сначала доктор конфига» + контекст
   восстановления памяти).
4. Перед рестартом шлюза — `openclaw config validate` (valid) +
   `openclaw doctor` (только warnings) прогнаны, конфиг чист.

## Попутно найдено / исправлено (в mcp-tools/bin/memory-server.py)

- **Deadlock** в `_metrics_text()`: держал `_state_lock` И вызывал
  `_disk_index_changed()` (который сам берёт тот же лок) →
  re-entrant deadlock (threading.Lock не реентерабелен). Из-за этого
  вис `/metrics` и НЕ срабатывал idle-shutdown. Исправлено (вызов
  `_disk_index_changed()` вынесен ВНЕ лока).
- Добавлены (env-gated, на проде no-op): idle-shutdown watchdog,
  Prometheus `/metrics` side-car, `last_activity`/`degraded_total`.
- Коммит через `lab-commit.sh antcat` (без shared-идентичности).

## Статус

Решён. Память восстановлена 17:03 MSK. Прод 8087 — always-on.
Прототип on-demand (8091/8092) — демонстрация паттерна, НЕ для продa.
