# ADR-0056: Стандарт создания и редактирования скиллов (устранение хаоса при создании)

- **Status:** Accepted
- **Date:** 2026-07-13
- **Author:** kotolizator (КотОлизатОр), по запросу ЗавЛаба
- **Relates:** ADR-0048 (управление конфигом gateway), ADR-0055 (Gatekeeper threat model), П.3 методологии `docs/skills-creation-methodology.md`
- **Scope:** Все операции создания/редактирования/удаления скиллов в `/root/LabDoctorM` и на хосте `~/.openclaw`.

## Context

DDP-аудит 19 кастомных скиллов лаборатории (2026-07-13) выявил корень хаоса: при создании/копировании скиллов **нет единого стандарта и реестра**. Следствия (фактические):
- Расходящиеся копии скиллов в `workspaces/*/skills` перекрывали канон (уровень загрузки workspace=1 выше managed=4) — агенты получали устаревшие инструкции.
- Альтернативные «инструкции» (ручное редактирование `openclaw.json` allowlist, отдельные «стандарты качества») дублировали истину.
- Битые ссылки между скиллами (напр. `registering-incident` → несуществующий скил `accept`) никто не ловил.
- Канон `/root/.openclaw/skills` не был под VCS — правки SKILL.md необратимы.

Цель ЗавЛаба: **при создании новых скиллов не порождать хаос**.

## Decision

### Принципы (обязательны для всех агентов)

При создании/редактировании скила агент ОБЯЗАН:
1. **Пользоваться каноничной инструкцией** — единственный источник: `DoctorM_and_Ai/docs/skills-creation-methodology.md`.
2. **Создавать через единый вход `skill_workshop`** (тул). Ручное редактирование `openclaw.json` (allowlist `defaults.skills` / `agents.list[].skills`) **запрещено**.
3. **Зарегистрировать скил** чрез `skill_workshop` (тул ведёт собственный реестр/историю принятых скиллов; нет записи = скил не принят). ⚠️ `myrmex-control/skill-registry.json` — это реестр **PROJECT-SPECIFIC** скиллов самого проекта myrmex-control (add-pytest, security-audit, evolve-activator, …), а НЕ лаб-скиллов (AgentSkills из `skills-canon/`). Не смешивать сущности: лаб-скиллы живут в `skills-canon/` + symlink в `~/.openclaw/skills/`, регистрируются чрез `skill_workshop`, НЕ дублируются в myrmex registry.
4. **Обходные пути запрещены** — никаких копий скиллов в `workspaces/*/skills`, `projects/*/skills`; никакого ручного правления конфигом.

### Governance-слой (C-слой) — связность без плодения новых сервисов

- **Реестр истины для лаб-скиллов** = `skills-canon/` (под VCS) + `skill_workshop` (регистрация). `myrmex-control/skill-registry.json` — отдельный реестр project-скиллов myrmex-control (НЕ лаб-скиллов); не дублируем лаб-скиллы туда. Gatekeeper = только store результатов lint (изолированный).
- **link-lint** (внешний скрипт `DoctorM_and_Ai/scripts/skill-link-lint.sh`, гоняется в крон как `gatekeeper-audit.timer`) сканирует SKILL.md на битые ссылки и обходные копии, пишет результат в **изолированный store Gatekeeper** (`data/registry.json` через новый `put_registry` tool) — НЕ трогая PDP-ядро Gatekeeper. ADR-0054-коллизия номеров исключена индексом ADR.
- **Обязательная проверка (contract)** при принятии скила: соответствие канону (frontmatter, структура) + наличие записи в реестре + отсутствие битых ссылок.

### Уже применено (ядро A+B, 2026-07-13)

- Канон перенесён в `DoctorM_and_Ai/skills-canon/`, `/root/.openclaw/skills/<name>` — symlink'и (commit `51c6c37`). Правки SKILL.md теперь под VCS + rollback.
- Удалены все расходящиеся workspace-копии скиллов (Сова, Штрейкбрехер) — бэкапы в `.ops/trash`.
- Помечены устаревшими альтернативные инструкции (Доминики `skill-standard.md`, доки Совы).

## Consequences

- **Плюсы:** новый скил не создаст хаос (единый вход + реестр + авто-линт). Обходные копии ловятся автоматически.
- **Риски/обязательства:** `skill_workshop` должен стать реальным единственным входом (канон `skill-manager` поправлен — см. ниже). link-lint + Gatekeeper-store требуют поддержки (крон), иначе устареют. Любая правка Gatekeeper — по ADR-0048 (backup→validate→doctor→24ч).
- **Не делаем:** не создаём отдельный сервис реестра (используем Myrmex + Gatekeeper как store результатов линта).

## Implementation

1. ✅ Канон под VCS + symlink (сделано).
2. ✅ Удаление workspace-копий (сделано).
3. ✅ Правка канона `skill-manager` (добавлен единый вход `skill_workshop`, запрет ручного allowlist, обязательная регистрация) — см. `skills-canon/skill-manager/SKILL.md`.
4. ✅ `scripts/skill-link-lint.sh` (создан: (a) обходные копии, (b) битые ссылки, (c) валидность реестра Myrmex). НЕ требует лаб-скиллы в myrmex registry (разные сущности).
5. ⏳ Интеграция link-lint в крон + запись результатов в Gatekeeper isolated store — отдельная задача (правка живого Gatekeeper по ADR-0048).
6. ⏳ Переиндексация семантической памяти (Штрейкбрехер), чтобы не выдавала удалённый/исправленный контент.
