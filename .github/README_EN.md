<div align="center">

# 🧬 LabDoctorM

**An AI lab that's been shipping while you were reading this README.**

*Founded April 25, 2026. 23 projects, 8 agents, ~627 tests. Updated: 2026-06-24.*

[![Website](https://img.shields.io/badge/Website-shtab--ai.ru-00D4AA?style=flat-square)](https://shtab-ai.ru)
[![Dashboard](https://img.shields.io/badge/Dashboard-myrmexcontrol.shtab--ai.ru-00D4AA?style=flat-square)](https://myrmexcontrol.shtab-ai.ru)
[![Telegram](https://img.shields.io/badge/Telegram-@DoctorMES-00D4AA?style=flat-square)](https://t.me/DoctorMES)

[🇬🇧 English](#) · [🇷🇺 Русский](README_RU.md)

</div>

---

## Why You're Still Reading

We don't have a pitch deck. No whitepaper. No slides with stock photos and "AI-powered" stamped on them.

Here's what we do have:

- **8 AI agents** writing code 24/7 — not as a demo, but on production
- **Autonomous incident response** — when one agent screws up, another runs the post-mortem. The human doesn't even wake up.
- **627 tests** (excluding node_modules/dist) — because we don't trust "it works on my machine"
- **38 incidents** recorded and analyzed — none repeated

If that's interesting — keep reading. If you need more proof — we'll prove it.

---

## The Agents

Eight specialists. Nobody's an "assistant". Each one owns their domain.

| Agent | Specialization | What They Actually Do |
|-------|---------------|----------------------|
| 🐱 **Kotolizator** | Coordination | VPN, data, monitoring. Knows what's happening at any given moment |
| 🐜 **Ant** | Engineering | Myrmex Control, bots, automation. Writes code that doesn't need rewriting |
| 🐺 **Bestia** | Infrastructure | SnabLab, services. Keeps production alive |
| ⚡ **Streikbrecher** | Fullstack | Cross-project development. The one who sees the whole picture |
| 🦉 **Owl** | Audit & Quality | Standards, architecture. Won't let bad code through |
| 🐦‍⬛ **Raven** | Recon | Monitoring, analytics, content. Flies ahead and finds threats |
| 🦊 **Dominika** | Scout | Fast search, resource reconnaissance, data gathering |
| 🦡 **Mongoose** | Analytics | Data analysis, integrations, ADR, external system connections |

**ZavLab** (@DoctorMES) — human operator. Sets tasks. Makes strategic decisions. Doesn't write code at 3am — the agents do that for him.

---

## Projects

### 🟢 Production (running, no SLA, best-effort)

| Project | What It Does | Stack |
|---------|--------------|-------|
| [snablab](https://github.com/thedoctormes-hue/snablab) | Full-stack procurement automation for clinical labs: catalogs, RFQ parsing, inventory, orders, equipment, analytics, Telegram bot. 651 tests | FastAPI, React 18, PostgreSQL 16, Redis |
| [myrmex-control](https://github.com/thedoctormes-hue/myrmex-control) | Lab control panel: kanban, sessions, artifacts, chat, Knowledge Graph. 44 modules, 195 tests | React 19, TS, Express |
| [consilium](https://github.com/thedoctormes-hue/consilium) | AI council of 6 roles: Skeptic, Post-mortem, First Principles, Growth, Outsider, Executor. HTTP API + Telegram bot | Go |
| [stenographer](https://github.com/thedoctormes-hue/stenographer) | Audio/video transcription from Telegram → 4 documents: text, protocol, tasks, reflection | Python, aiogram, OpenRouter |
| [free-api-hunter](https://github.com/thedoctormes-hue/free-api-hunter) | Free LLM API monitoring with web dashboard | Go, React |
| [vpn-daemon](https://github.com/thedoctormes-hue/vpn-daemon) | VPN management via Telegram (Xray VLESS+REALITY). 355+ tests | Python, aiogram, FastAPI |
| [mail-daemon](https://github.com/thedoctormes-hue/mail-daemon) | IMAP monitoring + AI classification + OCR for lab results | Go, chi, Tesseract OCR |
| [zprr-tracker](https://github.com/thedoctormes-hue/zprr-tracker) | Speech development tracker for children with ZPRR. Observations, vocabulary, lesson plans, progress stats | FastAPI, React, PostgreSQL |

### 🟡 In Development

| Project | What It Does | Stack |
|---------|--------------|-------|
| [autoexpert](https://github.com/thedoctormes-hue/autoexpert) | Traffic accident damage assessment automation: VIN parts search, price scraping, PDF report. 67 tests | FastAPI, React/Vite, PostgreSQL |
| [hype-pilot](https://github.com/thedoctormes-hue/hype-pilot) | Hype and viral content monitoring. Telegram autoposting. 44 tests | Python, Playwright |
| [lab-monitoring](https://github.com/thedoctormes-hue/lab-monitoring) | Server, website, VPN, PostgreSQL, Docker, SSL monitoring | Python, systemd |
| [artifact-pulse](https://github.com/thedoctormes-hue/artifact-pulse) | Lab artifact health monitoring | Python |
| [lab-playwright-expert](https://github.com/thedoctormes-hue/lab-playwright-expert) | Test automation framework. 376 tests | Python, Playwright |
| [SNZK](https://github.com/thedoctormes-hue/SNZK) | Browser visual novel in cyberpunk aesthetic. 5 phases, 92 events, 7 endings | TypeScript, Vite, Canvas |
| [remote-access](https://github.com/thedoctormes-hue/remote-access) | Remote access via Xray VLESS+REALITY | Bash, Xray, SSH |
| [DoctorMandDesign](https://github.com/thedoctormes-hue/DoctorMandDesign) | Presentation generator. 18 templates, WCAG-AA, i18n | Python, reportlab |
| [msk-gastro-digest-bot](https://github.com/thedoctormes-hue/msk-gastro-digest-bot) | Moscow restaurant news digest. $0 (free models) | aiogram, OpenRouter |
| [polyscope](https://github.com/thedoctormes-hue/polyscope) | Interactive landing page | React 19, Vite 7, Radix UI, GSAP |
| [api-hub](https://github.com/thedoctormes-hue/api-hub) | Unified API gateway for external services | FastAPI, SQLAlchemy |
| [cheque-bot](https://github.com/thedoctormes-hue/cheque-bot) | AI receipt parsing. **Frozen** | aiogram, OpenRouter Vision |
| [mcp-tools](https://github.com/thedoctormes-hue/mcp-tools) | MCP tools for LLM integration | — |

---

## Architecture

```
ZavLab (@DoctorMES)
  └── Myrmex Control (44 modules, ModuleRegistry auto-discovery)
        ├── Kotolizator ─── VPN, data, coordination
        ├── Ant ─────────── engineering, Myrmex, bots
        ├── Bestia ──────── infrastructure, SnabLab
        ├── Streikbrecher — fullstack, architecture
        ├── Owl ─────────── audit, standards, quality
        ├── Raven ──────── recon, monitoring
        ├── Dominika ───── scout, resource search
        └── Mongoose ───── analytics, integrations, ADR
```

**Facts:**
- Each agent in an **isolated** workspace
- **44 ADR** — every decision documented
- **38 incidents** with post-mortem (see `incidents/`)
- **Git Guardian** blocks unverified pushes to main

---

## Technology

```
Languages:   Python · TypeScript · Go · Bash
Backend:     FastAPI · aiogram · Express · chi · PostgreSQL · SQLite · Redis · MinIO
Frontend:    React 18/19 · Vite 5/7/8 · Tailwind CSS · Radix UI · Zustand
AI/LLM:      OpenRouter (multi-provider) · EmbeddingGemma-300m · FAISS · ONNX Runtime
DevOps:      Docker · systemd · GitHub Actions · pre-commit
VPN:         Xray Core (VLESS/REALITY) · nginx SNI routing
```

---

## Metrics

- **627 tests** (excluding node_modules/dist/.venv)
- **~252K lines of code** (excluding node_modules/dist)
- **44 ADR**, 21 patterns, 38 incidents
- **1588+ .md files** indexed in semantic memory

---

## What We Don't Have

- ❌ 3 servers across 3 continents (1 server, and it works)
- ❌ "52 skills" copied from Qwen docs
- ❌ AI that's "planned" or "on the roadmap" — only working code
- ❌ "Passive income" as a project
- ❌ A team of 50 people (8 agents)

What we do have:
- ✅ Running services
- ✅ Documented architecture
- ✅ Quality culture (post-mortem for every incident)
- ✅ Automation that saves hours every day

---

## Stay Connected

- 🌐 [shtab-ai.ru](https://shtab-ai.ru)
- 📊 [myrmexcontrol.shtab-ai.ru](https://myrmexcontrol.shtab-ai.ru)
- 📡 [@DoctorMES](https://t.me/DoctorMES)

---

<div align="center">

**"We don't need a superhero. We need working code."**

*© 2026 DoctorM&Ai Laboratory. The colony is working. Seriously.*

</div>
