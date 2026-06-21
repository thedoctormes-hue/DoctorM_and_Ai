---
type: pattern
id: PAT-004
title: 'PAT-004: Мерж вместо перезаписи при сохранении состояния'
status: active
author: system
created: 2026-05-24 21:07:07+00:00
updated: 2026-06-18
last_verified: 2026-06-18
confidence: outdated
source: manual
tags:
- pattern
- migrated
code_refs:
- projects/myrmex-control/server-dist/myrmex.js
freshness_score: 99
last_checked: '2026-06-20T01:00:32+00:00'
---
# PAT-001: Мерж вместо перезаписи при сохранении состояния

## Категория
architecture

## Контекст
Когда сервис сохраняет состояние в файл (JSON, YAML, БД), а файл может быть отредактирован извне. Прямая перезапись уничтожает данные, которые не загружены в память процесса.

## Решение
При сохранении состояния — мержить с существующим файлом, а не перезаписывать:
1. Прочитать текущий файл
2. Прочитать состояние из памяти
3. Смержить: поля из памяти перезаписывают поля файла, но поля файла которых нет в памяти — сохраняются
4. Записать результат

## Примеры
```javascript
// ПЛОХО: полная перезапись
fs.writeFileSync('state.json', JSON.stringify(memoryState));

// ХОРОШО: мерж
const diskState = JSON.parse(fs.readFileSync('state.json', 'utf8'));
const merged = { ...diskState, ...memoryState };
fs.writeFileSync('state.json', JSON.stringify(merged, null, 2));
```

## Критерии применимости
- [ ] Сервис хранит состояние в файле
- [ ] Файл может быть отредактирован извне
- [ ] Не все поля состояния загружены в память

## Связанные артефакты
- RUL-003 — Запрет прямого редактирования myrmex.json
- BL-012 — Исправление writeState()
- INC-20260512111530 — Потеря users в myrmex.json

## Примечание
Инцидент: `writeState()` в myrmex.js полностью перезаписывал myrmex.json из памяти процесса. Поля `users` и `refresh_tokens` отсутствовали в памяти → были потеряны.
