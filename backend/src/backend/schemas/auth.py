from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, EmailStr, Field


class PublicRole(StrEnum):
    renter = "renter"
    owner = "owner"


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(min_length=2, max_length=100)
    community: str = Field(min_length=2, max_length=120)
    role: PublicRole


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=1, max_length=4096)


class UpdateProfileRequest(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    community: str | None = Field(default=None, min_length=2, max_length=120)
    phone: str | None = Field(default=None, max_length=30)
    bio: str | None = Field(default=None, max_length=500)
    avatar_url: str | None = Field(default=None, max_length=2048)


class UserProfile(BaseModel):
    id: str
    email: EmailStr
    name: str
    community: str
    role: str
    avatar_url: str | None = None
    phone: str = ""
    bio: str = ""
    is_suspended: bool = False
    created_at: datetime | None = None


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int
    token_type: str = "bearer"
    user: UserProfile
