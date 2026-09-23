import logging
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query
from postgrest.exceptions import APIError

from backend.api.dependencies import CurrentUser
from backend.core.supabase import get_supabase_client
from backend.schemas.review import ReviewCreate, ReviewResponse

router = APIRouter(prefix="/reviews", tags=["Reviews"])
logger = logging.getLogger(__name__)

_ERRORS = {
    "renter_required": (403, "Renter access required"),
    "rental_not_found": (404, "Completed rental not found"),
    "rental_not_completed": (409, "Only completed rentals can be reviewed"),
    "review_exists": (409, "This rental has already been reviewed"),
    "invalid_rating": (422, "Rating must be between 1 and 5"),
    "invalid_comment": (422, "Review must be 300 characters or fewer"),
}


@router.post("", response_model=ReviewResponse, status_code=201)
def create_review(payload: ReviewCreate, user: CurrentUser):
    if user.role != "renter":
        raise HTTPException(403, "Renter access required")
    params = {
        "p_renter_id": user.id,
        "p_rental_request_id": str(payload.rental_request_id),
        "p_rating": payload.rating,
        "p_comment": payload.comment,
    }
    try:
        rows = get_supabase_client().rpc("create_rental_review", params).execute().data or []
        if not rows:
            raise HTTPException(502, "Review could not be saved")
        return ReviewResponse.model_validate(rows[0])
    except HTTPException:
        raise
    except APIError as exc:
        if exc.code == "P0001" and exc.message in _ERRORS:
            code, detail = _ERRORS[exc.message]
            raise HTTPException(code, detail) from exc
        logger.exception("Review database operation failed")
        raise HTTPException(502, "Review could not be saved") from exc
    except Exception as exc:
        logger.exception("Review could not be saved")
        raise HTTPException(502, "Review could not be saved") from exc


@router.get("", response_model=list[ReviewResponse])
def list_reviews(
    user: CurrentUser,
    owner_id: UUID | None = None,
    renter_id: UUID | None = None,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    if owner_id is not None and renter_id is not None:
        raise HTTPException(422, "Choose only one review filter")
    try:
        query = get_supabase_client().table("reviews").select("*")
        if owner_id is not None:
            query = query.eq("owner_id", str(owner_id))
        elif renter_id is not None:
            query = query.eq("renter_id", str(renter_id))
        return (
            query.order("created_at", desc=True)
            .order("id")
            .range(offset, offset + limit - 1)
            .execute()
            .data
            or []
        )
    except Exception as exc:
        raise HTTPException(502, "Reviews could not be loaded") from exc
