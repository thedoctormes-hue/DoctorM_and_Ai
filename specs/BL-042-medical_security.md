---
type: backlog
id: BL-042
title: 'BL-77: 🏥 medical_security.md — правила HIPAA для PHI данных'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:28+00:00'
---
# BL-77: 🏥 medical_security.md — правила HIPAA для PHI данных

## Контекст
IT-медицинская лаборатория ЗавЛаб работает с PHI (Protected Health Information) данными. Требуется HIPAA compliance для защиты данных пациентов: audit trail для всех операций с PHI, шифрование данных, доступ по ролям. Это security-задача высшего приоритета.

## Цель
Создать правила medical_security.md с требованиями HIPAA compliance для всех сервисов лаборатории.

## Зачем
Защитить PHI данные пациентов и обеспечить юридическую безопасность IT-медицинской лаборатории.

## Проект/контекст
/rules/security.md — слой rules, security compliance

## Что сделать
- [ ] Анализировать HIPAA требования к PHI данным
- [ ] Определить требования к audit trail для всех операций с PHI
- [ ] Выработать правила шифрования данных (at rest, in transit)
- [ ] Описать контроль доступа по ролям (RBAC)
- [ ] Включить требования к логированию и ротации логов
- [ ] Добавить в /root/.qwen/rules/security.md

## Критерии готовности
- [ ] Создан /root/.qwen/rules/security.md с HIPAA требованиями
- [ ] Прописаны правила audit trail для PHI операций
- [ ] Описаны методы шифрования и контроля доступа
- [ ] Документ проверен на соответствие HIPAA

## Зависимости
- Отсутствуют — security база

## Назначение
- **Вес:** 5 (сложность security + юридическая ответственность)
- **Скиллы:** security-audit, security-auditor
- **Статус:** in_progress
- **Приоритет:** high

## Примечания
PHO-данные = Patient Health Observations. Любой агент, работающий с медицинскими данными, обязан следовать этим правилам.
