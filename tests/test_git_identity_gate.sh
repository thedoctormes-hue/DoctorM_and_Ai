#!/bin/bash
# Тест: race-free атрибуция коммитов (lab-commit.sh + гейт pre-commit).
# Воспроизводит гонку за общий .git/config и проверяет 4 сценария.
set -uo pipefail

LAB_ROOT="/root/LabDoctorM"
LAB_COMMIT="$LAB_ROOT/scripts/lab-commit.sh"
PRECOMMIT="$LAB_ROOT/.githooks/pre-commit"
AUTHORS="$LAB_ROOT/.qwen/git-authors.json"

PASS=0; FAIL=0
ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p .qwen scripts .githooks
cp "$AUTHORS" .qwen/git-authors.json
cp "$LAB_COMMIT" scripts/lab-commit.sh
cp "$PRECOMMIT" .githooks/pre-commit
chmod +x scripts/lab-commit.sh .githooks/pre-commit
git config core.hooksPath .githooks
# Имитируем "перетёртый общий config" — чужой агент
git config user.name "Сова"
git config user.email "owl@labdoctorm.ru"
git checkout -q -b antcat/session

echo "── Сценарий 1: lab-commit antcat при config=Сова → автор antcat ──"
echo "a" > f1 && git add f1
if scripts/lab-commit.sh antcat -m "test antcat" >/dev/null 2>&1; then
  A=$(git log -1 --pretty='%an <%ae>')
  [ "$A" = "Муравей <antcat@labdoctorm.ru>" ] && ok "автор = $A (config перетёрт, но env победил)" || bad "автор = $A (ожидался Муравей)"
else
  bad "lab-commit antcat упал"
fi

echo "── Сценарий 2: голый git commit с LAB_AGENT=antcat при config=Сова → ГЕЙТ блокирует ──"
echo "b" > f2 && git add f2
if LAB_AGENT=antcat git commit -m "naked commit" >/dev/null 2>&1; then
  bad "коммит прошёл (гейт не сработал!), автор=$(git log -1 --pretty='%an')"
else
  ok "гейт заблокировал коммит под чужим автором"
fi
git reset -q HEAD f2 2>/dev/null; rm -f f2

echo "── Сценарий 3: lab-commit с неизвестным агентом → ошибка обёртки ──"
echo "c" > f3 && git add f3
if scripts/lab-commit.sh nosuchagent -m "x" >/dev/null 2>&1; then
  bad "обёртка приняла неизвестного агента"
else
  ok "обёртка отвергла неизвестного агента"
fi
git reset -q HEAD f3 2>/dev/null; rm -f f3

echo "── Сценарий 4: параллельные коммиты (гонка config) → атрибуция корректна ──"
# Запускаем 2 коммита от разных агентов одновременно, между ними дёргаем config
git checkout -q -b raven/session
( for i in 1 2 3 4 5; do git config user.name "RANDOM$i"; git config user.email "rnd$i@x.ru"; sleep 0.02; done ) &
NOISE=$!
echo "d" > f4 && git add f4
scripts/lab-commit.sh raven -m "parallel raven" >/dev/null 2>&1
A4=$(git log -1 --pretty='%an <%ae>')
wait $NOISE 2>/dev/null
[ "$A4" = "Ворон <raven@labdoctorm.ru>" ] && ok "автор = $A4 (несмотря на шум в config)" || bad "автор = $A4 (ожидался Ворон)"

echo ""
echo "════════ РЕЗУЛЬТАТ: $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
