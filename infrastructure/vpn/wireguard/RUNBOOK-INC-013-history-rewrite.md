---
description: "Runbook: чистка секретов из истории git — приватные ключи WG/AmneziaWG (INC-013) + cookies браузер-профилей (INC-015)"
type: runbook
last_reviewed: 2026-06-16
status: ready
owner: zavlab
related: [incidents/INC-013-wireguard-private-key-in-git.md, incidents/INC-015-browser-profiles-cookies-in-git.md]
---
# 🔧 RUNBOOK — INC-013 + INC-015: rewrite истории git (удаление секретов)

> **ВНИМАНИЕ — высокий blast radius.** Этот runbook переписывает ВСЮ историю git
> и требует `git push --force` в общий remote `git@github.com:thedoctormes-hue/LabDoctorM.git`.
> После него у КАЖДОГО агента, у кого есть локальный клон, история разойдётся —
> их нужно предупредить и переклонировать. Запускает **только ЗавЛаб**.

## Что и почему
Чистим за один проход ДВА класса секретов из общего первого коммита `dedecf4c`:

- **INC-013** (🔴 critical): **37 блобов** с реальными `PrivateKey`/`PresharedKey`
  (WireGuard + AmneziaWG): сервер `wg0`, клиенты Бестии (iPhone/iPad/MacBook),
  amnezia-wg, `remote-access/awg0.conf`. Список путей — `inc013-secret-paths.txt` (33 пути).
- **INC-015** (🟠 high): **1354 файла** браузер-профилей `infrastructure/browser-use/profiles/`
  с валидными cookies Habr/Yandex/vc.ru (1248 уникальных блобов).
- В **HEAD ключей уже нет** (коммит `8552774e`), профили из индекса убрала Сова
  (`git rm --cached`). Проблема — только в истории. Это **рецидив INC-004**.

> ⛔ **КРИТИЧНО — два разных метода, не путать (проверено на зеркале 16.06):**
> - **WG-ключи → `--strip-blobs-with-ids`** (по blob-id). Содержимое уникально,
>   имена непредсказуемы (`v2..v22`, вложенные `archive/`) — id ловит все версии.
> - **Профили → `--path ... --invert-paths`** (по пути). Удалять профили по blob-id
>   НЕЛЬЗЯ: среди них есть пустой блоб `e69de29b`, общий со ВСЕМИ пустыми
>   `__init__.py`/`conftest.py` в репо. strip-by-id снёс бы 16 легит-файлов кода
>   (snablab, lab-monitoring, context-api). Поймано на тест-прогоне.

## Предусловие (выполнено при подготовке)
- ✅ WG/AmneziaWG-сервис мёртв (`wg show` пусто, unit `disabled`+`inactive`), пиров нет.
- ✅ `git filter-repo` v2.47.0 установлен.
- ✅ Прогон на зеркальной копии (комбинированный проход):
  37 WG-блобов → 0, профилей → 0, HEAD `main` цел (**1273 → 1273 файла, 0 потерь кода**),
  1754 → 1753 коммита (схлопнулся ставший пустым коммит).

## Артефакты подготовки (в /tmp, проверить перед запуском)
- `/tmp/labdoctorm-mirror.git` — зеркальный бэкап ДО чистки (откат).
- `/tmp/secretblobs.txt` — 37 SHA WG-блобов (вход для `--strip-blobs-with-ids`).
- `/tmp/inc013-secret-paths.txt` — 33 пути WG (для отчёта/верификации).
- `/tmp/inc015-profile-paths.txt` — 1354 пути профилей (для отчёта).

> ⚠️ /tmp эфемерен. Перед боевым запуском пересоздать бэкап и список блобов
> (раздел «Пересборка списка» ниже), не полагаться на старые файлы.

---

## Этап 0 — Координация (ОБЯЗАТЕЛЬНО до force-push)
1. Объявить заморозку коммитов в `main` всем агентам (Муравей, Бестия, Ворон,
   Штрейкбрехер, Сова, Мангуст, Доминика).
2. Убедиться, что ни у кого нет неотправленных коммитов (`git log origin/main..HEAD`).
3. Зафиксировать текущий `origin/main` SHA для протокола.

## Этап 1 — Свежий бэкап
```bash
TS=$(date +%Y%m%d-%H%M%S)
git clone --mirror /root/LabDoctorM /root/backups/labdoctorm-pre-inc013-${TS}.git
```

## Этап 2 — Пересборка списка секретных блобов (не доверять старому /tmp)
```bash
cd /tmp && rm -rf scan.git && git clone --mirror /root/LabDoctorM scan.git && cd scan.git
git cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' \
  | awk '$2=="blob"{print $1}' > /tmp/blobs.txt
> /tmp/secretblobs.txt
while read b; do
  if git cat-file -p "$b" 2>/dev/null \
     | grep -qE "(PrivateKey|PresharedKey) *= *[A-Za-z0-9+/]{42,}="; then
    echo "$b" >> /tmp/secretblobs.txt
  fi
done < /tmp/blobs.txt
echo "найдено блобов: $(wc -l < /tmp/secretblobs.txt)"   # ожидаем ~37
```

## Этап 3 — Rewrite на рабочем репо (комбинированный проход)
```bash
cd /root/LabDoctorM
git filter-repo --force \
  --path infrastructure/browser-use/profiles/ --invert-paths \
  --strip-blobs-with-ids /tmp/secretblobs.txt
```
- `--path ... --invert-paths` — удаляет профили (INC-015) по пути.
- `--strip-blobs-with-ids` — удаляет WG-ключи (INC-013) по blob-id.
- filter-repo удалит `origin` remote (это нормально, защита от случайного push).

> ⚠️ НЕ добавлять профильные блобы в `secretblobs.txt` — там пустой блоб `e69de29b`,
> снесёт легит `__init__.py`. Профили — ТОЛЬКО через `--path`.

## Этап 4 — Верификация ДО push
```bash
cd /root/LabDoctorM
# 1. WG-ключи в истории (должно быть ПУСТО):
git cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' \
  | awk '$2=="blob"{print $1}' \
  | while read b; do
      git cat-file -p "$b" 2>/dev/null \
        | grep -qE "(PrivateKey|PresharedKey) *= *[A-Za-z0-9+/]{42,}=" && echo "ОСТАЛОСЬ КЛЮЧ: $b"
    done
# 2. Профили в истории (должно быть 0):
git log --all --pretty=format: --name-only | grep -c 'infrastructure/browser-use/profiles/'
# 3. Целостность HEAD: число файлов main должно совпасть с зеркалом (ожидаем 1273):
git ls-tree -r --name-only main | wc -l
# Всё чисто = ключей нет, профилей 0, дерево цело. Тесты ключевых проектов — зелёные.
```

## Этап 5 — force-push (ТОЧКА НЕВОЗВРАТА, решение ЗавЛаба)
```bash
cd /root/LabDoctorM
git remote add origin git@github.com:thedoctormes-hue/LabDoctorM.git
git push --force --all origin
git push --force --tags origin
```

## Этап 6 — После push
1. Все агенты делают `git clone` заново (старые клоны несовместимы).
   Альтернатива для смелых: `git fetch && git reset --hard origin/main`.
2. На GitHub проверить, что секретов нет в blame/раскопках; при необходимости
   попросить GitHub Support очистить кэш PR/вьюшек.
3. **Ротация ключей** (`rotate.sh --confirm`) — только если WG будет подниматься.
   Сейчас сервис мёртв, ключи нерабочие; ротация обязательна ПЕРЕД запуском WG.
4. Закрыть INC-013, отметить рецидив INC-004 в реестре.

## Откат (если что-то пошло не так ДО или ВО ВРЕМЯ, но до push)
```bash
# рабочий репо испорчен — восстановить из зеркала:
mv /root/LabDoctorM /root/LabDoctorM.broken
git clone /root/backups/labdoctorm-pre-inc013-${TS}.git /root/LabDoctorM
# (или из /tmp/labdoctorm-mirror.git, если бэкап ещё там)
```
После force-push откат сложнее: восстановить историю из зеркала и снова force-push.

## Что я (Кот) НЕ делаю без явной команды ЗавЛаба
- Этап 3 (rewrite рабочего репо), Этап 5 (force-push). Всё до них — обратимо.
