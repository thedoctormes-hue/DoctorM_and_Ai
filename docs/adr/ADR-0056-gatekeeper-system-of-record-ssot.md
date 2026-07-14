title: "ADR-0056: Gatekeeper как System-of-Record (SSOT) — архитектура Fact/Intent Reconciliation"
status: accepted
date: 2026-07-14
author: Ворон (raven)
reviewed_by: ЗавЛаб
tags: [infrastructure, gatekeeper, ports, timers, units, single-source-of-truth, architecture, reconciliation]

# ADR-0056: Gatekeeper как System-of-Record (SSOT)

## Context

`ADR-0047` (принят 2026-07-11, тег `single-source-of-truth`) провозгласил канонический
реестр портов и таймеров единым источником истины. Однако реализация gatekeeper
(`mcp-gatekeeper`, `CONTRACT.md` PDP v1) была выполнена как **permission checkpoint
(«привратник»)**, а не как authoritative registry. Разрыв между намерением ADR-0047 и
контрактом/реализацией подтверждён DDP (2026-07-14):

- **ROOT 1 (мастер, BY DESIGN):** gatekeeper — PDP, не system-of-record. `CONTRACT.md`
  не содержит SSOT/inventory/authoritative (grep → 0 hits). Хранит только `leases`
  (права) в памяти (`self.leases: Dict`, `server.py:162`).
- **ROOT 2 (MIXED):** shim ловит только `ListenStream`-порты `.service`; `.timer`,
  `daemon-reload`, порты в коде (`--port`, `PORT=`) — мимо (`systemctl:144-147`, `:165`).
- **ROOT 3 (MIXED):** правда размазана по 4 источникам (systemd + `leases.json` +
  `policy.reserve` + ручной `PORT_REGISTRY.md`); gatekeeper — детектор (`gk-audit.sh`
  ALERT), не реконсилятор (`gk-scan.sh` не пишет обратно).
- **ROOT 4 (ACCIDENTAL):** eBPF-профилактика не деплоена (требует reboot, в бэклоге
  per ЗавЛаб 2026-07-12).

Цель ЗавЛаба (msg 15194): «найти эстетичный архитектурный способ, сделать гейткипера
источником достоверных данных о портах, таймерах и юнитах».

## Decision

Реконтрактить gatekeeper: он становится **System-of-Record + PDP** (две роли в одном
компоненте). Архитектурная модель — **Fact/Intent Reconciliation**:

### 1. Разделение Fact и Intent
- **Fact (реальность):** фактическое состояние systemd — юниты, таймеры, слушающие
  порты. Собирается reconciliation loop (`gk-reconcile`) через `systemctl list-units`,
  `systemctl show`, `ss -tlnp`, `/proc/net/tcp`. systemd остаётся исполнителем
  (executor), но его состояние теперь ингестится gatekeeper.
- **Intent (governance):** lease-объекты от `register_port` / `register_timer` /
  `register_service` (кто / зачем / проект / agent). Это то, что агенты запрашивают
  через MCP — право на ресурс.

### 2. Resolved (SSOT) — единый персистентный state
- Gatekeeper мержит Fact + Intent в единую модель, хранит на диске (**sqlite**,
  заменяет in-memory `self.leases` + snapshot `leases.json`).
- State читается при старте (решает ROOT 1/3 — не теряет данные при reboot).
- **Drift detection:** порт/юнит есть в Fact, но нет lease → `ungoverned` (ALERT или
  auto-record с меткой); lease есть, а Fact нет → `stale` (cleanup).

### 3. Read-API (новая роль)
- `list_units` / `list_ports` / `list_timers` поверх merged state. Сейчас у gatekeeper
  только `list_leases` (права) — нет чтения реальности.
- `PORT_REGISTRY.md` / `TIMER_REGISTRY.md` генерируются gatekeeper как read-only views
  (или заменяются `gatekeeper list`); ручное дублирование `policy.blocked_ports`
  убирается.

### 4. Shim = тонкий Gate, не инвентарь (решает ROOT 2)
- Shim остаётся обязательной медиацией (ADR-0053), но его роль — только запрет без
  lease (PDP-gate).
- Расширить захват: `ExecStart --port`, `PORT=env`, bare `ListenStream=8710`, и
  `.timer` как носители сервисов (не passthrough — таймер активирует сервис, который
  биндит порт).
- Полнота покрытия достигается reconciliation loop (наблюдение реальности), а не
  только шимом.

### 5. gk-scan → Writer-back (federation, решает ROOT 3)
- `gk-scan.sh` пишет observed в gatekeeper (не только ALERT). Gatekeeper становится
  реконсилятором, а не детектором.

### 6. Unification (решает ROOT 3 duplication)
- `policy_v1.yaml` `reserve.blocked_ports` — единый источник зарезервированных портов.
- Ручной `PORT_REGISTRY.md` — упраздняется как самостоятельный источник; генерируется
  из gatekeeper.

### 7. eBPF (ROOT 4) — compensating control
- Деплоить как доп. слой (требует `lsm=bpf` + reboot, отложено в бэклог per ЗавЛаб
  2026-07-12). Не блокирует SSOT, но сужает blast radius при обходе шима.

## Consequences

**Положительные:**
- Gatekeeper отвечает на вопрос «что сейчас есть по портам/таймерам/юнитам» (read-API)
  — становится настоящим SSOT.
- Устранено дублирование (`policy.reserve` — единый источник reserved ports).
- Учтены таймеры и порты в коде (расширение shim + reconcile loop).
- Единый персистентный state переживает reboot.

**Риски / требует реализации:**
- Persistence (sqlite), read-API, reconcile loop, shim expansion — новый код
  (архитектурная модель, не костыли).
- Race condition: одновременный reconcile + shim-gate (нужен lock / versioning).
- Gatekeeper становится availability-critical: уже есть kill-switch (ADR-0055,
  commit `55c3ee0`) + fail-closed/open по контракту ADR-0054.

**Зависимости:**
- `ADR-0047` (намерение SSOT) — этот ADR приводит реализацию в соответствие.
- `ADR-0053` (shim mandatory interception), `ADR-0054` (dead+heal+mandatory_retry),
  `ADR-0055` (threat model + kill-switch).

## References
- ADR-0047 — Канонический реестр портов и таймеров (единый источник истины)
- ADR-0053 — Shim mandatory interception for gatekeeper
- ADR-0054 — Gatekeeper dead + heal + mandatory retry
- ADR-0055 — Gatekeeper threat model + mitigations (incl. kill-switch)
- `mcp-tools/mcp-gatekeeper/docs/CONTRACT.md` — контракт PDP v1 (подлежит реконтракту)
- DDP 2026-07-14: deep-dive → root-cause (4 roots) → fact-check (все confirmed) →
  research (SSOT hub, service registry, reconciliation loop)
