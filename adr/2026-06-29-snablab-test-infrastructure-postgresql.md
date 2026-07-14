# ADR: Перенос тестов СнабЛаб на PostgreSQL

- **Дата:** 2026-06-29
- **Статус:** accepted
- **Автор:** Бестия
- **Проект:** snablab

## Контекст

Тесты СнабЛаб использовали SQLite как базу для тестов. Это приводило к:
- ошибкам синтаксиса SQLite-specific (GENERATED ALWAYS AS, типы колонок)
- расхождению с production-средой (PostgreSQL)
- проблемам с enum-значениями (SQLite не поддерживает нативные enums)
- невозможности использовать PostgreSQL-специфичные фикстуры

## Решение

Перенести все тесты на PostgreSQL:
- заменить anyio на pytest-asyncio для асинхронных тестов
- рефакторнуть conftest.py: перейти на SAVEPOINT-подход вместо пересоздания БД
- добавить employee fixture для тестов, требующих привязку к сотруднику
- исправить enum-значения под PostgreSQL
- 12 тестовых файлов переключены с app.main на test_app для корректной изоляции БД

## Последствия

- тесты теперь отражают production-поведение
- выше время прогона (PostgreSQL vs in-memory SQLite)
- требуется запущенный PostgreSQL для тестового окружения
- SAVEPOINT-подход быстрее полной пересоздания БД

## Ссылки

- `479a4f9` — switch tests to PostgreSQL, add employee fixture
- `8f4b7b8` — stabilize unit tests, replace anyio with pytest-asyncio
- `cb4d291` — switch tests to PostgreSQL (первый проход)
- `e0a6487` — switch 12 test files from app.main to test_app
