# ADR 2026-07-20: Nextcloud (GyxerCloud) как второй Colony Groupware-hub

- **Статус:** accepted
- **Дата:** 2026-07-20
- **Автор:** КотОлизатОр (kotolizator)
- **Канон:** `projects/DoctorM_and_Ai/adr/`

## Контекст

Лаборатория использует **Colony Disk Exchange** для файлообмена между агентами
OpenClaw и ЗавЛабом — ранее только на Яндекс Диске (`yandex.sh`, скилл `yandex-suite`).
Со временем выяснилось:

- На VPS лабы (AdminVPS) **почта заблокирована** провайдером (порты 25/110/143/465/587/993/995),
  жив только HTTPS 443. Через `yandex.sh` работают только Диск/CalDAV/CardDAV; почта в тупике.
- ЗавЛабу выделили **собственный инстанс Nextcloud** — `cloud.gyxer.com` (GyxerCloud, Nextcloud 32.0.0,
  5 GB, друг-админ; логин ЗавЛаба `mrBaristo`). `mrBaristo` НЕ является суб-админом
  (403 на `provisioning_api` создание юзеров), но имеет полный доступ ко всем приложениям
  через app-password.
- ЗавЛаб решил (2026-07-20): использовать инстанс **только для себя и агентов OpenClaw**,
  внешних людей не подключать.

Цель: дать агентам и ЗавЛабу единый, программно-доступный groupware-хаб поверх одного
инстанса Nextcloud — файлы + календари + контакты + чат + заметки + канбан — без браузера,
через единый скрипт и единый app-password.

## Решение

1. **Второй Colony-канал на Nextcloud.** Структура `/colony/` повторяет паттерн Яндекс Диска:
   - `/colony/inbox/<agent>/` и `/colony/outbox/<agent>/` для 9 субъектов
     (`mangust dominika kotolizator antcat bestia owl raven streikbrecher zavlab`)
   - `/colony/shared/` — общие артефакты
   - `/colony/backups/` — бэкапы
2. **Обёртка `nc.sh`** (canonical: `projects/DoctorM_and_Ai/bin/nc.sh`, по образцу `yandex.sh`):
   - Файлы (WebDAV): `ls get put del mkdir`
   - Calendar (CalDAV): `cal ls/add/rm`
   - Contacts (CardDAV): `contacts ls`
   - Talk (OCS): `talk ls/send`
   - Notes (REST): `notes ls/add/rm`
   - Deck (REST канбан): `deck ls/add`
   - `usage` — сводка лога
   - Лог всех вызовов в `.ops/logs/nc-usage.log` (сервис | действие | аккаунт | результат).
3. **Auth:** Nextcloud app-password хранится в `~/.config/nextcloud/.nc-pass` (chmod 600,
   **вне git**). Скрипт читает его сам; в CLI не светится. Login — `~/.config/nextcloud/.nc-user`.
4. **Бэклог — почта.** Nextcloud Mail app на инстансе **выключен** (нет в OCS capabilities,
   API `404`). Если друг-админ включит Mail app и добавит внешний IMAP-аккаунт
   (напр. `moscowskiymichi@yandex.ru`), агенты смогут читать/писать почту через API Nextcloud
   поверх 443 — это **обходит блок почтовых портов VPS лабы**. Задача в бэклоге:
   запросить у друга включение + дописать `nc.sh mail ...`.

## Следствия

- **Плюсы:** агенты получают groupware (файлы/кал/контакты/чат/заметки/канбан) через единый
  скрипт и единый пароль; выделенный 5 GB независим от квот Яндекса; структура изолирована
  от внешних людей.
- **Минусы/риски:** `mrBaristo` не админ — нельзя программно создавать юзеров через API
  (внешних людей всё равно не подключаем по решению ЗавЛаба, поэтому не критично). Почта
  заблокирована до действия админа. Все агенты сейчас ходят под одним app-password
  `mrBaristo` (раздельные per-agent пароли — опционально, генерит ЗавЛаб в UI Settings→Security).
- **Связь с Яндексом:** `yandex.sh`/`yandex-suite` остаётся основным для Диска/Календаря/Контактов
  лабы; Nextcloud — второй hub для выделенного обмена ЗавЛаба и агентов. Не дублируем функционал
  (PAT-004): если задача покрывается Яндексом — используем его; Nextcloud — для изолированного
  `/colony/` обмена и будущей почты.

## Проверка (2026-07-20, живьём)

- Структура `/colony/*` создана (MKCOL 201), round-trip `put→get→del` = 201/200/204.
- OCS capabilities: включены `calendar`, `dav`, `spreed`(Talk), `notes`, `deck`, `assistant`,
  `provisioning_api` (без прав суб-админа), `mail` — ВЫКЛЮЧЕН.
- `nc.sh` команды: `disk ls`(207), `cal ls`(207), `contacts ls`(207), `talk ls`(200),
  `notes ls`(200), `deck ls`(200), `notes add`+`notes rm` round-trip = 200.
- Бэклог почты зафиксирован в `workspaces/kotolizator/MEMORY.md`.

## Обратная совместимость

Не ломает ничего существующего. `nc.sh` — новый файл, не конфликтует с `yandex.sh`.
`/colony/` — новая структура на отдельном инстансе.
