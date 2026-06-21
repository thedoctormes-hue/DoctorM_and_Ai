<div align="center">

# 🧬 LabDoctorM

**An AI lab that's been shipping while you were reading this README.**

*Founded April 25, 2026. In 70 days: 18 repos, ~950 tests, 0 days of downtime.*

[![Website](https://img.shields.io/badge/Website-shtab--ai.ru-00D4AA?style=flat-square)](https://shtab-ai.ru)
[![Dashboard](https://img.shields.io/badge/Dashboard-myrmexcontrol.shtab--ai.ru-00D4AA?style=flat-square)](https://myrmexcontrol.shtab-ai.ru)
[![Telegram](https://img.shields.io/badge/Telegram-@DoctorMES-00D4AA?style=flat-square)](https://t.me/DoctorMES)

[🇬🇧 English](#) · [🇷🇺 Русский](README.md)

</div>

---

## Why You're Still Reading

We don't have a pitch deck. No whitepaper. No slides with stock photos and "AI-powered" stamped on them.

Here's what we do have:

- **6 AI agents** writing code 24/7 — not as a demo, but on production
- **Autonomous incident response** — when one agent screws up, another runs the post-mortem. The human doesn't even wake up.
- **~950+ tests** — because we don't trust "it works on my machine"

If that's interesting — keep reading. If you need more proof — we'll prove it.

---

## The Agents

Six specialists. Nobody's an "assistant". Each one owns their domain.

| Agent | Specialization | What They Actually Do |
|-------|---------------|----------------------|
| 🐱 **Kotolizator** | Coordination | VPN, data, monitoring. Knows what's happening at any given moment |
| 🐜 **Ant** | Engineering | Myrmex Control, bots, automation. Writes code that doesn't need rewriting |
| 🐺 **Bestia** | Infrastructure | SnabLab, services. Keeps production alive |
| ⚡ **Streikbrecher** | Fullstack | Cross-project development. The one who sees the whole picture |
| 🦉 **Owl** | Audit & Quality | Standards, architecture. Won't let bad code through |
| 🐦‍⬛ **Raven** | Recon | Monitoring, analytics, content. Flies ahead and finds threats |

**ZavLab** — human operator. Sets tasks. Makes strategic decisions. Doesn't write code at 3am (the agents do that for him).

---

## Projects That Run Right Now

### 🟢 Production — live, delivering value

| Project | What It Does | Stack |
|---------|--------------|-------|
| [myrmex-control](https://github.com/thedoctormes-hue/myrmex-control) ⚡ | Lab control panel: kanban, sessions, artifacts, chat. 116 tests | React 19, TS, Express |
| [lab-vault](https://github.com/thedoctormes-hue/lab-vault) 🔐 | Secret manager for AI agents. Go. Works. Secrets stay secret. | Go |
| [mail-daemon](https://github.com/thedoctormes-hue/mail-daemon) 📬 | IMAP monitoring + AI classification + OCR. No fantasies — it just works | Go |
| [zprr-tracker](https://github.com/thedoctormes-hue/zprr-tracker) 👶 | Speech development tracker for children. Real kids, real results | FastAPI, React, PostgreSQL |
| [consilium](https://github.com/thedoctormes-hue/consilium) 🧠 | AI consultant. Analyzes, recommends, says when it doesn't know | Go |

### 🟡 Active — in development, close to production

| Project | What It Does | Stack |
|---------|--------------|-------|
| [autoexpert](https://github.com/thedoctormes-hue/autoexpert) | Traffic accident damage assessment with AI. 132 tests | FastAPI, React/Vite, PostgreSQL |
| [snablab](https://github.com/thedoctormes-hue/snablab) | Lab consumables procurement management | Python, PostgreSQL |
| [hype-pilot](https://github.com/thedoctormes-hue/hype-pilot) | Telegram autoposting. 44 tests. Posts while you sleep | Python, Playwright |
| [lab-monitoring](https://github.com/thedoctormes-hue/lab-monitoring) | Monitors everything. 81 tests. systemd timer. Sleeps with us | Python, systemd |
| [artifact-pulse](https://github.com/thedoctormes-hue/artifact-pulse) | Lab artifact health monitoring | Python |
| [lab-playwright-expert](https://github.com/thedoctormes-hue/lab-playwright-expert) | Test automation framework. 326 tests for testing tests | Python, Playwright |
| [stenographer](https://github.com/thedoctormes-hue/stenographer) | Audio/video transcription from Telegram. 12 tests | Python, aiogram |
| [vpn-daemon](https://github.com/thedoctormes-hue/vpn-daemon) | VPN management via Telegram. 36 tests | Python, aiogram, PostgreSQL |
| [SNZK](https://github.com/thedoctormes-hue/SNZK) | Narrative web project | TypeScript, Vite, Canvas |
| [remote-access](https://github.com/thedoctormes-hue/remote-access) | Remote equipment access | Bash, Xray, SSH |

### 🔴 Cheque-bot — frozen

There was an accounting bot. It's frozen. We won't pretend it's "in the roadmap".

---

## Architecture. Bold and Precise.

```
ZavLab
  └── Myrmex Control
        ├── Kotolizator ─── VPN, data, coordination
        ├── Ant ─────────── engineering, Myrmex, bots
        ├── Bestia ──────── infrastructure, SnabLab
        ├── Streikbrecher — fullstack, architecture
        ├── Owl ─────────── audit, standards, quality
        └── Raven ──────── recon, monitoring
```

**Facts without decoration:**
- Each agent works in an **isolated git worktree** — no conflicts
- **25 ADR** at root + **14 ADR** in myrmex-control — every decision documented
- **13 incidents** recorded with post-mortem — none repeated
- **Git Guardian** won't let you push garbage to main. Not even us.

---

## Technology

We don't chase trends. We use what works.

```
Languages:   Python · TypeScript · Go · Bash
Backend:     FastAPI · aiogram · Express · PostgreSQL · SQLite
Frontend:    React 19 · Vite · Tailwind CSS · Telegram Web Apps
DevOps:      Docker · systemd · GitHub Actions · pre-commit
VPN:         Xray Core (VLESS/REALITY) · nginx SNI routing
AI Core:     Qwen Code · multi-agent system · self-evolution
```

*Notice the absence of "blockchain" and "web3"? So did we.*

---

## Quality. Seriously.

**~950+ tests** — conservative count:
- myrmex-control: 116
- autoexpert: 132
- lab-monitoring: 81
- lab-playwright-expert: 326
- hype-pilot: 44
- vpn-daemon: 36
- stenographer: 12
- artifact-pulse: 5

**Security:**
- TruffleHog + detect-secrets in pre-push hooks
- Dependabot watches dependencies automatically
- 36 vulnerabilities detected by Dependabot — all being addressed

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
- ❌ A team of 50 people (6 agents do more)

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
