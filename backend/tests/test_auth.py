from types import SimpleNamespace
from unittest.mock import MagicMock

from fastapi.testclient import TestClient

from backend.api.routes import auth as auth_routes
from backend.main import app

client = TestClient(app)


def test_registration_rejects_admin_role_before_database_access() -> None:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "admin-candidate@example.com",
            "password": "strong-password",
            "name": "Admin Candidate",
            "community": "Davao Community",
            "role": "admin",
        },
    )
    assert response.status_code == 422


def test_registration_validates_password_length() -> None:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "renter@example.com",
            "password": "short",
            "name": "Test Renter",
            "community": "Davao Community",
            "role": "renter",
        },
    )
    assert response.status_code == 422


def test_registration_reports_an_existing_email(monkeypatch) -> None:
    service_client = MagicMock()
    service_client.auth.admin.create_user.side_effect = Exception(
        "User already registered"
    )
    monkeypatch.setattr(
        auth_routes, "get_supabase_client", lambda: service_client
    )

    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "existing@example.com",
            "password": "strong-password",
            "name": "Existing User",
            "community": "Davao Community",
            "role": "renter",
        },
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "An account with this email already exists."
    )


def test_registration_recognizes_supabase_email_exists_code(monkeypatch) -> None:
    service_client = MagicMock()
    service_client.auth.admin.create_user.side_effect = Exception("email_exists")
    monkeypatch.setattr(
        auth_routes, "get_supabase_client", lambda: service_client
    )

    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "existing@example.com",
            "password": "strong-password",
            "name": "Existing User",
            "community": "Davao Community",
            "role": "renter",
        },
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "An account with this email already exists."
    )


def test_me_requires_bearer_token() -> None:
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401
    assert response.json()["detail"] == "Authentication required"


def test_profile_update_requires_bearer_token() -> None:
    response = client.patch("/api/v1/auth/me", json={"name": "Updated Name"})
    assert response.status_code == 401


def test_refresh_accepts_short_opaque_supabase_tokens(monkeypatch) -> None:
    _mock_refresh(monkeypatch, suspended=False)

    response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "4bi6tpvkc24n"},
    )

    assert response.status_code == 200


def _mock_refresh(monkeypatch, *, suspended: bool) -> None:
    auth_client = MagicMock()
    auth_client.auth.refresh_session.return_value = SimpleNamespace(
        user=SimpleNamespace(id="user-123", email="renter@example.com"),
        session=SimpleNamespace(
            access_token="access-token",
            refresh_token="next-refresh-token",
            expires_in=3600,
        ),
    )
    table = MagicMock()
    table.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
        "id": "user-123",
        "name": "Test Renter",
        "community": "Davao Community",
        "role": "renter",
        "is_suspended": suspended,
    }
    service_client = MagicMock()
    service_client.table.return_value = table
    secret = SimpleNamespace(get_secret_value=lambda: "service-role-key")

    monkeypatch.setattr(auth_routes, "create_client", lambda *_: auth_client)
    monkeypatch.setattr(
        auth_routes,
        "get_settings",
        lambda: SimpleNamespace(
            supabase_url="https://example.supabase.co",
            supabase_service_role_key=secret,
        ),
    )
    monkeypatch.setattr(auth_routes, "get_supabase_client", lambda: service_client)


def test_refresh_returns_a_new_session(monkeypatch) -> None:
    _mock_refresh(monkeypatch, suspended=False)

    response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "valid-refresh-token-value"},
    )

    assert response.status_code == 200
    assert response.json()["access_token"] == "access-token"
    assert response.json()["user"]["id"] == "user-123"


def test_refresh_rejects_a_suspended_user(monkeypatch) -> None:
    _mock_refresh(monkeypatch, suspended=True)

    response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "valid-refresh-token-value"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Account is suspended"
