# Аудит кастомных скилов

**Дата:** 2026-06-29
**Аудитор:** Муравей (Builder)
**Область:** `~/.openclaw/skills/` (все подкаталоги)

---

### 300-vision
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "1.0.0"
- description: есть (138 символов)
- В entries (openclaw.json): нет (но есть в allowBundled) ← ❌ нет в entries
- user-invocable: отсутствует ← ❌
- Проблемы: Нет user-invocable в frontmatter. Нет в skills.entries (хотя есть в allowBundled — вероятно баг конфигурации, скил должен быть И в entries И в allowBundled если кастомный).

### accepting-work
- Статус: ✅ ОК
- SKILL.md: есть
- status в frontmatter: active ← ❌ (нет в entries скилах)
- version: "3.0.0"
- description: есть (125 символов)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: Нет в skills.entries.

### anti-loop
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "2.0.0"
- description: есть (178 символов) ← ❌ >160
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: description 178 символов (лимит 160). Нет в skills.entries.

### change-management
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "2.0.0"
- description: есть (169 символов) ← ❌ >160
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: description 169 символов (лимит 160). Нет в skills.entries.

### colony-disk-exchange
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "2.0.0"
- description: есть (223 символа) ← ❌ >160
- В entries (openclaw.json): нет (но есть в allowBundled) ← ❌ нет в entries
- user-invocable: true
- Проблемы: description 223 символа (лимит 160). Нет в skills.entries.

### deep-dive
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "v1.1" ← ❌ не семвер
- description: есть (114 символов)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: version "v1.1" — не соответствует семвер X.Y.Z (ведущий ноль/буква v). Нет в skills.entries.

### ebsh
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "1.0.0"
- description: есть (69 символов)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: Нет в skills.entries.

### fact-check
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "2.0.0"
- description: есть (155 символов)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: Нет в skills.entries.

### finishing-session
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "2.0.0"
- description: есть (96 символов)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: Нет в skills.entries.

### gitlab
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "1.0.0"
- description: есть (206 символов) ← ❌ >160
- В entries (openclaw.json): нет (но зарегистрирован как git-lab в entries) ← ❌ имя не совпадает
- user-invocable: true
- Проблемы: description 206 символов (лимит 160). В entries зарегистрирован как "git-lab" но не как "gitlab" — скил недоступен по имени папки. requires.binaries: ["jq"] — jq найден в PATH.

### labsearch (❌ УДАЛЁН/DEPRECATED — НЕ использовать)
- Статус: ❌ УДАЛЁН из системы. Семантический поиск теперь ТОЛЬКО через MCP `memory-gateway__search_memory` (бэкенд ALM/AnythingLLM).
- Прямые вызовы `lab_search.py` / `labsearch` / `mcp-memory :8087` / `onnx-embedder :8082` — ЗАПРЕЩЕНЫ (см. APPEND_SYSTEM.md).
- (историческая справка, не актуально) SKILL.md был симлинком → /root/LabDoctorM/projects/lab-memory/skills/labsearch; version 2.0.0; description 261 символ; не в skills.entries.

### manus-outsourcing
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: 2.0.0 (без кавычек) ← ❌ не семвер (нет patch-номера)
- description: есть (258 символов) ← ❌ >160
- В entries (openclaw.json): да ✅
- user-invocable: отсутствует ← ❌
- Проблемы: version 2.0.0 без patch (должно быть X.Y.Z). description 258 символов. Нет user-invocable. requires.binaries: ["python3", "curl", "jq"] — все найдены в PATH.

### registering-incident
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "1.1.0"
- description: есть (184 символа) ← ❌ >160
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: description 184 символа (лимит 160). Нет в skills.entries.

### research
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "1.1.0"
- description: есть (217 символов) ← ❌ >160
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: description 217 символов (лимит 160). Нет в skills.entries.

### root-cause-archaeologist
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "v1.1" ← ❌ не семвер
- description: есть (82 символа)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: version "v1.1" — не семвер (ведущий "v"). Нет в skills.entries.

### safe-restart
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "2.0.0"
- description: есть (163 символа) ← ❌ >160
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: description 163 символа (лимит 160). Нет в skills.entries.

### skill-manager
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "2.0.0"
- description: есть (131 символ)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: Нет в skills.entries.

### starting-session
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: есть
- status в frontmatter: active
- version: "3.0.0"
- description: есть (116 символов)
- В entries (openclaw.json): нет ← ❌
- user-invocable: true
- Проблемы: Нет в skills.entries.

### skill-creator
- Статус: ❌ ПРОБЛЕМА
- SKILL.md: нет (папка отсутствует) ← ❌
- status в frontmatter: отсутствует
- version: отсутствует
- description: отсутствует
- В entries (openclaw.json): нет ← ❌
- user-invocable: отсутствует
- Проблемы: Папка скила полностью отсутствует на диске. Скил заявлен в системе (упоминается в списке доступных скилов) но файлов нет. Скил есть в allowBundled но фактически не установлен.

---

## Итоговая сводка

- **Всего скилов (на диске):** 16
- **Полностью валидных:** 0
- **С проблемами:** 16
- **Отсутствуют (skill-creator):** 1

### Типичные проблемы (группировка)

#### 🔴 Отсутствует в `openclaw.json` → `skills.entries` (15 из 16)
**Единственный скил в entries:** manus-outsourcing.
Нужно зарегистрировать в entries все кастомные скилы:
- 300-vision, accepting-work, anti-loop, change-management, colony-disk-exchange, deep-dive, ebsh, fact-check, finishing-session, gitlab, registering-incident, research, root-cause-archaeologist, safe-restart, skill-manager, starting-session

#### 🔴 Description > 160 символов (9 скилов)
- anti-loop (178), change-management (169), colony-disk-exchange (223), gitlab (206), manus-outsourcing (258), registering-incident (184), research (217), safe-restart (163)

#### 🔴 Не семвер-формат version (3 скила)
- deep-dive: "v1.1" → должно быть "1.1.2" или "1.1.0"
- root-cause-archaeologist: "v1.1" → должно быть "1.1.0" или "1.1.1"
- manus-outsourcing: 2.0.0 (без кавычек, но текст) → должно быть "2.0.0" (не semver X.Y.Z так как нет patch)

#### 🔴 Нет `user-invocable` (2 скила)
- 300-vision, manus-outsourcing

#### 🔴 Полностью отсутствует (1 скил)
- skill-creator: папка не создана, хотя заявлен в системе и есть в allowBundled

#### 🟡 Имя не совпадает с ключом в entries (1 скил)
- gitlab: в entries как "git-lab", папка называется "gitlab" — конфликт имён

---

## Рекомендации по приоритету

1. **Критично — регистрация в entries:** Добавить все 16 кастомных скилов в `openclaw.json → skills.entries` (с `enabled: true`)
2. **Критично — skill-creator:** Создать папку и SKILL.md
3. **Высокий — description:** Сократить description до ≤160 символов в 9 скилах
4. **Высокий — version:** Исправить формат version в deep-dive, root-cause-archaeologist (убрать "v"), manus-outsourcing (добавить patch и кавычки)
5. **Средний — user-invocable:** Добавить `user-invocable: true` в 300-vision и manus-outsourcing
6. **Средний — gitlab/git-lab:** Убрать дублирование (gitlab в папках vs git-lab в entries)
