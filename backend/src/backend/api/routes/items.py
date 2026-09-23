import logging
from datetime import UTC, datetime
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import APIRouter, File, HTTPException, Query, UploadFile, status
from postgrest.exceptions import APIError

from backend.api.dependencies import CurrentUser
from backend.core.supabase import get_supabase_client
from backend.schemas.item import (
    ItemAvailability,
    ItemCategory,
    ItemCreate,
    ItemImageResponse,
    ItemImageCleanup,
    ItemResponse,
    ItemUpdate,
)

router = APIRouter(tags=["Items"])
logger = logging.getLogger(__name__)
_IMAGE_BUCKET = "item-images"
_MAX_IMAGE_BYTES = 5 * 1024 * 1024
_IMAGE_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


def _require_owner(user: CurrentUser) -> None:
    if user.role != "owner":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Owner access required")


def _clean_strings(values: list[str]) -> list[str]:
    cleaned = [value.strip() for value in values if value.strip()]
    if len(set(cleaned)) != len(cleaned):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Image paths must be unique")
    return cleaned


def _validate_image_paths(values: list[str], owner_id: str) -> list[str]:
    paths = _clean_strings(values)
    prefix = f"{owner_id}/"
    if any(not path.startswith(prefix) or ".." in path for path in paths):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            "Every image must be uploaded by the authenticated owner",
        )
    return paths


def _image_urls(paths: list[str]) -> list[str]:
    storage = get_supabase_client().storage.from_(_IMAGE_BUCKET)
    return [storage.get_public_url(path) for path in paths]


def _remove_images(paths: list[str], *, strict: bool = False) -> None:
    if not paths:
        return
    try:
        service = get_supabase_client()
        # Check each path independently: a limited result page must never hide
        # a reference in another listing. Fail closed if the query fails.
        unused = []
        for path in dict.fromkeys(paths):
            references = (
                service.table("items").select("id")
                .contains("image_paths", [path]).limit(1).execute().data
            )
            if references == []:
                snapshots = (
                    service.table("rental_requests").select("id")
                    .contains("item_snapshot", {"image_paths": [path]})
                    .limit(1).execute().data
                )
                if snapshots == []:
                    unused.append(path)
        if unused:
            service.storage.from_(_IMAGE_BUCKET).remove(unused)
    except Exception:
        logger.exception("Could not remove %d orphaned item images", len(paths))
        if strict:
            raise HTTPException(
                status.HTTP_502_BAD_GATEWAY, "Unused images could not be removed"
            )


def _has_valid_signature(content_type: str, contents: bytes) -> bool:
    if content_type == "image/jpeg":
        return contents.startswith(b"\xff\xd8\xff")
    if content_type == "image/png":
        return contents.startswith(b"\x89PNG\r\n\x1a\n")
    if content_type == "image/webp":
        return (
            len(contents) >= 12
            and contents.startswith(b"RIFF")
            and contents[8:12] == b"WEBP"
        )
    return False


def _item_response(row: dict) -> ItemResponse:
    values = dict(row)
    owner = values.pop("owner", None)
    if not isinstance(owner, dict) or not owner.get("name"):
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Item owner could not be loaded")
    return ItemResponse(owner_name=owner["name"], **values)


@router.get("/items", response_model=list[ItemResponse])
def list_items(
    user: CurrentUser,
    category: ItemCategory | None = None,
    availability: ItemAvailability | None = None,
    search: str | None = Query(default=None, min_length=1, max_length=100),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> list[ItemResponse]:
    try:
        query = (
            get_supabase_client()
            .table("items")
            .select("*,owner:profiles!items_owner_id_fkey(name)")
            .eq("moderation_status", "active")
        )
        if category is not None:
            query = query.eq("category", category.value)
        if availability is not None:
            query = query.eq("availability", availability.value)
        if search:
            safe_search = search.strip().replace("%", "").replace(",", " ")
            query = query.or_(
                f"name.ilike.%{safe_search}%,description.ilike.%{safe_search}%"
            )
        rows = (
            query.order("created_at", desc=True)
            .order("id")
            .range(offset, offset + limit - 1)
            .execute()
            .data
            or []
        )
        return [_item_response(row) for row in rows]
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("Could not list items")
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Items could not be loaded") from exc


@router.get("/items/{item_id}", response_model=ItemResponse)
def get_item(item_id: UUID, user: CurrentUser) -> ItemResponse:
    try:
        row = (
            get_supabase_client()
            .table("items")
            .select("*,owner:profiles!items_owner_id_fkey(name)")
            .eq("id", str(item_id))
            .maybe_single()
            .execute()
            .data
        )
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Item could not be loaded") from exc
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Item not found")
    if row["moderation_status"] != "active" and user.id != str(row["owner_id"]) and user.role != "admin":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Item not found")
    return _item_response(row)


@router.get("/owner/items", response_model=list[ItemResponse])
def list_owner_items(user: CurrentUser) -> list[ItemResponse]:
    _require_owner(user)
    try:
        rows = (
            get_supabase_client()
            .table("items")
            .select("*")
            .eq("owner_id", user.id)
            .order("created_at", desc=True)
            .execute()
            .data
            or []
        )
        return [ItemResponse(owner_name=user.name, **row) for row in rows]
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Listings could not be loaded") from exc


@router.post("/owner/items", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
def create_item(payload: ItemCreate, user: CurrentUser) -> ItemResponse:
    _require_owner(user)
    values = payload.model_dump(mode="json")
    values["name"] = payload.name.strip()
    values["description"] = payload.description.strip()
    for field in ("city", "barangay", "meeting_point", "pickup_instructions"):
        values[field] = values[field].strip()
    paths = _validate_image_paths(payload.image_paths, user.id)
    values["image_paths"] = paths
    values["image_urls"] = _image_urls(paths)
    values.update(owner_id=user.id, community=user.community, moderation_status="active")
    try:
        row = get_supabase_client().table("items").insert(values).execute().data[0]
        return ItemResponse(owner_name=user.name, **row)
    except Exception as exc:
        _remove_images(paths)
        logger.exception("Owner %s could not create an item", user.id)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Listing could not be created") from exc


@router.patch("/owner/items/{item_id}", response_model=ItemResponse)
def update_item(item_id: UUID, payload: ItemUpdate, user: CurrentUser) -> ItemResponse:
    _require_owner(user)
    values = payload.model_dump(exclude_none=True, mode="json")
    if not values:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "No changes supplied")
    for field in ("name", "description", "city", "barangay", "meeting_point", "pickup_instructions"):
        if field in values:
            values[field] = values[field].strip()
    try:
        existing = (
            get_supabase_client()
            .table("items")
            .select("id,image_paths")
            .eq("id", str(item_id))
            .eq("owner_id", user.id)
            .maybe_single()
            .execute()
            .data
        )
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Listing could not be loaded") from exc
    if not existing:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
    old_paths = existing.get("image_paths") or []
    removed_paths: list[str] = []
    if "image_paths" in values:
        paths = _validate_image_paths(values["image_paths"], user.id)
        values["image_paths"] = paths
        values["image_urls"] = _image_urls(paths)
        removed_paths = [path for path in old_paths if path not in paths]
    values["updated_at"] = datetime.now(UTC).isoformat()
    try:
        rows = (
            get_supabase_client()
            .table("items")
            .update(values)
            .eq("id", str(item_id))
            .eq("owner_id", user.id)
            .execute()
            .data
            or []
        )
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Listing could not be updated") from exc
    if not rows:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
    _remove_images(removed_paths)
    return ItemResponse(owner_name=user.name, **rows[0])


@router.delete("/owner/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(item_id: UUID, user: CurrentUser) -> None:
    _require_owner(user)
    try:
        existing = (
            get_supabase_client()
            .table("items")
            .select("id,image_paths")
            .eq("id", str(item_id))
            .eq("owner_id", user.id)
            .maybe_single()
            .execute()
            .data
        )
        if not existing:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
        get_supabase_client().table("items").delete().eq("id", str(item_id)).eq(
            "owner_id", user.id
        ).execute()
        _remove_images(existing.get("image_paths") or [])
    except HTTPException:
        raise
    except APIError as exc:
        if exc.code == "23503":
            raise HTTPException(409, "This listing has rental records. Mark it unavailable instead.") from exc
        raise HTTPException(502, "Listing could not be deleted") from exc
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Listing could not be deleted") from exc


@router.post("/owner/items/images", response_model=ItemImageResponse, status_code=status.HTTP_201_CREATED)
async def upload_item_image(user: CurrentUser, image: UploadFile = File(...)) -> ItemImageResponse:
    _require_owner(user)
    if image.content_type not in _IMAGE_TYPES:
        raise HTTPException(status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, "Use a JPEG, PNG, or WebP image")
    contents = await image.read(_MAX_IMAGE_BYTES + 1)
    if not contents:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Image is empty")
    if len(contents) > _MAX_IMAGE_BYTES:
        raise HTTPException(status.HTTP_413_CONTENT_TOO_LARGE, "Image must be 5 MB or smaller")
    if not _has_valid_signature(image.content_type, contents):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Image contents do not match its file type")
    suffix = _IMAGE_TYPES[image.content_type]
    stem = Path(image.filename or "image").stem[:40]
    path = f"{user.id}/{uuid4()}-{stem}{suffix}"
    try:
        storage = get_supabase_client().storage.from_(_IMAGE_BUCKET)
        storage.upload(
            path,
            contents,
            {"content-type": image.content_type, "upsert": "false"},
        )
        url = storage.get_public_url(path)
        return ItemImageResponse(path=path, url=url)
    except Exception as exc:
        logger.exception("Owner %s could not upload an item image", user.id)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Image could not be uploaded") from exc


@router.post("/owner/items/images/cleanup", status_code=status.HTTP_204_NO_CONTENT)
def cleanup_item_images(payload: ItemImageCleanup, user: CurrentUser) -> None:
    _require_owner(user)
    paths = _validate_image_paths(payload.image_paths, user.id)
    _remove_images(paths, strict=True)
