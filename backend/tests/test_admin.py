from datetime import UTC, datetime
from types import SimpleNamespace
from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from backend.api.dependencies import get_current_user
from backend.api.routes import admin as routes
from backend.main import app
from backend.schemas.auth import UserProfile

client = TestClient(app)
ADMIN = str(uuid4())
USER = str(uuid4())
ITEM = str(uuid4())


def current(role="admin"):
    return UserProfile(id=ADMIN, email="admin@example.com", name="Admin", role=role, community="Davao")


@pytest.fixture(autouse=True)
def cleanup():
    yield
    app.dependency_overrides.clear()


def test_admin_routes_require_authentication():
    assert client.get("/api/v1/admin/dashboard").status_code == 401
    assert client.patch(f"/api/v1/admin/users/{USER}", json={"is_suspended": True, "reason": "Abuse"}).status_code == 401


def test_non_admin_is_forbidden():
    app.dependency_overrides[get_current_user] = lambda: current("owner")
    assert client.get("/api/v1/admin/dashboard").status_code == 403


def test_admin_dashboard_returns_server_calculated_metrics(monkeypatch):
    app.dependency_overrides[get_current_user] = current
    service = MagicMock()
    service.table.return_value.select.return_value.order.return_value.execute.return_value.data = []
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.get("/api/v1/admin/dashboard")
    assert response.status_code == 200
    assert response.json()["metrics"] == {
        "users": 0,
        "listings": 0,
        "requests": 0,
        "active_rentals": 0,
        "completed_rentals": 0,
        "reviews": 0,
        "estimated_rental_value_centavos": 0,
    }


def test_admin_profile_accepts_email_already_present_in_database_row():
    profile = routes._user_profile(
        {
            "id": USER,
            "email": "database@example.com",
            "name": "User",
            "community": "Davao",
            "role": "renter",
        },
        {USER: "auth@example.com"},
    )

    assert str(profile.email) == "database@example.com"


def test_user_moderation_is_scoped_and_requires_reason(monkeypatch):
    app.dependency_overrides[get_current_user] = current
    assert client.patch(f"/api/v1/admin/users/{USER}", json={"is_suspended": True}).status_code == 422
    service = MagicMock()
    saved = {"id": USER, "email": "user@example.com", "name": "User", "community": "Davao", "role": "renter", "is_suspended": True}
    query = service.table.return_value.update.return_value
    query.eq.return_value.neq.return_value.execute.return_value.data = [saved]
    service.auth.admin.get_user_by_id.return_value.user = SimpleNamespace(email="user@example.com")
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.patch(f"/api/v1/admin/users/{USER}", json={"is_suspended": True, "reason": "Policy violation"})
    assert response.status_code == 200
    assert response.json()["is_suspended"] is True
    query.eq.assert_called_once_with("id", USER)
    query.eq.return_value.neq.assert_called_once_with("role", "admin")


def test_admin_cannot_suspend_self():
    app.dependency_overrides[get_current_user] = current
    response = client.patch(f"/api/v1/admin/users/{ADMIN}", json={"is_suspended": True, "reason": "Mistake"})
    assert response.status_code == 409


def test_listing_moderation_requires_reason_and_returns_owner(monkeypatch):
    app.dependency_overrides[get_current_user] = current
    assert client.patch(f"/api/v1/admin/items/{ITEM}", json={"moderation_status": "hidden"}).status_code == 422
    service = MagicMock()
    now = datetime.now(UTC).isoformat()
    item = {"id": ITEM, "owner_id": USER, "name": "Camera", "description": "Camera for events.",
        "category": "electronics", "condition": "Good", "price_per_day": 100,
        "discount_percent": 0, "availability": "available", "community": "Davao",
        "image_urls": [], "image_paths": [], "moderation_status": "hidden",
        "moderation_reason": "Unsafe", "moderated_at": now, "created_at": now, "updated_at": now}
    service.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [item]
    service.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {"name": "Owner"}
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.patch(f"/api/v1/admin/items/{ITEM}", json={"moderation_status": "hidden", "reason": "Unsafe"})
    assert response.status_code == 200
    assert response.json()["moderation_status"] == "hidden"


@pytest.mark.parametrize("body", [{}, {"moderation_status": "deleted"}, {"moderation_status": "hidden", "owner_id": USER}])
def test_listing_moderation_validates_body(body):
    app.dependency_overrides[get_current_user] = current
    assert client.patch(f"/api/v1/admin/items/{ITEM}", json=body).status_code == 422
