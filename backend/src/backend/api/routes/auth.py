import logging

from fastapi import APIRouter, HTTPException, status
from supabase import create_client

from backend.api.dependencies import CurrentUser
from backend.core.config import get_settings
from backend.core.supabase import get_supabase_client
from backend.schemas.auth import (
    AuthResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    UpdateProfileRequest,
    UserProfile,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])
logger = logging.getLogger(__name__)


def _auth_response(auth_response: object, profile: dict) -> AuthResponse:
    session = getattr(auth_response, "session", None)
    user = getattr(auth_response, "user", None)
    if session is None or user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Email confirmation is required")
    values = dict(profile)
    values.setdefault("email", user.email)
    return AuthResponse(
        access_token=session.access_token,
        refresh_token=session.refresh_token,
        expires_in=session.expires_in,
        user=UserProfile(**values),
    )


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest) -> AuthResponse:
    client = get_supabase_client()
    created_id: str | None = None
    try:
        created = client.auth.admin.create_user(
            {
                "email": str(payload.email),
                "password": payload.password,
                "email_confirm": True,
            }
        )
        created_id = str(created.user.id)
        profile = {
            "id": created_id,
            "name": payload.name.strip(),
            "community": payload.community.strip(),
            "role": payload.role.value,
            "email": str(payload.email),
        }
        client.table("profiles").insert(profile).execute()
        auth_client = create_client(
            get_settings().supabase_url,
            get_settings().supabase_service_role_key.get_secret_value(),
        )
        signed_in = auth_client.auth.sign_in_with_password(
            {"email": str(payload.email), "password": payload.password}
        )
        return _auth_response(signed_in, profile)
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("Registration failed for %s", payload.email)
        if created_id:
            try:
                client.auth.admin.delete_user(created_id)
            except Exception:
                pass
        message = str(exc).lower()
        duplicate = any(
            marker in message
            for marker in ("already", "registered", "email_exists", "email exists")
        )
        code = status.HTTP_409_CONFLICT if duplicate else status.HTTP_502_BAD_GATEWAY
        detail = (
            "An account with this email already exists."
            if duplicate
            else "Account could not be created"
        )
        raise HTTPException(code, detail) from exc


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest) -> AuthResponse:
    settings = get_settings()
    try:
        client = create_client(
            settings.supabase_url,
            settings.supabase_service_role_key.get_secret_value(),
        )
        auth = client.auth.sign_in_with_password(
            {"email": str(payload.email), "password": payload.password}
        )
        profile = (
            get_supabase_client().table("profiles").select("*").eq("id", str(auth.user.id)).single().execute().data
        )
        if profile.get("is_suspended"):
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Account is suspended")
        return _auth_response(auth, profile)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password") from exc


@router.post("/refresh", response_model=AuthResponse)
def refresh(payload: RefreshRequest) -> AuthResponse:
    settings = get_settings()

    try:
        client = create_client(
            settings.supabase_url,
            settings.supabase_service_role_key.get_secret_value(),
        )
        auth = client.auth.refresh_session(payload.refresh_token)

        profile = (
            get_supabase_client()
            .table("profiles")
            .select("*")
            .eq("id", str(auth.user.id))
            .single()
            .execute()
            .data
        )

        if not profile:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                "User profile is unavailable",
            )

        if profile.get("is_suspended"):
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                "Account is suspended",
            )

        return _auth_response(auth, profile)

    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Invalid refresh token",
        ) from exc

@router.get("/me", response_model=UserProfile)
def me(user: CurrentUser) -> UserProfile:
    return user


@router.patch("/me", response_model=UserProfile)
def update_me(payload: UpdateProfileRequest, user: CurrentUser) -> UserProfile:
    updates = payload.model_dump(exclude_none=True)
    if not updates:
        return user
    updates = {
        key: value.strip() if isinstance(value, str) else value
        for key, value in updates.items()
    }
    try:
        row = (
            get_supabase_client()
            .table("profiles")
            .update(updates)
            .eq("id", user.id)
            .execute()
            .data[0]
        )
        return UserProfile(**row)
    except Exception as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY, "Profile could not be updated"
        ) from exc
