---
name: cascade
description: "Параллельное исследование темы через подборку релевантных агентов. Каждый агент ищет в вебе, пишет отчёт в pool, оркестратор синтезирует. Use when: нужно масштабное исследование, сравнение подходов, сбор best practices. NOT for: простые вопросы (use general-purpose), быстрый поиск (use explore), единичные задачи."
location: user
version: 6.0.0
category: orchestration
triggers: ["/cascade", "каскад", "cascade research", "исследуй", "изучи"]
requiredTools: [agent, write_file, read_file, glob]
---

# Cascade v6.0.0 — Relevant Agent Research

## Назначение
Параллельное исследование темы через **подборку релевантных агентов**. Оркестратор решает кого запускать на основе темы.

## Архитектура
1. **Analyze** — определить тему и подобрать релевантных агентов
2. **Init** — создать pool директории (mkdir -p)
3. **Spawn** — semaphore(6) + backoff: `agent <type> ... is_background=true`
4. **Synthesize** — прочитать pool/*.md, создать synthesis
5. **Output** — одно финальное сообщение

## Выбор агентов (NEW v6.0)

**НЕ запускай всех подряд.** Подбирай релевантных на основе темы:

1. Проанализируй тему исследования
2. Из доступных агентов выбери тех, чья специализация пересекается с темой
3. Минимум 2-3 агента, максимум 8-10 (не больше!)
4. Для широких тем ("best practices") — бери разных специалистов
5. Для узких тем ("VPN latency") — только профильных

**Доступные агенты:** используй полный список из системного промпта (agent tool descriptions). Не ограничивайся захардкоженным перечнем — список агентов может расти.

## Tools
- `agent` — spawn с `is_background: true` (ОБЯЗАТЕЛНО)
- `write_file` — создание директорий и файлов
- `read_file` — чтение результатов
- `glob` — поиск файлов

## Error Handling
- Retry ×2 с экспоненциальным backoff
- Fallback на sequential mode при падении
- Логирование в pool/errors.log

## Examples
```bash
# Узкая тема — 2-3 профильных агента
/cascade "VPN latency optimization"
# → vpn-infrastructure-agent, devops-engineer, data-scientist

# Широкая тема — 5-7 разных специалистов
/cascade "oauth security best practices"
# → security-audit, security-auditor, code-reviewer, skill-architect, docs-writer

# Pool: /root/LabDoctorM/cascade/pool/20260525_1430-oauth-security/
# Synthesis: /root/LabDoctorM/archive-labdoctorm/20260527/cascade-synthesis/20260525_1430-oauth-security.md
```


## 🔮 Маркировка инсайтов

При обнаружении инсайта в процессе работы, в конце вывода добавляй маркер:

```
[INSIGHT: <тип>] <краткое описание>
[layer: <rules|memory|skills|backlog|agents>]
[source: <откуда инсайт>]
```

## Границы
- Только финальное сообщение: "Каскад завершён..."
- Никаких промежуточных выводов в чат
- **Релевантность > количество** — 2-3 правильных агента лучше чем 26 случайных
