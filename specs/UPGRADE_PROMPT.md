---
description: "Промпт для старта апгрейда Myrmex Control"
type: spec
last_reviewed: 2026-05-12
last_code_change: 2026-05-12
status: active
---
# Промпт для старта апгрейда Myrmex Control

Скопируй и вставь в новую сессию Qwen Code:

---

## Промпт v1.0 (после каскадного анализа)

```
Привет, OWL! Ранее мы провели полный каскадный анализ проекта myrmex-control.
23 агента, 80+ проблем, дедуплицировано в 26 спецификаций (BL-011..BL-026).

Результаты в:
- /root/LabDoctorM/specs/BL-011..BL-026 — все спецификации
- /root/LabDoctorM/myrmex.json — 26 задач (tasks), 26 specs, version 1.3.0
- /root/LabDoctorM/cascade/pool/20260512_0815-myrmex-control/SYNTHESIS.md — матрица ответственных

Текущее состояние:
- BL-011..BL-025 — созданы, ожидают реализации
- BL-026 — добавлена после инцидента (смена пароля через UI)

Задачи:

1. **Срочно** — реализовать BL-026 (смена пароля через UI):
   - POST /api/auth/change-password (backend)
   - форма смены пароля (frontend)
   - Зависит от BL-012 (file locking fix)

2. **Критично** — исправить writeState() в myrmex.js:
   - writeState() перезаписывает myrmex.json целиком → теряет поля (users, refresh_tokens)
   - Нужно: читать файл → мержить → записывать
   - Инцидент: INC-20260512111530

3. **План апгрейда** — реализовать BL-011..BL-026 по приоритету:
   - P0: BL-011 (JWT_SECRET), BL-012 (file locking), BL-026 (change password)
   - P1: BL-013 (CSP), BL-014 (input validation), BL-015 (rate limiting)
   - P2: BL-016..BL-025 (остальные)

Стратегия: одна спека = один коммит. После каждого — build + smoke test.
Используй агентов по матрице из SYNTHESIS.md.
```

---

*Создано: 2026-05-12T11:30+03:00*
*Версия плана: 1.3.0*
