# ADR-0055: Gatekeeper — Threat Model & Mitigations (Product-Ready Hardening)

- **Status:** Accepted (implementation in progress)
- **Date:** 2026-07-12
- **Author:** raven (Ворон), по запросу ЗавЛаба
- **Supersedes/Relates:** ADR-0053 (shim mandatory interception), ADR-0054 (dead+heal+mandatory_retry)
- **Scope:** Доведение `mcp-gatekeeper` до product-ready: перенаправить ВСЕ пути деплоя на сервер (mandatory mediation), чтобы обход был невозможен (kernel-level) или всегда заметен (audit).

## Context

Gatekeeper (PDP) контролирует порядок портов/сервисов/таймеров в лаборатории. Поверх него — shim-обёртка `systemctl` (Слой 1, PATH-intercept) + audit-scan (Слой 2). Аудит выявил 9 способов обхода PDP (см. ниже). Цель: применить индустриальные паттерны (Kubernetes admission control, eBPF, Zero-Trust PEP/PDP, fail-closed) чтобы сделать обход невозможным или всегда видимым.

## Threat Model — 9 способов обойти сервер

1. **Полный пропуск** — агент не вызывает Gatekeeper вообще (Доминика: написала unit руками, не дёрнула `register_service`).
2. **Прямой `/usr/bin/systemctl`** — мимо shim-обёртки (PATH-dependent shim пропускает).
3. **Ручной процесс вне systemd** — `python3 server.py &` без юнита.
4. **Spoofing агента** — shim хардкодит `agent=shim`, пулы не проверяются по реальному агенту.
5. **Backdoor `as_root`/`bypass`** — злоупотребление backdoor без реального агента/аудита.
6. **Docker/K8s-порты вне systemd** — порт проброшен на хост мимо shim.
7. **Игнор REJECT/`DEAD`-контракта** — агент получил отказ/контракт, но задеплоил.
8. **Правка `policy.yaml`/`leases.json`** — агент меняет конфиг/состояние сервера.
9. **Race/TTL** — lease истёк (300s), порт живой, но audit не поймал; гонка shim vs ручной процесс.

## Mitigations — 6 фаз (индустриальные паттерны)

### Фаза 1 — Mandatory mediation (закрывает 1, 2)
**Паттерн:** PEP стоит на каждом ресурсе, обход невозможен (NIST 800-207 ZTA).
**Реализация:** Сделать обёртку `systemctl` обязательной для ВСЕХ (не через PATH).
- `dpkg-divert --divert /usr/bin/systemctl.real --rename /usr/bin/systemctl` (сохранить оригинал systemd).
- Положить shim-обёртку на `/usr/bin/systemctl` (вызывает `/usr/bin/systemctl.real` после проверки Gatekeeper).
- Whitelist self-calls (systemd сам вызывает systemctl — пропускать).
- Закрывает: 1, 2.

### Фаза 2 — Real agent identity (закрывает 4, 5)
**Паттерн:** Webhook аутентифицирует вызывающих (K8s sig-security Mitigation ID 3).
**Реализация:** Shim подставляет РЕАЛЬНОГО агента (из ENV `AGENT_ID` или PPID), не хардкод `shim`. Gatekeeper проверяет пул по реальному агенту. `as_root`/`bypass` только для авторизованных + аудит.
- Закрывает: 4, 5.

### Фаза 3 — Kernel-level enforcement, eBPF LSM `socket_bind` (закрывает 2, 3, 6, 9)
**Паттерн:** eBPF на `bind()` блокирует порты вне разрешённых на уровне ядра — необходим из user-space (Доминика-стиль, Docker, ручной процесс, race).
**Реализация:** eBPF-программа (`SEC("lsm/socket_bind")`) читает BPF map разрешённых портов (reserve.blocked_ports + активные lease из `leases.json`). Любой `bind()` на порт вне разрешённых → блок ядром. Loader на Go (cilium/ebpf) + systemd unit `gatekeeper-ebpf.service`. Fail-open при ошибке загрузки (не блокировать всё). Kernel 5.15 поддерживает BPF LSM.
- Закрывает: 2 (если обёртка обойдена), 3, 6, 9.

### Фаза 4 — Fail-closed (доводит 7)
**Паттерн:** Webhook fails closed (K8s sig-security Mitigation ID 2); firewall fails closed (authzed).
**Реализация:** Shim при REJECT/DEAD реально НЕ выполняет `systemctl enable` (exit 2). При DEAD — блокировать до heal, не отступать к fail-open. Контракт ADR-0054 + Фаза 1/3 блокируют на уровне ОС при игноре.
- Закрывает: 7.

### Фаза 5 — RBAC на конфигурацию (закрывает 8, 6, 2-удаление)
**Паттерн:** RBAC права строго контролируются (K8s sig-security Mitigation ID 1).
**Реализация:** `policy_v1.yaml`, `leases.json`, обёртка `systemctl` — права `root:gatekeeper`, `640`. Группа `agents` — только read. Unit `mcp-gatekeeper.service` — `ProtectSystem=strict`; polkit rule запрещает агентам `systemctl stop mcp-gatekeeper`.
- Закрывает: 8, 6, 2(удаление обёртки).

### Фаза 6 — Audit live ports (Слой 2.5, поймает 1, 3, 7, 9)
**Паттерн:** Regular reviews of webhook configuration (K8s sig-security Mitigation ID 8).
**Реализация:** Systemd timer (5-10 мин) → `gk-audit.sh`: `ss -tlnp` → сверка с реестром/lease. Любой порт вне порядка → алерт в Telegram/Myrmex + запись инцидента.
- Закрывает: 1 (если агент совсем не шёл через систему), 3, 7, 9.

## Map: Дыра × Фаза

- 1 (полный пропуск): Ф1, Ф6
- 2 (прямой systemctl): Ф1, Ф3, Ф5
- 3 (ручной процесс): Ф3, Ф6
- 4 (spoofing): Ф2
- 5 (backdoor): Ф2, Ф5
- 6 (Docker/K8s): Ф3, Ф5
- 7 (игнор REJECT/DEAD): Ф4, Ф6
- 8 (правка config): Ф5
- 9 (race/TTL): Ф3, Ф6

## Приоритет реализации

1. Ф1 (dpkg-divert) — быстро, закрывает 1,2.
2. Ф6 (audit 2.5) — быстро, поймает остальное.
3. Ф5 (RBAC) — быстро, закрывает 8,6,2.
4. Ф2 (real agent) — средне, закрывает 4,5.
5. Ф4 (fail-closed) — доработка существующего.
6. Ф3 (eBPF) — сложно, но самый сильный (2,3,6,9). **Режим «ебш» — приоритет ЗавЛаба.**

## Индустриальные источники (fact-check)

- Kubernetes sig-security — Admission Control Threat Model: fails closed, RBAC, authenticate callers, regular review.
- NIST SP 800-207 — Zero Trust: PEP на каждом ресурсе, enforcement points cannot be bypassed.
- authzed — Fail-open vs Fail-closed: security-critical → fail-closed.
- eBPF LSM `socket_bind` — kernel-level bind restriction (kernel ≥5.7).

## Product-Ready критерии (accepting-work)

- Покрытие тестами ≥85% (shim, gatekeeper server, eBPF loader unit-тесты, audit).
- Документация: README shim, README eBPF, ADR-0055, CONTRACT.md обновлён.
- Git: коммиты через `lab-commit.sh`, ветка `raven/gatekeeper-hardening`, push в origin.
- Уборка хвостов: инцидент INC-20260712-gatekeeper-no-dead-contract закрыт; Доминика 8088 зарегистрирована задним числом или откачена.
- Фактчек: после каждой фазы — live проверка (`ss`, `systemctl`, лог gatekeeper).
