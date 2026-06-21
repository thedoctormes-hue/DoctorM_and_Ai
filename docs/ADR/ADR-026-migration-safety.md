---
name: ADR-026
description: Предотвращение поломки сервисов при миграции/удалении проектов
status: proposed
date: 2026-06-15
author: streikbrecher
---

# ADR-026: Предотвращение поломки сервисов при миграции/удалении проектов

## Контекст

12.06.2026 Штрейкбрехер вынес 18 проектов в отдельные репозитории (коммиты `bff0904f`, `401aa9de`), удалив исходники из `/root/LabDoctorM/projects/`. 7 systemd-сервисов остались с путями к удалённым файлам и упали. Проблема обнаружена только через сутки при старте сессии — никакой автоматической проверки не было.

## Решение: 4 уровня защиты

### Уровень 1: Guard в pre-commit hook (уже существует + дополнение)

В `.git/hooks/pre-commit` добавить **Systemd Reference Guard**:

```bash
# ── Systemd Reference Guard ───────────────────────────────────────────
# При удалении файлов — проверяет, не ссылаются ли на них из systemd unit-файлов.
# Затрагивает только файлы удаляемые в коммите (diff-filter=D).

STAGED_DELETED=$(git diff --cached --name-only --diff-filter=D 2>/dev/null)

if [ -n "$STAGED_DELETED" ]; then
    SYSTEMD_REFS=""
    while IFS= read -r deleted_file; do
        [ -z "$deleted_file" ] && continue
        # Ищем ссылки на удаляемый файл во всех unit-файлах
        FOUND=$(grep -rlF "$deleted_file" /etc/systemd/system/*.service 2>/dev/null || true)
        if [ -n "$FOUND" ]; then
            SYSTEMD_REFS="${SYSTEMD_REFS}УДАЛЯЕТСЯ: ${deleted_file}\n"
            for ref in $FOUND; do
                SYSTEMD_REFS="${SYSTEMD_REFS}  ← используется в: $(basename $ref)\n"
            done
        fi
    done <<< "$STAGED_DELETED"

    if [ -n "$SYSTEMD_REFS" ]; then
        echo ""
        echo "🚫 SYSTEMD REFERENCE GUARD: удаляемые файлы используются в systemd-сервисах!"
        echo -e "$SYSTEMD_REFS"
        echo "   Варианты:"
        echo "   1. Обновите unit-файл(ы) перед удалением"
        echo "   2. Отключите сервис: systemctl disable --now <service>"
        echo "   3. Принудительно: FORCE_SYSTEMD=1 git commit ..."
        echo ""
        exit 1
    fi
fi
```

### Уровень 2: Чеклист миграции (обязательно при выносе/удалении проектов)

Файл `docs/MIGRATION_CHECKLIST.md` — обязателен при любом массовом удалении:

```markdown
## Чеклист миграции проекта

- [ ] Найти все ссылки на проект в systemd: `grep -rl "$PROJECT" /etc/systemd/system/`
- [ ] Найти все ссылки в cron: `grep -rl "$PROJECT" /etc/cron* /var/spool/cron/`
- [ ] Найти все ссылки в других проектах: `grep -rl "$PROJECT" /root/LabDoctorM/projects/*/`
- [ ] Отключить и удалить unit-файлы ИЛИ обновить пути
- [ ] Проверить после коммита: `systemctl list-units --state=failed`
- [ ] Задокументировать изменения в ADR
```

### Уровень 3: Post-commit smoke test

В `session_end.sh` добавить проверку после массовых коммитов (>5 файлов):

```bash
# После коммита с массовыми изменениями — проверить systemd
CHANGED=$(git diff HEAD~1 --stat | tail -1 | awk '{print $1}')
if [ "$CHANGED" -gt 5 ] 2>/dev/null; then
    FAILED=$(systemctl list-units --state=failed --no-legend 2>/dev/null | wc -l)
    if [ "$FAILED" -gt 0 ]; then
        echo "⚠️ ВНИМАНИЕ: $FAILED сервисов в состоянии failed!"
        systemctl list-units --state=failed --no-legend
    fi
fi
```

### Уровень 4: Мониторинг (уже должен быть)

Сервис `lab-monitoring` (когда починят) должен проверять `systemctl is-active` для критических сервисов и алертировать при падении.

## Что было сломано (факты)

| Сервис | Удалённый файл | Причина |
|--------|---------------|---------|
| hype-orq | hype_pilot/orq/hype_orq.py | Вынос hype-pilot |
| lab-monitoring | точка входа пакета | Вынос lab-monitoring |
| raven-patrol | stack_patrol модуль | Вынос lab-monitoring |
| saas-api-health | scripts/health_check.sh | Вынос lab-playwright-expert |
| hype-daily | channels/daily_report.py | Вынос hype-pilot |
| artifact-health | artifact_health.py | Вынос artifact-pulse |

## Критерии принятия

- [ ] Systemd Reference Guard добавлен в pre-commit hook
- [ ] MIGRATION_CHECKLIST.md создан
- [ ] Smoke test добавлен в session_end.sh
- [ ] Все сломанные сервисы восстановлены или отключены
