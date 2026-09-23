import pytest
from pydantic import ValidationError

from backend.core import supabase as supabase_module
from backend.core.config import Settings
from backend.core.supabase import SupabaseNotConfiguredError


def test_cors_origins_are_parsed() -> None:
    settings = Settings(cors_allowed_origins="http://one.test, http://two.test")
    assert settings.cors_origins == ["http://one.test", "http://two.test"]


def test_api_prefix_requires_leading_slash() -> None:
    with pytest.raises(ValidationError):
        Settings(api_v1_prefix="api/v1")


def test_supabase_client_fails_clearly_without_credentials(monkeypatch) -> None:
    unconfigured = Settings.model_construct(
        supabase_url=None,
        supabase_service_role_key=None,
    )
    monkeypatch.setattr(supabase_module, "get_settings", lambda: unconfigured)
    supabase_module.get_supabase_client.cache_clear()
    with pytest.raises(SupabaseNotConfiguredError):
        supabase_module.get_supabase_client()
