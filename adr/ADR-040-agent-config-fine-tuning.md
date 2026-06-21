# ADR 040: Тонкая настройка конфигурации агентов OpenClaw

**Дата:** 2026-06-20
**Автор:** kotolizator (по запросу ЗавЛаба)
**Статус:** applied

## Контекст

После внедрения базовых улучшений (ADR 039) проведён дополнительный аудит с фактчекингом документации OpenClaw. Выявлены 3 области для тонкой настройки.

## Решения

### 1. Явно заданные дефолтные параметры модели

**Было:** 8 параметров модели не заданы (None), использовались скрытые дефолты OpenClaw.
**Стало:**

```
contextTokens: 200000
maxConcurrent: 3
timeoutSeconds: 600
thinkingDefault: "low"
verboseDefault: "off"
reasoningDefault: "off"
elevatedDefault: "on"
toolProgressDetail: "explain"
```

**Обоснование:**
- Воспроизводимость — поведение не зависит от версии OpenClaw
- Явный контроль над ресурсами для 8 агентов
- `maxConcurrent: 3` — консервативнее дефолта 4, безопаснее для лаборатории
- `timeoutSeconds: 600` (10 мин) — достаточно для любой задачи, при 900с зависший агент ждёт 15 минут

### 2. Compaction safeguard

**Было:** compaction.mode не задан (дефолт safeguard), но без явных настроек qualityGuard.
**Стало:**

```json5
{
  "compaction": {
    "mode": "safeguard",
    "qualityGuard": { "enabled": true, "maxRetries": 1 },
    "identifierPolicy": "strict"
  }
}
```

**Обоснование:**
- `safeguard` — компакция с проверкой качества
- `qualityGuard` — автоматический retry при неудачной компакции
- `identifierPolicy: "strict"` — сохранение ID деплоев, тикетов, host:port без изменений

### 3. Gateway reload hybrid

**Было:** gateway.reload.mode не задан (дефолт hybrid согласно документации).
**Стало:**

```json5
{
  "gateway": {
    "reload": {
      "mode": "hybrid",
      "debounceMs": 300
    }
  }
}
```

**Обоснование:**
- `hybrid` — безопасные изменения мгновенно, критические с автоперезапуском
- `debounceMs: 300` — защита от гонок при редактировании файла
- Явная фиксация для воспроизводимости

## Побочные эффекты

- При gateway рестарте startupContext был сброшен до исходных значений. Исправлено повторным patch.
- Директория `streikbrekh/` была создана gateway при reindex. Удалена. Тест обновлён.

## Тесты

33 теста в `workspaces/kotolizator/tests/test_agent_config.py` — все проходят.

```bash
python3 -m pytest workspaces/kotolizator/tests/test_agent_config.py -v
```

## Связанные

- ADR 039: Улучшения конфигурации агентов OpenClaw
- OpenClaw docs: /gateway/configuration.md, /gateway/config-agents.md
