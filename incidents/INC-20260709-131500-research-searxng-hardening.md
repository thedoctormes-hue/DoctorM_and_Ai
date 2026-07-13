---
id: INC-20260709-131500-research-searxng-hardening
timestamp: "2026-07-09T13:15:00Z"
category: tech
type: other
severity: high
status: closed
agent: unknown
title: "INC-20260709-131500 — /research: verify-bug + SearXNG fragility (доведено до идеала)"
---

# INC-20260709-131500 — /research: verify-bug + SearXNG fragility (доведено до идеала)

**Дата:** 2026-07-09 13:15 МСК
**Серьёзность:** high (рецидив PAT-005 в первом прогоне verify)
**Статус:** resolved

## Контекст
ЗавЛаб указал: в первом пошаговом прогоне скила `verify` ничего не вышло — значит в
чеклисте скила есть дефект. Дальше: стать профи по SearXNG, довести `/research` и
веб-поиск агентов лаборатории до идеала.

## Корневые причины и фиксы (Фазы A–D)

### A. SearXNG контейнер падал и не поднимался
- **Причина:** `RestartPolicy=no` + OOM (SIGKILL/137) → любой сбой гейтвея/перезапуск
  оставлял контейнер мёртвым → `searxng_urls=0` → verify всегда `unverified`.
- **Фикс:** `docker update --restart=unless-stopped searxng`; курированный
  `searxng/settings.yml` (DDG + keyless фоллбэки `mojeek`/`wiby`/`marginalia`/`bing` +
  `wikipedia`/`wikidata`; `server.limiter: false`; botdetection off); healthcheck
  `bin/searxng-health.sh` (results>0 → OK). Воспроизводимость: `docker-compose.searxng.yml`.
- **Commit:** `a8a0f3c` (free-api-hunter).

### B. verify ложно падал в unverified при недоступном источнике
- **Фикс:** `verify_research()` различает `searxng_unavailable` / `tavily_unavailable` /
  `both_sources_unavailable` от `unverified_synthesis`. Провайдеры: явный `401/429/
  Unauthorized` = временный бан (backoff 2s, пометка `provider_temp_banned`), НЕ
  «мёртвые ключи».
- **Commit:** `824c78c`.

### C. deep_research отдавал пустой answer
- **Причина:** `merge_results` берёт только список результатов; поле `answer` никогда не
  наполнялось.
- **Фикс:** добавлен `synthesize` в `process.py` (предпочитает готовый `answer`, иначе
  синтезирует из топ-5 результатов) + прокинут в `deep_research_v2`.
- **Commit:** `f63e409`.

### Ранее (этот же цикл): verify_research() терял ответ Tavily
- **Причина:** `echo "$tj" | python3 - "$fj" "$threshold" <<'PY'` — heredoc перекрывал pipe,
  `sys.stdin.read()` был пуст → `json.loads("")` → всегда `tavily_unavailable_or_invalid`.
- **Фикс:** ответы пишутся во временные файлы (mktemp), python читает через `open(...)`.
- **Commit:** `b315dc5`.

## Проверка (live, end-to-end)
- `verify` при живом SearXNG → `verified: True` (tavily 5, searxng 10).
- `verify` при остановленном SearXNG (симуляция) → `status: searxng_unavailable`,
  `searxng_available: False` — НЕ `unverified_synthesis`. Грейсфул-деградация работает.
- `deep_research` → `answer` заполнен («Synthesized from 27 aggregated sources…»).
- SearXNG healthcheck → `OK 23`.

## Уроки (PAT-005)
1. «Первый прогон не вышел» ≠ «скил сломан». Искать реальный дефект в коде, а не
   списывать на ключи/провайдеров.
2. Контейнер без `RestartPolicy=unless-stopped` — хрупкость сама по себе.
3. `echo $x | python3 - … <<'PY'` — классическая ловушка: heredoc глушит stdin от pipe.
4. Soft-ban (401/429) провайдера ≠ мёртвые ключи. Различать в коде.
5. DDG в SearXNG периодически выдаёт CAPTCHA → держать keyless фоллбэк-движки.
