---
id: 2026-06-22-systemd-zombie-cleanup
timestamp: "2026-06-22T00:00:00Z"
category: tech
type: other
severity: critical
status: retired
agent: dominika
title: "Устранение systemd-зомби — 2026-06-22 07:30 UTC"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# Устранение systemd-зомби — 2026-06-22 07:30 UTC

## Статус: ✅ RESOLVED

## Что было сделанo

### Группа A — удалены полностью (4 сервиса + 4 таймера)
- hype-observe.service + timer — scripts/venv удалены (commit c812e96)
- hype-daily.service + timer — scripts/venv удалены
- hype-orq.service + timer — scripts/venv удалены
- saas-api-health.service + timer — venv/playwright удалён
- Действие: unit-файлы удалены из /etc/systemd/system/, daemon-reload, reset-failed

### Группа B — исправлены (2 сервиса)
- onnx-reindex.service — увеличен MemoryMax 1G→2G, CPUAffinity 3→0-2 (3 ядра), Timeout 2h→3h
- artifact-audit.service — добавлен SuccessExitStatus=1 (exit 1 = нашёл проблемы, не сбой)

### Группа C — подтверждены рабочими
- runtime-state-update — работает штатно, путь правильный
- context-api-reindex — работает штатно, зависимость от ollama устарела (но не критично)

## Результат
- До: 11 failed сервисов
- После: 0 failed сервисов

## Причина root cause
Компоненты проектов были удалены/перемещены (commit c812e96, миграция 21.06),
но systemd unit-файлы продолжали ссылаться на несуществующие пути.

## Рекомендация
При удалении проекта — всегда проверять systemctl list-units --all на зависимости.

---

## Повторение 2026-06-25 11:10 UTC

6 failed юнитов снова накопились за 3 дня. Root cause: WANT-сироты.

### Ликвидированные юниты
1. lab-index-seq@dominika.service — OOM-kill, unit-файл удалён
2. lab-monitoring-dashboard.service — exit-code, 16 928 рестартов!, unit-файл удалён
3. snablab.service — SIGKILL, unit-файл удалён
4. lab-monitoring.timer — resources, unit-файл удалён
5. raven-patrol.timer — resources, unit-файл ЕСТЬ, но service-файл удалён
6. snablab-db-dump.timer — resources, unit-файл удалён

### Действия
- Отключены таймеры: `systemctl disable --now` (3 шт.)
- Удалены сиротские WANT-symlink'и из multi-user.target.wants/ и timers.target.wants/
- `systemctl reset-failed`
- `systemctl daemon-reload`
- Результат: 0 failed units

### Глубинный корень (археологический анализ)
При удалении проекта/сервиса отсутствует обязательный шаг `systemctl disable --now <unit>` перед удалением unit-файла. Без этого WANT-symlink остаётся → systemd пытается запустить → not-found failed. Если Restart=always — restart storm (16 928 раз!).

**Обязательное правило:** перед `rm <unit-file>` → `systemctl disable --now <unit>` + `systemctl reset-failed <unit>`

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
