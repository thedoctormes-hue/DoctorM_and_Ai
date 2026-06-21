---
description: "План защиты от Context Hijacking"
type: guide
last_reviewed: 2026-05-27
status: active
---

# 🛡️ План защиты от Context Hijacking

**Incident:** `INC-005`
**Дата:** 27.05.2026
**Статус:** 🟡 Частично implemented

---

## Что произошло

27 мая 2026 система Qwen Code была **намеренно демонтирована**:

| Компонент | Статус | Описание |
|-----------|--------|----------|
| `hooks/` | ❌ Удалены | insight_catcher, decision_engine, adaptive_router |
| `memory/` | ❌ Удалены | Контекстная память |
| `metrics/` | ❌ Удалены | Метрики git |
| `skills/` | ❌ Удалены | Специализированные навыки |
| `agents/` | ❌ Удалены | Определения агентов |
| `insights_queue.json` | ❌ Очищен | Очередь инсайтов |
| `settings.json` | ⚠️ Искажены | Инструкции каналов повреждены |

---

## Реализованные меры

### ✅ 1. Восстановление из источника истины
```bash
cp -r /root/LabDoctorM/.qwen/{agents,agents-legacy,hooks,memory,metrics,skills,tests} /root/.qwen/
cp /root/LabDoctorM/.qwen/{insights_queue.json,self_evolve.sh,tier.yml} /root/.qwen/
```

### ✅ 2. Мониторинг целостности
**Создан скрипт:** `/root/.qwen/hooks/integrity_check.sh`

**Что делает:**
- Проверяет наличие всех обязательных компонентов `.qwen/`
- Сравнивает длину инструкций в `settings.json`
- Логирует проблемы в `/root/.qwen/logs/integrity_check.log`
- Автоматически восстанавливает при обнаружении проблем

**Интеграция:**
- Добавлен в `PostToolUse` hooks (работает после каждого действия)
- Вызывается в `session_init.sh` при старте сессии

### ✅ 3. Бэкап
**Источник истины:** `/root/LabDoctorM/.qwen/`

---

## Запланированные меры

### 🟡 1. Иммутабельность `.qwen/` (critical)
```bash
chattr +i /root/.qwen -R
```

**Эффект:** файлы станут неизменяемыми — даже root не сможет удалить.

**Внимание:** перед восстановлением нужно снять иммутабельность:
```bash
chattr -i /root/.qwen -R
```

### 🟡 2. Автоматический бэкап (high)
Ежечасный бэкап в `/root/.qwen-backup/` с ротацией 7 дней.

### 🟡 3. Шифрование конфигов (medium)
- Хранить `settings.json` в зашифрованном виде
- Ключ доступа в отдельном секрете
- Проверка целостности конфига при загрузке

### 🟡 4. Мониторинг в lab-monitoring (medium)
- Добавить endpoint `/api/v1/health/qwen-integrity`
- Алерты при сбое целостности
- Дашборд состояния `.qwen/`

### 🟡 5. Проверка хешей файлов (medium)
Хранить хеши всех файлов `.qwen/` и проверять их регулярно.

---

## Правила поведения

### Запрещено
1. ❌ Удалять файлы из `/root/.qwen/` без одобрения Совой
2. ❌ Изменять `settings.json` вручную — использовать `self_evolve.sh`
3. ❌ Запускать скрипты без проверки целостности

### Разрешено
1. ✅ Читать файлы `.qwen/` для отладки
2. ✅ Запускать `integrity_check.sh` для проверки
3. ✅ Восстанавливать из `/root/LabDoctorM/.qwen/` при проблемах

---

## Реакция на инцидент

### При обнаружении проблемы:
1. Запустить `integrity_check.sh` — он автоматически восстановит
2. Если не помогло — запустить вручную:
   ```bash
   bash /root/.qwen/hooks/integrity_check.sh --force
   ```
3. Если не помогло — восстановить из источника:
   ```bash
   cp -r /root/LabDoctorM/.qwen/{agents,agents-legacy,hooks,memory,metrics,skills,tests} /root/.qwen/
   ```

### Если файлы повторно удаляются:
1. **Это атака!** Запустить расследование
2. Проверить логи: `cat /root/.qwen/logs/integrity_check.log`
3. Проверить крон jobs: `crontab -l`
4. Проверить systemd timers: `systemctl list-timers`
5. Создать incident

---

## Связанные файлы

| Файл | Описание |
|------|----------|
| `/root/.qwen/hooks/integrity_check.sh` | Скрипт мониторинга целостности |
| `/root/.qwen/hooks/session_init.sh` | Интегрирован проверка при старте |
| `/root/LabDoctorM/incidents/INC-005-inc005-context-hijacking-attack-udalenie.md` | Запись инцидента |
| `/root/LabDoctorM/.qwen/` | Источник истины (бэкап) |

---

*План обновляется при новых инцидентах. Последнее обновление: 2026-05-27*
