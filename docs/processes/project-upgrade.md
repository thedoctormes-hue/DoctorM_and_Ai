---
name: project-upgrade
description: "Комплексный апгрейд проекта: health-check → тесты → линтеры → README → security → деплой. Use when: нужен полный апгрейд проекта от аудита до деплоя, систематическое улучшение качества. NOT for: точечные улучшения (используй add-linter / add-pytest / create-readme), создание проекта с нуля (используй vibcoding-lab)."
owner: "LabDoctorM"
last_reviewed: 2026-06-21
last_code_change: 2026-05-25
status: active
location: user
version: 3.0.0
category: orchestration
requires: [deprecation-and-migration]
triggers: ["апгрейд проекта", "обнови зависимости", "витамины проекту"]
requiredTools: [read_file, write_file, run_shell_command, grep_search, list_directory, glob]
---

# 🚀 Project Upgrade v3

## Назначение
Комплексный апгрейд проекта: health-check → тесты → линтеры → README → security → деплой.

## ⚠️ ОБЯЗАТЕЛЬНО: ПЕРЕД РАБОТОЙ
1. Прочитай файл `~/.qwen/rules.md` и следуй этим правилам
2. Сделай бэкап перед изменениями: `cp -r <project> <project>.bak`
3. Запуски скиллов — последовательно, не параллельно

## Императивные инструкции

### Шаг 1: Health Check
Выполни project-health-check. Запомни health score.
Если score < 30 — сообщи пользователю, что проект в критическом состоянии.

### Шаг 2: Тесты
Проверь наличие tests/:
```
list_directory("tests/") → если нет → вызови add-pytest
```
Запусти существующие тесты: `pytest tests/ -v`

### Шаг 3: Линтеры
Проверь наличие pyproject.toml или .eslintrc:
```
glob("pyproject.toml") или glob("eslint.config.js") → если нет → вызови add-linter
```

### Шаг 4: README
Проверь наличие README.md:
```
read_file("README.md") → если нет или пустой → создай
```
README должен содержать: название, описание, установку, использование, лицензию.

### Шаг 5: Security
Выполни security-audit. Если найдены утечки — исправь.

### Шаг 6: Зависимости
```bash
# Python
pip install --upgrade -r requirements.txt
# React
npm update
```

### Шаг 7: Деплой (если есть systemd)
Выполни auto-deploy-check.

### Шаг 8: Финальный отчёт
Сравни health score до и после.

## Формат отчёта
```
# Upgrade Report — <project>
| Компонент | Было | Статус |
|-----------|------|--------|
| Health Score | 45/100 | 85/100 |
| Тесты | 0 | 12 test_*.py |
| Линтер | нет | ruff ✅ |
| README | нет | ✅ |
| Security | утечка | ✅ исправлено |
```


## 🔮 Маркировка инсайтов

При обнаружении инсайта в процессе работы, в конце вывода добавляй маркер:

```
[INSIGHT: <тип>] <краткое описание>
[layer: <rules|memory|skills|backlog|agents>]
[source: <откуда инсайт>]
```

## Границы
- НЕ трогай: существующую бизнес-логику без согласия
- Остановись: проект критически важен и нет бэкапа
- НЕ пушь в main без подтверждения

---
*v3.0.0 — императивные инструкции, 2026-05-11*
