from functools import lru_cache

from supabase import Client, create_client

from backend.core.config import get_settings


class SupabaseNotConfiguredError(RuntimeError):
    """Raised when database access is requested before configuration."""


@lru_cache
def get_supabase_client() -> Client:
    """Create one lazy, server-side Supabase client."""
    settings = get_settings()
    if not settings.supabase_configured:
        raise SupabaseNotConfiguredError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required"
        )
    assert settings.supabase_url is not None
    assert settings.supabase_service_role_key is not None
    return create_client(
        settings.supabase_url,
        settings.supabase_service_role_key.get_secret_value(),
    )
