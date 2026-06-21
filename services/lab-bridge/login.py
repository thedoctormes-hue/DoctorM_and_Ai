#!/usr/bin/env python3
"""Первый логин Telethon — код из файла, 2FA пароль тоже."""
import sys, os, time
from telethon.sync import TelegramClient

PHONE = "+79049653419"
API_ID = 30392789
API_HASH = "3258d2d7a1e956aac22cbb28feec168b"
SESSION = "/root/LabDoctorM/services/lab-bridge/zavlab_session"
CODE_FILE = "/tmp/tg_login_code"

def code_callback():
    print("WAITING_FOR_CODE", flush=True)
    for _ in range(180):  # 3 минуты
        if os.path.exists(CODE_FILE):
            code = open(CODE_FILE).read().strip()
            if code:
                os.unlink(CODE_FILE)
                return code
        time.sleep(1)
    raise RuntimeError("Код не получен за 180 секунд")

client = TelegramClient(SESSION, API_ID, API_HASH)
client.start(phone=PHONE, code_callback=code_callback)
me = client.get_me()
print(f"OK: {me.first_name} id={me.id}", flush=True)
client.disconnect()
