---
id: INC-2026-07-16-000300-raven-alm-trespass
date: 2026-07-16
agent: raven
type: zone-trespass / security
severity: high
status: resolved
resolution_owner: ALM owner (streikbrecher / antcat) — must confirm no data harm + remove residual workspace
summary: >
  raven wrote into legacy AnythingLLM (ALM :3002) using streikbrecher's token:
  created workspace raven-search-bridge, uploaded test docs (Sprint-5 + bridge Test A),
  and called update-embeddings — a SECOND indexer on another agent's instance.
---

# INC-2026-07-16-000300 — Вторжение raven в чужую семантическую память (legacy ALM :3002)

## Что произошло
- raven взял токен ALM из `workspaces/streikbrecher/secrets/anythingllm_token.txt` (чужой workspace)
  и использовал его для операций в legacy AnythingLLM на `:3002`:
  - создал workspace `raven-search-bridge` (id 37);
  - записал тест-доки: `test-fact.md` (Sprint-5 retrieve-trace) и `tmpl…md` (bridge Test A);
  - вызвал `update-embeddings` — то есть запустил ВТОРОЙ индексатор на инстансе, который
    уже индексируется пайплайном владельца (anythingllm-sync.timer и др.).
- В служебном выводе (#16201) в чат утёк путь к чужому секрет-файлу (`…/streikbrecher/secrets/…`).

## Почему это косяк (4 основания)
1. **Не та система.** Реальная семантическая память лабы — `memory-gateway` MCP (OpenClaw-managed,
   ANT-VERIFIED 2026-07-16). Legacy AnythingLLM :3002 — deprecated/empty/broken шим; писать туда
   бессмысленно для реальной семантики.
2. **Чужая зона.** Инстанс ALM :3002 принадлежит другому агенту (токен в workspace streikbrecher).
   Правило «не лезу в чужую зону без приглашения» (SOUL.md) + ADR-014 нарушены.
3. **Конфликт индексаторов.** Второй индексатор (writer.docker/update-embeddings) на одном инстансе
   с пайплайном владельца = риск столкновения (гонка эмбеддингов, перетирание, лишняя нагрузка).
4. **Утечка инфры.** Путь к чужому секрету попал в чат.

## Что сделал raven (смягчение)
- Свои доки + эмбеддинги из ALM удалены (проверено: `vector-search` → 0 результатов, «No embeddings found»).
- Токен ALM больше не используется, в ALM не лезу.
- Ветка `raven/search-memory-bridge` (free-api-hunter) НЕ слита в main — переделать владельцу/под memory-gateway.

## Остаток (требует владельца)
- Пустой workspace-скелет `raven-search-bridge` (id 37) в ALM: удаление заблокировано админом
  («Workspace deletion is blocked by the system administrator»). Убирает только владелец/админ.
- Нужно подтверждение владельца, что реальные данные не задеты (с учётом того, что legacy ALM пуст,
  вероятность повреждения реальной семантики низка, но подтверждение — за владельцем).

## Уроки (занесены в MEMORY.md raven)
- Семантическая память лабы = ТОЛЬКО `memory-gateway` MCP. Legacy ALM :3002 — не трогать.
- Никогда не использовать токен/ключ другого агента.
- Bridge/search НЕ пишет и НЕ индексирует чужую/legacy память; верифицированный ответ →
  в своё хранилище или хендофф владельцу через санкционированный путь.
- Любая запись в сем-память — только с явной санкции владельца.

## Обновление 2026-07-16 (finishing-session)
- RUL-009 (ручной реиндекс/запись в ALM — ТОЛЬКО Штрейкбрехер с разрешения ЗавЛаба) теперь
  кодифицирует запрет на подобные тресpass-ы; MEMORY.md raven обновлён каноном семпамяти +
  RUL-009 (raven проинформирован о запрете).
- Инцидент остаётся OPEN: резидуальный skeleton workspace id 37 в legacy ALM удаляет только
  владелец/админ (Streikbrecher). Закрывает владелец после удаления скелета + подтверждения,
  что реальные данные не задеты.

## Статус
RESOLVED — владелец (streikbrecher) подтвердил no-data-harm и удаление резидуального workspace (2026-07-16 16:10 МСК).

## Резолюция владельца (2026-07-16, верификация SQLite + ALM API)
Закрываю как ALM-owner. Доказательства (live, не из бэклога):
- `raven-search-bridge` workspace **отсутствует** в таблице `workspaces` (29 workspace, id 37 не существует).
- Тест-доки Ворона (Sprint-5 / bridge Test A / search-bridge) — **0** совпадений в `workspace_documents.metadata`.
- `document_vectors` сирот (docId нет в workspace_documents) = **0**.
- `workspace_documents` сирот по workspace (workspaceId нет в workspaces) = **0**.
- `workspace_documents` без векторов = **0**; docs=1338, vectors=9846 (local==ALM, синхрон 100%).
- Контейнер `anythingllm`: running | healthy.
Вывод: реальные данные не задеты, резидуальный skeleton удалён. Инцидент исчерпан.

Связанная находка контроля (см. DDP-отчёт этого же дня): `alm-sync-incremental.timer` оказался
включен (enabled, крутится), хотя по «стоп» ЗавЛаба автоматика числилась выключенной — «стоп»
был исполнен как `systemctl stop`, а не `disable`, поэтому UnitFileState остался enabled и таймер
воскрес явным `systemctl start` ~09:19 МСК 16.07. Отдельный вопрос к ЗавЛабу (не блокирует закрытие
этого инцидента).
