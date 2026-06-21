#!/usr/bin/env python3
"""Логин через SMS — код приходит по SMS, не через Telegram."""
import asyncio
import os
import time
from telethon import TelegramClient

API_ID = 30392789
API_HASH = "3258d2d7a1e956aac22cbb28feec168b"
SESSION = "/root/LabDoctorM/services/lab-bridge/zavlab_session"
PHONE = "+79049653419"
CODE_FILE = "/tmp/tg_login_code"


async def main():
    client = TelegramClient(SESSION, API_ID, API_HASH)
    await client.connect()

    if await client.is_user_authorized():
        me = await client.get_me()
        print(f"Уже авторизован: {me.first_name} id={me.id}", flush=True)
        await client.disconnect()
        return

    # Запрашиваем код через SMS
    await client.send_code_request(PHONE, force_sms=True)
    print("SMS отправлен! Код придёт по SMS на +79049653419", flush=True)
    print("Жду код в /tmp/tg_login_code ...", flush=True)

    # Ждём код из файла
    for _ in range(180):
        if os.path.exists(CODE_FILE):
            code = open(CODE_FILE).read().strip()
            if code:
                os.unlink(CODE_FILE)
                break
        await asyncio.sleep(1)
    else:
        print("Таймаут!", flush=True)
        await client.disconnect()
        return

    # Подтверждаем вход
    await client.sign_in(PHONE, code)
    me = await client.get_me()
    print(f"OK: {me.first_name} id={me.id}", flush=True)

    from telethon.sessions import StringSession
    with open(SESSION + ".string", "w") as f:
        f.write(client.session.save())
    print("StringSession saved", flush=True)

    await client.disconnect()


asyncio.run(main())
