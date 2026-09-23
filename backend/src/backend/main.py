import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.api.router import api_router
from backend.api.routes.health import health_check
from backend.core.config import get_settings

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    logger.info(
        "Starting %s in %s mode (Supabase configured: %s)",
        settings.app_name,
        settings.environment,
        settings.supabase_configured,
    )
    yield


def create_app() -> FastAPI:
    """Create the API without making external connections."""
    settings = get_settings()
    application = FastAPI(
        title=settings.app_name,
        description="Backend API for the RentMark community rental application",
        version=settings.app_version,
        docs_url="/docs" if settings.docs_enabled else None,
        redoc_url="/redoc" if settings.docs_enabled else None,
        openapi_url="/openapi.json" if settings.docs_enabled else None,
        lifespan=lifespan,
    )
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    application.include_router(api_router, prefix=settings.api_v1_prefix)
    application.add_api_route("/", health_check, methods=["GET"], tags=["Health"])
    application.add_api_route(
        "/health", health_check, methods=["GET"], tags=["Health"]
    )
    return application


app = create_app()


def main() -> None:
    """Run the RentMark API development server."""
    uvicorn.run("backend.main:app", host="127.0.0.1", port=8000, reload=True)
