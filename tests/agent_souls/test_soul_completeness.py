#!/usr/bin/env python3
"""Comprehensive pytest suite for agent SOUL.md and IDENTITY.md files.

Checks per agent:
  - SOUL.md has Goal and Tool Policy sections with >= 3 bullets each
  - No markdown tables in SOUL.md or IDENTITY.md
  - IDENTITY.md contains required front-matter fields: description, type, status, version
"""

import os
import re
import pytest

WORKSPACE = "/root/LabDoctorM/workspaces"
AGENTS = ["antcat", "bestia", "dominika", "kotolizator", "mangust", "owl", "raven", "streikbrecher"]


def _load(name: str, filename: str) -> str:
    path = os.path.join(WORKSPACE, name, filename)
    if not os.path.exists(path):
        pytest.fail(f"{filename} not found for {name}")
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def _has_section(content: str, title: str) -> bool:
    return bool(re.search(rf"##\s*{re.escape(title)}", content, re.IGNORECASE))


def _extract_section(content: str, title: str) -> str:
    m = re.search(rf"##\s*{re.escape(title)}", content, re.IGNORECASE)
    if not m:
        return ""
    start = m.end()
    nxt = re.search(r"\n##\s", content[start:])
    end = start + nxt.start() if nxt else len(content)
    return content[start:end]


def _count_bullets(text: str) -> int:
    return len([l for l in text.splitlines() if re.match(r"\s*[-*]\s+", l)])


def _has_no_tables(content: str) -> bool:
    for line in content.splitlines():
        if line.strip().startswith("|") and line.count("|") >= 2:
            return False
    return True


@pytest.mark.parametrize("agent", AGENTS)
def test_soul_has_goal_section(agent):
    content = _load(agent, "SOUL.md")
    assert _has_section(content, "Goal"), f"{agent}: missing Goal section"


@pytest.mark.parametrize("agent", AGENTS)
def test_soul_has_tool_policy_section(agent):
    content = _load(agent, "SOUL.md")
    assert _has_section(content, "Tool Policy"), f"{agent}: missing Tool Policy section"


@pytest.mark.parametrize("agent", AGENTS)
def test_soul_goal_min_bullets(agent):
    content = _load(agent, "SOUL.md")
    section = _extract_section(content, "Goal")
    assert _count_bullets(section) >= 3, f"{agent}: Goal section has fewer than 3 bullets"


@pytest.mark.parametrize("agent", AGENTS)
def test_soul_tool_policy_min_bullets(agent):
    content = _load(agent, "SOUL.md")
    section = _extract_section(content, "Tool Policy")
    assert _count_bullets(section) >= 3, f"{agent}: Tool Policy has fewer than 3 bullets"


@pytest.mark.parametrize("agent", AGENTS)
def test_soul_no_tables(agent):
    content = _load(agent, "SOUL.md")
    assert _has_no_tables(content), f"{agent}: SOUL.md contains a markdown table"


@pytest.mark.parametrize("agent", AGENTS)
def test_identity_has_front_matter(agent):
    content = _load(agent, "IDENTITY.md")
    for key in ("description", "type", "status", "version"):
        assert re.search(rf"^{key}:\s*", content, re.MULTILINE | re.IGNORECASE), \
            f"{agent}: IDENTITY.md missing field '{key}'"


@pytest.mark.parametrize("agent", AGENTS)
def test_identity_no_tables(agent):
    content = _load(agent, "IDENTITY.md")
    assert _has_no_tables(content), f"{agent}: IDENTITY.md contains a markdown table"
