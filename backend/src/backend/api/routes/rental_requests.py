import logging
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query
from postgrest.exceptions import APIError

from backend.api.dependencies import CurrentUser
from backend.core.supabase import get_supabase_client
from backend.schemas.rental_request import (
    RentalRequestCreate,
    RentalRequestResponse,
    RentalRequestTransition,
)

router = APIRouter(prefix="/rental-requests", tags=["Rental Requests"])
logger = logging.getLogger(__name__)
_ERRORS = {
    "renter_required": (403, "Renter access required"),
    "retry_conflict": (409, "This submission key was already used for different request details"),
    "invalid_dates": (422, "Choose dates starting today or later, for at most 365 days (Philippine time)"),
    "item_not_found": (404, "Item not found"),
    "own_item": (403, "You cannot rent your own item"),
    "item_unavailable": (409, "This item is unavailable for rental"),
    "date_conflict": (409, "The item is already booked during these dates"),
    "owner_required": (403, "Owner access required"),
    "request_not_found": (404, "Rental request not found"),
    "invalid_transition": (409, "This rental status transition is not allowed"),
    "invalid_rejection_reason": (422, "Rejection reason must be 500 characters or fewer"),
    "unsupported_status": (422, "Unsupported rental status"),
    "participant_required": (403, "Renter or owner access required"),
}


def _participant_column(user: CurrentUser) -> str:
    if user.role == "renter":
        return "renter_id"
    if user.role == "owner":
        return "owner_id"
    raise HTTPException(403, "Renter or owner access required")


@router.post("", response_model=RentalRequestResponse, status_code=201)
def create_request(payload: RentalRequestCreate, user: CurrentUser):
    if user.role != "renter":
        raise HTTPException(403, "Renter access required")
    params = {f"p_{key}": value for key, value in payload.model_dump(mode="json").items()}
    params["p_renter_id"] = user.id
    try:
        rows = get_supabase_client().rpc("create_rental_request", params).execute().data
        return RentalRequestResponse.model_validate(rows[0])
    except APIError as exc:
        if exc.code == "P0001" and exc.message in _ERRORS:
            code, detail = _ERRORS[exc.message]
            raise HTTPException(code, detail) from exc
        logger.exception("Rental request database operation failed")
        raise HTTPException(502, "Rental request could not be saved. Retry the same submission.") from exc
    except Exception as exc:
        logger.exception("Rental request could not be saved")
        raise HTTPException(502, "Rental request could not be saved. Retry the same submission.") from exc


@router.get("", response_model=list[RentalRequestResponse])
def list_requests(user: CurrentUser, limit: int = Query(50, ge=1, le=100), offset: int = Query(0, ge=0)):
    column = _participant_column(user)
    try:
        return (get_supabase_client().table("rental_requests").select("*")
                .eq(column, user.id).order("requested_at", desc=True).order("id")
                .range(offset, offset + limit - 1).execute().data or [])
    except Exception as exc:
        raise HTTPException(502, "Rental requests could not be loaded") from exc


@router.get("/{request_id}", response_model=RentalRequestResponse)
def get_request(request_id: UUID, user: CurrentUser):
    column = _participant_column(user)
    try:
        rows = (get_supabase_client().table("rental_requests").select("*")
                .eq(column, user.id).eq("id", str(request_id)).limit(1).execute().data or [])
    except Exception as exc:
        raise HTTPException(502, "Rental request could not be loaded") from exc
    if not rows:
        raise HTTPException(404, "Rental request not found")
    return rows[0]


@router.patch("/{request_id}/status", response_model=RentalRequestResponse)
def transition_request(request_id: UUID, payload: RentalRequestTransition, user: CurrentUser):
    if user.role not in {"renter", "owner"}:
        raise HTTPException(403, "Renter or owner access required")
    if payload.status == "return_requested" and user.role != "renter":
        raise HTTPException(403, "Renter access required")
    if payload.status != "return_requested" and user.role != "owner":
        raise HTTPException(403, "Owner access required")
    params = {
        "p_actor_id": user.id,
        "p_request_id": str(request_id),
        "p_status": payload.status,
        "p_rejection_reason": payload.rejection_reason,
    }
    try:
        rows = get_supabase_client().rpc("transition_rental_request", params).execute().data or []
        if not rows:
            raise HTTPException(404, "Rental request not found")
        return RentalRequestResponse.model_validate(rows[0])
    except HTTPException:
        raise
    except APIError as exc:
        if exc.code == "P0001" and exc.message in _ERRORS:
            code, detail = _ERRORS[exc.message]
            raise HTTPException(code, detail) from exc
        logger.exception("Rental status database operation failed")
        raise HTTPException(502, "Rental status could not be updated") from exc
    except Exception as exc:
        logger.exception("Rental status could not be updated")
        raise HTTPException(502, "Rental status could not be updated") from exc
