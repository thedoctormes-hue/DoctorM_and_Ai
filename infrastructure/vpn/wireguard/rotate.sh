#!/usr/bin/env bash
#
# rotate.sh — ротация ключей WireGuard-сервера wg0 (INC-013)
#
# ПОЧЕМУ: приватный ключ сервера попал в git (INC-013, рецидив INC-004).
# Любой ключ из истории git считается скомпрометированным — нужна ротация,
# переписывания истории недостаточно.
#
# ВНИМАНИЕ: ротация серверного ключа РАЗОРВЁТ соединение со всеми 8 пирами,
# пока им не будут розданы новые публичный ключ сервера и (для части) PSK.
# Это НЕ соло-операция Совы — запускает ЗавЛаб с пониманием простоя.
#
# Запуск (без --confirm только показывает план, ничего не меняет):
#   sudo bash rotate.sh            # dry-run, печатает что будет сделано
#   sudo bash rotate.sh --confirm  # реальная ротация
#
set -euo pipefail

WG_IF="wg0"
CONF="/root/LabDoctorM/infrastructure/vpn/wireguard/wg0.conf"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="${CONF}.bak.${TS}"

CONFIRM="${1:-}"

echo "=== WireGuard rotate (INC-013) ==="
echo "Интерфейс : ${WG_IF}"
echo "Конфиг    : ${CONF}"
echo

if [[ "${CONFIRM}" != "--confirm" ]]; then
  cat <<'PLAN'
[DRY-RUN] Реального изменения НЕ будет. План ротации:

  1. Бэкап текущего wg0.conf (рядом, с таймстампом).
  2. Генерация новой пары ключей сервера (wg genkey | wg pubkey).
  3. Генерация новых PresharedKey для пиров, у которых PSK есть.
  4. Замена PrivateKey в [Interface] на новый.
  5. Перезапуск туннеля: wg-quick down wg0 && wg-quick up wg0.
  6. Печать НОВОГО публичного ключа сервера + новых PSK для раздачи пирам.

  После запуска ОБЯЗАТЕЛЬНО раздать каждому из 8 пиров:
    - новый PublicKey сервера (во все клиентские конфиги)
    - новый PresharedKey (тем пирам, у кого он был)
  Пока пиры не обновлены — связи с ними не будет.

Чтобы выполнить по-настоящему:  sudo bash rotate.sh --confirm
PLAN
  exit 0
fi

echo "[1/6] Бэкап -> ${BACKUP}"
cp -a "${CONF}" "${BACKUP}"

echo "[2/6] Новая пара ключей сервера"
NEW_PRIV="$(wg genkey)"
NEW_PUB="$(printf '%s' "${NEW_PRIV}" | wg pubkey)"

echo "[3/6] Замена PrivateKey в [Interface]"
# Меняем только строку PrivateKey внутри секции [Interface] (первая в файле).
sed -i "0,/^PrivateKey *=.*/s##PrivateKey = ${NEW_PRIV}#" "${CONF}"

echo "[4/6] Перегенерация PresharedKey у пиров (где PSK присутствует)"
# Для каждой строки PresharedKey подставляем свежий ключ и запоминаем для вывода.
PSK_LOG=""
while IFS= read -r line; do
  NEW_PSK="$(wg genpsk)"
  PSK_LOG+="  PresharedKey -> ${NEW_PSK}"$'\n'
done < <(grep -c '^PresharedKey' "${CONF}" >/dev/null; grep '^PresharedKey' "${CONF}")
# Заменяем все PSK по очереди свежими.
while grep -q '^PresharedKey *=' "${CONF}"; do
  NEW_PSK="$(wg genpsk)"
  sed -i "0,/^PresharedKey *=.*/s##PresharedKey = ${NEW_PSK}#" "${CONF}"
done

echo "[5/6] Перезапуск туннеля"
wg-quick down "${WG_IF}" || true
wg-quick up "${WG_IF}"

echo "[6/6] ГОТОВО. Раздай пирам новые данные:"
echo
echo "  >>> НОВЫЙ ПУБЛИЧНЫЙ КЛЮЧ СЕРВЕРА (во все клиентские конфиги):"
echo "      ${NEW_PUB}"
echo
echo "  >>> Новые PresharedKey — см. актуальный ${CONF} (раздать соответствующим пирам)."
echo
echo "Бэкап старого конфига: ${BACKUP}"
echo "Не забудь: старый ключ остаётся в истории git — нужен rewrite истории (этап 3 INC-013)."
