# Context API v1.2.0 — Security Audit Report

**Дата:** 2026-05-23
**Проверяющий:** OWL (Security Analyst)
**Scope:** Все исходные файлы, конфигурация, systemd unit

---

## Executive Summary

Сервис значительно улучшен после v1.1.0. Path traversal устранён, добавлена валидация ID, исправлен CORS. Остаются 2 MEDIUM и 3 LOW находки.

---

## Scoring

| Категория | Балл | Комментарий |
|-----------|------|-------------|
| Input Validation | 8/10 | validate_id() в place, glob больше не используется напрямую |
| Transport Security | 7/10 | localhost only, но нет TLS (приемлемо для loopback) |
| Auth & Access | 6/10 | API key через env var, но default значение захардкожено |
| Error Handling | 8/10 | Обработка OK, нет stacktrace leak |
| Systemd Hardening | 9/10 | NoNewPrivileges, ProtectSystem, MemoryMax, CPUQuota |

---

## Findings

### MEDIUM-1: Health endpoint отдаёт версию в открытом виде

**Файл:** `routers/health.py`

**Описание:** Health endpoint возвращает `"version": "1.1.0"` (устаревшая версия). Информация о версии может помочь атакующему искать известные уязвимости.

**Риск:** MEDIUM — информация о версии облегчает targeted attacks.

**Рекомендация:**
- Убрать версию из health endpoint
- Или обновить до `"1.2.0"`

### MEDIUM-2: FastAPI тестовый клиент не проверяет API key middleware

**Файл:** `tests/test_api.py`

**Описание:** API key добавлен в main.py, но тесты не проверяют сценарии с отсутствующим/невалидным ключом. Текущие 149 тестов используют `TestClient` который не проходит через full middleware stack.

**Риск:** MEDIUM — false sense of security, возможны непротестированные edge cases.

**Рекомендация:**
- Добавить тесты на 403 при отсутствующем/невалидном API key
- Добавить тест на 200 при валидном ключе

### LOW-1: Rate limiter memory leak

**Файл:** `common.py` — `RateLimiter._requests`

**Описание:** Словарь `_requests` хранит все timestamps для всех клиентов бессрочно. При большом количестве уникальных client IPs (даже на localhost) возможна утечка памяти.

**Риск:** LOW — на localhost маловероятно, но при долгой работе возможно.

**Рекомендация:**
```python
def cleanup_old_clients(self, max_age: int = 3600):
    """Remove clients with no recent requests."""
    now = time.time()
    stale = [k for k, v in self._requests.items()
             if v and now - v[-1] > max_age]
    for k in stale:
        del self._requests[k]
```

### LOW-2: Health endpoint не имеет rate limiting

**Файл:** `routers/health.py`

**Описание:** `/health` не имеет `Depends(check_rate_limit)`. Корректно для health checks (иначе LB не сможет проверять при превышении лимита), но polluting rate limiter state.

**Риск:** LOW — design decision, документировать.

**Рекомендация:** Добавить в docstring осознанное решение об отсутствии rate limiting.

### LOW-3: Response Content-Type не всегда согласован

**Файлы:** `routers/adr.py`, `routers/patterns.py`

**Описание:** ADR get возвращает `response_class=PlainTextResponse`, patterns get — обычный JSON. Оба возвращают markdown. Непоследовательно.

**Риск:** LOW — не влияет на безопасность, но усложщает клиентский код.

**Рекомендация:** Унифицировать response_class для всех «get by ID» эндпоинтов.

---

## Устранённые находки (v1.1.0 → v1.2.0)

| # | Находка v1.1.0 | Статти| Исправление |
|---|----------------|--------|-------------|
| C-1 | Path traversal через glob в ADR/Patterns/Sessions | ✅ Устранено | validate_id() + точное совпадение |
| C-2 | Отсутствие аутентификации | ✅ Устранено | API key через env var CONTEXT_API_KEY |
| I-1 | CORS wildcard не работает | ✅ Устранено | Явные origins |
| I-2 | Metrics не учитывал errors | ✅ Устранено | Middleware считает все запросы |
| S-4 | Project parser fragile | ✅ Устранено | startswith + line[3:] |

---

## Secure Configuration Checklist

- [x] Path traversal protection (validate_id + exact glob)
- [x] API key authentication (env var)
- [x] Rate limiting (sliding window, 120 req/min)
- [x] CORS restricted (explicit origins)
- [x] Security headers (X-Response-Time, etc.)
- [x] systemd hardening (NoNewPrivileges, ProtectSystem, MemoryMax, CPUQuota)
- [x] Error handling (no stacktrace leak)
- [ ] TLS (N/A — localhost only)
- [ ] Rate limiter cleanup (рекомендация LOW-1)

---

## Заключение

Context API v1.2.0 готова к production на localhost. Критических уязвимостей не обнаружено. Рекомендации MEDIUM/LOW можно исправить в следующем релизе.

**Overall Security Score: 7.5/10** (было 5/10 в v1.1.0)

---

*Отчёт подготовлен OWL (Security Analyst), 2026-05-23*
