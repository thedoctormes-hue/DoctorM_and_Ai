"""Конфигурация тестов Context API."""
import pytest
from fastapi.testclient import TestClient

from main import app
from common import cache, rate_limiter


@pytest.fixture
def client():
    """Тестовый клиент FastAPI с сброшенным rate limiter и кешем."""
    rate_limiter._requests.clear()
    cache.clear()
    return TestClient(app)
