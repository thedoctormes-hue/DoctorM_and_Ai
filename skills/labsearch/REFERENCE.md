# Lab Search — Reference

## Параметры lab_search.py

```bash
# Базовый поиск
python3 {baseDir}/scripts/lab_search.py "<запрос>"

# С лимитами и фильтром по типу
python3 {baseDir}/scripts/lab_search.py "<запрос>" --limit 5 --type adr

# Проверка статуса индекса
python3 {baseDir}/scripts/lab_search.py --status
```

## Типы артектов (--type)

| Тип | Описание | Пример |
|-----|----------|--------|
| `adr` | Architecture Decision Records | Архитектурные решения |
| `pattern` | Паттерны | Паттерны проектирования |
| `rule` | Правила | Правила лаборатории |
| `spec` | Спецификации | Технические спеки |
| `incident` | Инциденты | INC-001, INC-013 и т.д. |
| `metric` | Метрики | Метрики и KPI |

## Score interpretation

| Score | Интерпретация | Действие |
|-------|---------------|----------|
| > 0.7 | Уверенное совпадение | Использовать результат |
| 0.5 – 0.7 | Среднее совпадение | Читать критически |
| < 0.5 | Слабое совпадение | Проверить вручную или уточнить запрос |

## Каверзы

- **Холодный старт Ollama ~12с.** Первый запрос за сессию медленный. Таймаут по умолчанию 35с — не уменьшай. При таймауте просто повтори.
- Индекс пересобирается ночью (systemd-таймер `context-api-reindex`). Свежесть проверяй через `--status`.

## Формат выдачи

Возвращает топ-N: score, тип, ID, заголовок, путь к файлу.

```
0.82 | adr | ADR-001 | Стандартизация скилов | /root/LabDoctorM/adr/ADR-001-...
0.71 | incident | INC-013 | Приватный ключ в git | /root/LabDoctorM/.../incidents/INC-013-...
```

Открывай файл по пути для полного текста, либо тяни через `/api/v1/adr/{id}`.

## Fallback paths

```
context-api (lab_search.py)
    ↓ при ошибке
grep -r -l "<keywords>" /root/LabDoctorM/adr/
                       /root/LabDoctorM/docs/
                       /root/LabDoctorM/projects/*/docs/
    ↓ если пусто
memory_search (query="<запрос>", corpus=all)
    ↓ если пусто
"Ничего не найдено. Попробуй уточнить запрос."
```
