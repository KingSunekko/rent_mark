from datetime import UTC, datetime
from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from postgrest.exceptions import APIError

from backend.api.dependencies import get_current_user
from backend.api.routes import reviews as routes
from backend.main import app
from backend.schemas.auth import UserProfile

client = TestClient(app)
RENTER = str(uuid4())
OWNER = str(uuid4())
RENTAL = str(uuid4())


def user(role="renter"):
    return UserProfile(
        id=RENTER if role == "renter" else OWNER,
        email="reviewer@example.com",
        name="Reviewer",
        role=role,
        community="Davao",
    )


def review_row():
    return {
        "id": str(uuid4()),
        "rental_request_id": RENTAL,
        "item_id": str(uuid4()),
        "renter_id": RENTER,
        "owner_id": OWNER,
        "renter_name": "Reviewer",
        "owner_name": "Owner",
        "item_name": "Camera",
        "rating": 5,
        "comment": "Excellent item.",
        "created_at": datetime.now(UTC).isoformat(),
    }


@pytest.fixture(autouse=True)
def cleanup():
    yield
    app.dependency_overrides.clear()


def test_review_routes_require_authentication():
    assert client.get("/api/v1/reviews").status_code == 401
    assert client.post(
        "/api/v1/reviews",
        json={"rental_request_id": RENTAL, "rating": 5},
    ).status_code == 401


def test_only_renters_create_reviews():
    app.dependency_overrides[get_current_user] = lambda: user("owner")
    assert client.post(
        "/api/v1/reviews",
        json={"rental_request_id": RENTAL, "rating": 5},
    ).status_code == 403


@pytest.mark.parametrize("field,value", [
    ("owner_id", OWNER),
    ("renter_id", RENTER),
    ("item_id", str(uuid4())),
    ("owner_name", "Fake"),
    ("created_at", datetime.now(UTC).isoformat()),
])
def test_review_rejects_server_controlled_fields(field, value):
    app.dependency_overrides[get_current_user] = user
    body = {"rental_request_id": RENTAL, "rating": 5, field: value}
    assert client.post("/api/v1/reviews", json=body).status_code == 422


def test_review_uses_authoritative_database_transaction(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    saved = review_row()
    service.rpc.return_value.execute.return_value.data = [saved]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)

    response = client.post(
        "/api/v1/reviews",
        json={
            "rental_request_id": RENTAL,
            "rating": 5,
            "comment": " Excellent item. ",
        },
    )

    assert response.status_code == 201
    assert response.json()["owner_id"] == OWNER
    service.rpc.assert_called_once_with(
        "create_rental_review",
        {
            "p_renter_id": RENTER,
            "p_rental_request_id": RENTAL,
            "p_rating": 5,
            "p_comment": "Excellent item.",
        },
    )


@pytest.mark.parametrize("message,status", [
    ("renter_required", 403),
    ("rental_not_found", 404),
    ("rental_not_completed", 409),
    ("review_exists", 409),
    ("invalid_rating", 422),
    ("invalid_comment", 422),
])
def test_review_database_errors_are_clear(monkeypatch, message, status):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    service.rpc.return_value.execute.side_effect = APIError(
        dict(code="P0001", message=message, details=None, hint=None)
    )
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)
    response = client.post(
        "/api/v1/reviews",
        json={"rental_request_id": RENTAL, "rating": 4},
    )
    assert response.status_code == status
    assert response.json()["detail"] == routes._ERRORS[message][1]


def test_review_body_validation():
    app.dependency_overrides[get_current_user] = user
    for body in [
        {"rental_request_id": RENTAL, "rating": 0},
        {"rental_request_id": RENTAL, "rating": 6},
        {"rental_request_id": RENTAL, "rating": 5, "comment": "x" * 301},
        {"rental_request_id": "not-a-uuid", "rating": 5},
    ]:
        assert client.post("/api/v1/reviews", json=body).status_code == 422


def test_reviews_can_be_filtered_and_paginated(monkeypatch):
    app.dependency_overrides[get_current_user] = user
    service = MagicMock()
    query = service.table.return_value.select.return_value
    query.eq.return_value.order.return_value.order.return_value.range.return_value.execute.return_value.data = [
        review_row()
    ]
    monkeypatch.setattr(routes, "get_supabase_client", lambda: service)

    response = client.get(f"/api/v1/reviews?owner_id={OWNER}&limit=10&offset=20")

    assert response.status_code == 200
    query.eq.assert_called_once_with("owner_id", OWNER)
    query.eq.return_value.order.return_value.order.return_value.range.assert_called_once_with(20, 29)


def test_review_list_rejects_multiple_filters():
    app.dependency_overrides[get_current_user] = user
    response = client.get(f"/api/v1/reviews?owner_id={OWNER}&renter_id={RENTER}")
    assert response.status_code == 422
