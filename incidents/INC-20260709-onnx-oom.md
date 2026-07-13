---
id: INC-20260709-onnx-oom
timestamp: "2026-07-09T00:00:00Z"
category: tech
type: other
severity: critical
status: closed
agent: streikbrecher
title: INC-20260709-onnx-oom — OOM killer убил сервер из-за индексатора
---

# INC-20260709-onnx-oom — OOM killer убил сервер из-за индексатора

**Дата:** 2026-07-09
**Серьёзность:** критическая (сервер упал, hard reboot)
**Виновник:** Streikbrecher (эксперименты с лимитами ONNX + запуск reindex --full без ограничений)

## Что случилось
- Убран `MemoryMax` у ONNX → он перешёл из свопа (был под лимитом 700M) в RAM и съел ~3.1GB.
- Запущен `reindex --full` (systemd, 5158 файлов) без лимитов ресурсов.
- Сумма с postgres + dockerd + containerd + trading bot + 8 агентами превысила 7.8GB RAM.
- OOM killer убил postgres/dockerd/containerd → сервер завис, hard reboot (техподдержка).

## Корень
- Непонимание общей картины сервера (не учтены postgres/docker/trading bot).
- Убран лимит памяти у ONNX (он съел 3.1GB вместо свопа).
- reindex запущен без CPU/Memory/IO лимитов.

## Исправление
- ONNX: `MemoryMax=2.5G`, `MemoryHigh=2G`, `CPUQuota=100%`, своп разрешён (убран `MemorySwapMax=0`).
- reindex: `MemoryMax=1G`, `CPUQuota=50%`, `IOWeight=10`, запуск только в off-peak.
- Правило в `docs/INDEXING-RULES.md`: «индексатор не должен ложить сервер — лимиты ресурсов обязательны».

## Статус
- ONNX и reindex остановлены (ЗавЛаб сказал «стоп»).
- Trading bot (doctorm-unify-protocol) / postgres / docker — active (не тронуты, критичные процессы целы).
- Ожидаю «го» от ЗавЛаба для запуска с новыми лимитами.
