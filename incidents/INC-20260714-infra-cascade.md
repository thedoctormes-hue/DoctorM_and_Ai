---
description: "INC-20260714 — Каскад падений инфраструктуры: OOM gateway ← reindex-full hang"
type: incident
created: 2026-07-14
status: closed
severity: critical
verified: false
verified_at: "2026-07-15"
recommended_close: true
---

# INC-20260714-infra-cascade

## Симптомы (алерты 21:01–22:03 МСК)
- openclaw-gateway авто-перезапуск x2/час.
- onnx-embedder.service FAILED, reindex-incremental.service FAILED.
- doctor-m-bot / llmevangelist петля auto-restart (ValueError .env).

## Root cause (установлен read-only, 21:53 МСК)
1. reindex-full.service завис в `deactivating` ~5ч: `reindex.py` убит (kill -9 parent), но cgroup-children (embedding/ONNX workers) не умерли → systemd ждал, RAM заблокирован.
2. → OOM-killer убил openclaw-gateway (17:33:58, 17:34:50 UTC).
3. onnx-embedder.service остановлен 17:57 (SIGKILL после stop-timeout) — cleanup.
4. reindex-incremental + reindex-full unit-файлы ОТСУТСТВУЮТ на диске (systemctl cat → No files found) — сервисы-«призраки».
5. doctor-m-bot / llmevangelist: .env отсутствует по реальному пути /root/LabDoctorM/projects/hype-pilot/channels/ (не /root/hype-pilot/).

## План фикса (ждёт «го»)
- gateway OOM: swap / лимиты агентов / cleanup висячих cgroup.
- reindex unit-файлы: пересоздать (убрать ошибочный Conflicts=reindex-incremental).
- onnx-embedder: systemctl start / пересоздать unit.
- .env ботов: создать (TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL, OPENROUTER_API_KEY, ADMIN_CHAT_ID) + restart.

## Fact-check (2026-07-15, owl) — РЕЗУЛЬТАТ: СТАЛ / ЛОЖНЫЙ АЛЕРТ
Сверено с живой системой (systemctl + ss + ps):
- openclaw-gateway: НЕ systemd-юнит; процесс gateway жив (PID 3916757, running). Каскад OOM НЕ наблюдается.
- onnx-embedder / reindex-incremental / reindex-full: юнитов НЕ существует; :8082 НЕ слушает. Заявленное «FAILED» устарело (сервисы-призраки удалены/не пересозданы).
- doctor-m-bot / llmevangelist: inactive/dead, NRestarts=0 — НЕ в петле auto-restart.
- autoexpert / snablab-backend / zprr-backend: active/running, NRestarts=0 (заявлено +378/+287/+416 — ЛОЖЬ сейчас).
- dnsmasq / irqbalance: inactive (не failed).
- Единственный упавший юнит сейчас: update-notifier-download (относится к инц. 2026-06-20-systemd-failures, не к каскаду).
ВЫВОД: событие 2026-07-14 полностью рассосалось. Каскад НЕ актуален. recommended_close=true.
