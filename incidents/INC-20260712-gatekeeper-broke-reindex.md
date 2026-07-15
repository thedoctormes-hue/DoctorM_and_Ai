---
id: INC-20260712-gatekeeper-broke-reindex
timestamp: "2026-07-12T00:00:00Z"
category: tech
type: other
severity: medium
status: retired
agent: antcat
title: INC-20260712-gatekeeper-broke-reindex
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-20260712-gatekeeper-broke-reindex

**Дата:** 2026-07-12
**Агент:** Ворон (raven)
**Статус:** Закрыт (hotfix `707e239` в main)

## Описание
После мержа ADR-0055 hardening (коммит `5e986cd`) Gatekeeper начал отклонять
root-bypass (`as_root`) для всех агентов кроме `raven`. В среде lab все сервисы
бегут от root (non-root юзеров нет), поэтому reindex (antcat) и другие
root-сервисы перестали запускаться:
- gatekeeper: `REJECT "agent 'antcat' НЕ авторизован для root-bypass"`
- shim: перехватывал `systemctl start reindex` и пытался `register_port 00`
  для `.timer` (ловил `:00` из `OnCalendar`), `agent=sh` → REJECT.

Результат: `reindex-incremental.service` failed, таймеры inactive. Семантическая
память лаборатории перестала индексироваться.

## Корень
1. `authorized_root_agents: [raven]` (Фаза 2 ADR-0055) — слишком строго для
   root-only среды: легитимные сервисы (reindex/antcat, dominika и т.д.)
   используют `as_root` и были заблокированы.
2. `check_least_privilege` блокировал `run_as=root` ВООБЩЕ (в root-only среде
   это ломает всё).
3. Shim искал `:[0-9]{2,5}` в ЛЮБОМ юнит-файле → ловил `:00` из `OnCalendar`
   таймеров → пытался `register_port 00`.

## Исправление (commit `707e239`, main)
- `authorized_root_agents`: `[raven]` → все известные агенты (raven, antcat,
  dominika, kotolizator, mangust, owl, bestia, streikbrecher). Дыра 5 закрыта
  для АНОНИМНЫХ агентов (`ghost` → REJECT), но легитимные сервисы работают.
- `check_least_privilege`: `run_as=root` разрешён для известных агентов
  (`self.agents`), запрещён для неизвестных.
- Shim: пропускает `.timer` юниты; порт извлекается только из
  `Listen*`/`127.0.0.1:` (не ловит `:00` из `OnCalendar`).
- `test_r7` обновлён: `run_as=root` rejected для unknown agent; allowed для known.

## Верификация
- pytest: **54 passed**.
- gatekeeper: `antcat as_root → ALLOW`; `ghost as_root → REJECT`.
- `reindex-incremental.timer` сработал 17:00, сервис запустился (лог:
  `Starting Incremental reindex... Reindex already running` — защита от
  параллельного запуска сработала, gatekeeper не блокировал).

## Уроки
- В root-only среде (все сервисы от root, нет non-root юзеров) дыру 5
  (root-backdoor) нельзя закрыть полностью без перестройки (создание non-root
  юзеров для сервисов). Компромисс: `as_root` разрешён для ИЗВЕСТНЫХ агентов +
  аудит, блокировка анонимов.
- Shim должен гейтить ТОЛЬКО port-несущие юниты (`Listen`/`127.0.0.1:порт`),
  не таймеры/сервисы без порта.
- Перед мержем hardening-изменений в gatekeeper — тестировать на реальных
  root-сервисах (reindex), а не только unit-тестами.

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
