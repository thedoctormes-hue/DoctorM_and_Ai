---
id: INC-20260709-081300-lost-search-keys
timestamp: "2026-07-09T08:13:00Z"
category: tech
type: config_error
severity: high
status: retired
agent: unknown
title: INC-20260709-081300 — Потерян файл ключей поисковых провайдеров
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-20260709-081300 — Потерян файл ключей поисковых провайдеров

- **Дата:** 2026-07-09
- **Тип:** Потеря конфигурации (секреты)
- **Серьёзность:** high (скил `/research` тихо лишился 3 из 4 провайдеров: Tavily, Firecrawl, TinyFish)
- **Статус:** closed (решён восстановлением из бэкапа)

## Описание
В ходе сессии улучшения скила `/research` выяснилось, что `configs/search-keys.yaml`
в проекте `free-api-hunter` физически отсутствует на диске (остался только
`search-keys.yaml.template`). Из-за этого `get_next_key` находил 0 ключей, провайдеры
вызывались с пустым `api_key` → auth-error → код выдавал ярлык `all_keys_exhausted`.

## Первопричина
Не установлена. Файл присутствовал в полном бэкапе
`/root/LabDoctorM/.ops/backups/full/snapshots/20260709_020445/projects/free-api-hunter/configs/search-keys.yaml`
(снимок 02:44), но исчез с диска к ~07:30. Возможно — побочный эффект чисток/тестов
в этой сессии. Требует мониторинга: почему gitignored-секрет исчезает с диска.

## Решение
- Восстановлен `configs/search-keys.yaml` из бэкапа 02:44 (ЗавЛаб дал карт-бланш).
- Файл gitignored — в репозиторий не попадает (секреты защищены).
- Сброшена отравленная статистика адаптивного роутинга `configs/.provider-stats.json`.
- Реальный вызов Tavily API подтвердил: ключи ВАЛИДНЫ, квота НЕ исчерпана.
- `factual` через оркестратор: `provider_used=tavily`, 3 результата + answer.

## Урок
Ярлык `all_keys_exhausted` в коде означает «ключей нет в конфиге», а не «квота
исчерпана». Перед утверждением о состоянии провайдера — делать реальный end-to-end
вызов, а не изолированный тест с неполным окружением.

## Связанные
- memory/2026-07-09.md (хронология сессии + PAT-005 урок)
- free-api-hunter commits 393bae5, 238a5fc
