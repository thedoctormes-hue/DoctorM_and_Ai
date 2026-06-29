#!/usr/bin/env python3
"""scan-secrets.py — сканирование staged-файлов на секреты.

Вызывается из lab-commit.sh перед коммитом.
Возвращает найденные нарушения (stdout) или пустой вывод (чисто).
"""
import subprocess
import re
import sys

# Паттерн: строка добавления (+) с присваиванием секрета
SECRET_PATTERN = re.compile(
    r'^[+].*'
    r'(password|secret|token|api_key|private_key|apikey'
    r'|TELEGRAM_TOKEN|OPENAI_API_KEY|ANTHROPIC_API_KEY'
    r'|DATABASE_URL|JWT_SECRET)'
    r'\s*[=:]\s*'
    r'["\'`]?'
    r'[A-Za-z0-9+/=_-]{16,}',
    re.IGNORECASE
)

# Исключения: плейсхолдеры, env-переменные, тесты
EXCLUDE_PATTERN = re.compile(
    r'(example|placeholder|your_|test_|<REDACTED>'
    r'|\*\*\*|\{\{|process\.env|config\[|getenv'
    r'|os\.environ|ENV\[|\$\{'
    r'|localhost|127\.0\.0\.1|0\.0\.0\.0'
    r'|changeme|replace_me|INSERT_'
    r'|sk-[A-Za-z]{4,}:XXX'  # masked OpenAI keys
    r')',
    re.IGNORECASE
)

# Расширения файлов для сканирования
SCAN_EXTENSIONS = ('*.py', '*.js', '*.ts', '*.go', '*.sh', '*.yaml', '*.yml', '*.json', '*.md', '*.toml', '*.cfg', '*.ini', '*.env')

def main():
    try:
        diff = subprocess.check_output(
            ['git', '--no-pager', 'diff', '--cached', '--'] + list(SCAN_EXTENSIONS),
            stderr=subprocess.DEVNULL,
            text=True
        )
    except subprocess.CalledProcessError:
        # Нет staged-файлов или git не в репо — молча выходим
        sys.exit(0)

    if not diff.strip():
        sys.exit(0)

    violations = []
    for line in diff.splitlines():
        if SECRET_PATTERN.search(line) and not EXCLUDE_PATTERN.search(line):
            violations.append(line[:150])

    if violations:
        print('\n'.join(violations[:10]))
        sys.exit(0)  # exit 0 — результат в stdout, блокировка в lab-commit.sh

if __name__ == '__main__':
    main()
