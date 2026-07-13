---
id: INC-20260712-gatekeeper-no-dead-contract
timestamp: "2026-07-12T00:00:00Z"
category: tech
type: security
severity: high
status: closed
agent: antcat
title: INC-20260712-gatekeeper-no-dead-contract
---

# INC-20260712-gatekeeper-no-dead-contract

- **Дата:** 2026-07-12
- **Серьёзность:** High (порядок портов нарушен из-за отсутствия обратной связи)
- **Статус:** Closed (2026-07-12, ADR-0054 + реализация)

## Корень

Gatekeeper (mcp-gatekeeper) при своей смерти не возвращал агенту **контрактного ответа**.
Агент получал глухой `Session not found` (смерть MCP-сессии) — без причины и без инструкции.

## Симптом

Агент Муравей при деплое rerank-сервиса вызвал `gatekeeper__register_port` (8090, затем 8091).
Gatekeeper был мёртв → `Session not found`. Агент задеплоил сервис на 8091 (вне своего пула
antcat 8100-8119) без регистрации. Гэп вскрылся только когда ЗавЛаб спросил.

## Почему это уязвимость порядка

Порядок зависел от человеческого фактора (ЗавЛаб должен был спросить). Автоматика (shim/PDP)
не поймала гэп: агент шёл через API мимо shim, а shim не знает про пулы агентов. PDP не узнал
бы о 8091 без попытки регистрации.

## Решение (ADR-0054)

Протокол «dead + heal + mandatory_retry»: при вызове регистрации, если Gatekeeper недоступен,
клиент возвращает структурированный контракт:
- `status: "dead"`
- `heal: "systemctl restart mcp-gatekeeper"`
- `mandatory_retry: true`
- `message`: инструкция для агента

Агент обязан: вылечить сервер (restart) и повторить вызов. Гэп замыкается автоматически.

## Реализация

- `shim/gk-register`: при недоступности Gatekeeper возвращает `GATEKEEPER_DEAD <json>` + exit 2
  (вместо fail-open `ERROR`).
- `shim/systemctl-wrapper` (Слой 1): распознаёт `GATEKEEPER_DEAD`, печатает контракт агенту,
  exit 2 (НЕ вызывает оригинал systemctl, не fail-open).
- ADR-0054 зафиксирован.

## Проверка

Остановить `mcp-gatekeeper`, вызвать `gk-register port 8105` → `GATEKEEPER_DEAD {...}`, exit 2.
Вызвать `systemctl enable test.service` (с LISTEN=:8105) → обёртка печатает контракт, exit 2.
Запустить `mcp-gatekeeper` → повторный вызов → ALLOW/REJECT (корректно).
