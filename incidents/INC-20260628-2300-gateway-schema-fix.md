---
id: INC-20260628-2300
timestamp: "2026-06-28T23:00:00Z"
category: tech
type: other
severity: critical
status: retired
agent: mangust
title: Gateway schema errors cacheRead/cacheWrite — 643 рестарта/день
date: 2026-06-28
verified: true
verified_by: kotolizator
retired_date: 2026-07-16
---

## Описание
Gateway 643 раза перезапускался за день из-за system-level systemd unit. После отключения — schema errors в models.json (cacheRead/cacheWrite).

## Корневая причина
OpenClaw 2026.6.9 требует cacheRead/cacheWrite в cost когда cost не пустой. Провайдеры onnx-local/cerebras/pollinations/cf-* имели cost {input:0, output:0}.

## Решение
1. Отключён system-level unit
2. Добавлен cacheRead:0, cacheWrite:0 во все провайдеры openclaw.json
3. stop+start gateway (restart не помогает — кэш)

## Урок
При изменении cost в openclaw.json — всегда все 4 поля: input, output, cacheRead, cacheWrite.
