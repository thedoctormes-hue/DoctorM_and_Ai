---
type: backlog
id: BL-032
title: 'BL-041: Content Pipeline — Changelog, Release Notes, Docs'
status: archived
author: system
created: 2026-05-15 00:00:00+00:00
updated: 2026-05-24 21:19:59+00:00
tags:
- backlog
- archived
- migrated
freshness_score: 93
last_checked: '2026-06-20T01:00:26+00:00'
---
# BL-041: Content Pipeline — Changelog, Release Notes, Docs

## Контекст
Changelog, release notes и документация создаются вручную. Нет автоматизации, conventional commits не используются. API документация не генерируется автоматически.

## Цель
Реализовать автоматический content pipeline: conventional commits → changelog → release notes → docs.

## Зачем
Чтобы автоматически генерировать changelog, release notes и документацию из артефактов и коммитов, экономя время и обеспечивая консистентность.

## Проект/контекст
Myrmex Control — CI/CD + модуль контента.

## Что сделать
- [ ] Внедрить conventional commits (commitlint в CI)
- [ ] Настроить auto-generation changelog из commits (по тегам)
- [ ] Создать template-driven release notes из артефактов (BL, INC, ADR)
- [ ] Настроить OpenAPI/Swagger auto-generation для API docs
- [ ] Реализовать content pipeline: tag push → release notes → changelog → docs
- [ ] Добавить review workflow: draft → review → publish
- [ ] Интегрировать release-please для automated releases
- [ ] Настроить Docusaurus для documentation site с versioning
- [ ] Добавить multi-format export: Markdown, HTML, plain text

## Критерии готовности
- [ ] Conventional commits enforced в CI
- [ ] Changelog генерируется автоматически при создании тега
- [ ] Release notes создаются из артефактов
- [ ] API docs генерируются из FastAPI
- [ ] Content pipeline работает end-to-end
- [ ] Docusaurus site с версионированием работает

## Зависимости
- BL-034 — Blue-Green Deployment (CI/CD pipeline)
- BL-035 — Artifact CRUD (артефакты как источник данных)
- BL-038 — OpenAPI (API docs)

## Назначение
- **Вес:** 3
- **Скиллы:** content-agent, ci-cd-and-automation
- **Статус:** pending
- **Приоритет:** low

## Примечания
- Audience-specific release notes: users vs developers
- Multi-language support через translation APIs
- Content API для dashboard integration
