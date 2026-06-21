---
name: reference-parsing
description: Парсинг внешних сайтов — обращаться к lab-playwright-expert, не autoexpert.
type: insight
status: active
verified: 2026-06-17
source: reference_parsing.md
---

# 🔍 Парсинг Внешних Источников

## Правильный проект
`/root/LabDoctorM/projects/lab-playwright-expert` (НЕ autoexpert!)

## Ключевые файлы
- `src/lab_playwright_kit/scrapy_engine/` — Scrapy + Playwright движок
- `src/lab_playwright_kit/data_parser.py` — парсеры данных

## Почему не autoexpert
autoexpert — парсер автозапчастей (Emex, Autodoc, Exist), не для общего парсинга.

## Применение
Для парсинга любых внешних сайтов (лрц.рф, zakupki.gov.ru и т.д.) обращаться к lab-playwright-expert.
