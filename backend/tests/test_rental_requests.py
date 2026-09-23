from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from postgrest.exceptions import APIError

from backend.main import app
from backend.api.dependencies import get_current_user
from backend.api.routes import rental_requests as routes
from backend.schemas.auth import UserProfile

client = TestClient(app)
RENTER = str(uuid4())
OWNER = str(uuid4())
ITEM = str(uuid4())


def user(role="renter"):
    return UserProfile(id=RENTER if role == "renter" else OWNER,
                       email="test@example.com", name="Test", role=role, community="Davao")


def payload():
    day = (datetime.now(UTC) + timedelta(days=2)).date().isoformat()
    return dict(client_request_id=str(uuid4()), item_id=ITEM,
                start_date=day, end_date=day, message="Hello", pickup_method="Community meetup")


def row(body=None):
    body = body or payload()
    now = datetime.now(UTC).isoformat()
    return dict(**body, id=str(uuid4()), renter_id=RENTER, owner_id=OWNER,
                renter_name="Renter", duration_days=1, daily_price_centavos=8415,
                total_centavos=8415, status="pending", requested_at=now,
                item_snapshot=dict(id=ITEM, owner_id=OWNER, owner_name="Owner", name="Camera",
                    description="Camera for events.", category="electronics", condition="Good",
                    price_per_day=99, discount_percent=15, availability="available", community="Davao",
                    image_urls=[], image_paths=[], moderation_status="active", created_at=now, updated_at=now))


@pytest.fixture(autouse=True)
def cleanup():
    yield
    app.dependency_overrides.clear()


def test_auth_required():
    assert client.get("/api/v1/rental-requests").status_code == 401
    assert client.post("/api/v1/rental-requests", json=payload()).status_code == 401


@pytest.mark.parametrize("role", ["owner", "admin"])
def test_only_renters_create(role):
    app.dependency_overrides[get_current_user] = lambda: user(role)
    assert client.post("/api/v1/rental-requests", json=payload()).status_code == 403


@pytest.mark.parametrize("field,value", [
    ("owner_id", OWNER), ("renter_id", OWNER), ("status", "approved"),
    ("total_centavos", 1), ("price_per_day", 1), ("discount_percent", 20),
])
def test_rejects_client_controlled_authority_fields(field, value):
    app.dependency_overrides[get_current_user] = user
    assert client.post("/api/v1/rental-requests", json={**payload(), field: value}).status_code == 422


def test_create_passes_only_identity_and_validated_fields_to_transaction(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    body = payload()
    saved = row(body)
    service.rpc.return_value.execute.return_value.data = [saved]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    for _ in range(2):
        response = client.post("/api/v1/rental-requests", json=body)
        assert response.status_code == 201
        assert response.json()["id"] == saved["id"]
        assert response.json()["total_centavos"] == 8415
        assert response.json()["status"] == "pending"
    name, args = service.rpc.call_args.args
    assert name == "create_rental_request"
    assert args == {**{f"p_{k}": v for k, v in body.items()}, "p_renter_id": RENTER}


@pytest.mark.parametrize("message,status", [
    ("renter_required", 403), ("retry_conflict", 409), ("invalid_dates", 422),
    ("item_not_found", 404), ("own_item", 403), ("item_unavailable", 409), ("date_conflict", 409),
])
def test_transaction_errors_are_clear(monkeypatch, message, status):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    service.rpc.return_value.execute.side_effect = APIError(dict(code="P0001", message=message, details=None, hint=None))
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.post("/api/v1/rental-requests", json=payload())
    assert response.status_code == status
    assert response.json()["detail"] == routes._ERRORS[message][1]


@pytest.mark.parametrize("role,column", [("renter", "renter_id"), ("owner", "owner_id")])
def test_lists_and_details_are_participant_scoped(monkeypatch, role, column):
    app.dependency_overrides[get_current_user] = lambda: user(role)
    service = MagicMock()
    query = service.table.return_value
    query.select.return_value.eq.return_value.order.return_value.order.return_value.range.return_value.execute.return_value.data = [row()]
    query.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value.data = []
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    assert client.get("/api/v1/rental-requests?limit=10&offset=20").status_code == 200
    query.select.return_value.eq.assert_called_with(column, user(role).id)
    query.select.return_value.eq.return_value.order.return_value.order.return_value.range.assert_called_with(20, 29)
    assert client.get(f"/api/v1/rental-requests/{uuid4()}").status_code == 404
    query.select.return_value.eq.assert_called_with(column, user(role).id)


def test_dates_and_message_validation():
    app.dependency_overrides[get_current_user] = user
    body = payload()
    for changes in [dict(end_date="2000-01-01"), dict(end_date="2100-01-01"),
                    dict(message="x" * 2001), dict(pickup_method="unknown"), dict(item_id="mock-1")]:
        assert client.post("/api/v1/rental-requests", json={**body, **changes}).status_code == 422


def test_unexpected_errors_do_not_leak_database_details(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    service.rpc.return_value.execute.side_effect = RuntimeError("private database detail")
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.post("/api/v1/rental-requests", json=payload())
    assert response.status_code == 502
    assert "private" not in response.text


def test_only_owner_can_transition_requests():
    request_id = uuid4()
    app.dependency_overrides[get_current_user] = user
    response = client.patch(
        f"/api/v1/rental-requests/{request_id}/status",
        json={"status": "approved"},
    )
    assert response.status_code == 403


def test_owner_transition_uses_server_side_transaction(monkeypatch):
    app.dependency_overrides[get_current_user] = lambda: user("owner")
    service = MagicMock()
    saved = row()
    saved.update(status="rejected", rejection_reason="Dates no longer available")
    service.rpc.return_value.execute.return_value.data = [saved]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)

    response = client.patch(
        f"/api/v1/rental-requests/{saved['id']}/status",
        json={"status": "rejected", "rejection_reason": "Dates no longer available"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "rejected"
    assert response.json()["rejection_reason"] == "Dates no longer available"
    service.rpc.assert_called_once_with(
        "transition_rental_request",
        {
            "p_actor_id": OWNER,
            "p_request_id": saved["id"],
            "p_status": "rejected",
            "p_rejection_reason": "Dates no longer available",
        },
    )


@pytest.mark.parametrize("status", ["pending"])
def test_phase_11e_rejects_unsupported_client_transitions(status):
    app.dependency_overrides[get_current_user] = lambda: user("owner")
    response = client.patch(
        f"/api/v1/rental-requests/{uuid4()}/status",
        json={"status": status},
    )
    assert response.status_code == 422


def test_renter_can_request_return_through_transaction(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    saved = row()
    saved.update(
        status="return_requested",
        return_requested_at=datetime.now(UTC).isoformat(),
    )
    service.rpc.return_value.execute.return_value.data = [saved]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)

    response = client.patch(
        f"/api/v1/rental-requests/{saved['id']}/status",
        json={"status": "return_requested"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "return_requested"
    assert response.json()["return_requested_at"] is not None


def test_owner_can_confirm_return_through_transaction(monkeypatch):
    app.dependency_overrides[get_current_user] = lambda: user("owner")
    service = MagicMock()
    saved = row()
    saved.update(status="completed", completed_at=datetime.now(UTC).isoformat())
    service.rpc.return_value.execute.return_value.data = [saved]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)

    response = client.patch(
        f"/api/v1/rental-requests/{saved['id']}/status",
        json={"status": "completed"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "completed"
    assert response.json()["completed_at"] is not None


def test_return_actions_enforce_participant_roles():
    request_id = uuid4()
    app.dependency_overrides[get_current_user] = lambda: user("owner")
    assert client.patch(
        f"/api/v1/rental-requests/{request_id}/status",
        json={"status": "return_requested"},
    ).status_code == 403
    app.dependency_overrides[get_current_user] = user
    assert client.patch(
        f"/api/v1/rental-requests/{request_id}/status",
        json={"status": "completed"},
    ).status_code == 403


@pytest.mark.parametrize("message,status", [
    ("owner_required", 403),
    ("request_not_found", 404),
    ("invalid_transition", 409),
    ("date_conflict", 409),
])
def test_transition_database_errors_are_clear(monkeypatch, message, status):
    app.dependency_overrides[get_current_user] = lambda: user("owner")
    service = MagicMock()
    service.rpc.return_value.execute.side_effect = APIError(
        dict(code="P0001", message=message, details=None, hint=None)
    )
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.patch(
        f"/api/v1/rental-requests/{uuid4()}/status",
        json={"status": "approved"},
    )
    assert response.status_code == status
    assert response.json()["detail"] == routes._ERRORS[message][1]
