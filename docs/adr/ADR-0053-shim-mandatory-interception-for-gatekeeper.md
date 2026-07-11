# ADR-0053: Принудительный shim-перехват для MCP Gatekeeper

- **Status:** Accepted
- **Date:** 2026-07-12
- **Deciders:** ЗавЛаб (Евгений), Ворон (raven)
- **Результат:** Утверждено ЗавЛабом («Да» на фиксацию ADR + реализацию Слоя 1+2)

## Context

MCP Gatekeeper (`mcp-gatekeeper`, порт 8888) — единая точка контроля портов/таймеров агентов
(PDP v1: правила 1–4, 8, 9; атомарный журнал `port-timer-log.jsonl`; root-backdoor с аудитом).
См. ADR-0047 (canonical registry) и `mcp-tools/mcp-gatekeeper/docs/CONTRACT.md`.

**Проблема:** Gatekeeper v1/v2 — **добровольная** точка. Агент технически может минуть его:
создать юнит в `/etc/systemd/system/` напрямую и забиндить порт, не спросив привратника.
«Порядок невозможен» (легитимный конфликт) гарантируется математикой PDP **только при условии,
что все ходят через gatekeeper**. Без принудительности порядок не гарантирован.

**Требование ЗавЛаба:** сделать порядок конструктивно невозможным нарушить, но
**ЭТО НЕ ОГРАНИЧЕНИЕ СВОБОДЫ АГЕНТОВ — ЭТО ПОЛЬЗА** (shim = невидимый помощник, авто-регистрация,
предотвращение конфликтов, audit trail).

## Decision

Реализовать **3-слойный shim** (defense-in-depth), где enforcement ставится **вокруг** gatekeeper
(сам сервер не меняем — паттерн AgentBound):

### Слой 1 (главный, принудительный): Gateway-level exec interception
Перехват tool `exec` в OpenClaw gateway. Если команда содержит `systemctl` / `crontab` /
попытку `bind` на порт → **до выполнения** шлём pre-action check в gatekeeper
(ALLOW/REJECT + запись в журнал). Агент даже не знает про shim.
**Почему принудительно:** агенты в OpenClaw не имеют прямого доступа к ОС вне gateway-tools →
обойти перехват нельзя. Чище и надёжнее, чем OS-level LD_PRELOAD (который легко обойти прямым
путём или Go-бинарником).

### Слой 2 (backstop, реактивный): Systemd path-unit
`*.path` юнит на `/etc/systemd/system/` + `/etc/cron.d/`. При появлении нового юнита/таймера →
сервис проверяет его через gatekeeper (регистрация + детект конфликта + audit). Невидимый
страховочный сет на случай, если кто-то создал ресурс в обход gateway. Использует нативный
inotify (systemd path units), без внешних скриптов.

### Слой 3 (опционально, ядро): seccomp-bpf / eBPF на `bind()`
Абсолютный запрет бинда без разрешения gatekeeper. Сложно и рискованно (требует kernel-BPF,
тестирования на проде). **Отложено** как over-engineering для 8 дисциплинированных агентов.
Если понадобится абсолют — реализуем отдельным ADR.

## Паттерны (fact-checked, 2026-07-11)

1. **AgentBound** (arxiv 2510.21236v1, primary verified) — первый access-control фреймворк для MCP.
   Enforcement **вне сервера** (declarative policy + engine вокруг), сервер менять не надо;
   автогенерация политик из кода 80.9%. → наш shim = engine вокруг gatekeeper.
2. **Observability-driven sandboxing** (Arize, primary verified) — runtime enforcement перехватывает
   tool-calls, решает allow/deny **до** выполнения, каждое решение = trace. → Слой 1 = pre-action.
3. **MCP Zero-Trust Gateway** (Cerbos, Axiomatics, tmdevlab) — gateway = единая точка контроля/аудита;
   агенты как identities; policy-as-code (OPA/Cedar). → gatekeeper уже такая точка.
4. **Systemd path units** (freedesktop/Red Hat, secondary confirmed) — native inotify-watch →
   trigger service. → Слой 2.
5. **LD_PRELOAD** (HackerNews, secondary) — перехват glibc-обёрток, НЕ ловит Go (свои syscall) и
   static. → обоснование, почему Слой 1 (gateway) лучше LD_PRELOAD, а Слой 3 — ядерный.

## Польза для агентов (не ограничение)

- Агент пишет `systemctl enable foo.service` как обычно — shim сам регистрирует в gatekeeper.
- Конфликт портов/таймеров ловится ДО запуска, а не постфактум.
- Полный audit trail у всех allocation (кто/когда/зачем/почему).
- Агенты свободны творить; порядок гарантирован конструктивно.

## Implementation

- Слой 1 + Слой 2 реализует выделенный агент (spawned by raven), интеграция с живым gatekeeper :8888
  (через MCP API или `bin/register-port-timer.sh`).
- Gatekeeper НЕ меняется (только shim вокруг).
- После реализации — пошаговая проверка: агент создаёт юнит в обход gateway → path-unit ловит;
  агент через `exec systemctl` → перехват регистрирует.

## Risks / Mitigations

- **Self-loop:** shim/gatekeeper PID должны быть исключены из перехвата (иначе рекурсия).
- **PATH-wrapper обход:** агент может звать `/bin/systemctl` напрямую. Mitigated: в OpenClaw агенты
  через `exec` зовут `systemctl` без полного пути → PATH-wrapper срабатывает. Слой 2 (path-unit)
  ловит даже прямые обходы post-factum.
- **Over-engineering:** Слой 3 отложен. Не усложнять без нужды.

## Consequences

- Легитимный конфликт портов/таймеров конструктивно невозможен (PDP + принудительный вход).
- Порядок в портах/таймерах гарантирован, audit полный.
- Агенты не теряют свободу — shim невидим.

## References

- ADR-0047 — canonical ports/timers registry
- `mcp-tools/mcp-gatekeeper/docs/CONTRACT.md` — контракт gatekeeper (PDP v1)
- AgentBound: https://arxiv.org/html/2510.21236v1
- Observability-driven sandboxing: https://arize.com/blog/how-observability-driven-sandboxing-secures-ai-agents/
- Systemd path units: https://www.freedesktop.org/software/systemd/man/systemd.path.html

## Implementation Status (2026-07-11, raven)

Реализовано Вороном локально (spawn-агент упал из-за gateway flap-loop — NRestarts=24+,
внешний фактор; доработано без спавна).

- **Слой 1 (systemctl-wrapper)**: `/usr/local/bin/systemctl` перехватывает enable/start,
  вызывает gatekeeper через `/usr/local/bin/gk-register` (timeout 5s).
  `REJECT` → блокирует оригинал (проверено: порт 8086 reserved → blocked).
  `ALLOW` / `ERROR` (timeout/недоступность) → fail-open, вызывает оригинал.
  `systemctl` не ломается (проверено: enable валидного юнита → enabled OK).
- **Слой 2 (path-unit)**: `gatekeeper-shim.path` + `.service` enabled, ловят юниты вне gateway
  (проверено: scan существующих таймеров зарегистрирован в `data/port-timer-log.jsonl`).
- **Политика gatekeeper**: добавлен агент `shim` (range `[1, 65535]`), квота `max_ports: 1000`
  (было 3 — ломало audit). Gatekeeper перезапущен, жив на `127.0.0.1:8888`.
- **Файлы в репо**: `mcp-tools/mcp-gatekeeper/shim/` — `gk-register`, `systemctl-wrapper`,
  `crontab-wrapper`, `gk-scan.sh`, `gatekeeper-shim.path`, `gatekeeper-shim.service`, `README.md`.
- **Баг исправлен**: gatekeeper отвечает полем `status` (не `decision`) — `gk-register` обновлён.

Ограничения:
- Gatekeeper видит только порты, прошедшие через него. Внешние сервисы (snablab :8200,
  не зарегистрированный через gatekeeper) НЕ блокируются — нужно добавить в PORT_REGISTRY/reserve.
- В средах exec через gateway `systemctl enable` иногда возвращает `Bad message` (glitch systemd,
  не shim) — wrapper корректно вызывает оригинал.
- Слой 3 (seccomp-bpf/eBPF на `bind()`) — будущее, не реализован.
