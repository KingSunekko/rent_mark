from datetime import UTC, datetime
from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from backend.api.dependencies import get_current_user
from backend.api.routes import notifications as routes
from backend.main import app
from backend.schemas.auth import UserProfile

client = TestClient(app)
USER = str(uuid4())
OTHER = str(uuid4())


def user():
    return UserProfile(id=USER, email="user@example.com", name="User", role="renter", community="Davao")


def row(notification_id=None):
    return {
        "id": str(notification_id or uuid4()), "user_id": USER,
        "kind": "status", "title": "Request approved",
        "message": "Camera was approved.", "related_request_id": str(uuid4()),
        "related_review_id": None, "is_read": False, "is_deleted": False,
        "created_at": datetime.now(UTC).isoformat(),
    }


@pytest.fixture(autouse=True)
def cleanup():
    yield
    app.dependency_overrides.clear()


def test_notification_routes_require_authentication():
    notification_id = uuid4()
    assert client.get("/api/v1/notifications").status_code == 401
    assert client.patch(f"/api/v1/notifications/{notification_id}", json={"is_read": True}).status_code == 401


def test_list_is_scoped_and_paginated(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    query = service.table.return_value.select.return_value
    query.eq.return_value.eq.return_value.order.return_value.order.return_value.range.return_value.execute.return_value.data = [row()]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.get("/api/v1/notifications?limit=10&offset=20")
    assert response.status_code == 200
    query.eq.assert_called_once_with("user_id", USER)
    query.eq.return_value.eq.assert_called_once_with("is_deleted", False)
    query.eq.return_value.eq.return_value.order.return_value.order.return_value.range.assert_called_once_with(20, 29)


def test_update_is_scoped_to_current_user(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    notification_id = uuid4()
    service = MagicMock()
    query = service.table.return_value.update.return_value
    saved = row(notification_id)
    saved["is_read"] = True
    query.eq.return_value.eq.return_value.execute.return_value.data = [saved]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.patch(f"/api/v1/notifications/{notification_id}", json={"is_read": True})
    assert response.status_code == 200
    query.eq.assert_called_once_with("id", str(notification_id))
    query.eq.return_value.eq.assert_called_once_with("user_id", USER)


def test_missing_notification_is_hidden(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    service.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    assert client.patch(f"/api/v1/notifications/{uuid4()}", json={"is_deleted": True}).status_code == 404


def test_bulk_read_is_scoped(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    ids = [uuid4(), uuid4()]
    service = MagicMock()
    query = service.table.return_value.update.return_value
    query.eq.return_value.in_.return_value.execute.return_value.data = []
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    assert client.patch("/api/v1/notifications", json={"notification_ids": [str(v) for v in ids], "is_read": True}).status_code == 200
    query.eq.assert_called_once_with("user_id", USER)
    query.eq.return_value.in_.assert_called_once_with("id", [str(v) for v in ids])


@pytest.mark.parametrize("body", [{}, {"is_read": "yes"}, {"is_deleted": 1}, {"title": "hack"}])
def test_update_validation(body):
    app.dependency_overrides[get_current_user] = user
    assert client.patch(f"/api/v1/notifications/{uuid4()}", json=body).status_code == 422
