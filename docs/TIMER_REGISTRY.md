---
description: "TIMER REGISTRY — карта периодики лаборатории в 4 слоях (канонический, ADR-0047)"
type: guide
last_reviewed: 2026-07-11
last_code_change: 2026-07-11
status: active
---

# TIMER_REGISTRY.md — Карта периодики лаборатории (4 слоя)

> Единый источник истины по периодике (ADR-0047). Любой агент открывает этот файл и
> видит **всё**, что крутится, в каком слое планировщика — без ползания по `systemctl`.
> Сырой скан: `TIMER_SCAN.md` (генерирует `bin/gen-port-timer-map.sh`). Связанный файл:
> `PORT_REGISTRY.md`.

## Слои планировщика

- **A — systemd timers (OS)** — сканируются генератором (`systemctl list-timers`).
- **B — системный cron** (`/etc/cron.d`, root crontab) — сканируется генератором.
  Пакетные (certbot/sysstat) оставляем; лаб-собственные конвертируем в слой A.
- **C — OpenClaw Gateway Scheduler (agent cron)** — НЕ systemd, живёт в шлюзе (18789).
  Не сканируется; обновляется вручную (T8). Проверка: `openclaw cron list`.
- **D — Agent heartbeat** — фича шлюза, per-agent расписание в `HEARTBEAT.md`. Не
  таймер; одна строка-ссылка.

---

## Слой A — systemd timers (лабораторные)

| Таймер | Сервис | Расписание | Владелец | Назначение | Статус |
|--------|--------|-----------|----------|------------|--------|
| myrmex-healthcheck.timer | myrmex-healthcheck.service | каждые 2 мин | Муравей | healthcheck дашборда myrmex-control | ✅ enabled |
| disk-monitor.timer | disk-monitor.service | каждые 5 мин | Бестия | мониторинг свободного места | ✅ enabled |
| openclaw-cf-rotate.timer | openclaw-cf-rotate.service | ~каждые 30 мин | Бестия/инфра | ротация Cloudflare cert/туннеля | ✅ enabled |
| free-api-hunter.timer | free-api-hunter.service | каждые 6 ч | Бестия | watchdog оркестратора (перезапуск) | ✅ enabled |
| free-api-hunter-scan.timer | free-api-hunter-scan.service | каждые 6 ч | Бестия | проверка ключей/провайдеров поиска | ✅ enabled |
| backup-myrmex.timer | backup-myrmex.service | ежечасно :00 | Муравей | бэкап данных myrmex | ✅ enabled |
| pg-backup.timer | pg-backup.service | 4×/сут (00,06,12,18) | Бестия | бэкап PostgreSQL | ✅ enabled |
| dpkg-db-backup.timer | dpkg-db-backup.service | ежедневно 00:00 | инфра | бэкап БД dpkg | ✅ enabled |
| logrotate-myrmex.timer | logrotate-myrmex.service | ежедневно 00:00 | Муравей | ротация логов myrmex | ✅ enabled |
| reindex-full.timer | reindex-full.service | ежедневно 00:02 UTC | Бестия/инфра | полная переиндексация памяти (MD) | ✅ enabled |
| backup-projects.timer | backup-projects.service | ежедневно 02:01 UTC | Бестия | бэкап всех проектов лаборатории | ✅ enabled |
| snablab-price-snapshot.timer | snablab-price-snapshot.service | ежедневно 03:00 | Бестия | снимок цен snablab | ✅ enabled |
| krv-notify.timer | krv-notify.service | ежедневно 03:18 | Бестия (free-api-hunter) | KRV discovery bridge → pending_review.json | ✅ enabled (ранее не задокументирован) |
| cleanup-tmp.timer | cleanup-tmp.service | ежедневно 04:25 | Бестия | очистка /tmp | ✅ enabled |
| cleanup-go-cache.timer | cleanup-go-cache.service | ежедневно 05:00 UTC | Бестия | очистка Go build cache | ✅ enabled |
| mskgastrodigestbot.timer | mskgastrodigestbot.service | ежедневно 10:16 | Мангуст | ежедневный дайджест gastrodigest-бота | ✅ enabled |
| update-notifier-download.timer | update-notifier-download.service | ежедневно 12:16 | системный | уведомления обновлений | ⚠️ failed (benign, системный) |
| docker-prune.timer | docker-prune.service | вс 03:00 | Сова | docker system prune | ✅ enabled |
| lab-memory-healthcheck.timer | lab-memory-healthcheck.service | (по расписанию hourly) | Бестия | healthcheck семантической памяти | ⚠️ **disabled** (inert, не стреляет) |
| reindex-incremental.timer | reindex-incremental.service | (по расписанию) | Бестия/инфра | инкрементальная переиндексация | ⚠️ **disabled**; service **failed** |

> Примечание: `reindex-full.service` в настоящий момент отрабатывает штатно
> (inactive после запуска в 00:02 UTC), НЕ failed. Реально failed — только
> `reindex-incremental.service`. Старый реестр ошибочно валил вину на reindex-full.

## Слой A — системные таймеры (Ubuntu, не трогать)

| Таймер | Сервис | Расписание | Статус |
|--------|--------|-----------|--------|
| apt-daily.timer | apt-daily.service | 2×/сут (06,18) | ✅ |
| apt-daily-upgrade.timer | apt-daily-upgrade.service | ежедневно 06:00 | ✅ |
| logrotate.timer | logrotate.service | ежедневно 00:00 | ✅ |
| man-db.timer | man-db.service | ежедневно 00:00 | ✅ |
| systemd-tmpfiles-clean.timer | systemd-tmpfiles-clean.service | ежедневно | ✅ |
| motd-news.timer | motd-news.service | 2×/сут (00,12) | ✅ |
| update-notifier-motd.timer | update-notifier-motd.service | вс 06:00 | ✅ |
| e2scrub_all.timer | e2scrub_all.service | вс 03:10 | ✅ |
| fstrim.timer | fstrim.service | пн | ✅ |
| apport-autoreport.timer | apport-autoreport.service | каждые 3 ч | ⚠️ inactive |
| ua-timer.timer | ua-timer.service | каждые 6 ч | ⚠️ inactive |

---

## Слой B — системный cron

| Источник | Расписание | Назначение | Примечание |
|----------|-----------|------------|------------|
| /etc/cron.d/certbot | 2×/сут | обновление SSL | пакетный, оставляем |
| /etc/cron.d/sysstat | период | сбор статистики | пакетный, оставляем |
| /etc/cron.d/e2scrub_all | период | ext4 scrub | пакетный, оставляем |
| root crontab: memory-watchdog.sh | ежедневно 23:00 | watchdog памяти (streikbrecher) | лаб-собственный → **рекомендуется конвертировать в systemd-таймер** |
| /etc/cron.d/cheque-bot (+ дубликаты) | — | (историч.) | `.bak`/`.start` дубликаты удалены 2026-07-11 |

> OpenClaw gateway-cron (raven: Tavily Daily, weekly-automation-audit, raven-tech-radar)
> **удалены 2026-07-04** — в CRON_REGISTRY.md (2026-06-22) они ошибочно числятся
> активными; тот файл устарел и не является источником истины.

---

## Слой C — OpenClaw Gateway Scheduler (agent cron)

| ID / имя | Расписание | Target | Владелец | Назначение | Статус |
|----------|-----------|--------|----------|------------|--------|
| — | — | — | — | **Активных agent-cron на 2026-07-11 нет** (raven-кроны удалены 07-04) | ⚪ пусто |

> Правило T8: любой созданный agent-cron регистрируется здесь при создании. Проверка
> актуальности — `openclaw cron list`. Генератор НЕ сканирует этот слой.

---

## Слой D — Agent heartbeat

- Heartbeat — фича шлюза OpenClaw: периодически подкидывает агенту heartbeat-промпт
  (см. `HEARTBEAT.md` каждого агента). Настраивается per-agent, НЕ systemd, НЕ cron.
- Не является «таймером» в смысле выполнения задачи; в реестре — как ссылка.
- Агент, ищущий «откуда прилетают heartbeat»: см. `HEARTBEAT.md` своего workspace.

---

## Правила (ADR-0047)

- **T5 (удаление):** перед удалением проекта/сервиса — `systemctl disable --now <unit>.timer <unit>.service`, `daemon-reload`, затем удаляй файлы. Иначе осиротевший юнит → restart storm / диск забит логами.
- **T8:** agent-cron создан/удалён → реестр (слой C) обновлён. Нарушение = инцидент.
- **G3:** изменение таймера = regenerate + обнови этот файл + commit через `lab-commit.sh`.

## Как посмотреть live-состояние

```
systemctl list-timers --all --no-legend --no-pager        # слой A
systemctl list-units --state=failed --no-pager            # упавшие юниты
openclaw cron list                                        # слой C
cat /etc/cron.d/* ; crontab -l                            # слой B
```

## История изменений

| Дата | Изменение | Автор |
|------|-----------|-------|
| 2026-07-08 | Создание карты таймеров | Бестия |
| 2026-07-11 | Fact-check (Ворон): добавлен krv-notify; исправлено время reindex-full (00:02), mskgastrodigestbot (10:16); lab-memory-healthcheck и reindex-incremental помечены disabled (а не активные); reindex-full снят с «broken». Переведено в 4 слоя (ADR-0047) | Ворон (raven) |
