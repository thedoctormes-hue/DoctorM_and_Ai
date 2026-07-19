---
description: "DoctorM_and_Ai — история изменений"
type: changelog
last_reviewed: 2026-06-21
last_code_change: 2026-06-21
status: active
---

# Changelog

## [Unreleased]

- Создан базовый CHANGELOG.

## [2026-07-19]

- **ADR-046**: bestia делегированы push-права в `master` (doctorm-unify-protocol) под
  реальной identity (author `bestia@labdoctorm.ru`, push с `AGENT_ID=bestia`).
  Реализация: `git-hooks/check-branch-ownership.sh` — `bestia` добавлена в `is_priv`.
  Авторизовано ЗавЛабом. Решение НЕ даёт кросс-веточный карт-бланш; force-push
  остаётся заблокированным ADR-0059 для всех.
