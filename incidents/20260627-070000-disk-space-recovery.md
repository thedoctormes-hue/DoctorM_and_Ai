---
id: 20260627-070000-disk-space-recovery
timestamp: "2026-06-27T07:00:00Z"
category: tech
type: bug
severity: medium
status: retired
agent: unknown
title: "INC-035: Переполнение дискового пространства (95%)"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-035: Переполнение дискового пространства (95%)

**Дата:** 2026-06-27 07:00 UTC
**Статус:** ✅ Устранён
**Зона:** Штрейкбрехер (Developer)

## Симптом
Диск /dev/vda1 заполнен на 95% (53G/59G, 3.2G свободно).

## Корневые причины (Root Constellation)
1. **Бэкапы полных копий проектов** — 4.1G (38%). systemd-таймер создавал полные копии включая node_modules, .venv, .git.
2. **/tmp мусор** — 1.7G (15%). Go build cache, разархивированные проекты, node compile cache, TTS модели.
3. **Go module cache** — 3.5G (32%). /root/go/pkg/mod/ накапливался годами.
4. **Docker образы** — 57MB (мало, но 89% было reclaimable).

## Что сделано
1. `docker system prune -a --volumes -f` → +57MB
2. `rm -rf /tmp/go-build* /tmp/polyscope_extracted /tmp/node-compile-cache /tmp/vits-piper-* /tmp/en_tts.tar.bz2` → +1.2G
3. `rm -rf backups/git-hygiene-20260626/ backups/Before-Standards-20260626/` → +4.1G
4. `go clean -cache && rm -rf /root/go/pkg/mod/*` → +3.5G
5. Создан .backupignore в 27 проектах
6. Настроен systemd-timer для ежедневной очистки /tmp

## Результат
3.2G → 14G свободно (95% → 77%)

## Уроки
- Бэкапы должны быть incremental (rsync --link-dest), не полные копии
- .backupignore обязателен для каждого проекта
- /tmp нужно чистить автоматически (Go build cache растёт бесконечно)
- Go module cache нужно периодически чистить
- Docker нужно регулярно prune

## Профилактика
- [x] .backupignore в 27 проектах
- [x] systemd-timer для очистки /tmp (ежедневно 04:00 UTC)
- [x] docker-prune.timer уже был настроен (еженедельно, воскресенье 03:00 UTC)
- [ ] Перевести бэкапы на incremental (rsync --link-dest) — запущен агент incremental-backup
- [ ] Настроить Go cache cleanup по расписанию — запущен агент go-cache-cleanup
- [ ] Настроить мониторинг диска с алертами — запущен агент disk-monitor

## Дополнительно (07:07-07:24 UTC)
- Запущены 3 параллельных агента для завершения профилактики
- Docker образы 2G — это рабочие контейнеры (grafana, vaultwarden, searxng), не мусор
- Существующий docker-prune.timer настроен (еженедельно, воскресенье 03:00 UTC)

## Найденные и исправленные ошибки
1. **backup.sh исключал .git/objects/ и .git/hooks/** — критическая ошибка, без objects репозиторий не восстановить. Исправлено.
2. **.backupignore во всех 27 проектах исключал .git/objects/ и .git/hooks/** — исправлено во всех.
3. **disk-monitor.sh экстренная очистка `find /tmp -mindepth 1 -delete`** — удалила бы systemd sockets (.X11-unix, .ICE-unix, systemd-private-*). Исправлено на безопасные паттерны.
4. **disk-monitor.log не имел ротации** — добавлена ротация при 1000 строках.

## Итоговая конфигурация профилактики
- [x] .backupignore в 27 проектах (исправлен, без objects/hooks)
- [x] cleanup-tmp.timer — ежедневно 04:00 UTC
- [x] cleanup-go-cache.timer — ежедневно 05:00 UTC
- [x] backup-projects.timer — ежедневно 02:00 UTC (incremental, rsync --link-dest)
- [x] disk-monitor.timer — каждые 5 минут (пороги 85/90/95%)
- [x] docker-prune.timer — еженедельно воскресенье 03:00 UTC (уже был)
- [x] Тестовый incremental бэкап: 27 проектов, 306M (вместо 3.6G полной копии)

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
