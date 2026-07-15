---
id: INC-2026-07-14-133000-antcat-conflicts-killed-run1
timestamp: "2026-07-14T13:30:00Z"
category: tech
type: config_error
severity: high
status: closed
agent: antcat
title: "INC-2026-07-14-133000 — Муравей убил RUN #1 через Conflicts= в full.unit"
---

# INC-2026-07-14-133000 — Муравей убил RUN #1 через Conflicts= в full.unit

- **Status:** CLOSED (2026-07-14 21:45 МСК) — проект sem-memory закрыт, unit `reindex-full` удалён, Conflicts= более не применяется.
- **Дата:** 2026-07-14 13:30 МСК
- **Тип:** Ошибка конфигурации (systemd Conflicts= семантика)
- **Серьёзность:** high (потеря 14ч прогона + зависший unit 5ч)

## Описание
При включении incremental timer (ЗавЛаб: «Включай!») Муравей добавил
`Conflicts=reindex-incremental.service` в `reindex-full.service` (якобы для
защиты от конфликта). Неверно понял семантику: **Conflicts= работает в ОБЕ
стороны** — при запуске incremental systemd останавливает full.

В 08:31:04 `enable --now reindex-incremental.timer` → incremental.service
стартовал (Persistent=true сработал немедленно) → full получил TERM
(status=15/TERM at 08:31:04) → **RUN #1 (14+ч, staging 29 943) убит до swap**.

full завис в `deactivating` 5 часов: reindex.py убит (kill -9 parent), но
cgroup children (embedding workers, spawn reindex.py) не умерли → systemd
ждал их. `reset-failed` НЕ сбросил deactivating (это переходное состояние,
не failed). `systemctl stop` блокировался. Только
`systemctl kill reindex-full.service` (SIGKILL всего cgroup) разблокировал
→ inactive.

## Чинка (2026-07-14 13:30 МСК)
1. Убран `Conflicts=` из `reindex-full.service` (repo `/root/LabDoctorM/projects/lab-memory/deploy/systemd/` + live `/etc/systemd/system/`).
2. Улучшен bash-guard в `reindex-incremental.service`:
   - Было: `if systemctl is-active --quiet reindex-full.service` (пропускает только при `active`, НЕ при `deactivating`/`activating`).
   - Стало: `if [ "$(systemctl is-active reindex-full.service)" != "inactive" ]` (skip при ЛЮБОМ не-inactive состоянии full).
3. `systemctl kill reindex-full.service` (SIGKILL cgroup) → `reset-failed` → `start reindex-full.service` (RUN #2).

## Наблюдения после чинки (13:30 МСК)
- full: inactive → после явного `start` должен стать active (RUN #2).
- live `md-files.sqlite`: **41 761** (было 40 529 до инцидента) — incremental успел сделать swap (обновил live).
- staging: 31 566 (incremental дописал).
- incremental.timer: active (работает).

## Урок (PAT-05 / инженерный)
- **Conflicts= агрессивен**: убивает конфликтующий юнит при старте ЛЮБОГО из пары. Для защиты incremental от full использовать **bash-guard (skip)**, НЕ Conflicts=.
- **reset-failed НЕ сбрасывает `deactivating`** (переходное состояние). Для разблокировки зависшего unit — `systemctl kill <unit>` (SIGKILL cgroup).
- **kill -9 parent НЕ убивает children в cgroup** → unit висит в deactivating. Использовать `systemctl kill` (SIGKILL cgroup целиком).
- При включении timer с `Persistent=true` — первый прогон стартует немедленно (не через интервал). Учитывать при добавлении Conflicts=.

## Статус (2026-07-14 18:25 МСК)
- **Чинка применена** (repo `ccf4473` запушен): `Conflicts=` удалён из `reindex-full.service`; bash-guard улучшен и затем (по приказу ЗавЛаба «Я БЛЯДЬ... запустить инкрементную») **полностью убран** из `reindex-incremental.service`, чтобы full + incremental шли параллельно.
- **RUN #2 запущен** (ручной `systemctl start reindex-full.service`, PID 2529956) + incremental параллельно (PID 2640554).
- Состояние на 18:25 МСК: full `activating` (staging **6 248**, растёт), incremental `activating` (live **44 093**, +1 038 за ~4ч с 14:19), workers 8084/8085 `active`, mcp-memory `active` (hybrid).
- **НЕ закрыт**: инцидент считается решённым только после успешного swap RUN #2 (staging→live, ребилд FAISS + FTS5) без конфликтов. Мониторинг перенесён в новую сессию.
- Таймеры `reindex-full.timer` / `reindex-incremental.timer` **отключены** (приказ ЗавЛаба «Отключи таймеры») — per-user order, не баг.

## Урок (финальный)
- `Conflicts=` — только если нужен жёсткий взаимоисключающий запуск. Для защиты incremental от full — bash-guard (skip), и только если ДЕЙСТВИТЕЛЬНО нужно блокировать. ЗавЛаб прямо разрешил параллель → guard убран.
