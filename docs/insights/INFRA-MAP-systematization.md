---
name: infra-map-systematization
description: Как систематизировать таймеры и порты лаборатории, чтобы агенты не путались
type: insight
status: active
verified: 2026-07-08
source: аудит таймеров/портов + research-агент (web, Arch Wiki / systemd.unit(5) / systemd.service(5))
---

# 🗺 Систематизация карты таймеров и портов

## Корень путаницы (найдено 2026-07-08)

- Нет **одного актуального списка**. Агенты узнают, что и где крутится, только когда спотыкаются и бегут в `grep`/`systemctl`.
- Старая документация протухла: `PORT_REGISTRY.md` (от 21.06) не знала половины сервисов; `CRON_REGISTRY.md` вообще про внутренний cron OpenClaw, а не про systemd-таймеры. Карты systemd-таймеров не было вообще.
- Повторяющийся сбой: удалил проект → не выключил юнит → `disable --now` не сделал → осиротевший таймер → crash loop / диск забит логами. Ловили на `apihub` и `myrmex`.

## Что сделано (2026-07-08)

- `docs/TIMER_REGISTRY.md` — карта всех 30 systemd-таймеров: что / где / когда / зачем / владелец. Разбивка на лаб- и системные.
- `docs/PORT_REGISTRY.md` — реестр портов обновлён по live (`ss -tulpn`): добавлены free-api-hunter (8090), onnx (8082), consilium (8300), chisel (8444), экспортеры (9100/9187), snablab (8200), zprr (8001), doctorm (8899), openclaw (18789); убраны мёртвые 8190/vpn-daemon.
- `scripts/infra-drift-check.sh` — «страж»: ловит упавшие юниты, осиротевшие таймеры (сервис `LoadState=not-found`) и публичные порты. Возвращает exit 1 при критике → готов завеситься в timer с алертом.

## Паттерны, как держать это в порядке (из web + наших инцидентов)

1. **Единый источник истины + авто-сверка.** Карта — не догадка, а отражение live. Раз в сутки `infra-drift-check.sh` сверяет реальность с ожидаемым и кричит при расхождении.
2. **Правило «disable --now перед rm».** Любое удаление проекта/сервиса = `systemctl disable --now <unit>` (+ таймер) → `daemon-reload` → только потом удалять файлы. Это убивает корень crash-loop/orphan-проблемы.
3. **Per-project target + `PartOf=`.** Сгруппировать юниты проекта под `proj-<name>.target`; каждый child объявляет `PartOf=proj-<name>.target`. Один `disable --now proj-<name>.target` гасит проект целиком, без осиротков.
4. **`X-Lab.Owner=` / `X-Lab.Port=` в юнитах.** systemd молча игнорирует неизвестные `X-*` ключи — можно класть машинно-читаемые факты рядом с юнитом и искать `systemctl show -p X-Lab.Owner`.
5. **Rate-limit + ресурсные потолки.** `StartLimitIntervalSec`/`RestartSec` + `MemoryMax`/`TasksMax` в per-service slice — сломанный юнит не может tight-loop-перезапуском сожрать CPU/RAM/диск (урок `myrmex` 2.6 GB лога).
6. **Лимит логов.** `LogRateLimit*` на шумных юнитах + ротация; направлять бурные ошибки в `null`/ротируемый файл, чтобы crash-loop не забил диск.
7. **Детект осиротов через `systemd-analyze verify`.** Флагает таймеры, чей `Unit=` не резолвится. Дешевле, чем разбирать пожар.
8. **CI drift-check + `Documentation=` на каждом юните.** Регистрируемая карта не «аспирационная»: если live разошёлся с манифестом — сборка не проходит; у каждого юнита `Documentation=<ссылка на реестр>`.
9. **Project-prefixed имена.** `<project>.<role>.service`, `proj-<name>.target`, `<role>@<instance>.timer` — grep-able, без коллизий между агентами.
10. **Timer hygiene.** `RandomizedDelaySec` по умолчанию (без thundering herd), осознанный `Persistent=`.

## Следующие шаги (опционально)

- Завесить `infra-drift-check.sh` в systemd.timer (раз в сутки) с алертом в Telegram при exit≠0.
- Добавить `X-Lab.Owner`/`X-Lab.Port` в лаб-юниты и перейти на `proj-<name>.target`.
- Разобраться с `reindex-full.service` (падает по signal TERM; невалидный `RefuseManualStart` в `[Service]`).
- Проверить публичные метрики (9100/9187) и DNS (53 на внешнем IP) — нужны ли они в сети.
