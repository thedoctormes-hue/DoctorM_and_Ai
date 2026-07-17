---
id: ADR-0058
title: Persistent Gatekeeper — реализация System-of-Record (шаг А ADR-0056)
status: proposed
author: raven
created: 2026-07-17
related: ADR-0056 (System-of-Record + PDP contract), INC-20260717-101833-348a9a, PAT-019 (I-17, I-18)
---

# ADR-0058: Persistent Gatekeeper (System-of-Record)

## Context
Gatekeeper спроектирован как PDP-чекпоинт, но не System-of-Record (ADR-0056 принят, но шаг А — persistence — не реализован). Сейчас state держится в `self.leases` (in-memory). Любой restart gatekeeper или истечение `lease_timeout` (300с) стирает всё.

### Симптомы (наблюдались 2026-07-17, Ворон):
- `list_leases` пустеет через 300с после регистрации.
- cross-agent дедуп НЕ очищается после истечения lease → повторная регистрация `REJECT` («уже заявлен sh»), хотя `sh` ушёл.
- GK-AUDIT орет «unauthorized listening socket» на порты, которые работают, но lease истёк.
- Агенты (raven) вынуждены перерегистрировать порты каждые 5 минут вручную.
- Подъём сервиса на reserve-порту (3000) → `REJECT` при регистрации, но сервис уже слушает → рассинхрон Intent vs Fact.

## Decision
Реализовать шаг А ADR-0056: заменить in-memory `self.leases` на **sqlite + disk snapshot** (`leases.json` для аудита). State читается при старте gatekeeper. Lease НЕ истекает без явного `release` (или долгий timeout, например 86400с + heartbeat). cross-agent дедуп очищается при истечении lease.

### Шаги реализации:
1. `gatekeeper/store.py`: sqlite (`/var/lib/gatekeeper/leases.db`) + `leases.json` snapshot каждые N сек.
2. `mcp-gatekeeper-server.py`: `self.leases` → `self.store` (sqlite). `register_*` пишет в sqlite; `release_*` удаляет; `list_leases` читает из sqlite.
3. **Startup**: `store.load()` читает sqlite → state восстановлен после reboot/restart gatekeeper.
4. **cross-agent дедуп**: при `register_port` проверять, что существующий lease НЕ истёк (`acquired_at + lease_timeout > now`). Если истёк — разрешить перерегистрацию (очистить дедуп). Баг 2026-07-17: дедуп висел после истечения → фикс здесь.
5. **Shim auto-lease**: при обнаружении bypass (`systemctl.real` / `GATEKEEPER_SHIM_DISABLED`) — авто-создавать lease (agent=`sh`, timeout=3600) + Telegram-алерт (gk_notify уже настроен). Чтобы порт не висел unauthorized вечно.
6. **gk-reconcile**: merge Fact (ss/systemd) + Intent (sqlite leases) → drift (ungoverned/stale).

## Insights (И1-И5)
- **И1 — git rm auto-generated ломает сервисы:** `git rm` (не `--cached`) удаляет файл с диска, ломая зависимые systemd-сервисы (INC-20260717-091700). Превенция: `git rm --cached` + проверка зависимостей перед удалением.
- **И2 — gatekeeper должен быть persistent:** in-memory lease истекают → порты слетают, GK-AUDIT ложно орет. Превенция: sqlite + disk snapshot (этот ADR).
- **И3 — умный монитор наблюдает и делегирует:** Ворон не должен копать руками — субагенты для сбора/исправления (PAT-019 I-17). Лимиты провайдера мешают субагентам — временно делать сам, но перестроить процесс на `sessions_spawn`.
- **И4 — не поднимать сервисы на reserve-портах:** 3000 в `blocked_ports` → gatekeeper REJECT. Выбирать свободный (3001) (PAT-019 I-18).
- **И5 — обход shim требует регистрации:** `systemctl.real` = bypass → сразу `gatekeeper__register_port` (PAT-019 I-18).

## Consequences
- **Положительные:** порты не слетают с учёта; GK-AUDIT не ложно орет; агент не перерегистрирует вручную; cross-agent дедуп корректно очищается.
- **Риски:** sqlite добавляет зависимость; нужна миграция с in-memory при апгрейде; требует рестарта gatekeeper (через `systemctl.real`, см. MEMORY.md red lines).

## Status
Proposed (2026-07-17, raven). Требует review ЗавЛаба + реализации (antcat/infra, зона gatekeeper).
