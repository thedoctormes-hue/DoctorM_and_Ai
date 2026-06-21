# ADR 039: Улучшения конфигурации агентов OpenClaw

**Дата:** 2026-06-20
**Автор:** kotolizator (по запросу ЗавЛаба)
**Статус:** applied

## Контекст

Аудит конфигурации агентов выявил 5 областей для улучшения. Все проверены документацией OpenClaw.

## Решения

### 1. Удаление мусорных директорий агентов

Удалены 3 незарегистрированные директории в `/root/.openclaw/agents/`:
- `cat/` — тестовый агент, 1 сессия от 18.06, 450KB trajectory
- `streikbreher/` — опечатка от streikbrecher, пустой sessions.json
- `streikbrekh/` — опечатка от streikbrecher, SQLite 131KB

Все три без bindings, не влияли на работу.

### 2. bootstrapTotalMaxChars: 120000

**Было:** не задано (дефолт 60000)
**Стало:** 120000

**Обоснование:** У owl (116 файлов) и streikbrecher (84 файла) суммарный bootstrap-контекст превышает 60K. Документация рекомендует увеличивать для агентов с большими workspaces.

### 3. startupContext: увеличены лимиты

**Было:** maxTotalChars=6000, maxFileChars=4000, maxFileBytes=16384
**Стало:** maxTotalChars=30000, maxFileChars=12000, maxFileBytes=65536

**Обоснование:** 6K суммарно — только 1 файл memory. После /reset агент теряет контекст. Документация: startupContext используется при new/reset для восстановления контекста.

### 4. Heartbeat для координаторов

**Добавлено для kotolizator и owl:**
```json5
{
  "heartbeat": {
    "every": "30m",
    "target": "telegram",
    "directPolicy": "allow"
  }
}
```

**Обоснование:** Документация рекомендует 30m для API-key auth. Проактивная проверка памяти, уведомления. Расход ~2-5K токенов на heartbeat.

### 5. toolResultMaxChars: 64000 для разработчиков

**Добавлено для streikbrecher и antcat:**
```json5
{
  "contextLimits": {
    "toolResultMaxChars": 64000
  }
}
```

**Обоснование:** 32K потолок обрезает большие логи/диффы. Документация: 64K рекомендуется для моделей с 100K+ context при работе с большими выводами.

## Влияние

- Нет критических изменений
- Heartbeat добавляет ~2-5K токенов каждые 30m для 2 агентов
- Увеличение context limits улучшает восстановление после reset
- Удаление мусора освобождает дисковое пространство

## Связанные

- ADR 028: openclaw-json-agent-registry
- ADR 024: channel-config-evolution
- OpenClaw docs: /gateway/configuration.md, /gateway/config-agents.md
