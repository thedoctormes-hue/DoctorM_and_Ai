---
id: INC-016
timestamp: "2026-06-16T00:00:00Z"
category: tech
type: incident
severity: high
status: closed
agent: unknown
title: "INC-016: GitHub PAT в plaintext в remote URL (.git/config)"
author: kotolizator
created: "2026-06-16 10:20:00+00:00"
updated: "2026-06-16 12:30:00+00:00"
tags:
code_refs:
related:
freshness_score: 98
last_checked: "2026-06-20T01:00:20+00:00"
---

# INC-016: GitHub PAT в plaintext в remote URL

## Описание
В `projects/msk-gastro-digest-bot/.git/config` remote `origin` был задан как HTTPS-URL
со встроенным GitHub Personal Access Token (`ghp_...`) в открытом виде:

```
https://thedoctormes-hue:ghp_***@github.com/thedoctormes-hue/msk-gastro-digest-bot.git
```

Обнаружено при аудите клонов репозитория (сессия КотОлизатора, 16.06.2026), когда
проверялся реальный блок-радиус rewrite истории по INC-013.

## Severity
🟠 **HIGH** — действующий (живой) токен доступа к GitHub-аккаунту в plaintext на диске.
Опаснее мёртвых WG-ключей из INC-013, так как токен **рабочий**. При утечке диска/бэкапа
даёт доступ к репозиториям аккаунта в пределах scope токена.

## Масштаб (проверено по факту)
- Токен присутствовал **только** в `.git/config` вложенного репо `msk-gastro-digest-bot`.
- **НЕ** в git-индексе LabDoctorM (`git grep` — пусто).
- **НЕ** в истории LabDoctorM (`git log -S` — пусто).
- `.git/config` не версионируется → в коммиты не попадал. Утечка локальная (диск), не в remote-историю.

## Сделано (КотОлизатор, обратимая часть)
- ✅ `git remote set-url origin git@github.com:...` — переключение на SSH, токен убран из URL.
- ✅ Проверено: `grep ghp_ .git/config` — пусто.

## Сделано ЗавЛабом (16.06.2026, вне CLI — со слов ЗавЛаба, из CLI не верифицируется)
- ✅ **Токен отозван на GitHub** (Settings → Developer settings → Personal access tokens).
  Скомпрометированный `ghp_***` более не действителен.

## Осталось
- ⏸️ Проверить остальные машины/бэкапы на тот же токен.
- ⏸️ Если SSH-ключ для пуша из этого репо не настроен — настроить, либо использовать
  git credential helper вместо токена в URL.

## Системный вывод
Токены в remote URL — антипаттерн (видны в `ps`, логах, бэкапах `.git/config`).
Канон: SSH-ключи или credential helper. Стоит добавить в аудит-скрипт проверку
`grep -rE 'ghp_|github_pat_' */.git/config`.

## Связанные
- INC-004 / INC-013 — утечки секретов; общий системный корень (нет secret-gate).
- INC-007 — процедура ротации секретов (применить к отзыву токена).
