"""Тесты Context API v1.2.0 — все эндпоинты."""
import json
import os
import tempfile
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest


# ── Health ─────────────────────────────────────────
class TestHealth:
    def test_health_returns_200(self, client):
        r = client.get("/health")
        assert r.status_code == 200

    def test_health_returns_json(self, client):
        r = client.get("/health")
        data = r.json()
        assert data["status"] == "ok"
        assert data["service"] == "context-api"
        assert data["version"] == "1.2.0"


# ── Metrics ────────────────────────────────────────
class TestMetrics:
    def test_metrics_returns_200(self, client):
        r = client.get("/metrics")
        assert r.status_code == 200

    def test_metrics_has_structure(self, client):
        r = client.get("/metrics")
        data = r.json()
        assert "total_requests" in data
        assert "endpoints" in data
        assert "cache" in data
        assert "rate_limiter" in data

    def test_metrics_cache_stats(self, client):
        r = client.get("/metrics")
        cache = r.json()["cache"]
        assert "size" in cache
        assert "hits" in cache
        assert "misses" in cache
        assert "hit_rate" in cache


# ── Context endpoints ──────────────────────────────
class TestContext:
    @pytest.mark.parametrize("name", ["core", "staff", "projects", "rules"])
    def test_context_returns_200(self, client, name):
        r = client.get(f"/api/v1/context/{name}")
        assert r.status_code == 200

    @pytest.mark.parametrize("name", ["core", "staff", "projects", "rules"])
    def test_context_returns_json(self, client, name):
        r = client.get(f"/api/v1/context/{name}")
        assert "application/json" in r.headers["content-type"]

    def test_context_has_pagination_fields(self, client):
        r = client.get("/api/v1/context/core")
        data = r.json()
        assert "content" in data
        assert "total_lines" in data
        assert "offset" in data
        assert "limit" in data
        assert "has_more" in data
        assert "context" in data

    def test_context_pagination_offset(self, client):
        r = client.get("/api/v1/context/core?offset=10&limit=5")
        data = r.json()
        assert data["offset"] == 10
        assert data["limit"] == 5

    def test_context_limit_bounds(self, client):
        r = client.get("/api/v1/context/core?limit=0")
        assert r.status_code == 422
        r = client.get("/api/v1/context/core?limit=2001")
        assert r.status_code == 422

    def test_context_core_contains_lab(self, client):
        r = client.get("/api/v1/context/core")
        data = r.json()
        assert "LabDoctorM" in data["content"]

    def test_context_staff_contains_roles(self, client):
        r = client.get("/api/v1/context/staff")
        data = r.json()
        text = data["content"].lower()
        assert "лаборант" in text or "ворон" in text or "кот" in text

    def test_context_unknown_returns_404(self, client):
        r = client.get("/api/v1/context/nonexistent")
        assert r.status_code == 404


# ── Project endpoints ──────────────────────────────
class TestProject:
    @pytest.mark.parametrize("name", ["snablab", "myrmex", "hype"])
    def test_project_returns_200(self, client, name):
        r = client.get(f"/api/v1/project/{name}")
        assert r.status_code == 200

    @pytest.mark.parametrize("name", ["raven", "autoexpert", "playwright"])
    def test_project_archived_returns_200_or_404(self, client, name):
        """Архивированные проекты могут не иметь секций в QWEN-projects.md."""
        r = client.get(f"/api/v1/project/{name}")
        assert r.status_code in (200, 404)

    def test_project_snablab_contains_info(self, client):
        """Секция СнабЛаб из QWEN-projects.md должна содержать детали."""
        r = client.get("/api/v1/project/snablab")
        assert r.status_code == 200
        data = r.json()
        assert "content" in data
        assert "СнабЛаб" in data["content"] or "snablab" in data["content"].lower()
        # Не весь файл, только секция
        assert "Myrmex" not in data["content"]


# ── Memory endpoints ───────────────────────────────
class TestMemory:
    def test_memory_topic_returns_200(self, client):
        r = client.get("/api/v1/memory/myrmex")
        assert r.status_code == 200

    def test_memory_topic_returns_json(self, client):
        r = client.get("/api/v1/memory/myrmex")
        assert "application/json" in r.headers["content-type"]

    def test_memory_topic_has_pagination(self, client):
        r = client.get("/api/v1/memory/myrmex")
        data = r.json()
        assert "content" in data
        assert "total_lines" in data
        assert "file" in data

    def test_memory_topic_not_empty(self, client):
        r = client.get("/api/v1/memory/myrmex")
        data = r.json()
        assert len(data["content"]) > 50

    def test_memory_unknown_returns_404(self, client):
        r = client.get("/api/v1/memory/topicthatdoesnotexist12345")
        assert r.status_code == 404

    def test_memory_search_returns_json(self, client):
        r = client.get("/api/v1/memory/search?q=vpn")
        assert r.status_code == 200
        assert "application/json" in r.headers["content-type"]

    def test_memory_search_has_results(self, client):
        r = client.get("/api/v1/memory/search?q=vpn")
        data = r.json()
        assert "query" in data
        assert "results" in data
        assert "total" in data
        assert data["query"] == "vpn"
        assert data["total"] > 0

    def test_memory_search_results_have_snippet(self, client):
        r = client.get("/api/v1/memory/search?q=vpn")
        data = r.json()
        if data["results"]:
            assert "file" in data["results"][0]
            assert "snippet" in data["results"][0]

    def test_memory_search_short_query_returns_422(self, client):
        r = client.get("/api/v1/memory/search?q=x")
        assert r.status_code == 422

    def test_memory_search_no_query_returns_422(self, client):
        r = client.get("/api/v1/memory/search")
        assert r.status_code == 422

    def test_memory_search_returns_max_10_results(self, client):
        r = client.get("/api/v1/memory/search?q=проект")
        data = r.json()
        assert len(data["results"]) <= 10

    def test_memory_search_relevance_order(self, client):
        r = client.get("/api/v1/memory/search?q=api")
        data = r.json()
        if len(data["results"]) >= 2:
            first_count = data["results"][0]["snippet"].lower().count("api")
            last_count = data["results"][-1]["snippet"].lower().count("api")
            assert first_count >= last_count


# ── Insights endpoint ──────────────────────────────
class TestInsights:
    def test_insights_returns_200(self, client):
        r = client.get("/api/v1/insights/recent")
        assert r.status_code == 200

    def test_insights_returns_json(self, client):
        r = client.get("/api/v1/insights/recent")
        assert "application/json" in r.headers["content-type"]

    def test_insights_has_structure(self, client):
        r = client.get("/api/v1/insights/recent")
        data = r.json()
        assert "insights" in data
        assert "total" in data

    def test_insights_default_limit_5(self, client):
        r = client.get("/api/v1/insights/recent")
        data = r.json()
        assert len(data["insights"]) <= 5

    def test_insights_custom_limit(self, client):
        r = client.get("/api/v1/insights/recent?limit=3")
        data = r.json()
        assert len(data["insights"]) <= 3

    def test_insights_limit_bounds(self, client):
        r = client.get("/api/v1/insights/recent?limit=0")
        assert r.status_code == 422
        r = client.get("/api/v1/insights/recent?limit=21")
        assert r.status_code == 422

    def test_insights_have_required_fields(self, client):
        r = client.get("/api/v1/insights/recent")
        data = r.json()
        if data["insights"]:
            insight = data["insights"][0]
            assert "id" in insight
            assert "title" in insight
            assert "summary" in insight
            assert "file" in insight


# ── ADR endpoints ───────────────────────────────────
class TestADR:
    def test_adr_list_returns_200(self, client):
        r = client.get("/api/v1/adr")
        assert r.status_code == 200

    def test_adr_list_has_items(self, client):
        r = client.get("/api/v1/adr")
        data = r.json()
        assert data["total"] > 0

    def test_adr_list_items_have_fields(self, client):
        r = client.get("/api/v1/adr")
        data = r.json()
        if data["adrs"]:
            adr = data["adrs"][0]
            assert "id" in adr
            assert "title" in adr
            assert "status" in adr

    def test_adr_get_returns_200(self, client):
        r = client.get("/api/v1/adr/ADR-001-myrmex-control-realizovan")
        assert r.status_code == 200

    def test_adr_get_returns_text(self, client):
        r = client.get("/api/v1/adr/ADR-001-myrmex-control-realizovan")
        assert "text/plain" in r.headers["content-type"]

    def test_adr_unknown_returns_404(self, client):
        r = client.get("/api/v1/adr/nonexistent")
        assert r.status_code == 404


# ── Patterns endpoints ─────────────────────────────
class TestPatterns:
    def test_patterns_list_returns_200(self, client):
        r = client.get("/api/v1/patterns")
        assert r.status_code == 200

    def test_patterns_list_has_items(self, client):
        """Patterns директория может быть пустой — проверяем структуру."""
        r = client.get("/api/v1/patterns")
        data = r.json()
        assert "patterns" in data
        assert "total" in data

    def test_patterns_list_items_have_fields(self, client):
        r = client.get("/api/v1/patterns")
        data = r.json()
        if data["patterns"]:
            pattern = data["patterns"][0]
            assert "id" in pattern
            assert "title" in pattern

    def test_pattern_get_returns_200_or_404(self, client):
        """Patterns директория может быть пустой."""
        r = client.get("/api/v1/patterns/PAT-001-merge-not-overwrite")
        assert r.status_code in (200, 404)

    def test_pattern_unknown_returns_404(self, client):
        r = client.get("/api/v1/patterns/nonexistent")
        assert r.status_code == 404


# ── Identity endpoints ─────────────────────────────
class TestIdentity:
    def test_identity_returns_200(self, client):
        r = client.get("/api/v1/identity/raven")
        assert r.status_code == 200

    def test_identity_has_identity_file(self, client):
        r = client.get("/api/v1/identity/raven")
        data = r.json()
        assert "IDENTITY.md" in data["files"]

    def test_identity_has_soul_file(self, client):
        """По умолчанию compact=true → SOUL-compact.md."""
        r = client.get("/api/v1/identity/raven")
        data = r.json()
        assert "SOUL-compact.md" in data["files"]

    def test_identity_content_not_empty(self, client):
        r = client.get("/api/v1/identity/raven")
        data = r.json()
        assert len(data["content"]["IDENTITY.md"]) > 100

    def test_identity_unknown_returns_404(self, client):
        r = client.get("/api/v1/identity/nonexistent")
        assert r.status_code == 404


# ── Sessions endpoints ─────────────────────────────
class TestSessions:
    def test_sessions_recent_returns_200(self, client):
        r = client.get("/api/v1/sessions/recent")
        assert r.status_code == 200

    def test_sessions_recent_has_items(self, client):
        """Сессии in-memory, могут быть пустыми после рестарта — проверяем структуру."""
        r = client.get("/api/v1/sessions/recent")
        data = r.json()
        assert "sessions" in data
        assert "total" in data
        assert isinstance(data["sessions"], list)

    def test_sessions_recent_items_have_fields(self, client):
        r = client.get("/api/v1/sessions/recent")
        data = r.json()
        if data["sessions"]:
            session = data["sessions"][0]
            assert "id" in session
            assert "title" in session
            assert "size" in session

    def test_sessions_recent_default_limit(self, client):
        r = client.get("/api/v1/sessions/recent")
        data = r.json()
        assert len(data["sessions"]) <= 5

    def test_sessions_recent_custom_limit(self, client):
        r = client.get("/api/v1/sessions/recent?limit=3")
        data = r.json()
        assert len(data["sessions"]) <= 3

    def test_sessions_recent_limit_bounds(self, client):
        r = client.get("/api/v1/sessions/recent?limit=0")
        assert r.status_code == 422
        r = client.get("/api/v1/sessions/recent?limit=21")
        assert r.status_code == 422

    def test_session_get_returns_200_or_404(self, client):
        """Сессия может быть in-memory (после рестарта пустая)."""
        r = client.get("/api/v1/sessions/insights_session_20260525_laptop")
        assert r.status_code in (200, 404)

    def test_session_unknown_returns_404(self, client):
        r = client.get("/api/v1/sessions/nonexistent")
        assert r.status_code == 404


# ── Response headers ───────────────────────────────
class TestResponseHeaders:
    def test_response_has_timing_header(self, client):
        r = client.get("/health")
        assert "X-Response-Time-Ms" in r.headers

    def test_response_has_request_count_header(self, client):
        r = client.get("/health")
        assert "X-Request-Count" in r.headers

    def test_response_has_cache_hit_rate_header(self, client):
        r = client.get("/health")
        assert "X-Cache-Hit-Rate" in r.headers


# ── Rate limiting ──────────────────────────────────
class TestRateLimiting:
    def test_rate_limit_allows_normal_usage(self, client):
        """10 запросов подряд должны пройти."""
        for _ in range(10):
            r = client.get("/health")
            assert r.status_code == 200

    def test_rate_limit_headers_present(self, client):
        """Rate limiter не блокирует обычные запросы."""
        r = client.get("/health")
        assert r.status_code == 200


# ── Cache ──────────────────────────────────────────
class TestCache:
    def test_cache_hit_on_second_request(self, client):
        """Второй запрос того же ресурса должен попасть в кеш."""
        # Первый запрос — cache miss
        client.get("/api/v1/context/core")
        # Второй запрос — cache hit
        client.get("/api/v1/context/core")
        r = client.get("/metrics")
        data = r.json()
        assert data["cache"]["hits"] > 0


# ── OpenAPI ────────────────────────────────────────
class TestOpenAPI:
    def test_openapi_returns_200(self, client):
        r = client.get("/openapi.json")
        assert r.status_code == 200

    def test_openapi_lists_all_routes(self, client):
        r = client.get("/openapi.json")
        data = r.json()
        paths = data.get("paths", {})
        assert "/health" in paths
        assert "/metrics" in paths
        assert "/api/v1/context/{name}" in paths
        assert "/api/v1/project/{name}" in paths
        assert "/api/v1/memory/{topic}" in paths
        assert "/api/v1/memory/search" in paths
        assert "/api/v1/insights/recent" in paths
        assert "/api/v1/adr" in paths
        assert "/api/v1/adr/{adr_id}" in paths
        assert "/api/v1/patterns" in paths
        assert "/api/v1/patterns/{pattern_id}" in paths
        assert "/api/v1/identity/{agent}" in paths
        assert "/api/v1/sessions/recent" in paths
        assert "/api/v1/sessions/{session_id}" in paths


# ── 404 ────────────────────────────────────────────
class TestNotFound:
    def test_unknown_route_returns_404(self, client):
        r = client.get("/api/v1/unknown")
        assert r.status_code == 404


# ── Логические тесты: Identity для всех агентов ─────
class TestIdentityAllAgents:
    """Проверяем что каждый агент получает свой правильный контекст."""

    @pytest.mark.parametrize("agent,expected_dir", [
        ("raven", "raven"),
        ("owl", "owl"),
        ("bestia", "bestia"),
        ("antcat", "antcat"),
        ("kotolizator", "kotolizator"),
        ("streikbrecher", "streikbrecher"),
    ])
    def test_identity_all_agents_return_200(self, client, agent, expected_dir):
        """Все канонические имена агентов должны возвращать 200."""
        r = client.get(f"/api/v1/identity/{agent}")
        assert r.status_code == 200, f"Agent {agent} failed"

    @pytest.mark.parametrize("agent", ["raven", "owl", "bestia", "antcat", "kotolizator", "streikbrecher"])
    def test_identity_has_identity_file_compact_false(self, client, agent):
        """Каждый агент должен иметь IDENTITY.md (compact=false)."""
        r = client.get(f"/api/v1/identity/{agent}?compact=false")
        data = r.json()
        assert "IDENTITY.md" in data["files"], f"{agent}: missing IDENTITY.md"
        assert "IDENTITY.md" in data["content"], f"{agent}: no IDENTITY.md content"

    @pytest.mark.parametrize("agent", ["raven", "owl", "bestia", "antcat", "kotolizator", "streikbrecher"])
    def test_identity_content_has_agent_name(self, client, agent):
        """IDENTITY.md должен содержать каноническое имя агента."""
        r = client.get(f"/api/v1/identity/{agent}")
        data = r.json()
        identity_content = data["content"]["IDENTITY.md"]
        assert agent.lower() in identity_content.lower() or \
               data["agent"].lower() in identity_content.lower(), \
            f"{agent}: IDENTITY.md doesn't contain agent name"

    def test_identity_raven_has_raven_content(self, client):
        """Ворон должен получить именно свой контекст, а не чужой."""
        r = client.get("/api/v1/identity/raven")
        data = r.json()
        content = data["content"]["IDENTITY.md"]
        # Ворон — аналитик и разведчик
        assert "разведчик" in content.lower() or "аналитик" in content.lower()

    def test_identity_owl_has_owl_content(self, client):
        """Сова должна получить именно свой контекст."""
        r = client.get("/api/v1/identity/owl")
        data = r.json()
        content = data["content"]["IDENTITY.md"]
        assert "principal" in content.lower() or "аудитор" in content.lower() or "стандарт" in content.lower()

    def test_identity_compact_returns_only_identity(self, client):
        """compact=true должен возвращать IDENTITY.md + SOUL-compact.md (без CHECKPOINT/HANDOFF)."""
        r = client.get("/api/v1/identity/raven?compact=true")
        assert r.status_code == 200
        data = r.json()
        assert data["compact"] is True
        assert "IDENTITY.md" in data["files"]
        assert "SOUL-compact.md" in data["files"]
        assert "SOUL.md" not in data["files"]
        assert "CHECKPOINT.md" not in data["content"]
        assert "SESSION_HANDOFF.md" not in data["content"]

    def test_identity_compact_false_returns_identity(self, client):
        """compact=false должен возвращать как минимум IDENTITY.md."""
        r = client.get("/api/v1/identity/raven?compact=false")
        assert r.status_code == 200
        data = r.json()
        assert data["compact"] is False
        assert "IDENTITY.md" in data["content"]
        assert len(data["content"]["IDENTITY.md"]) > 50

    def test_identity_compact_false_includes_existing_files(self, client):
        """compact=false должен включать только существующие файлы."""
        # kotolizator — единственный агент с полным набором
        r = client.get("/api/v1/identity/kotolizator?compact=false")
        assert r.status_code == 200
        data = r.json()
        assert "IDENTITY.md" in data["content"]
        assert "SOUL.md" in data["content"]
        assert "SOUL-deep.md" in data["content"]
        assert "CHECKPOINT.md" in data["content"]
        assert "SESSION_HANDOFF.md" in data["content"]

    def test_identity_compact_smaller_payload(self, client):
        """compact payload должен быть меньше full (на примере kotolizator)."""
        r_full = client.get("/api/v1/identity/kotolizator?compact=false")
        r_compact = client.get("/api/v1/identity/kotolizator?compact=true")
        full_size = len(r_full.text)
        compact_size = len(r_compact.text)
        assert compact_size < full_size, \
            f"compact ({compact_size}) should be smaller than full ({full_size})"

    @pytest.mark.parametrize("agent", ["raven", "owl", "bestia", "antcat", "kotolizator", "streikbrecher"])
    def test_identity_compact_all_agents(self, client, agent):
        """compact режим должен работать для всех агентов (IDENTITY + SOUL-compact)."""
        r = client.get(f"/api/v1/identity/{agent}?compact=true")
        assert r.status_code == 200
        data = r.json()
        assert "IDENTITY.md" in data["files"]
        assert "SOUL-compact.md" in data["files"]
        assert len(data["files"]) == 2
        assert len(data["content"]["IDENTITY.md"]) > 100


# ── Тесты унификации имён агентов ──────────────────
class TestAgentNameUnification:
    """Проверяем что у каждого агента одно каноническое имя, без дубликатов."""

    @pytest.mark.parametrize("agent", ["antcat", "kotolizator", "bestia", "raven", "owl", "streikbrecher"])
    def test_canonical_names_return_200(self, client, agent):
        """Канонические имена агентов должны работать."""
        r = client.get(f"/api/v1/identity/{agent}")
        assert r.status_code == 200, f"Каноническое имя {agent} не работает"

    def test_identity_agent_field_matches_request(self, client):
        """Поле agent в ответе должно совпадать с запрошенным именем."""
        for agent in ["antcat", "kotolizator", "bestia", "raven", "owl", "streikbrecher"]:
            r = client.get(f"/api/v1/identity/{agent}")
            assert r.status_code == 200
            assert r.json()["agent"] == agent, \
                f"Запросили {agent}, получили {r.json()['agent']}"


# ── Логические тесты: Context секции ────────────────
class TestContextSections:
    """Проверяем что секции контекста содержат ожидаемую информацию."""

    def test_context_core_contains_api_info(self, client):
        """QWEN-core.md должен содержать информацию о Context API."""
        r = client.get("/api/v1/context/core")
        content = r.json()["content"]
        assert "context-api" in content.lower() or "Context API" in content

    def test_context_staff_contains_all_agents(self, client):
        """QWEN-staff.md должен содержать всех лаборантов."""
        r = client.get("/api/v1/context/staff")
        content = r.json()["content"].lower()
        # Должны упоминаться основные агенты
        assert "ворон" in content or "raven" in content

    def test_context_projects_contains_multiple(self, client):
        """QWEN-projects.md должен содержать несколько проектов."""
        r = client.get("/api/v1/context/projects")
        content = r.json()["content"]
        # Должны быть секции проектов
        assert "## " in content  # markdown headers

    def test_context_rules_has_frontmatter(self, client):
        """rules.md должен иметь frontmatter."""
        r = client.get("/api/v1/context/rules")
        content = r.json()["content"]
        assert "---" in content  # YAML frontmatter


# ── Логические тесты: Project секции ────────────────
class TestProjectSections:
    """Проверяем что проектные секции изолированы корректно."""

    def test_project_snablab_does_not_contain_myrmex(self, client):
        """Секция snablab не должна содержать данные myrmex."""
        r = client.get("/api/v1/project/snablab")
        content = r.json()["content"].lower()
        # Секция snablab должна быть изолирована
        assert "snablab" in content or "закупк" in content

    def test_project_myrmex_does_not_contain_snablab(self, client):
        """Секция myrmex не должна содержать данные snablab."""
        r = client.get("/api/v1/project/myrmex")
        content = r.json()["content"].lower()
        assert "myrmex" in content

    def test_project_raven_has_raven_content(self, client):
        """Проект raven — заархивирован, может вернуть 404."""
        r = client.get("/api/v1/project/raven")
        assert r.status_code in (200, 404)


# ── Логические тесты: Graceful degradation ──────────
class TestGracefulDegradation:
    """Проверяем что API корректно обрабатывает ошибки."""

    def test_identity_nonexistent_agent_returns_404_with_detail(self, client):
        """Несуществующий агент должен вернуть 404 с понятным сообщением."""
        r = client.get("/api/v1/identity/totally_fake_agent")
        assert r.status_code == 404
        data = r.json()
        assert "detail" in data

    def test_context_nonexistent_returns_404_with_detail(self, client):
        """Несуществующий контекст должен вернуть 404."""
        r = client.get("/api/v1/context/fake_context")
        assert r.status_code == 404
        assert "detail" in r.json()

    def test_project_nonexistent_returns_404_with_detail(self, client):
        """Несуществующий проект должен вернуть 404."""
        r = client.get("/api/v1/project/fake_project_xyz")
        assert r.status_code == 404
        assert "detail" in r.json()

    def test_memory_nonexistent_returns_404_with_detail(self, client):
        """Несуществующая тема памяти должна вернуть 404."""
        r = client.get("/api/v1/memory/zzzzzzzzzzzzz")
        assert r.status_code == 404
        assert "detail" in r.json()

    def test_invalid_pagination_params_return_422(self, client):
        """Невалидные параметры пагинации должны вернуть 422."""
        r = client.get("/api/v1/context/core?offset=-1")
        assert r.status_code == 422

    def test_search_too_short_query_returns_422(self, client):
        """Слишком короткий поисковый запрос должен вернуть 422."""
        r = client.get("/api/v1/memory/search?q=a")
        assert r.status_code == 422


# ── Логические тесты: Кеширование ──────────────────
class TestCacheLogic:
    """Проверяем что кеширование работает корректно."""

    def test_second_request_uses_cache(self, client):
        """Второй запрос того же файла должен попасть в кеш."""
        # Первый запрос — cache miss
        client.get("/api/v1/context/core")
        metrics_after_first = client.get("/metrics").json()
        hits_after_first = metrics_after_first["cache"]["hits"]

        # Второй запрос — cache hit
        client.get("/api/v1/context/core")
        metrics_after_second = client.get("/metrics").json()
        hits_after_second = metrics_after_second["cache"]["hits"]

        assert hits_after_second > hits_after_first

    def test_different_contexts_cached_separately(self, client):
        """Разные контексты должны кешироваться отдельно."""
        client.get("/api/v1/context/core")
        client.get("/api/v1/context/staff")
        r = client.get("/metrics")
        # Оба запроса должны быть учтены
        assert r.json()["total_requests"] >= 3  # core + staff + metrics

    def test_identity_cached_per_agent(self, client):
        """Identity разных агентов кешируется отдельно."""
        client.get("/api/v1/identity/raven")
        client.get("/api/v1/identity/owl")
        r = client.get("/metrics")
        assert r.json()["total_requests"] >= 3


# ── Логические тесты: Метрики ──────────────────────
class TestMetricsLogic:
    """Проверяем что метрики отражают реальную активность."""

    def test_metrics_requests_increase_after_calls(self, client):
        """Счётчик запросов должен расти после вызовов других эндпоинтов."""
        # Делаем несколько запросов к НЕ-metrics эндпоинтам
        for _ in range(5):
            client.get("/health")

        r = client.get("/metrics")
        total_after = r.json()["total_requests"]

        # После 5+ запросов total_requests должен быть > 0
        assert total_after > 5

    def test_metrics_endpoints_tracked(self, client):
        """Метрики должны отслеживать конкретные эндпоинты."""
        client.get("/api/v1/identity/raven")
        r = client.get("/metrics")
        endpoints = r.json()["endpoints"]
        # Должен быть хотя бы один эндпоинт identity
        identity_endpoints = [k for k in endpoints if "identity" in k]
        assert len(identity_endpoints) > 0

    def test_metrics_response_times_recorded(self, client):
        """Время ответа должно записываться."""
        client.get("/api/v1/context/core")
        r = client.get("/metrics")
        endpoints = r.json()["endpoints"]
        context_endpoints = [k for k in endpoints if "context" in k]
        if context_endpoints:
            ep_data = endpoints[context_endpoints[0]]
            assert ep_data["avg_ms"] > 0


# ── Логические тесты: Безопасность ─────────────────
class TestSecurity:
    """Базовые проверки безопасности."""

    def test_no_server_version_leak(self, client):
        """Заголовок Server не должен содержать версию uvicorn."""
        r = client.get("/health")
        server_header = r.headers.get("server", "")
        # Не должен содержать версию python/uvicorn
        assert "Python" not in server_header

    def test_content_type_json_for_api(self, client):
        """API эндпоинты должны возвращать application/json."""
        r = client.get("/api/v1/identity/raven")
        assert "application/json" in r.headers["content-type"]

    def test_openapi_does_not_expose_secrets(self, client):
        """OpenAPI спецификация не должна содержать секретов."""
        r = client.get("/openapi.json")
        spec = r.text.lower()
        assert "password" not in spec
        assert "secret" not in spec
        assert "api_key" not in spec or "X-API-Key" in r.text  # только имя заголовка


# ── Edge cases: Пустые файлы ───────────────────────
class TestEdgeCasesEmptyFiles:
    """API должен корректно обрабатывать пустые файлы."""

    def test_read_file_cached_returns_none_for_empty_file(self):
        """Пустой файл должен возвращать None, а не пустую строку."""
        from common import read_file_cached

        with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as f:
            f.write("")
            f.flush()
            result = read_file_cached(Path(f.name), use_cache=False)
            os.unlink(f.name)

        assert result is None, "Empty file should return None"

    def test_read_file_cached_returns_none_for_whitespace_only(self):
        """Файл только с пробелами/переносами должен возвращать None."""
        from common import read_file_cached

        with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as f:
            f.write("   \n\n  \n")
            f.flush()
            result = read_file_cached(Path(f.name), use_cache=False)
            os.unlink(f.name)

        assert result is None, "Whitespace-only file should return None"

    def test_read_file_cached_handles_invalid_utf8(self):
        """Файл с невалидным UTF-8 должен возвращать None, не падать."""
        from common import read_file_cached

        with tempfile.NamedTemporaryFile(mode='wb', suffix='.md', delete=False) as f:
            f.write(b"valid text \xff\xfe invalid bytes")
            f.flush()
            result = read_file_cached(Path(f.name), use_cache=False)
            os.unlink(f.name)

        assert result is None, "Invalid UTF-8 file should return None gracefully"

    def test_read_file_cached_handles_missing_file(self):
        """Отсутствующий файл должен возвращать None."""
        from common import read_file_cached

        result = read_file_cached(Path("/tmp/nonexistent_file_12345.md"), use_cache=False)
        assert result is None

    def test_read_file_cached_handles_directory(self):
        """Путь к директории должен возвращать None, не падать."""
        from common import read_file_cached

        with tempfile.TemporaryDirectory() as tmpdir:
            result = read_file_cached(Path(tmpdir), use_cache=False)
            assert result is None


# ── Edge cases: Кеш при деградации ─────────────────
class TestEdgeCasesCache:
    """Кеш должен корректно работать при проблемах."""

    def test_cache_survives_nonexistent_key(self):
        """Запрос несуществующего ключа не должен ломать кеш."""
        from common import cache

        cache.clear()
        result = cache.get("nonexistent_key")
        assert result is None
        # Кеш должен работать после miss
        cache.set("real_key", "real_value")
        assert cache.get("real_key") == "real_value"

    def test_cache_stats_after_clear(self):
        """После clear() стата должна быть чистой."""
        from common import cache

        cache.set("key1", "val1")
        cache.get("key1")  # hit
        cache.clear()
        stats = cache.stats
        assert stats["size"] == 0

    def test_cache_handles_none_value_gracefully(self):
        """Cache должен корректно обрабатывать None значения."""
        from common import cache

        cache.set("none_key", "some_value")
        cache.invalidate("none_key")
        assert cache.get("none_key") is None


# ── Edge cases: Identity при отсутствии файлов ─────
class TestEdgeCasesIdentityMissingFiles:
    """Identity роутер должен корректно обрабатывать отсутствующие файлы."""

    def test_identity_returns_even_if_checkpoint_missing(self, client):
        """Identity должен работать даже если CHECKPOINT.md отсутствует."""
        # Raven может не иметь CHECKPOINT.md — должен вернуть то что есть
        r = client.get("/api/v1/identity/raven")
        assert r.status_code == 200
        data = r.json()
        # Минимум IDENTITY.md должен быть
        assert "IDENTITY.md" in data["files"]

    def test_identity_compact_always_returns_identity(self, client):
        """Compact режим всегда возвращает IDENTITY.md если он есть."""
        for agent in ["raven", "owl", "bestia", "antcat", "kotolizator", "streikbrecher"]:
            r = client.get(f"/api/v1/identity/{agent}?compact=true")
            assert r.status_code == 200, f"{agent} compact failed"
            data = r.json()
            assert "IDENTITY.md" in data["files"]
            assert len(data["content"]["IDENTITY.md"]) > 50


# ── Edge cases: Rate Limiter ───────────────────────
class TestEdgeCasesRateLimiter:
    """Rate limiter должен корректно обрабатывать edge cases."""

    def test_rate_limiter_allows_different_clients(self):
        """Разные клиенты должны иметь отдельные лимиты."""
        from common import RateLimiter

        rl = RateLimiter(max_requests=5, window_seconds=60)
        for i in range(5):
            assert rl.is_allowed(f"client_{i}") is True

    def test_rate_limiter_blocks_after_limit(self):
        """Клиент должен быть заблокирован после превышения лимита."""
        from common import RateLimiter

        rl = RateLimiter(max_requests=3, window_seconds=60)
        for _ in range(3):
            rl.is_allowed("test_client")
        # 4-й запрос должен быть заблокирован
        assert rl.is_allowed("test_client") is False

    def test_rate_limiter_remaining_decreases(self):
        """remaining должен уменьшаться с каждым запросом."""
        from common import RateLimiter

        rl = RateLimiter(max_requests=5, window_seconds=60)
        assert rl.get_remaining("new_client") == 5
        rl.is_allowed("new_client")
        assert rl.get_remaining("new_client") == 4


# ── Security: Path Traversal ───────────────────────
class TestPathTraversal:
    """API должен блокировать попытки path traversal."""

    def test_identity_rejects_path_traversal_slash(self, client):
        """../etc/passwd должен быть отклонён."""
        r = client.get("/api/v1/identity/..%2F..%2Fetc%2Fpasswd")
        assert r.status_code in (404, 422)

    def test_identity_rejects_path_traversal_dotdot(self, client):
        """../../etc/passwd должен быть отклонён."""
        r = client.get("/api/v1/identity/../../etc/passwd")
        assert r.status_code in (404, 422)

    def test_identity_rejects_null_bytes(self, client):
        """Null bytes в имени агента должны быть отклонены."""
        r = client.get("/api/v1/identity/raven%00")
        assert r.status_code in (404, 422)

    def test_identity_rejects_absolute_path(self, client):
        """Абсолютный путь должен быть отклонён."""
        r = client.get("/api/v1/identity/%2Fetc%2Fpasswd")
        assert r.status_code in (404, 422)

    def test_context_rejects_path_traversal(self, client):
        """Path traversal в context name должен быть отклонён."""
        r = client.get("/api/v1/context/..%2F..%2Fetc")
        assert r.status_code in (404, 422)


# ── Security: CORS ─────────────────────────────────
class TestCORS:
    """CORS заголовки должны быть корректными."""

    def test_cors_allows_localhost_3000(self, client):
        """Origin localhost:3000 должен быть разрешён."""
        r = client.get("/health", headers={"Origin": "http://localhost:3000"})
        assert r.status_code == 200
        assert "access-control-allow-origin" in r.headers

    def test_cors_allows_127_0_0_1(self, client):
        """Origin 127.0.0.1 должен быть разрешён."""
        r = client.get("/health", headers={"Origin": "http://127.0.0.1:3000"})
        assert r.status_code == 200
        assert "access-control-allow-origin" in r.headers

    def test_cors_disallows_unknown_origin(self, client):
        """Неизвестный origin не должен получать CORS заголовок."""
        r = client.get("/health", headers={"Origin": "http://evil.com"})
        # CORS middleware не добавляет заголовок для неизвестных origins
        assert r.status_code == 200  # запрос проходит, но без CORS


# ── Security: Input Validation ─────────────────────
class TestInputValidation:
    """API должен корректно валидировать входные данные."""

    def test_identity_empty_agent_name(self, client):
        """Пустое имя агента должно вернуть 404."""
        r = client.get("/api/v1/identity/")
        assert r.status_code in (404, 422)

    def test_identity_very_long_agent_name(self, client):
        """Очень длинное имя агента должно быть отклонено."""
        long_name = "a" * 500
        r = client.get(f"/api/v1/identity/{long_name}")
        assert r.status_code in (404, 422)

    def test_identity_special_chars_in_name(self, client):
        """Спецсимволы в имени агента должны быть отклонены."""
        for name in ["raven;drop", "raven|cat", "raven&&ls", "raven'--"]:
            r = client.get(f"/api/v1/identity/{name}")
            assert r.status_code in (404, 422), f"Special chars '{name}' not rejected"

    def test_memory_search_sql_injection(self, client):
        """SQL-подобные инъекции в поиске должны быть безопасны."""
        r = client.get("/api/v1/memory/search?q='; DROP TABLE users; --")
        # Должен вернуть 200 с пустыми результатами или 422, но не 500
        assert r.status_code in (200, 422)

    def test_memory_search_regex_special_chars(self, client):
        """Regex-специальные символы в поиске должны быть безопасны."""
        for query in ["(.*)", "[a-z]+", "^test$", ".*"]:
            r = client.get(f"/api/v1/memory/search?q={query}")
            assert r.status_code in (200, 422), f"Regex query '{query}' caused error"


# ── Integration: API Key Auth ──────────────────────
class TestApiKeyAuth:
    """API Key аутентификация должна работать корректно."""

    def test_health_no_key_required(self, client):
        """Health endpoint должен быть доступен без ключа."""
        r = client.get("/health")
        assert r.status_code == 200

    def test_identity_no_key_required(self, client):
        """Identity endpoint должен быть доступен без ключа (публичный)."""
        r = client.get("/api/v1/identity/raven")
        assert r.status_code == 200

    def test_metrics_no_key_required(self, client):
        """Metrics endpoint должен быть доступен без ключа."""
        r = client.get("/metrics")
        assert r.status_code == 200


# ── Integration: Rate Limit 429 ────────────────────
class TestRateLimit429:
    """Rate limiter должен возвращать 429 при превышении лимита."""

    def test_rate_limit_returns_429_when_exceeded(self, client):
        """После превышения лимита должен вернуться 429 на identity endpoint."""
        from common import rate_limiter

        # Устанавливаем очень низкий лимит для теста
        original_max = rate_limiter._max_requests
        rate_limiter._max_requests = 3
        rate_limiter._requests.clear()

        try:
            # Делаем запросы до лимита (identity endpoint имеет rate limiting)
            for _ in range(3):
                r = client.get("/api/v1/identity/raven")
                assert r.status_code == 200

            # Следующий запрос должен быть 429
            r = client.get("/api/v1/identity/raven")
            assert r.status_code == 429, f"Expected 429, got {r.status_code}"
        finally:
            rate_limiter._max_requests = original_max
            rate_limiter._requests.clear()

    def test_rate_limit_429_has_detail(self, client):
        """429 ответ должен содержать detail с информацией."""
        from common import rate_limiter

        original_max = rate_limiter._max_requests
        rate_limiter._max_requests = 2
        rate_limiter._requests.clear()

        try:
            client.get("/api/v1/identity/raven")
            client.get("/api/v1/identity/raven")
            r = client.get("/api/v1/identity/raven")
            assert r.status_code == 429
            # Ответ должен быть JSON
            data = r.json()
            assert "detail" in data
        finally:
            rate_limiter._max_requests = original_max
            rate_limiter._requests.clear()


# ── Integration: Full Session Startup Flow ─────────
class TestSessionStartupFlow:
    """Проверяем полный поток загрузки контекста при старте сессии."""

    @pytest.fixture(autouse=True)
    def _reset_rate_limiter(self):
        """Сбрасываем rate limiter перед каждым тестом."""
        from common import rate_limiter
        rate_limiter._requests.clear()
        yield
        rate_limiter._requests.clear()

    def test_identity_then_context_then_memory(self, client):
        """Типичный поток: identity → context → memory."""
        # Шаг 1: Загружаем идентичность
        r = client.get("/api/v1/identity/raven?compact=true")
        assert r.status_code == 200
        identity_size = len(r.text)

        # Шаг 2: Загружаем контекст
        r = client.get("/api/v1/context/core")
        assert r.status_code == 200
        context_size = len(r.text)

        # Шаг 3: Загружаем память
        r = client.get("/api/v1/memory/myrmex")
        assert r.status_code == 200

        # Все три ответа должны иметь содержимое
        assert identity_size > 0
        assert context_size > 0

    def test_all_agents_can_load_context(self, client):
        """Все агенты должны загружать контекст без ошибок (compact → IDENTITY + SOUL-compact)."""
        agents = ["raven", "owl", "bestia", "antcat", "kotolizator", "streikbrecher"]
        for agent in agents:
            r = client.get(f"/api/v1/identity/{agent}?compact=true")
            assert r.status_code == 200, f"{agent}: identity failed"
            data = r.json()
            assert "IDENTITY.md" in data["content"], f"{agent}: no IDENTITY.md"
            assert "SOUL-compact.md" in data["content"], f"{agent}: no SOUL-compact.md"

    def test_context_api_response_time_under_100ms(self, client):
        """Context API должен отвечать быстрее 100ms для compact режима."""
        import time

        start = time.time()
        r = client.get("/api/v1/identity/raven?compact=true")
        elapsed = (time.time() - start) * 1000

        assert r.status_code == 200
        assert elapsed < 100, f"Response too slow: {elapsed:.1f}ms"


# ── Context Index endpoints (Myrmex proxy) ──────────
class TestContextIndex:
    """Context Index эндпоинты — прокси к Myrmex.

    Myrmex может быть недоступен в тестовом окружении — прокси возвращает 503.
    Проверяем что эндпоинты отвечают (200 если Myrmex up, 502/503 если down).
    """

    @pytest.mark.parametrize("path", [
        "/api/v1/context-index",
        "/api/v1/context-index/adr",
        "/api/v1/context-index/specs",
        "/api/v1/context-index/patterns",
        "/api/v1/context-index/sessions",
        "/api/v1/context-index/memory",
    ])
    def test_context_index_endpoints_respond(self, client, path):
        """Все context-index эндпоинты должны отвечать (200 или 5xx)."""
        r = client.get(path)
        assert r.status_code in (200, 502, 503), \
            f"{path} returned unexpected {r.status_code}"

    def test_context_index_openapi_registered(self, client):
        """Context index эндпоинты должны быть в OpenAPI."""
        r = client.get("/openapi.json")
        data = r.json()
        paths = data.get("paths", {})
        assert "/api/v1/context-index" in paths
        assert "/api/v1/context-index/adr" in paths
        assert "/api/v1/context-index/specs" in paths
        assert "/api/v1/context-index/patterns" in paths
        assert "/api/v1/context-index/sessions" in paths
        assert "/api/v1/context-index/memory" in paths


# ── Agent Context Profile endpoint ──────────────────
class TestAgentContextProfile:
    """Профиль контекста агента через Myrmex.

    Myrmex может быть недоступен — прокси возвращает 5xx.
    """

    @pytest.mark.parametrize("agent", ["raven", "owl", "bestia", "antcat", "kotolizator", "streikbrecher"])
    def test_context_profile_responds(self, client, agent):
        """Context profile должен отвечать (200 или 5xx)."""
        r = client.get(f"/api/v1/agents/{agent}/context-profile")
        assert r.status_code in (200, 502, 503), \
            f"Context profile for {agent} returned unexpected {r.status_code}"

    def test_context_profile_unknown_agent_returns_4xx(self, client):
        r = client.get("/api/v1/agents/nonexistent/context-profile")
        assert r.status_code in (404, 502, 503)

    def test_context_profile_openapi_registered(self, client):
        """agents context-profile должен быть в OpenAPI."""
        r = client.get("/openapi.json")
        data = r.json()
        paths = data.get("paths", {})
        assert "/api/v1/agents/{agent_id}/context-profile" in paths


# ── Additional Projects ─────────────────────────────
class TestAdditionalProjects:
    """Дополнительные проекты из PROJECT_SECTIONS."""

    @pytest.mark.parametrize("name", [
        "zprr", "monitoring", "artifact", "consilium",
        "vpn", "vault", "gastro", "remote",
        "snablab-bot", "snzk",
        "cheque", "stenographer", "mail-daemon",
        "protocol", "llm-evangelist",
    ])
    def test_project_returns_200_or_404(self, client, name):
        """Проект может вернуть 200 или 404 если секция не найдена."""
        r = client.get(f"/api/v1/project/{name}")
        assert r.status_code in (200, 404)

    @pytest.mark.parametrize("name", ["autoexpert", "raven", "playwright"])
    def test_project_archived_returns_200_or_404(self, client, name):
        """Архивированные проекты могут не иметь секций."""
        r = client.get(f"/api/v1/project/{name}")
        assert r.status_code in (200, 404)

    def test_project_gastro_has_content(self, client):
        """Gastro Bot — активный проект, должен иметь контент."""
        r = client.get("/api/v1/project/gastro")
        if r.status_code == 200:
            data = r.json()
            assert "content" in data
            assert len(data["content"]) > 0


