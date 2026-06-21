---

description: "ADR-027: Race-free атрибуция коммитов через обёртку lab-commit + гейт идентичности"
type: adr
last_reviewed: 2026-06-16
last_code_change: 2026-06-16
status: accepted
source: manual
last_verified: 2026-06-17
---# ADR-027: Race-free атрибуция коммитов

## Статус
accepted

## Контекст
Все агенты лаборатории коммитят из общего корневого worktree `/root/LabDoctorM`
(worktree-изоляция ADR-012 откатана из-за `chdir(2) failed`). Identity задавалась
записью в общий `.git/config` (`git config user.name`) при старте сессии. Параллельный
старт другого агента перетирал значение между `git add` и `git commit` → коммиты
уходили под чужими авторами. Рецидив фиксировался многократно (сессии 18, 19).

Три источника проблемы:
1. `session_startup.sh` писал identity в общий `.git/config` — гонка.
2. `scripts/agent-workspace.sh` делал то же (`git config` без `--worktree`).
3. `pre-commit` пытался `export GIT_AUTHOR_NAME` — но хук это дочерний процесс,
   его env не доходит до родительского `git commit`. Мёртвый код.

Per-worktree config (`git config --worktree`) НЕ решает: worktree один на всех агентов,
секция общая.

## Решение
Автор задаётся в **момент коммита** через `GIT_AUTHOR_*`/`GIT_COMMITTER_*` env —
это процесс-локально (гонки нет) и перебивает любое значение в config.

1. **`scripts/lab-commit.sh`** — обёртка. Резолвит автора из `.qwen/git-authors.json`
   (по аргументу `<agent>` или `$LAB_AGENT`), ставит env, вызывает `git commit`.
2. **`pre-commit` — гейт идентичности.** git к моменту хука уже разрешил автора и
   положил в `GIT_AUTHOR_EMAIL` окружения хука. Хук верифицирует:
   - если задан `LAB_AGENT` — автор обязан совпадать с его identity (ловит гонку точечно);
   - иначе автор обязан быть в белом списке (`git-authors.json` + ЗавЛаб).
   Несоответствие → коммит блокируется.
3. **`session_startup.sh` / `agent-workspace.sh`** больше не пишут identity в общий config.

## Последствия
- ✅ Атрибуция race-free даже при параллельной работе агентов.
- ✅ Структурный гейт, а не поведенческое правило (закрывает корень INC class B).
- ⚠️ Коммитить нужно через `lab-commit.sh` (или с `LAB_AGENT` для срабатывания гейта).
- 📋 Агенты должны знать про обёртку — выводится при старте сессии + в GIT_GUARDIAN.md.

## Альтернативы
- **Per-worktree config** — отклонён: worktree общий, изоляции нет.
- **Только обёртка без гейта** — отклонён: голый `git commit` всё равно уйдёт под чужим автором.
- **Только warning в хуке** — отклонён: остаётся поведенческим правилом, корень не закрыт.

## Связанные артефакты
- ADR-012 — worktree-изоляция (откачена, первопричина общего worktree)
- INC-004 / git identity рецидивы (сессии 18, 19)

## Примечания
- Обёртка: `scripts/lab-commit.sh`
- Гейт: `.githooks/pre-commit`
- Тест: `tests/test_git_identity_gate.sh` (4 сценария, включая гонку)
