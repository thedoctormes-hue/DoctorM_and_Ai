---
id: INC-029-rotation-bug-20260625
timestamp: "2026-06-25T00:00:00Z"
category: tech
type: incident
severity: medium
status: retired
agent: streikbrecher
title: "INC-029: Баг ротации в openclaw-backup.sh"
date: 2026-06-25
tags: [backup, manus, yandex-disk, script]
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-029: Баг ротации в openclaw-backup.sh

**Проблема:** `openclaw-backup.timer` (каждые 2ч) создавал бэкапы на Яндекс Диск, но ротация (удаление старше 24ч) не работала. ЗавЛаб: "Я тону в бэкапах!"

**Корень:**
- `$YANDEX_SH disk ls | while read` — pipe создаёт subshell, переменные теряются
- `grep -oP` — хрупкий парсинг, зависит от формата вывода
- `date -d` — падает при несовпадении формата
- Нет логирования ошибок

**Решение:**
1. Таймер остановлен и отключён: `systemctl stop disable openclaw-backup.timer`
2. Process substitution `< <( ... )` вместо pipe
3. Явный парсинг даты через bash-операции
4. Логирование: "проверено N, удалено M"

**Файл:** `/root/LabDoctorM/workspaces/mangust/scripts/openclaw-backup.sh`

**Статус:** ✅ исправлено, таймер отключён (решение о включении — за ЗавЛабом)

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «resolved», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
