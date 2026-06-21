---
name: project-structure
description: Структура проектов — каждый проект в своей папке, не монорепозиторий.
type: insight
status: active
verified: 2026-06-17
source: project_structure.md
---

# 📁 Структура Проектов

## Принцип

LabDoctorM — НЕ монорепозиторий. Каждый проект — отдельный репозиторий в своей папке.

## Текущее состояние (подтверждено 2026-06-17)

```
/root/LabDoctorM/
├── projects/
│   ├── snablab/          ← свой .git или worktree
│   ├── autoexpert/       ← свой .git
│   ├── hype-pilot/       ← свой .git
│   ├── lab-playwright-expert/ ← свой .git
│   ├── zprr-tracker/     ← свой .git
│   ├── bestia/           ← worktree
│   ├── kotolizator/      ← worktree
│   ├── owl/              ← worktree
│   ├── raven/            ← worktree
│   └── streikbrecher/    ← worktree
```

## Правила коммитов

- Если папка содержит `.git` — коммитить из неё (это проект)
- Если нет — коммитить из корня `/root/LabDoctorM/` через worktree
- НЕ использовать `git add .` из корня — только конкретные пути
