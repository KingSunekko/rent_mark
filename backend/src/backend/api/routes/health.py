from typing import Literal

from fastapi import APIRouter

from backend.core.config import get_settings
from backend.schemas.health import HealthResponse

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("", response_model=HealthResponse)
def health_check() -> HealthResponse:
    """Report process health and Supabase configuration state."""
    settings = get_settings()
    database: Literal["configured", "not_configured"] = (
        "configured" if settings.supabase_configured else "not_configured"
    )
    return HealthResponse(
        status="ok",
        service=settings.app_name,
        version=settings.app_version,
        environment=settings.environment,
        database=database,
    )
