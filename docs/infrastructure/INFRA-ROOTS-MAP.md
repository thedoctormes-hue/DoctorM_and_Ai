# 🗺️ INFRA-ROOTS-MAP — что зачем и почему

_Дата аудита: 2026-07-08. Хост: 197784.com (78.17.43.205)._
_Источник: 3 read-only субагента (timer-roots, port-roots, cron-audit) + live-фактчек Бестии._
_Все факты в этом документе перепроверены на живой системе. systemd не трогали._

---

## Краткая картина

- **Кроны:** есть, но это не основная боль. 1 user-job (memory-watchdog), certbot, cheque-bot-мусор, стандарт Ubuntu. Дублей cron↔systemd (кроме ожидаемых) нет.
- **Таймеры:** 35 лаб-таймеров в `/etc/systemd/system/`. 17 живых/здоровых, 9 мёртвых (masked/not-found), 4 бьют в удалённые пути (`/root/LabDoctorM/venv`, `/root/LabDoctorM/bin` удалены).
- **Порты:** ~38 слушающих. Большинство на localhost (хорошо). 5 мёртвых nginx-бэкендов, несколько сервисов без аутентификации торчат на 0.0.0.0, dnsmasq и sshd — лишнее публичное воздействие.

---

## 1. Кроны (cron-audit)

| Источник | Что делает | Проект | Дубль-systemd? | Вердикт |
|---|---|---|---|---|
| `root` crontab: `0 23 * * * memory-watchdog.sh` | сторож памяти агента | streikbrecher | нет (systemd-таймера нет) | оставить |
| `/etc/cron.d/certbot` | гвард certbot (блокирует timer) | infra | `certbot.timer` выключен | **починить timer** |
| `/etc/cron.d/cheque-bot*` (6 файлов, вкл. 3×.bak) | старый бот, «migrated to systemd» | cheque-bot | `cheque-bot.timer` выключен, сервис masked | **мусор + бот сломан** |
| `/etc/cron.daily/logrotate` | ротация логов | система | `logrotate.timer` | дубль (безопасно) |
| `/etc/cron.d/{e2scrub_all,sysstat}` | стандарт | система | — | оставить |

**Главные находки по кронам:**
- **Certbot не запланирован.** `certbot.timer` disabled, автообновление сертов не работает. Ближайший серт истекает **2026-08-12** (34 дня). Сайты посыплются.
- **cheque-bot сломан.** Cron-файлы закомментированы («migrated to systemd»), но `cheque-bot-start.service` **замаскирован** (→/dev/null), `cheque-bot.timer` выключен, процесс не бежит. Бот никак не стартует.
- **Мусор:** `cheque-bot*.bak` (cron игнорирует из-за точки в имени), `/etc/crontab.bak.20260703_103500`, осиротевший `/opt/scan.sh`.

---

## 2. Таймеры (timer-roots)

### ✅ Живые и здоровые (17)
zprr-tracker, autoexpert-sync, doctorm-unify-protocol, mskgastrodigestbot, onnx-reindex, reindex-incremental, agent-metrics-collect, backup-myrmex, disk-monitor, docker-prune, free-api-hunter-scan, free-api-hunter-watchdog, logrotate-myrmex, myrmex-healthcheck, pg-backup, snablab-price-snapshot, backup-projects, snablab-health, snablab-monitor, openclaw-cf-rotate, lab-memory-healthcheck, backup-etc, shb-roomba, streikbrecher-memory-watchdog, team-sync, finance-snapshot.

### 💀 Мёртвые (9) — висят, не работают
- **Masked:** `commit-audit`, `lab-monitoring-report` (намеренно выключены, но юнит-файлы мусорят).
- **Not-found (service отсутствует):** `git-metrics`, `graph-maintenance`, `insights-consolidator`, `lab-insights`, `raven-patrol`, `evolve-processor`, `zombie-checker`.
- Инсайт-пайплайн (insight/evolve/git-metrics) **полностью мёртв** — ни один таймер не гонит обработку инсайтов.

### 🔥 Бьют в удалённые пути (4) — корень хаоса
`/root/LabDoctorM/venv` и `/root/LabDoctorM/bin` **удалены**. Таймеры, ссылающиеся на них, падают:
`protocol-analyst`, `cheque-bot`, `lab-state-update`, `hype-combine-wb`.

### ⚠️ Дубликаты / дрейф
- **Две free-api-hunter:** `free-api-hunter.timer` → `projects/free-api-hunter/bin/hunter`, а `free-api-hunter-scan.timer` → `/opt/free-api-hunter/bin/hunter` (отдельный deploy, разный ELF). Оба каждые 6ч → конфликт/избыточность.
- **Дрейф путей после реорганизации:** `protocol-backup` → старый `telegram-bots/protocol/backup_db.sh` (ныне `projects/autoexpert/scripts/`), `raven-sync.sh` и `cheque-bot/auto_start.sh` выжили только в vault-бэкапах.
- **Два state-builder скрипта:** `bin/lab_state_builder.py` (удалён) vs `DoctorM_and_Ai/bin/runtime_state_builder.py` (есть).

---

## 3. Порты (port-roots)

### 🌐 Публичные (0.0.0.0 / внешний IP) — смотреть внимательно
- **nginx:** 80, 8443, 8445 (публично) + 8080 (localhost). Единая дверь — правильно.
- **sshd:** 2222 **и** 9090 (9090 — забытый второй порт в `sshd_config`).
- **snablab-backend:** 8200 `--host 0.0.0.0` (минует nginx, без аутентификации).
- **consilium:** 8300 (0.0.0.0, без аутентификации).
- **chisel:** 8444 (0.0.0.0).
- **node_exporter:** 9100 (0.0.0.0, метрики, без аутентификации).
- **postgres_exporter:** 9187 (0.0.0.0, метрики, без аутентификации).
- **dnsmasq:** 53 на `78.17.43.205` (публичный DNS — торчит наружу).
- **docker-proxy:** 9443 (mtproto-proxy), 8889 (searxng), 36713/udp (amnezia-awg2).

### 🔒 Локальные (127.0.0.1) — изолированы, ок
myrmex-control (3000), zprr (8001), free-api-hunter (8090), autoexpert (8099), onnx-embedder (8082), mail-daemon (8202), doctorm-unify (8899), postgres (5432), redis (6379), openclaw gateway (18789), xray (443/10443), containerd (35625).

### 💀 Мёртвые nginx-бэкенды (фронт жив, бэкенд не слушает)
Конфиги в `sites-available/` проксируют на порты, которые НЕ слушают → 502/пусто:
- `demo` → 3001
- `tgminiappmyrmex` → 3003
- `technoracer` → 3004
- `labmonitor` → 9101
- `vault` → 8201

### 🛡️ Позитив
VPN/xray изолирован через nginx (`ssl_preread`) — правильный паттерн. Большинство проектных бэкендов на localhost. systemd-юниты с hardening присутствуют.

---

## 4. Топ-действий (по приоритету)

1. **🔴 Certbot** — включить `certbot.timer` (или вернуть cron), иначе 12.08 серты протухнут. Ближайший дедлайн.
2. **🔴 myrmex-control не поднимется после ребута** — `systemctl enable`. Сейчас active, но disabled.
3. **🟠 Безопасность** — snablab(8200), consilium(8300), chisel(8444), node_exporter(9100), postgres_exporter(9187) на 0.0.0.0 без аутентификации. Закрыть в nginx или localhost.
4. **🟠 dnsmasq на публичном IP** — биндить на 127.0.0.1 или firewall.
5. **🟠 sshd 9090** — убрать второй порт из `sshd_config`.
6. **🟡 Мёртвые nginx-бэкенды** — либо поднять сервисы (demo/technoracer/vault/labmonitor/tgminiappmyrmex), либо выключить конфиги.
7. **🟡 9 мёртвых таймеров** — удалить not-found, размаскировать/удалить commit-audit, lab-monitoring-report (если не нужны).
8. **🟡 venv/bin удалены** — восстановить или переписать 4 таймера (protocol-analyst, cheque-bot, lab-state-update, hype-combine-wb).
9. **🟡 cheque-bot** — довести миграцию в systemd или удалить мусор cron/.bak.
10. **🟡 Две free-api-hunter** — оставить одну, вторая избыточна.

---

## 5. Как держать в порядке (см. INFRA-MAP-systematization.md)
- Единый манифест (timer+port) в `docs/infrastructure/`, regen из live через ночной скрипт.
- `PartOf=` + per-project target для безопасного teardown.
- Guard на удаление: `disable --now` → `daemon-reload` → удалить файл.
- `infra-drift-check.sh` ловит осиротевшие таймеры и новые публичные порты.

_Сырые отчёты субагентов: `/root/LabDoctorM/workspaces/bestia/infra-roots/` (timer-roots: inventory.csv, OBSERVATIONS.md; port-roots: ports.tsv, findings.md; cron-audit: cron-audit.md)._
