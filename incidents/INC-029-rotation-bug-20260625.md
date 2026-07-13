---
id: INC-029-rotation-bug-20260625
timestamp: "2026-06-25T00:00:00Z"
category: tech
type: incident
severity: medium
status: resolved
agent: streikbrecher
title: "INC-029: Баг ротации в openclaw-backup.sh"
date: 2026-06-25
tags: [backup, manus, yandex-disk, script]
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
