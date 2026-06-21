#!/usr/bin/env python3
"""
Lab Bridge — мост между Myrmex UI и агентами через Telegram.

Userbot (Telethon) логинится как ЗавЛаб и отправляет сообщения ботам агентов.
HTTP API на порту 8110 для приёма команд от Myrmex.

Схема: Myrmex UI → HTTP POST /api/send → Telethon → Telegram → qwen channel → агент
"""

import asyncio
import json
import logging
import os
import sys
from pathlib import Path

from aiohttp import web
from telethon import TelegramClient, events

# ─── Конфиг ──────────────────────────────────────────────────────────────
API_ID = int(os.environ.get("TG_API_ID", "0"))
API_HASH = os.environ.get("TG_API_HASH", "")
SESSION_DIR = Path(os.environ.get("SESSION_DIR", "/root/LabDoctorM/services/lab-bridge"))
SESSION_NAME = "zavlab_session"
PORT = int(os.environ.get("BRIDGE_PORT", "8110"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("lab-bridge")

# Агенты: имя канала → username бота
AGENTS = {
    "kotolizator": "@kOtolizatOrobot",
    "antcat": "@AntCatOnebot",
    "bestia": "@bestiarobot",
    "streikbrecher": "@Streikbrecherobot",
    "raven": "@rawen_robot",
    "owl": "@owl_iso_bot",
}

# ─── Глобальный клиент ───────────────────────────────────────────────────
client: TelegramClient = None


async def send_to_agent(agent: str, text: str) -> dict:
    """Отправить сообщение агенту через Telegram userbot."""
    username = AGENTS.get(agent)
    if not username:
        return {"ok": False, "error": f"Неизвестный агент: {agent}. Доступные: {list(AGENTS.keys())}"}

    try:
        entity = await client.get_entity(username)
        msg = await client.send_message(entity, text)
        log.info("→ %s [%s]: %s", agent, username, text[:80])
        return {
            "ok": True,
            "agent": agent,
            "bot": username,
            "message_id": msg.id,
            "text": text,
        }
    except Exception as e:
        log.error("Ошибка отправки %s: %s", agent, e)
        return {"ok": False, "agent": agent, "error": str(e)}


# ─── HTTP API ────────────────────────────────────────────────────────────
routes = web.RouteTableDef()


@routes.get("/health")
async def health(req):
    me = await client.get_me() if client and client.is_connected() else None
    return web.json_response({
        "status": "ok" if me else "disconnected",
        "user": me.first_name if me else None,
        "user_id": me.id if me else None,
    })


@routes.get("/api/agents")
async def list_agents(req):
    return web.json_response({
        "agents": [
            {"id": k, "bot": v} for k, v in AGENTS.items()
        ]
    })


@routes.post("/api/send")
async def api_send(req):
    """Отправить задачу агенту. Body: {"agent": "kotolizator", "text": "..."}"""
    body = await req.json()
    agent = body.get("agent", "")
    text = body.get("text", "")

    if not agent or not text:
        return web.json_response(
            {"ok": False, "error": "Нужны поля agent и text"},
            status=400,
        )

    result = await send_to_agent(agent, text)
    status = 200 if result.get("ok") else 502
    return web.json_response(result, status=status)


@routes.post("/api/broadcast")
async def api_broadcast(req):
    """Отправить сообщение всем агентам. Body: {"text": "..."}"""
    body = await req.json()
    text = body.get("text", "")
    if not text:
        return web.json_response({"ok": False, "error": "Нужно поле text"}, status=400)

    results = {}
    for agent in AGENTS:
        results[agent] = await send_to_agent(agent, text)

    ok_count = sum(1 for r in results.values() if r.get("ok"))
    return web.json_response({
        "ok": True,
        "sent": ok_count,
        "total": len(AGENTS),
        "results": results,
    })


# ─── Входящие ответы агентов ────────────────────────────────────────────
# Логируем ответы, чтобы видеть что происходит
@events.register(events.NewMessage(incoming=True))
async def on_incoming(event):
    sender = await event.get_sender()
    # Ищем какого агента это ответ
    for agent_name, bot_username in AGENTS.items():
        if sender.username and sender.username.lower() == bot_username.lower().lstrip("@"):
            log.info("← %s [%s]: %s", agent_name, bot_username, event.text.text[:120] if hasattr(event.text, 'text') else str(event.text)[:120])
            break


# ─── Main ────────────────────────────────────────────────────────────────
async def main():
    global client

    session_path = SESSION_DIR / SESSION_NAME
    client = TelegramClient(str(session_path), API_ID, API_HASH)

    log.info("Подключение к Telegram...")
    await client.start()
    me = await client.get_me()
    log.info("Авторизован как %s (id=%s)", me.first_name, me.id)

    # Регистрируем обработчик входящих
    client.add_event_handler(on_incoming, events.NewMessage(incoming=True))

    # HTTP сервер
    app = web.Application()
    app.add_routes(routes)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "127.0.0.1", PORT)
    await site.start()
    log.info("Lab Bridge API на http://127.0.0.1:%d", PORT)

    # Держим запущенным
    await client.run_until_disconnected()


if __name__ == "__main__":
    if not API_ID or not API_HASH:
        print("Нужны TG_API_ID и TG_API_HASH")
        sys.exit(1)
    asyncio.run(main())
