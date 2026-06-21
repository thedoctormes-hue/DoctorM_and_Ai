---
description: "Lab Insights Engine — система обработки инсайтов"
type: guide
last_reviewed: 2026-06-21
last_code_change: 2026-05-31
status: active
---
# Lab Insights Engine v2.1

Документация системы автоматической обработки инсайтов лаборатории ЗавЛаб.

> **Примечание:** система частично мигрирована на OpenClaw. Активные компоненты работают из `/root/LabDoctorM/.qwen/`. Данные хранятся в `/root/.qwen/projects/-root-LabDoctorM/memory/`.

## Обзор

Insights Engine — подсистема Jingle, которая перехватывает действия Qwen Code, извлекает из них знания и распределяет по слоям памяти.

## Архитектура

Источник → Извлечение → Фильтрация → Классификация → Очередь → Эволюция → Слои

Компоненты:
- PostToolUse hook → insight_catcher.sh → insights_queue.json → self_evolve.sh → слои (memory/skills/backlog/rules/agents)
- SessionEnd hook → session_finalize.sh — быстрая обработка безопасных слоёв (<5s)
- systemd timer (каждые 30 мин) → insights_maintenance.sh — полный maintenance + обработка pending
- decision_engine.py — классификатор инсайтов (рус + англ)
- adaptive_router.py — обучаемый роутер (epsilon-greedy bandit, eps=0.1)
- resolution_strategy.py — разрешение конфликтов между слоями
- decision_log.py — лог решений в JSONL

## Слои

- memory — знания, паттерны, архитектура, инсайты. Автоматическая запись.
- skills — инструменты, утилиты, скрипты. Автоматическая запись.
- backlog — задачи, баги, техдолг. Автоматическая запись в evolution_backlog.json.
- rules — безопасность, законы, запреты. ТОЛЬКО в backlog на ручное ревью. Не пишется автоматически.
- agents — поведение сотрудников, роли. ТОЛЬКО в backlog на ручное ревью. Не пишется автоматически.

Поток данных:
1. Qwen Code выполняет инструмент
2. PostToolUse hook вызывает insight_catcher.sh (async, 10s timeout)
3. Catcher: фильтрация (STOP/GO слова) → дедупликация (sha256) → классификация (bash regex + decision_engine.py + adaptive_router.py) → запись в insights_queue.json (flock)
4. При SessionEnd: session_finalize.sh — быстрая обработка memory/skills/backlog
5. Каждые 30 мин: lab-insights.timer → maintenance.sh → self_evolve.sh --all-pending
6. self_evolve.sh применяет инсайт к слою → обновляет статус → пишет decision_log → adaptive_router feedback

## Файлы

Хуки:
- `/root/LabDoctorM/.qwen/hooks/insight_catcher.sh` — перехват инсайтов
- `/root/LabDoctorM/.qwen/hooks/session_finalize.sh` — финализация сессии

Скрипты:
- `/root/LabDoctorM/.qwen/self_evolve.sh` — эволюция (обработка инсайтов)
- `/root/LabDoctorM/.qwen/scripts/insights_maintenance.sh` — maintenance

Python-движки:
- `/root/LabDoctorM/.qwen/hooks/decision_engine.py` — классификатор
- `/root/LabDoctorM/.qwen/hooks/adaptive_router.py` — обучаемый роутер
- `/root/LabDoctorM/.qwen/hooks/resolution_strategy.py` — разрешение конфликтов
- `/root/LabDoctorM/.qwen/hooks/decision_log.py` — лог решений

systemd:
- `/etc/systemd/system/lab-insights.timer` — таймер (каждые 30 мин)
- `/etc/systemd/system/lab-insights.service` — сервис

Данные:
- `/root/.qwen/projects/-root-LabDoctorM/memory/insights_queue.json` — очередь инсайтов
- `/root/.qwen/projects/-root-LabDoctorM/memory/.insight_hashes/` — хэши дедупликации
- `/root/.qwen/projects/-root-LabDoctorM/memory/insight_*.md` — memory layer
- `/root/.qwen/skills/*.md` — skills layer
- `/root/.qwen/evolution_backlog.json` — бэклог
- `/root/.qwen/memory/decision_log.jsonl` — лог решений
- `/root/.qwen/memory/insights/weights.json` — веса роутера
- `/root/.qwen/memory/insights/feedback.json` — обратная связь

Тесты:
- `/root/LabDoctorM/.qwen/tests/test_decision_engine.py`
- `/root/LabDoctorM/.qwen/tests/test_adaptive_router.py`
- `/root/LabDoctorM/.qwen/tests/test_resolution_strategy.py`
- `/root/LabDoctorM/.qwen/tests/test_catcher_pipeline.py`
- `/root/LabDoctorM/.qwen/tests/test_self_evolve.py`

## Запуск тестов

```bash
cd /root/LabDoctorM && python3 -m pytest .qwen/tests/ -v
```

## Управление таймером

systemctl status lab-insights.timer — статус
systemctl start lab-insights.timer — запуск
systemctl stop lab-insights.timer — остановка
journalctl -u lab-insights.service --no-pager -n 20 — логи

## Ручная обработка инсайтов

```bash
cd /root/LabDoctorM
bash .qwen/self_evolve.sh <id>                    # обработать один инсайт
bash .qwen/self_evolve.sh --all-pending            # обработать все pending
bash .qwen/self_evolve.sh create backlog "Название"  # создать задачу в бэклоге
bash .qwen/self_evolve.sh create adr "Решение"       # создать ADR
bash .qwen/self_evolve.sh create pattern "Паттерн"  # создать паттерн
bash .qwen/self_evolve.sh create incident "Описание" # создать инцидент
bash .qwen/self_evolve.sh create rule "Правило"     # создать правило
bash .qwen/self_evolve.sh create metric "Метрика"   # создать метрику
```

## Мониторинг

```bash
tail -f /root/.qwen/logs/insight_catcher.log                        # лог катchers
tail -f /root/.qwen/logs/self_evolve.log                            # лог эволюции
tail -f /root/.qwen/projects/-root-LabDoctorM/memory/maintenance.log # лог maintenance
python3 /root/LabDoctorM/.qwen/hooks/adaptive_router.py status       # статус роутера
```

## Фильтрация (insight_catcher.sh)

STOP-фильтр: инсайты < 10 символов, содержащие "коммит", "удали", "проверь", "chmod", " wget", "curl", "mkdir", "touch", "pwd" — отбрасываются.
GO-фильтр: инсайт должен содержать хотя бы одно слово из списка (~70 терминов): архитектура, паттерн, инсайт, решение, проблема, рефакторинг, оптимизация, безопасность и др.
Дедупликация: sha256 первых 12 символов. Хэш-файлы в .insight_hashes/. Очистка > 30 дней через maintenance.

## Классификация

Двухэтапная:
1. Bash regex: STOP/GO фильтры + базовые ключевые слова → layer (memory/skills/backlog/rules/agents)
2. decision_engine.py: расширенная классификация по 80+ ключевым словам (рус + англ).
   Если confidence >= 0.7 и слой отличается — перезапись.
   resolution_strategy.py: разрешение конфликтов при близких scores.
3. adaptive_router.py: epsilon-greedy (90% argmax, 10% exploration).
   Результат сохраняется в route_tag/route_layer инсайта.
   feedback после обработки: reward +1 если слой совпал, -1 если нет.
   Скорость обучения alpha=0.1.

## Формат insights_queue.json

{"version": 2, "insights": [
  {
    "id": 1,
    "timestamp": "2026-05-31T17:00:00+00:00",
    "tool_name": "bash",
    "session_id": "...",
    "content": "Описание инсайта",
    "status": "pending|processed|skipped",
    "hash": "abc123def456",
    "layer": "memory",
    "confidence": "high",
    "route_tag": "pattern",
    "route_layer": "memory",
    "processed_at": "2026-05-31T17:30:00+00:00"
  }
]}
