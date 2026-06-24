<div align="center">

# 🧬 LabDoctorM

**An AI lab that's been shipping while you were reading this README.**

*Founded April 25, 2026. 23 projects, 8 agents, ~627 tests. Last updated: 2026-06-24.*

[![Website](https://img.shields.io/badge/Website-shtab--ai.ru-00D4AA?style=flat-square)](https://shtab-ai.ru)
[![Dashboard](https://img.shields.io/badge/Dashboard-myrmexcontrol.shtab--ai.ru-00D4AA?style=flat-square)](https://myrmexcontrol.shtab-ai.ru)
[![Telegram](https://img.shields.io/badge/Telegram-@DoctorMES-00D4AA?style=flat-square)](https://t.me/DoctorMES)

[🇬🇧 English](#) · [🇷🇺 Русский](README.md)

</div>

---

## Why You're Still Reading

We don't have a pitch deck. No whitepaper. No slides with stock photos and "AI-powered" stamped on them.

Here's what we do have:

- **8 AI agents** writing code 24/7 — not as a demo, but on production
- **Autonomous incident response** — when one agent screws up, another runs the post-mortem. The human doesn't even wake up.
- **627 tests** (excluding node_modules/dist) — because we don't trust "it works on my machine"

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

**ZavLab** (@DoctorMES) — human operator. Sets tasks. Makes strategic decisions. Doesn't write code at 3am (the agents do that for him).

---

## Projects That Run Right Now

### 🟢 Production — live, delivering value (no SLA, best-effort)

| Project | What It Does | Stack |
|---------|--------------|-------|
| [myrmex-control](https://github.com/thedoctormes-hue/myrmex-control) ⚡ | Lab control panel: kanban, sessions, artifacts, chat. 44 modules, 195 tests | React 19, TS, Express |
| [lab-vault](https://github.com/thedoctormes-hue/lab-vault) 🔐 | Secret manager for AI agents. Go. Works. Secrets stay secret. | Go |
| [mail-daemon](https://github.com/thedoctormes-hue/mail-daemon) 📬 | IMAP monitoring + AI classification + OCR | Go |
| [zprr-tracker](https://github.com/thedoctormes-hue/zprr-tracker) 👶 | Speech development tracker for children. Real kids, real results. 99 tests | FastAPI, React, PostgreSQL |
| [consilium](https://github.com/thedoctormes-hue/consilium) 🧠 | AI council of 6 analytical roles: Skeptic, Post-mortem, First Principles, Growth, Outsider, Executor. HTTP API + Telegram bot | Go |
| [snablab](https://github.com/thedoctormes-hue/snablab) | Full-stack procurement for clinical labs: catalogs, RFQ parsing, inventory, orders, equipment, analytics, Telegram bot. 81 tests | Python, PostgreSQL |
| [stenographer](https://github.com/thedoctormes-hue/stenographer) | Audio/video transcription from Telegram. 4 tests | Python, aiogram |
| [free-api-hunter](https://github.com/thedoctormes-hue/free-api-hunter) | Monitoring free LLM APIs with web dashboard | Go, React |

### 🟡 Active — in development

| Project | What It Does | Stack |
|---------|--------------|-------|
| [autoexpert](https://github.com/thedoctormes-hue/autoexpert) | Traffic accident damage assessment with AI. 67 tests | FastAPI, React/Vite, PostgreSQL |
| [hype-pilot](https://github.com/thedoctormes-hue/hype-pilot) | Hype and viral content monitoring. Telegram autoposting. 44 tests | Python, Playwright |
| [lab-monitoring](https://github.com/thedoctormes-hue/lab-monitoring) | Infrastructure monitoring. 4 tests. systemd timer | Python, systemd |
| [artifact-pulse](https://github.com/thedoctormes-hue/artifact-pulse) | Lab artifact health monitoring | Python |
| [lab-playwright-expert](https://github.com/thedoctormes-hue/lab-playwright-expert) | Test automation framework. 106 tests | Python, Playwright |
| [vpn-daemon](https://github.com/thedoctormes-hue/vpn-daemon) | VPN management via Telegram. 18 tests | Python, aiogram, PostgreSQL |
| [SNZK](https://github.com/thedoctormes-hue/SNZK) | Narrative web project | TypeScript, Vite, Canvas |
| [remote-access](https://github.com/thedoctormes-hue/remote-access) | Remote equipment access | Bash, Xray, SSH |
| [DoctorMandDesign](https://github.com/thedoctormes-hue/DoctorMandDesign) | Presentation generator. 18 templates, WCAG-AA, i18n | Python, reportlab |
| [msk-gastro-digest-bot](https://github.com/thedoctormes-hue/msk-gastro-digest-bot) | Moscow restaurant news digest. $0 (free models) | aiogram, v6.5 |
| [polyscope](https://github.com/thedoctormes-hue/polyscope) | Interactive landing page | React 19, Vite 7, Radix UI, GSAP |
| [api-hub](https://github.com/thedoctormes-hue/api-hub) | Unified API gateway (in development) | FastAPI, SQLAlchemy |
| [cheque-bot](https://github.com/thedoctormes-hue/cheque-bot) | Receipt processing. 7 tests | aiogram |
| [mcp-tools](https://github.com/thedoctormes-hue/mcp-tools) | MCP tools (in development) | — |

### 🔴 Frozen

- Accounting bot — frozen, not maintained.

---

## Architecture. Bold and Precise.

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

**Facts without decoration:**
- Each agent in an **isolated** workspace — minimum conflicts
- **44 ADR** at root — every decision documented
- **38 incidents** recorded with post-mortem (see `incidents/`)
- **Git Guardian** blocks garbage pushes to main. Even ours.

---

## Technology

We don't chase trends. We use what works.

```
Languages:   Python · TypeScript · Go · Bash
Backend:     FastAPI · aiogram · Express · chi · PostgreSQL · SQLite · MinIO
Frontend:    React 18/19 · Vite 5/7/8 · Tailwind CSS · Radix UI · Zustand
AI/LLM:      OpenRouter (multi-provider) · EmbeddingGemma-300m · FAISS · ONNX Runtime
DevOps:      Docker · systemd · GitHub Actions · pre-commit
VPN:         Xray Core (VLESS/REALITY) · nginx SNI routing
```

*Notice the absence of "blockchain" and "web3"? So did we.*

---

## Quality. Seriously.

**627 tests** — excluding node_modules/dist/.venv:
- myrmex-control: 195
- autoexpert: 67
- lab-playwright-expert: 106
- zprr-tracker: 99
- snablab: 81
- lab-monitoring: 4
- vpn-daemon: 18
- stenographer: 4
- others: ~54

[VERIFIED: find -name "test_*" -not -path "*/node_modules/*" -not -path "*/.venv/*" | wc -l]

**Security:**
- TruffleHog + detect-secrets in pre-push hooks
- Dependabot watches dependencies automatically

**Cascade audits:** agents review each other's code. If one misses something — another catches it. The human doesn't need to be a 24/7 code reviewer.

---

## Infrastructure

- **Server:** Europe (production)
- **VPN:** VLESS + REALITY (Xray Core)
- **Monitoring:** lab-monitoring via systemd timer — no cron, no "forgot to set it up"
- **CI/CD:** GitHub Actions
- **Deploy:** via `merge-to-main.sh` with Git Guardian — no `git push --force` to main

---

## What We Don't Have

Honesty. That's what our competitors are missing.

We don't have:
- ❌ 3 servers across 3 continents (we have 1, and it works)
- ❌ "52 skills" copied from Qwen docs
- ❌ AI that's "planned" or "on the roadmap"
- ❌ "Passive income" as a project (we build actual products)
- ❌ A team of 50 people (8 agents, 23 projects)

What we do have:
- ✅ Running services
- ✅ Documented architecture
- ✅ Quality culture (post-mortem for every incident)
- ✅ Automation that saves hours every day

---

## Stay Connected

- 🌐 [shtab-ai.ru](https://shtab-ai.ru) — website
- 📊 [myrmexcontrol.shtab-ai.ru](https://myrmexcontrol.shtab-ai.ru) — dashboard
- 📡 [@DoctorMES](https://t.me/DoctorMES) — Telegram

We won't promise a 5-minute response. But we will respond. Probably faster than you expect.

---

<div align="center">

**"We don't need a superhero. We need working code."**

*© 2026 DoctorM&Ai Laboratory. The colony is working. Seriously.*

</div>
