from uuid import UUID

from fastapi import APIRouter, HTTPException, Query

from backend.api.dependencies import CurrentUser
from backend.core.supabase import get_supabase_client
from backend.schemas.notification import (
    NotificationBulkRead,
    NotificationResponse,
    NotificationUpdate,
)

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=list[NotificationResponse])
def list_notifications(
    user: CurrentUser,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    try:
        return (
            get_supabase_client().table("notifications").select("*")
            .eq("user_id", user.id).eq("is_deleted", False)
            .order("created_at", desc=True).order("id")
            .range(offset, offset + limit - 1).execute().data or []
        )
    except Exception as exc:
        raise HTTPException(502, "Notifications could not be loaded") from exc


@router.patch("/{notification_id}", response_model=NotificationResponse)
def update_notification(
    notification_id: UUID, payload: NotificationUpdate, user: CurrentUser
):
    values = payload.model_dump(exclude_none=True)
    try:
        rows = (
            get_supabase_client().table("notifications").update(values)
            .eq("id", str(notification_id)).eq("user_id", user.id)
            .execute().data or []
        )
    except Exception as exc:
        raise HTTPException(502, "Notification could not be updated") from exc
    if not rows:
        raise HTTPException(404, "Notification not found")
    return rows[0]


@router.patch("", response_model=list[NotificationResponse])
def update_notification_reads(payload: NotificationBulkRead, user: CurrentUser):
    try:
        return (
            get_supabase_client().table("notifications")
            .update({"is_read": payload.is_read})
            .eq("user_id", user.id)
            .in_("id", [str(value) for value in payload.notification_ids])
            .execute().data or []
        )
    except Exception as exc:
        raise HTTPException(502, "Notifications could not be updated") from exc
