#!/usr/bin/env python3
"""
Миграция спеков к единому формату frontmatter.
Добавляет недостающие поля: id, title, weight, priority, assignee, project_id.
"""
import os
import re
import yaml

PROJECTS_ROOT = "/root/LabDoctorM/projects"
SPECS_ROOT = "/root/LabDoctorM/specs"

# Маппинг спеков на проекты
SPEC_PROJECT_MAP = {
    "BL-001": "myrmex-control",
    "BL-002": "myrmex-control",
    "BL-003": "snablab",
    "BL-004": "myrmex-control",
    "BL-049": "snablab",
    "BL-068": "snablab",
    "BL-066": "hype-pilot",
    "BL-067": "hype-pilot",
    "BL-069": "hype-pilot",
    "BL-072": "hype-pilot",
    "BL-073": "hype-pilot",
    "BL-071": "vpn-daemon",
    "BL-075": "openclawbox",
    "BL-076": "openclawbox",
    "BL-077": "openclawbox",
    "BL-078": "openclawbox",
    "BL-079": "openclawbox",
    "BL-080": "openclawbox",
    "BL-057": "protocol-bot",
    "BL-063": "owl",
}

# Маппинг спеков на исполнителей
SPEC_ASSIGNEE_MAP = {
    "BL-001": "ant",
    "BL-002": "ant",
    "BL-003": "bestia",
    "BL-004": "ant",
    "BL-049": "bestia",
    "BL-065": "ant",
    "BL-063": "owl",
}

# Маппинг спеков на вес
SPEC_WEIGHT_MAP = {
    "BL-001": 4, "BL-002": 3, "BL-003": 2, "BL-004": 1,
    "BL-011": 3, "BL-012": 4, "BL-013": 2, "BL-014": 3,
    "BL-015": 2, "BL-016": 2, "BL-017": 2, "BL-019": 3,
    "BL-022": 2, "BL-026": 2, "BL-031": 3, "BL-048": 3,
    "BL-049": 3, "BL-052": 3, "BL-053": 4, "BL-054": 3,
    "BL-055": 3, "BL-056": 3, "BL-057": 4, "BL-058": 3,
    "BL-059": 2, "BL-060": 2, "BL-061": 3, "BL-062": 3,
    "BL-063": 1, "BL-064": 2, "BL-065": 3, "BL-066": 2,
    "BL-067": 3, "BL-068": 3, "BL-069": 3, "BL-070": 3,
    "BL-071": 2, "BL-072": 3, "BL-073": 3, "BL-074": 3,
    "BL-075": 4, "BL-076": 3, "BL-077": 2, "BL-078": 3,
    "BL-079": 3, "BL-080": 4,
}

# Маппинг спеков на приоритет
SPEC_PRIORITY_MAP = {
    "BL-001": "critical", "BL-002": "high", "BL-003": "critical", "BL-004": "medium",
    "BL-011": "high", "BL-012": "high", "BL-013": "high", "BL-014": "high",
    "BL-015": "high", "BL-016": "medium", "BL-017": "medium", "BL-019": "high",
    "BL-022": "medium", "BL-026": "medium", "BL-031": "high", "BL-048": "medium",
    "BL-049": "high", "BL-052": "medium", "BL-053": "high", "BL-054": "medium",
    "BL-055": "medium", "BL-056": "medium", "BL-057": "high", "BL-058": "medium",
    "BL-059": "medium", "BL-060": "medium", "BL-061": "medium", "BL-062": "medium",
    "BL-063": "low", "BL-064": "high", "BL-065": "medium", "BL-066": "medium",
    "BL-067": "medium", "BL-068": "medium", "BL-069": "medium", "BL-070": "medium",
    "BL-071": "medium", "BL-072": "medium", "BL-073": "medium", "BL-074": "medium",
    "BL-075": "medium", "BL-076": "low", "BL-077": "medium", "BL-078": "low",
    "BL-079": "low", "BL-080": "medium",
}


def parse_frontmatter(content):
    """Парсит YAML frontmatter из содержимого файла."""
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if match:
        return yaml.safe_load(match.group(1)), content[match.end():]
    return None, content


def extract_title(content_body):
    """Извлекает заголовок из тела файла."""
    match = re.search(r"^# (.+)$", content_body, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return None


def migrate_spec(filepath):
    """Мигрирует один спек-файл к единому формату."""
    filename = os.path.basename(filepath)
    spec_id = filename.replace(".md", "")

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    fm, body = parse_frontmatter(content)

    if fm is None:
        print(f"  ⚠ {filename}: нет frontmatter, пропуск")
        return False

    # Извлекаем title из заголовка если нет
    title = fm.get("title", "")
    if not title:
        title = extract_body_title(body) or fm.get("description", spec_id)

    # Определяем новые поля
    new_fm = {
        "id": spec_id,
        "title": title,
        "status": fm.get("status", "pending"),
        "priority": SPEC_PRIORITY_MAP.get(spec_id, fm.get("priority", "medium")),
        "weight": SPEC_WEIGHT_MAP.get(spec_id, fm.get("weight", 3)),
        "assignee": SPEC_ASSIGNEE_MAP.get(spec_id, fm.get("assignee", "unassigned")),
        "project_id": SPEC_PROJECT_MAP.get(spec_id, ""),
        "type": fm.get("type", "spec"),
        "last_reviewed": fm.get("last_reviewed", "2026-05-20"),
        "last_code_change": fm.get("last_code_change", "2026-05-20"),
    }

    # Собираем новый файл
    new_content = "---\n"
    new_content += yaml.dump(new_fm, default_flow_style=False, allow_unicode=True)
    new_content += "---\n"
    new_content += body

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"  ✓ {filename}: мигрирован")
    return True


def extract_body_title(body):
    """Извлекает заголовок из тела .md."""
    match = re.search(r"^# (.+)$", body, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return None


def find_all_specs():
    """Находит все BL-*.md файлы."""
    specs = []
    for root, dirs, files in os.walk(PROJECTS_ROOT):
        if "SPECS" in root:
            for f in files:
                if f.startswith("BL-") and f.endswith(".md"):
                    specs.append(os.path.join(root, f))
    unassigned = os.path.join(SPECS_ROOT, "unassigned")
    if os.path.exists(unassigned):
        for f in os.listdir(unassigned):
            if f.startswith("BL-") and f.endswith(".md"):
                specs.append(os.path.join(unassigned, f))
    return specs


def main():
    print("=== Миграция спеков ===\n")
    specs = find_all_specs()
    print(f"Найдено спеков: {len(specs)}\n")

    migrated = 0
    skipped = 0

    for spec in sorted(specs):
        if migrate_spec(spec):
            migrated += 1
        else:
            skipped += 1

    print(f"\n=== Итого: {migrated} мигрировано, {skipped} пропущено ===")


if __name__ == "__main__":
    main()
