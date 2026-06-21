#!/usr/bin/env python3
"""Логин через QR — PNG через Pillow."""
import asyncio
import os
import qrcode
from PIL import Image
from telethon import TelegramClient

API_ID = 30392789
API_HASH = "3258d2d7a1e956aac22cbb28feec168b"
SESSION = "/root/LabDoctorM/services/lab-bridge/zavlab_session"
QR_PATH = "/var/www/html/lab-bridge-qr.png"


def save_qr_png(url):
    qr = qrcode.QRCode(box_size=20, border=4, error_correction=qrcode.constants.ERROR_CORRECT_L)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    img = img.convert("RGB")
    img.save(QR_PATH, "PNG")
    sz = os.path.getsize(QR_PATH)
    print(f"QR saved ({sz} bytes): http://78.17.43.205:8888/lab-bridge-qr.png", flush=True)


async def main():
    client = TelegramClient(SESSION, API_ID, API_HASH)
    await client.connect()

    if await client.is_user_authorized():
        me = await client.get_me()
        print(f"OK: {me.first_name} id={me.id}", flush=True)
        await client.disconnect()
        return

    qr_login = await client.qr_login()
    save_qr_png(qr_login.url)

    while True:
        try:
            await qr_login.wait(timeout=90)
            break
        except asyncio.TimeoutError:
            await qr_login.recreate()
            save_qr_png(qr_login.url)

    me = await client.get_me()
    print(f"OK: {me.first_name} id={me.id}", flush=True)

    from telethon.sessions import StringSession
    with open(SESSION + ".string", "w") as f:
        f.write(client.session.save())
    print("StringSession saved", flush=True)

    await client.disconnect()


asyncio.run(main())
