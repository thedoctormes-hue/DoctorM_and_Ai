---
name: code-reviewer
description: "Линза code review: correctness, readability, architecture, security, performance. Применяй для ревью кода перед merge."
type: lens
version: 5.0.0
category: engineering
triggers: ["ревью", "review", "код", "проверь код", "code review", "PR", "pull request"]
---

# 🔍 Линза: Code Reader

## Назначение
Многоосевое ревью кода. Меняй фокус с «работает ли?» на «сломается ли через год?». Ты остаёшься собой — просто смотришь на код глазами человека, который будет его поддерживать.

## 5 вопросов (прочитай код и задай себе)

**1. Что сломается первым?**
— Если этот код увидит production нагрузку — где треснет? Edge cases, race conditions, null dereferences. Не «должно работать», а «что конкретно упадёт и почему».

**2. Поймёт ли джуниор через год?**
— Без комментариев, без созвона, без git blame. Если нужен «кто-то кто помнит контекст» — код слишком сложный. Имена говорят сами за себя.

**3. Что если требования изменятся завтра?**
— Что придётся переписать? Жёсткие зависимости, hardcoded значения, зашитая логика — всё что не переживёт изменение. Спроси: «а если клиент попросит наоборот?».

**4. Что если это прочтёт атакующий?**
— Секреты в коде? Ввод без валидации? Auth забыт на одном endpoint? Представь что ты — плохой парень. Где войдёшь?

**5. Что нельзя откатить?**
— Миграции БД, удаление таблиц, смена протокола. Всё что одностороннее — должно быть в красном. Если rollback невозможен — нужен manual approval.

## Классификация findings

- **Critical** — исправить до merge (security, data loss, broken functionality)
- **Important** — исправить до merge (missing test, wrong abstraction)
- **Suggestion** — рассмотреть для улучшения (naming, style)

## Правила
- **НЕ изменяй** код — только рецензия и рекомендации
- **НЕ утверждай** код с Critical issues
- **НЕ забывай** отметить что сделано хорошо (хотя бы один пункт)
- Читай тесты первыми — они раскрывают intent

## Формат вывода

```
## Review Summary
Verdict: APPROVE | REQUEST CHANGES

### Critical
- [файл:строка] проблема → fix

### Important
- [файл:строка] проблема → fix

### Suggestions
- [файл:строка] предложение

### Done Well
- ...

### Verification
- Tests: reviewed | Build: verified | Security: checked
```

## Ловец инсайтов

→ `/root/LabDoctorM/lenses/INSIGHT_CATCHER.md`
