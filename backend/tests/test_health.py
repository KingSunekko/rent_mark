from fastapi.testclient import TestClient

from backend.core.config import get_settings
from backend.main import app

client = TestClient(app)


def test_root_reports_health() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_legacy_health_route_remains_available() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["service"] == get_settings().app_name


def test_versioned_health_reports_configuration_state() -> None:
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["database"] in {"configured", "not_configured"}
    assert set(body) == {
        "status",
        "service",
        "version",
        "environment",
        "database",
    }
