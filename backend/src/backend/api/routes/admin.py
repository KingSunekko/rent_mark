from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter, HTTPException

from backend.api.dependencies import CurrentUser
from backend.core.supabase import get_supabase_client
from backend.schemas.admin import AdminDashboard, ListingModerationUpdate, UserModerationUpdate
from backend.schemas.auth import UserProfile
from backend.schemas.item import ItemResponse

router = APIRouter(prefix="/admin", tags=["Administration"])


def _require_admin(user: CurrentUser) -> None:
    if user.role != "admin":
        raise HTTPException(403, "Administrator access required")


def _item(row: dict) -> ItemResponse:
    values = dict(row)
    owner = values.pop("owner", None) or {}
    return ItemResponse(owner_name=owner.get("name", "Unknown owner"), **values)


def _auth_emails(service) -> dict[str, str]:
    users = service.auth.admin.list_users()
    return {str(value.id): value.email for value in users if value.email}


def _user_profile(row: dict, auth_emails: dict[str, str]) -> UserProfile:
    values = dict(row)
    values.setdefault(
        "email", auth_emails.get(str(values["id"]), "unknown@rentmark.invalid")
    )
    return UserProfile(**values)


@router.get("/dashboard", response_model=AdminDashboard)
def dashboard(user: CurrentUser):
    _require_admin(user)
    service = get_supabase_client()
    try:
        profiles = service.table("profiles").select("*").order("created_at", desc=True).execute().data or []
        emails = _auth_emails(service)
        items = service.table("items").select("*,owner:profiles!items_owner_id_fkey(name)").order("created_at", desc=True).execute().data or []
        rentals = service.table("rental_requests").select("*").order("requested_at", desc=True).execute().data or []
        reviews = service.table("reviews").select("*").order("created_at", desc=True).execute().data or []
        active = sum(row["status"] in {"active", "return_requested"} for row in rentals)
        completed = sum(row["status"] == "completed" for row in rentals)
        value = sum(row["total_centavos"] for row in rentals if row["status"] != "rejected")
        return {
            "metrics": {"users": len(profiles), "listings": len(items), "requests": len(rentals),
                "active_rentals": active, "completed_rentals": completed,
                "reviews": len(reviews), "estimated_rental_value_centavos": value},
            "users": [_user_profile(row, emails) for row in profiles],
            "listings": [_item(row) for row in items],
            "rentals": rentals, "reviews": reviews,
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(502, "Admin dashboard could not be loaded") from exc


@router.patch("/users/{user_id}", response_model=UserProfile)
def moderate_user(user_id: UUID, payload: UserModerationUpdate, user: CurrentUser):
    _require_admin(user)
    if str(user_id) == user.id:
        raise HTTPException(409, "Administrators cannot suspend their own account")
    if payload.is_suspended and not payload.reason:
        raise HTTPException(422, "A suspension reason is required")
    values = {"is_suspended": payload.is_suspended,
        "suspension_reason": payload.reason if payload.is_suspended else "",
        "suspended_at": datetime.now(UTC).isoformat() if payload.is_suspended else None}
    try:
        rows = get_supabase_client().table("profiles").update(values).eq("id", str(user_id)).neq("role", "admin").execute().data or []
    except Exception as exc:
        raise HTTPException(502, "User moderation could not be updated") from exc
    if not rows:
        raise HTTPException(404, "User not found")
    return UserProfile(**rows[0])


@router.patch("/items/{item_id}", response_model=ItemResponse)
def moderate_item(item_id: UUID, payload: ListingModerationUpdate, user: CurrentUser):
    _require_admin(user)
    if payload.moderation_status == "hidden" and not payload.reason:
        raise HTTPException(422, "A moderation reason is required")
    values = {"moderation_status": payload.moderation_status,
        "moderation_reason": payload.reason if payload.moderation_status == "hidden" else "",
        "moderated_at": datetime.now(UTC).isoformat()}
    try:
        rows = get_supabase_client().table("items").update(values).eq("id", str(item_id)).execute().data or []
        if not rows:
            raise HTTPException(404, "Listing not found")
        owner = get_supabase_client().table("profiles").select("name").eq("id", rows[0]["owner_id"]).single().execute().data
        return ItemResponse(owner_name=owner["name"], **rows[0])
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(502, "Listing moderation could not be updated") from exc
