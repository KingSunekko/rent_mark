from datetime import UTC, datetime
from unittest.mock import MagicMock
import pytest

from fastapi.testclient import TestClient

from backend.api.dependencies import get_current_user
from backend.api.routes import items as item_routes
from backend.main import app
from backend.schemas.auth import UserProfile

client = TestClient(app)


def _user(role: str = "owner") -> UserProfile:
    return UserProfile(
        id="2f443f52-0854-4e7a-b0b3-d1d2931a3f64",
        email=f"{role}@example.com",
        name="Test Owner" if role == "owner" else "Test Renter",
        community="Davao Community",
        role=role,
    )


def _item_row() -> dict:
    now = datetime.now(UTC).isoformat()
    return {
        "id": "1f443f52-0854-4e7a-b0b3-d1d2931a3f65",
        "owner_id": _user().id,
        "name": "Canon Camera",
        "description": "A reliable camera for community events.",
        "category": "electronics",
        "condition": "Good",
        "price_per_day": 500,
        "availability": "available",
        "community": "Davao Community",
        "image_urls": [],
        "moderation_status": "active",
        "created_at": now,
        "updated_at": now,
    }


def _discovery_row() -> dict:
    return {**_item_row(), "owner": {"name": "Test Owner"}}


def teardown_function() -> None:
    app.dependency_overrides.clear()


def test_items_require_authentication() -> None:
    response = client.get("/api/v1/items")
    assert response.status_code == 401


def test_item_discovery_uses_joined_owner_and_pagination(monkeypatch) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user("renter")
    table = MagicMock()
    table.select.return_value.eq.return_value.order.return_value.order.return_value.range.return_value.execute.return_value.data = [
        _discovery_row()
    ]
    service = MagicMock()
    service.table.return_value = table
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)

    response = client.get("/api/v1/items?limit=10&offset=20")

    assert response.status_code == 200
    assert response.json()[0]["owner_name"] == "Test Owner"
    table.select.return_value.eq.return_value.order.return_value.order.return_value.range.assert_called_once_with(
        20, 29
    )


def test_renter_cannot_create_an_item() -> None:
    app.dependency_overrides[get_current_user] = lambda: _user("renter")
    response = client.post(
        "/api/v1/owner/items",
        json={
            "name": "Canon Camera",
            "description": "A reliable camera for community events.",
            "category": "electronics",
            "condition": "Good",
            "price_per_day": 500,
        },
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "Owner access required"


def test_create_item_uses_authenticated_owner_and_community(monkeypatch) -> None:
    owner = _user()
    app.dependency_overrides[get_current_user] = lambda: owner
    table = MagicMock()
    table.insert.return_value.execute.return_value.data = [_item_row()]
    service = MagicMock()
    service.table.return_value = table
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)

    response = client.post(
        "/api/v1/owner/items",
        json={
            "name": "Canon Camera",
            "description": "A reliable camera for community events.",
            "category": "electronics",
            "condition": "Good",
            "price_per_day": 500,
            "owner_id": "attacker-controlled",
            "community": "Attacker controlled",
        },
    )

    assert response.status_code == 422

    response = client.post(
        "/api/v1/owner/items",
        json={
            "name": "Canon Camera",
            "description": "A reliable camera for community events.",
            "category": "electronics",
            "condition": "Good",
            "price_per_day": 500,
        },
    )
    assert response.status_code == 201
    inserted = table.insert.call_args.args[0]
    assert inserted["owner_id"] == owner.id
    assert inserted["community"] == owner.community


def test_owner_cannot_update_another_owners_item(monkeypatch) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    table = MagicMock()
    table.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
    service = MagicMock()
    service.table.return_value = table
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)

    response = client.patch(
        "/api/v1/owner/items/1f443f52-0854-4e7a-b0b3-d1d2931a3f65",
        json={"price_per_day": 300},
    )
    assert response.status_code == 404


def test_item_validation_rejects_invalid_price() -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    response = client.post(
        "/api/v1/owner/items",
        json={
            "name": "Canon Camera",
            "description": "A reliable camera for community events.",
            "category": "electronics",
            "condition": "Good",
            "price_per_day": 0,
        },
    )
    assert response.status_code == 422


def test_item_rejects_another_users_storage_path() -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    response = client.post(
        "/api/v1/owner/items",
        json={
            "name": "Canon Camera",
            "description": "A reliable camera for community events.",
            "category": "electronics",
            "condition": "Good",
            "price_per_day": 500,
            "image_paths": ["another-user/photo.jpg"],
        },
    )
    assert response.status_code == 422
    assert response.json()["detail"] == (
        "Every image must be uploaded by the authenticated owner"
    )


def test_upload_rejects_unsupported_image_type() -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    response = client.post(
        "/api/v1/owner/items/images",
        files={"image": ("notes.txt", b"not an image", "text/plain")},
    )
    assert response.status_code == 415


def test_upload_rejects_a_spoofed_image_content_type() -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    response = client.post(
        "/api/v1/owner/items/images",
        files={"image": ("fake.jpg", b"not really a jpeg", "image/jpeg")},
    )
    assert response.status_code == 422


def test_upload_rejects_an_image_larger_than_five_megabytes() -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    response = client.post(
        "/api/v1/owner/items/images",
        files={
            "image": (
                "large.jpg",
                b"\xff\xd8\xff" + b"0" * (5 * 1024 * 1024),
                "image/jpeg",
            )
        },
    )
    assert response.status_code == 413


def test_delete_removes_the_owners_storage_objects(monkeypatch) -> None:
    owner = _user()
    app.dependency_overrides[get_current_user] = lambda: owner
    path = f"{owner.id}/photo.jpg"
    table = MagicMock()
    table.select.return_value.contains.return_value.limit.return_value.execute.return_value.data = []
    table.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.return_value.data = {
        "id": _item_row()["id"],
        "image_paths": [path],
    }
    storage = MagicMock()
    service = MagicMock()
    service.table.return_value = table
    service.storage.from_.return_value = storage
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)

    response = client.delete(f"/api/v1/owner/items/{_item_row()['id']}")

    assert response.status_code == 204
    storage.remove.assert_called_once_with([path])


@pytest.mark.parametrize("operation", ["delete", "edit", "failed_create", "cleanup"])
def test_shared_images_survive_all_cleanup_paths(monkeypatch, operation) -> None:
    owner = _user()
    app.dependency_overrides[get_current_user] = lambda: owner
    path = f"{owner.id}/shared.jpg"
    service = MagicMock()
    table = service.table.return_value
    table.select.return_value.contains.return_value.limit.return_value.execute.return_value.data = [{"id": "other-listing"}]
    table.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.return_value.data = {
        "id": _item_row()["id"], "image_paths": [path],
    }
    table.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = [_item_row()]
    table.insert.return_value.execute.side_effect = RuntimeError("database unavailable")
    service.storage.from_.return_value.get_public_url.return_value = "https://example.com/shared.jpg"
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)
    url = f"/api/v1/owner/items/{_item_row()['id']}"
    if operation == "delete":
        response = client.delete(url)
        assert response.status_code == 204
    elif operation == "edit":
        response = client.patch(url, json={"image_paths": []})
        assert response.status_code == 200
    elif operation == "cleanup":
        response = client.post("/api/v1/owner/items/images/cleanup", json={"image_paths": [path]})
        assert response.status_code == 204
    else:
        response = client.post("/api/v1/owner/items", json={
            "name": "Camera", "description": "A camera for events.",
            "category": "electronics", "condition": "Good", "price_per_day": 100,
            "image_paths": [path],
        })
        assert response.status_code == 502
    service.storage.from_.return_value.remove.assert_not_called()


def test_cleanup_only_deletes_unreferenced_images(monkeypatch) -> None:
    owner = _user()
    app.dependency_overrides[get_current_user] = lambda: owner
    paths = [f"{owner.id}/unused.jpg", f"{owner.id}/used.jpg"]
    service = MagicMock()
    query = service.table.return_value.select.return_value.contains.return_value.limit.return_value
    query.execute.side_effect = [MagicMock(data=[]), MagicMock(data=[]), MagicMock(data=[{"id": "saved"}])]
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)
    response = client.post("/api/v1/owner/items/images/cleanup", json={"image_paths": paths})
    assert response.status_code == 204
    service.storage.from_.return_value.remove.assert_called_once_with([paths[0]])


@pytest.mark.parametrize("role,paths,expected", [
    ("renter", ["other/file.jpg"], 403),
    ("owner", ["other/file.jpg"], 422),
    ("owner", [f"{_user().id}/../file.jpg"], 422),
    ("owner", [], 422),
])
def test_cleanup_enforces_owner_and_path_validation(role, paths, expected) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user(role)
    response = client.post("/api/v1/owner/items/images/cleanup", json={"image_paths": paths})
    assert response.status_code == expected


def test_cleanup_query_failure_preserves_storage(monkeypatch) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    service = MagicMock()
    service.table.return_value.select.return_value.contains.return_value.limit.return_value.execute.side_effect = RuntimeError("offline")
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)
    response = client.post("/api/v1/owner/items/images/cleanup", json={"image_paths": [f"{_user().id}/photo.jpg"]})
    assert response.status_code == 502
    service.storage.from_.return_value.remove.assert_not_called()


@pytest.mark.parametrize("discount", [-1, 21, 5.5, "10", True])
def test_invalid_discounts_rejected_on_create_and_update(discount) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    body = {
        "name": "Camera", "description": "A camera for events.",
        "category": "electronics", "condition": "Good", "price_per_day": 99,
        "discount_percent": discount,
    }
    assert client.post("/api/v1/owner/items", json=body).status_code == 422
    assert client.patch(f"/api/v1/owner/items/{_item_row()['id']}", json={"discount_percent": discount}).status_code == 422


@pytest.mark.parametrize("discount", [0, 15, 20])
def test_owner_can_save_and_disable_discount(monkeypatch, discount) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    service = MagicMock()
    table = service.table.return_value
    row = {**_item_row(), "discount_percent": discount}
    table.insert.return_value.execute.return_value.data = [row]
    table.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.return_value.data = row
    table.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = [row]
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)
    response = client.post("/api/v1/owner/items", json={
        "name": "Camera", "description": "A camera for events.",
        "category": "electronics", "condition": "Good", "price_per_day": 99,
        "discount_percent": discount,
    })
    assert response.status_code == 201
    assert response.json()["discount_percent"] == discount
    assert table.insert.call_args.args[0]["discount_percent"] == discount
    response = client.patch(f"/api/v1/owner/items/{row['id']}", json={"discount_percent": discount})
    assert response.status_code == 200
    assert table.update.call_args.args[0]["discount_percent"] == discount


def test_renter_cannot_change_discount() -> None:
    app.dependency_overrides[get_current_user] = lambda: _user("renter")
    response = client.patch(f"/api/v1/owner/items/{_item_row()['id']}", json={"discount_percent": 20})
    assert response.status_code == 403


def test_cleanup_preserves_rental_snapshot_photos(monkeypatch) -> None:
    service = MagicMock()
    service.table.return_value.select.return_value.contains.return_value.limit.return_value.execute.side_effect = [
        MagicMock(data=[]), MagicMock(data=[{"id": "saved-rental"}]),
    ]
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)
    item_routes._remove_images([f"{_user().id}/photo.jpg"])
    service.storage.from_.return_value.remove.assert_not_called()


def test_owner_can_save_public_pickup_location(monkeypatch) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    service = MagicMock()
    fields = dict(city="Davao City", barangay="Matina", meeting_point="Barangay hall", pickup_instructions="Meet at the entrance.")
    service.table.return_value.insert.return_value.execute.return_value.data = [{**_item_row(), **fields}]
    monkeypatch.setattr(item_routes, "get_supabase_client", lambda: service)
    response = client.post("/api/v1/owner/items", json={
        "name": "Camera", "description": "Camera for events.", "category": "electronics",
        "condition": "Good", "price_per_day": 99, **fields,
    })
    assert response.status_code == 201
    for field, value in fields.items():
        assert response.json()[field] == value
        assert service.table.return_value.insert.call_args.args[0][field] == value


@pytest.mark.parametrize("field,limit", [("city", 120), ("barangay", 120), ("meeting_point", 200), ("pickup_instructions", 1000)])
def test_public_location_length_validation(field, limit) -> None:
    app.dependency_overrides[get_current_user] = lambda: _user()
    response = client.patch(f"/api/v1/owner/items/{_item_row()['id']}", json={field: "x" * (limit + 1)})
    assert response.status_code == 422
