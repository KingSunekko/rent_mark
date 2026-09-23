from fastapi import APIRouter

from backend.api.routes.health import router as health_router
from backend.api.routes.auth import router as auth_router
from backend.api.routes.items import router as items_router
from backend.api.routes.rental_requests import router as rental_requests_router
from backend.api.routes.reviews import router as reviews_router
from backend.api.routes.notifications import router as notifications_router
from backend.api.routes.admin import router as admin_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(items_router)
api_router.include_router(rental_requests_router)
api_router.include_router(reviews_router)
api_router.include_router(notifications_router)
api_router.include_router(admin_router)
