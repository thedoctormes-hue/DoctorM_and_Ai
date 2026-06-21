---
description: "GitHub Scan Summary - Laboratory Projects"
type: guide
last_reviewed: 2026-05-08
last_code_change: 2026-05-08
status: active
---
# GitHub Scan Summary - Laboratory Projects

**Date:** May 3, 2026
**Account:** thedoctormes-hue

---

## 📊 Repo Scan Results

### 🔍 Project → Repository Mapping

| Project | Type | Upstream Repos Found | Status |
|---------|------|---------------------|--------|
| kotolizator | cli-system | QwenLM/qwen-code | ✅ Watched |
| msk-gastro-digest-bot | telegram-bot | aiogram/aiogram | ⭐ Starred |
| vpn-daemon | telegram-bot | XTLS/Xray-core, shadowsocks/shadowsocks-rust | ✅ Watched |
| mail-daemon | telegram-bot | aiogram/aiogram | ⭐ Starred |
| stenographer | telegram-bot | aiogram/aiogram | ⭐ Starred |
| llm-evangelist | telegram-bot | python-telegram-bot/python-telegram-bot | ⭐ Starred (own) |
| syncthing-dashboard | dashboard | syncthing/syncthing | ⭐ Starred (own) |
| os-lab-api | api | Kludex/starlette (was encode/starlette) | ⭐ Starred (own) |
| protocol | infrastructure | modelcontextprotocol/python-sdk | ✅ Watched |
| metrics | infrastructure | - | - |

---

## ✅ Actions Completed

### Watched Repos (Critical - Breaking Change Risk)
- ✅ **QwenLM/qwen-code** - Already watched (24.1k stars, TypeScript)
- ✅ **XTLS/Xray-core** - Now watching (38.1k stars, Go) - VPN critical
- ✅ **modelcontextprotocol/python-sdk** - Now watching (22.9k stars, Python) - MCP spec

### Starred Repos (Lab Own + Dependencies)
- ⭐ thedoctormes-hue/os-lab-api (own repo)
- ⭐ thedoctormes-hue/syncthing-dashboard (own repo)
- ⭐ thedoctormes-hue/llm-evangelist (own repo)
- ⭐ thedoctormes-hue/shtab-ai-gb52 (own repo)
- ⭐ QwenLM/qwen-code (already starred)
- ⭐ XTLS/Xray-core (already starred)
- ⭐ modelcontextprotocol/python-sdk, servers

---

## 📈 Subscription Recommendations

### 🔴 PERMANENT WATCH (Critical Infrastructure)
| Repo | Stars | Why | Risk |
|------|-------|-----|------|
| QwenLM/qwen-code | 24.1k | Core CLI tool | Breaking changes affect all lab CLI work |
| XTLS/Xray-core | 38.1k | VPN core, REALITY/XHTTP protocols | Critical for VPN daemon functionality |
| modelcontextprotocol/python-sdk | 22.9k | MCP protocol, Protocol bot | Future protocol integrations |

### 🟡 TEMPORARY STAR (Dependencies)
| Repo | Stars | Purpose | Review Date |
|------|-------|---------|-------------|
| aiogram/aiogram | 5.7k | Telegram bot framework | Every 6 months |
| python-telegram-bot/python-telegram-bot | 29.1k | Alternative bot framework | If migration needed |
| shadowsocks/shadowsocks-rust | 10.6k | Backup VPN protocol | When Shadowsocks-2022 deployed |
| Kludex/starlette | 12.3k | ASGI framework (formerly encode/starlette) | Major version updates only |
| syncthing/syncthing | 83.5k | File sync target | Feature releases |

### 🟢 OWN REPOS (Already Starred)
| Repo | Type | Integration |
|------|------|-------------|
| thedoctormes-hue/os-lab-api | FastAPI monitoring | Warsaw/Florida/RF servers |
| thedoctormes-hue/syncthing-dashboard | Dashboard | Port 8002, nginx |
| thedoctormes-hue/llm-evangelist | Telegram bot | @llm_evangelist channel |
| thedoctormes-hue/shtab-ai-gb52 | Landing page | shtab-ai.ru |

---

## ⚠️ Notes

1. **starlette moved**: Formerly `encode/starlette`, now `Kludex/starlette` (301 redirect)
2. **No encode/starlette**: The repo was transferred - ensure dependencies point to Kludex/starlette
3. **Lab repos are public**: 4 public repos found under thedoctormes-hue
4. **MCP trend**: modelcontextprotocol/servers also starred for reference implementations

---

## 🎯 Next Actions

- [ ] Monitor Xray-core releases for REALITY/XHTTP protocol updates
- [ ] Set up daily watch check via cron: `gh api /user/subscriptions`
- [ ] Review aiogram/starlette compatibility before major upgrades
