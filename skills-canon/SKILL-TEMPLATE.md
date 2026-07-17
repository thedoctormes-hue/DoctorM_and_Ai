---
name: "{{NAME}}"
description: "{{ONE_LINE_DESCRIPTION_MAX_160_BYTES}}"
version: "1.0.0"
author: "{{AUTHOR_AGENT}}"
last_reviewed: "{{YYYY-MM-DD}}"
status: "active"
user-invocable: true
triggers:
  phrases: ["{{PHRASE_1}}", "{{PHRASE_2}}"]
  patterns: ["{{PATTERN_1}}", "{{PATTERN_2}}"]
  scope: ["{{SCOPE_1}}", "{{SCOPE_2}}"]
metadata:
  openclaw:
    requires:
      bins: ["{{BIN_1}}", "{{BIN_2}}"]
      env: ["{{ENV_1}}", "{{ENV_2}}"]
      config: ["{{CONFIG_1}}"]
    primaryEnv: "{{PRIMARY_ENV_OR_NA}}"
---

# {{DISPLAY_NAME}} — {{SHORT_TAGLINE}}

## Когда применять
- {{TRIGGER_1_CONCRETE_SIGNAL}}
- {{TRIGGER_2_CONCRETE_SIGNAL}}
- {{TRIGGER_3_CONCRETE_SIGNAL}}

## Границы применимости
- {{NOT_DO_1_ANTI_SCOPE}}
- {{NOT_DO_2_DEPENDENCY_BOUNDARY}}
- {{NOT_DO_3_TOOL_LIMITATION}}

## Чек-лист качества
- [ ] {{QUALITY_CHECK_1_VERIFIABLE}}
- [ ] {{QUALITY_CHECK_2_VERIFIABLE}}
- [ ] {{QUALITY_CHECK_3_VERIFIABLE}}
- [ ] {{QUALITY_CHECK_4_VERIFIABLE}}

## Анти-паттерны
- {{ANTI_PATTERN_1_LINK_INC_PAT}}
- {{ANTI_PATTERN_2_LINK_INC_PAT}}
- {{ANTI_PATTERN_3_LINK_INC_PAT}}

---

> **Инструкция для генератора (skill-creator/skill-manager):**
> 1. Заменить ВСЕ плейсхолдеры `{{...}}` на реальные значения
> 2. Удалить этот блок комментария
> 3. Проверить YAML frontmatter: `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]).read().split('---')[1])" SKILL.md`
> 4. Проверить наличие всех 4 секций тела: grep -E '^## (Когда применять|Границы применимости|Чек-лист качества|Анти-паттерны)$' SKILL.md | wc -l  # должно быть 4
> 5. После создания — запустить skill_workshop для регистрации
