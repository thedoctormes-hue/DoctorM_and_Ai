#!/bin/bash
# Подключение к Miix через резервный chisel туннель
# Использовать когда основной SSH туннель (:2225) недоступен
#
# Установка:
# 1. chisel server на сервере: chisel server --port 8444 --reverse --auth "lab:PASSWORD"
# 2. nginx proxy: /chisel → http://127.0.0.1:8444
# 3. chisel client на Miix: chisel client --auth "lab:PASSWORD" http://78.17.43.205:80/chisel R:0.0.0.0:2226:localhost:22

SERVER="78.17.43.205"
CHISEL_PORT=2226

echo "Подключение к Miix через chisel резервный туннель ($SERVER:$CHISEL_PORT)..."
echo "Для выхода: exit"
echo "---"

ssh -p $CHISEL_PORT root@$SERVER
