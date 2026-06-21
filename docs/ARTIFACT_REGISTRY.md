---
description: "Каталог всех артефактов лаборатории — единственный источник правды"
type: registry
id: REG-001
title: "Artifact Registry"
status: active
last_updated: 2026-05-27
---

# Каталог артефактов лаборатории

**~385 файлов .md** по всей лаборатории. Этот каталог — оглавление, не содержимое.
Загружай только то, что нужно по текущей задаче. Не всё сразу.

## Метки качества

- 🥇 **Gold** — проверено, актуально, используется
- 🥈 **Silver** — полезно, требует проверки
- 🥉 **Bronze** — историческая ценность
- 🗑️ **Junk** — мусор, дубликаты, черновики

---

## 1. Ядро лаборатории (корень)

🗑️ **QWEN.md, QWEN-core.md, QWEN-staff.md, QWEN-projects.md** — удалены при миграции на OpenClaw (июнь 2026). Заменены файлами в projects/DoctorM_and_Ai/docs/.
🗑️ **INCIDENTS.md, ARTIFACTS.md, LAB_PASSPORT.md, README.md, README_Profile.md, index.md, projects.md, SECURITY.md** — более не используются.

---

## 2. Документация лаборатории (docs/)

### docs/adr/ — Architecture Decision Records

🥇 **ADR-026-migration-safety.md** — единственный ADR в docs/adr/ (остальные перенесены в adr/)

### docs/processes/ — Процессы

🥇 **cascade.md** — процесс каскадного планирования
🥇 **council.md** — процесс совета лаборантов
🥇 **project-upgrade.md** — процесс обновления проектов

### docs/infra/ — Инфраструктура

🥇 **mcp-tiering.md** — тирование MCP-серверов
🥇 **ram-guardian.md** — защита RAM от утечек
🥇 **response-cache.md** — кэширование ответов
🥇 **MAILBOX.md** — почтовая система (ликвидирована, но документация полезна)
🥉 **OPENCLAW_ARCH.md** — архитектура OpenClaw (май)
🥉 **OPENROUTER_CACHE.md** — кэш OpenRouter
🥉 **GITHUB_SCAN.md** — сканирование GitHub
🥉 **SYSTEMD_TIMERS.md** — systemd таймеры

### docs/templates/ — Шаблоны

🥇 **ADR_TEMPLATE.md** — шаблон ADR
🥇 **PROJECT_TEMPLATE.md** — шаблон проекта
🥇 **SPEC_TEMPLATE.md** — шаблон спецификации
🥉 **PROJECT_CHECKLIST.md** — чеклист проекта
🥉 **README_TEMPLATE.md** — шаблон README

### docs/brand/ — Брендинг агентов

🥈 **content-agent.md** — бренд-гайд контент-агента
🥈 **content-pipeline-agent.md** — бренд-гайд конвейера
🥈 **commercial-agent.md** — бренд-гайд коммерческого агента
🥈 **creative-director.md** — бренд-гайд креативного директора

### docs/commercial/ — Коммерческие материалы

🥉 **COMMERCIAL_PROPOSAL_FEEDLAB.md** — коммерческое предложение
🥉 **COMMERCIAL_PROPOSAL_ZAKUPKI_DROP.md** — предложение по закупкам
🥉 **COLD_EMAIL.md** — шаблон холодного письма
🥉 **B2B_POSITIONING.md** — B2B позиционирование
🥉 **PRICE_LIST.md** — прайс-лист
🥉 **POLYP_DETECTION_OFFER.md** — предложение по полипам

### docs/content/ — Контент-стратегия

🥉 **CONTENT_STRATEGY.md** — контент-стратегия
🥉 **PIPELINE.md** — пайплайн контента
🥉 **PLAN_QWEN_BRAND.md** — план бренда Qwen
🥉 **PUBLICATION_PLAN.md** — план публикаций
🥉 **TOPIC_MAP.md** — карта тем
🥉 **articles-plan.md** — план статей
🗑️ **habr-*.md** (5 файлов) — черновики статей для Habr
🗑️ **linkedin-qwen-brand.md** — черновик для LinkedIn
🗑️ **qwen-team-case.md** — черновик кейса
🗑️ **twitter-thread-qwen-brand.md** — черновик твиттер-треда

### docs/strategy/ — Стратегия

🥉 **AUDIT_2026_FULL.md** — полный аудит лаборатории (май 2026)

### docs/archive/ — Архив

🗑️ **memory-old/** → `archive-labdoctorm/20260527/memory-old/` — старая память, май 2026 (архивировано 2026-05-27)

### docs/ — Корневые файлы docs/

🥇 **QUALITY_STANDARDS.md** — стандарты качества лаборатории
🥇 **SCRIPTS.md** — реестр скриптов
🥇 **DEPLOY.md** — инструкция деплоя
🥇 **PORT_REGISTRY.md** — реестр портов
🥉 **GIT_HEALTH_API.md** — API здоровья Git
🥉 **GIT_HEALTH_COORDINATION.md** — координация Git-здоровья
🥉 **GIT_METRICS_SCRIPTS.md** — скрипты метрик Git
🥉 **GIT_WORKTREES.md** — Git worktrees
🥉 **INSIGHTS.md** — инсайты (май 2026)
🗑️ **rules.md** — дублирует rules.md из корня

---

## 3. Линзы (lenses/)

🥇 **code-reviewer.md** — линза ревьюера кода
🥇 **security-auditor.md** — линза аудитора безопасности
🥇 **test-engineer.md** — линза тест-инженера
🥇 **incident-commander.md** — линза командира инцидентов
🥇 **anti-dpi-legend.md** — линза обхода DPI
🥇 **deploy-bot.md** — линза деплоя
🥇 **artifact-specialist.md** — линза специалиста артефактов
🥈 **INSIGHT_CATCHER.md** — ловец инсайтов (без frontmatter)
🥈 **LENS_VS_SKILL.md** — сравнение линз и скиллов
🥈 **README.md** — описание линз

---

## 4. Воркспейсы агентов (workspaces/)

### Сова (workspaces/owl/)

🥇 **IDENTITY.md** — идентичность Совы, роль Auditor
🥇 **SOUL.md** — душа, принципы, стиль
🥇 **MEMORY.md** — долгосрочная память
🥇 **AGENTS.md** — правила работы
🥇 **USER.md** — информация о ЗавЛабе
🥇 **TOOLS.md** — локальные заметки по инструментам
🥇 **HEARTBEAT.md** — задачи для heartbeat
📁 **memory/** — ежедневные заметки (YYYY-MM-DD.md)

### Остальные агенты

- **kotolizator** — workspaces/kotolizator/ (Orchestrator)
- **antcat** — workspaces/antcat/ (Builder)
- **bestia** — workspaces/bestia/ (Operator)
- **raven** — workspaces/raven/ (Researcher)
- **mangust** — workspaces/mangust/ (Analyst)
- **dominika** — workspaces/dominika/ (Scout)
- **muravey** — workspaces/muravey/ (Builder)
- **streikbrecher** — workspaces/streikbrecher/ (Developer)

Каждый воркспейс содержит: IDENTITY.md, SOUL.md, MEMORY.md, AGENTS.md, USER.md, TOOLS.md, HEARTBEAT.md, memory/.

---

## 5. Память лаборатории (.qwen/memory/)

📄 **decision_log.jsonl** — журнал решений
📄 **insight_playwright_expert_lost_2026_06_08.md** — инсайт о потере эксперта Playwright
📁 **insights/** — каталог инсайтов сессий
  - feedback.json
  - session_20260524_session_startup_v5.md
  - weights.json

---

## 6. Проекты — документация

### myrmex-control/docs/ (~25 файлов)

🥇 **FRONTMATTER_GUIDE.md** — гайд по frontmatter для артефактов
🥇 **ARTIFACT_SYNC_INTEGRATION.md** — интеграция синхронизации артефактов
🥇 **INTEGRATION_CONTEXT_API.md** — интеграция с Context API
🥇 **docs/SNAPSHOT_20260527.md** — снимок состояния
🥇 **docs/SPECS.md** — спецификация
🥇 **docs/design/DESIGN.md** — дизайн системы (33 KB)
🥇 **docs/ADR_FRONTMATTER.md** — ADR о frontmatter
🥇 **adr/index.md** — индекс ADR
🥇 **adr/ADR-001..011** (11 файлов) — все ADR Myrmex

### autoexpert/docs/ (~17 файлов)

🥇 **SPEC_AUTOEXPERT.md** — спецификация AutoExpert (81 KB)
🥇 **FRONTEND_SPEC_UX.md** — UX спецификация (111 KB)
🥇 **FRONTEND_SPEC_INTEGRATION.md** — интеграция фронтенда (52 KB)
🥇 **FRONTEND_SPEC_TECH.md** — техническая спецификация (55 KB)
🥇 **SPEC_FRONTEND.md** — спецификация фронтенда (58 KB)
🥇 **API_ALIGNMENT.md** — выравнивание API (24 KB)
🥇 **FRONTEND_REVIEW.md** — ревью фронтенда (22 KB)
🥇 **SECURITY_AUDIT_20260526.md** — аудит безопасности
🥇 **INTEGRATION_PLAN.md** — план интеграции
🥇 **EXPERT_PIPELINE_REAL.md** — пайплайн экспертиз
🥇 **BRIEFING_FOR_CAT.md** — брифинг для Кота
🥈 **ARCHITECTURE.md** — архитектура
🥈 **PRODUCT.md** — продуктовое описание
🥈 **SOURCES.md** — источники
🥈 **SPEC_registration_fix.md** — фикс регистрации
🥉 **REPORT_RAVEN_20260525.md** — отчёт Ворона

### snablab/docs/ (~20 файлов)

🥇 **security-audit.md** — аудит безопасности (28 KB)
🥇 **code-review.md** — ревью кода (28 KB)
🥇 **SPECS.md** — спецификация
🥇 **API.md** — API документация
🥇 **ROADMAP.md** — дорожная карта
🥇 **DOCUMENT_ENGINE_ARCHITECTURE.md** — архитектура документооборота
🥇 **architecture/ADR-001..012** (8 файлов) — ADR snablab
🥈 **research/kdl-lifecycle.md** — исследование KDL (74 KB)
🥈 **research/sop-standards.md** — стандарты SOP (38 KB)
🥈 **research/accreditation-requirements.md** — требования аккредитации (34 KB)
🥈 **research/profstandards.md** — профстандарты (29 KB)
🥈 **research/category-requirements.md** — требования категорий (29 KB)
🥈 **SESSION_SNAPSHOT.md** — снимок сессии
🥉 **AUDIT_20260519.md** — аудит (май)
🥉 **CHECKPOINT_20260518..22** (4 файла) — старые чекпоинты

### vpn-daemon/docs/ (~24 файла)

🥇 **architecture.md** — архитектура VPN-демона (12 KB)
🥇 **URI_GENERATION_GUIDE.md** — генерация URI (12 KB)
🥇 **LOAD_TEST_RESULTS.md** — результаты нагрузочного тестирования (14 KB)
🥇 **DPI_HARDENING.md** — закалка DPI (14 KB)
🥇 **IAC_DEPLOY.md** — Infrastructure as Code деплой (14 KB)
🥇 **TICKETS.md** — тикеты для VPN-пользователей (17 KB)
🥇 **IP_ROTATION.md** — ротация IP (10 KB)
🥇 **REALITY_KEY_SYNC_20260516.md** — синхронизация ключей REALITY
🥇 **PAYMENT.md** — платёжная система
🥇 **WHITE_LIST_SCHEME.md** — схема белого списка
🥇 **api.md** — API документация
🥇 **deployment.md** — деплой
🥇 **monitoring.md** — мониторинг
🥇 **DPI_BYPASS_FORMULA.md** — формула обхода DPI
🥇 **WARSAW_FIX_20260430.md** — фикс Warsaw
🥇 **runbooks/** (6 файлов) — рунбуки операций
🥇 **audits/** (2 файла) — аудиты
🥇 **infrastructure/docs/** (4 файла) — документация инфраструктуры

### lab-monitoring/docs/ (~8 файлов)

🥇 **API.md** — API документация (17 KB)
🥇 **ARCHITECTURE.md** — архитектура (12 KB)
🥇 **DEPLOY.md** — деплой
🥇 **RUNBOOK.md** — рунбук
🥇 **ADR/** (4 файла) — ADR мониторинга

### lab-playwright-expert/docs/ (~12 файлов)

🥇 **API.md** — API документация (26 KB)
🥇 **SCRIPTS.md** — скрипты (22 KB)
🥇 **ARCHITECTURE.md** — архитектура (18 KB)
🥇 **GETTING_STARTED.md** — начало работы (12 KB)
🥇 **GUIDES.md** — гайды (14 KB)
🥇 **DEPLOY.md** — деплой
🥈 **PERFORMANCE.md** — производительность
🥈 **ADR/** (3 файла) — ADR

### streikbrecher/docs/ (~12 файлов)

🥇 **HOOKS_TEST_SCENARIOS.md** — сценарии тестов хуков (17 KB)
🥇 **SPEC_KDL_DATA_HUB.md** — спецификация KDL Data Hub (14 KB)
🥇 **ADR_KDL_001_data_format.md** — ADR формат данных
🥇 **ADR_KDL_002_collection_strategy.md** — ADR стратегия сбора
🥈 **REPORT_SITE_HEALTH_RAVEN.md** — отчёт о здоровье сайтов (30 KB)
🥈 **REPORT_VPN_MONITOR_KOT.md** — отчёт о VPN мониторинге (18 KB)
🥈 **REPORT_SITE_HEALTH_MUAVEY.md** — отчёт о здоровье (14 KB)
🥈 **RESEARCH_glory_board_v3.md** — исследование (17 KB)
🥈 **SPEC_VPN_MONITOR.md** — спецификация VPN монитора
🥈 **SPEC_SITE_HEALTH_MONITOR.md** — спецификация монитора сайтов

### remote-access/docs/ (~5 файлов)

🥇 **methodology.md** — методология удалённого доступа (7 KB)
🥇 **ARCHITECTURE.md** — архитектура
🥇 **FULL_INSTRUCTION.md** — полная инструкция
🥇 **laptop-setup/README.md** — настройка ноутбука
🥇 **laptop-setup/CONFIGS.md** — конфигурации

### bestia/docs/ (2 файла)

🥇 **INSTRUCTION_AWG.md** — инструкция по AmneziaWG (7 KB)
🥈 **URI_RESEARCH_20260525.md** — исследование URI

### raven/docs/ (2 файла)

🥇 **SPEC_context_indexing_20260525.md** — спефикация индексации контекста
🥈 **REPORT_context_indexing_20260525.md** — отчёт об индексации (39 KB)

### passive-income-engine/docs/ (4 файла)

🥈 **RESEARCH-20260519-github.md** — исследование GitHub
🥈 **SPEC-001-referral-links.md** — реферальные ссылки
🥈 **SPEC-002-promo-integration.md** — интеграция промо
🥈 **SPEC-003-weekly-promo-post.md** — еженедельные промо

### hype-pilot/docs/ (1 файл)

🥉 **CHECKPOINT_20260518.md** — чекпоинт (давний)

### llm-evangelist/docs/ (2 файла)

🥉 **evangelist-workflow.md** — воркфлоу евангелиста
🥉 **architecture.md** — архитектура

---

## 7. Инциденты (incidents/)

Единый каталог инцидентов: `projects/DoctorM_and_Ai/incidents/`

📄 **README.md** — реестр инцидентов со статусами
📄 **INC-001..INC-025** — файлы инцидентов

---

## Сводка по качеству

- 🥇 Gold — ~100 артефактов (актуальное, проверенное)
- 🥈 Silver — ~50 артефактов (полезное, требует проверки)
- 🥉 Bronze — ~30 артефактов (историческая ценность)
- 🗑️ Junk — ~20 артефактов (мусор, дубликаты, черновики)

---

## Как пользоваться

1. Нашёл задачу → посмотри в каталоге нужный раздел
2. Загружай только Gold-артефакты по теме
3. Не читай всё подряд
4. Нашёл новый артефакт → зарегистрируй здесь
5. Нашёл мусор → отметь как Junk, архивируй

---

*Создано Совой 27.05.2026. Последнее обновление: 21.06.2026.*
