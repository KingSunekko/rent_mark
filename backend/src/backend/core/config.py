from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Server configuration loaded from environment variables or `.env`."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_name: str = "RentMark API"
    app_version: str = "0.1.0"
    environment: Literal["development", "test", "staging", "production"] = (
        "development"
    )
    api_v1_prefix: str = "/api/v1"
    docs_enabled: bool = True
    cors_allowed_origins: str = "http://localhost,http://127.0.0.1"
    supabase_url: str | None = None
    supabase_service_role_key: SecretStr | None = Field(default=None, repr=False)

    @field_validator("api_v1_prefix")
    @classmethod
    def validate_prefix(cls, value: str) -> str:
        normalized = value.rstrip("/")
        if not normalized.startswith("/"):
            raise ValueError("API_V1_PREFIX must start with '/'")
        return normalized

    @property
    def cors_origins(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.cors_allowed_origins.split(",")
            if origin.strip()
        ]

    @property
    def supabase_configured(self) -> bool:
        return bool(self.supabase_url and self.supabase_service_role_key)


@lru_cache
def get_settings() -> Settings:
    return Settings()
