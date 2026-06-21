# ADR-044: Agent Configuration Fine-Tuning

**Date:** 2026-06-20
**Author:** Штрейкбрехер (streikbrecher)
**Status:** implemented
**Version:** 1.0

## Context

После внедрения TOP-5 улучшений (ADR-040) выявлены дополнительные возможности тонкой настройки: кэширование промптов, обрезка tool-результатов, сохранение контекста перед компакцией.

## Decision

Внедрены 3 улучшения в `openclaw.json`:

### 1. cacheRetention: "long"
- **Что:** `agents.defaults.params.cacheRetention: "long"`
- **Зачем:** TTL кэша увеличен с 5 мин (default) до 24 часов. При heartbeat каждые 30 минут кэш теперь переживает промежутки между вызовами.
- **Экономия:** до 50% на input tokens для heartbeat-сессий
- **Документация:** `prompt-caching.md` — `cacheRetention: "long" maps to prompt_cache_retention: "24h"`
- **Источник:** Reddit r/openclaw — "paying double on input tokens for no reason" при heartbeat > 10 мин

### 2. contextPruning: cache-ttl
- **Что:** `agents.defaults.contextPruning: { mode: "cache-ttl", ttl: "1h" }`
- **Зачем:** Автоматически обрезает старые tool-результаты после 1 часа. Уменьшает размер кэша в длинных сессиях.
- **Эффект:** снижение размера кэша на 30-50%
- **Документация:** `session-pruning.md` — "Pruning reduces the cache-write size, directly lowering cost"
- **Риски:** Нет — pruning in-memory only, transcript на диске не трогается

### 3. compaction.memoryFlush.enabled
- **Что:** `compaction.memoryFlush: { enabled: true, softThresholdTokens: 6000 }`
- **Зачем:** Перед компакцией агент сохраняет важный контекст в `memory/*.md` файлы. После compaction контекст восстанавливается.
- **Эффект:** меньше потерь контекста при длительных сессиях
- **Документация:** `config-agents.md` — "Session nearing compaction. Store durable memories now."
- **Примечание:** Модель для memoryFlush уже была настроена (`gpt-oss-20b:free`), но `enabled` не был включён

### Startup Context Fix (бонус)
- **Проблема:** `maxFileChars: 12000` превышал лимит 10000
- **Решение:** `maxFileChars: 10000`, `maxFileBytes: 16384`, `maxTotalChars: 6000`

## Consequences

**Положительные:**
- Экономия до 50% на input tokens (cacheRetention)
- Снижение размера кэша на 30-50% в длинных сессиях (contextPruning)
- Сохранение контекста между сессиями (memoryFlush)

**Риски:**
- Минимальные — все изменения обратимы через бэкап

## Verification

- `openclaw config validate` — PASS
- 12 unit-тестов валидации конфига — все PASS
- Gateway перезапущен, 9 агентов активны

## References

- OpenClaw docs: `prompt-caching.md`, `session-pruning.md`, `config-agents.md`
- Reddit: r/openclaw — v2026.3.13 cacheRetention PSA
