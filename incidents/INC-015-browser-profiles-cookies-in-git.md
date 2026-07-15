---
id: INC-015
timestamp: "2026-05-17T00:00:00Z"
category: tech
type: incident
severity: low
status: retired
agent: owl
title: "INC-015: Cookies и сессии браузер-профилей в git"
author: owl
created: "2026-06-16 07:10:00+00:00"
updated: "2026-06-16 18:00:00+00:00"
tags:
code_refs:
related:
freshness_score: 98
last_checked: "2026-06-20T01:00:20+00:00"
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

# INC-015: Cookies и сессии браузер-профилей в git

## Описание
В git отслеживалось **1354 файла** из `infrastructure/browser-use/profiles/` — это рабочие профили Chromium агента browser-use (habr, habr2, habr3, vcru). Среди них:

- `habr2/auth.json` — **21 cookie** для доменов `.habr.com`, `account.habr.com`, `.yandex.com`, `mc.yandex.com` (валидные сессии входа).
- `habr/`, `habr3/`, `vcru/` — Chromium `Cookies`, `Cookies-journal`, `Session Storage`, `Trust Tokens`, `Sessions/...`.

Файлы присутствуют с первого коммита `dedecf4c` ("initial private release — clean history"). Это **тот же класс проблемы, что INC-013**: секреты (сессионные cookie) в истории git, запушенной в `origin/main`.

## Severity
🟠 **HIGH** — сессионные cookies дают доступ к аккаунтам Habr / vc.ru / Yandex, используемым Hype Pilot для публикаций. Компрометация = возможность постить/действовать от имени аккаунтов. Не CRITICAL (в отличие от ключа VPN), т.к. cookies можно инвалидировать разлогином, и риск ограничен внешними соц-аккаунтами, а не инфраструктурой лаборатории.

## Затронутые данные
- **Путь:** `infrastructure/browser-use/profiles/` (1354 файла)
- **Cookies:** Habr (`account.habr.com`, `.habr.com`), Yandex (`.yandex.com`, `mc.yandex.com`), vc.ru
- **Session Storage / Trust Tokens / Sessions** — Chromium-артефакты сессий

## Хронология
- **2026-05-17** — репозиторий пересоздан с «чистой» историей (INC-004); коммит `dedecf4c` уже содержит профили с cookies.
- **~2026-06-xx** — коммит `db09dde2` добавил `infrastructure/browser-use/profiles/` в `.gitignore` (для будущих файлов), но уже закоммиченные 1354 файла остались tracked.
- **2026-06-16** — при проверке `.gitignore`-находок (сессия owl) обнаружено: правило для профилей в актуальном `.gitignore` **отсутствует** (потеряно при последующей перезаписи `.gitignore`), файлы по-прежнему tracked.

## Статус ремедиации

**Сделано Совой (16.06.2026):**
- ✅ `git rm -r --cached infrastructure/browser-use/profiles/` — 1354 файла убраны из индекса (файлы на диске целы).
- ✅ Восстановлено правило в `.gitignore`: `infrastructure/browser-use/profiles/` (было потеряно после `db09dde2`).
- ✅ Проверено: `git check-ignore` подтверждает игнор, в `git status` профили больше не появляются.

**Сделано ЗавЛабом (16.06.2026, вне CLI — со слов ЗавЛаба, из CLI не верифицируется):**
- ✅ **Ротация сессий:** разлогин сессий Habr, vc.ru, Yandex — утёкшие cookies инвалидированы.

**Сделано Котом (16.06.2026 — подготовка rewrite, проверено на зеркале):**
- ✅ Собран список: 1248 уникальных блобов профилей (1354 пути) + 37 WG-блобов.
- ✅ Комбинированный проход протестирован на зеркале: профили→0, ключи→0,
  HEAD `main` цел (1273→1273 файла). Команда и метод зафиксированы в runbook.
- ⚠️ **Метод для профилей — `--path --invert-paths`, НЕ blob-id**: среди профилей
  пустой блоб `e69de29b`, общий с легит `__init__.py` — strip-by-id снёс бы 16 файлов кода.

**Осталось (высокий blast radius — решение/окно ЗавЛаба):**
- ⏸️ **Rewrite истории git** одним проходом вместе с INC-013 по
  `infrastructure/vpn/wireguard/RUNBOOK-INC-013-history-rewrite.md`, затем
  согласованный force-push. **Блокер:** незакоммиченная работа Бестии в дереве (нужна заморозка).

## Связанные инциденты
- **INC-013** — приватный ключ WireGuard в git (тот же первый коммит `dedecf4c`, тот же rewrite-проход).
- **INC-004** — оригинальная утечка секретов; пересоздание репозитория, не очистившее ни ключ VPN, ни профили.

## Системный вывод
Повтор корневой причины INC-004/INC-013: «чистая история» содержала секреты на момент initial commit. Дополнительно: правило `.gitignore` было добавлено, но потеряно при последующей правке файла — значит `.gitignore` без CI-гейта на секреты не является надёжной защитой. Нужен secret-scan как pre-commit hook / CI (см. ветки `fix/secret-scan-v2`, `fix/secret-scan-archive`).

## Решение

Списан per ADR-0057 (closure-integrity): ранее помечен «closed», но без подтверждённого `## Решение` и `verified: true`. Факт устранения из записи не реконструируется — инцидент списывается как не подтверждённый закрытым, без претензии на решённость. При необходимости переоткрыть и довести отдельно.
