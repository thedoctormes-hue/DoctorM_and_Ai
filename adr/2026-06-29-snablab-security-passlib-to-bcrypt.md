# ADR: Замена passlib на bcrypt в СнабЛаб

- **Дата:** 2026-06-29
- **Статус:** accepted
- **Автор:** Бестия
- **Проект:** snablab

## Контекст

СнабЛаб использовал passlib для хеширования паролей. passlib:
- давно не поддерживается (последний релиз 2020)
- имел проблемы с совместимостью на новых версиях Python
- добавлял тяжёлую зависимость ради одной функции

## Решение

Прямой переход на bcrypt:
- убрать passlib из зависимостей
- использовать bcrypt напрямую для hash/verify
- миграция существующих хешей через двойную проверку (passlib → bcrypt при логине)
- обновить python-jose и pyasn1 (связанные security-зависимости)
- миграция Pydantic v1 → v2 (ConfigDict вместо class Config)
- multi-stage Dockerfile для уменьшения размера образа
- добавлен CI/CD pipeline

## Последствия

- меньше зависимостей, меньше attack surface
- bcrypt — индустриальный стандарт
- существующие пароли работают через backward-compatibility
- Pydantic v2 — текущий стандарт, лучшая производительность

## Ссылки

- `2974ea4` — replace passlib with bcrypt, Pydantic v2 ConfigDict migration
- `df25c4a` — replace passlib with direct bcrypt, fix Pydantic v2 ConfigDict
