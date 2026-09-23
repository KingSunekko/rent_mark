from pydantic import BaseModel, ConfigDict, Field

from backend.schemas.auth import UserProfile
from backend.schemas.item import ItemResponse
from backend.schemas.rental_request import RentalRequestResponse
from backend.schemas.review import ReviewResponse


class AdminMetrics(BaseModel):
    users: int
    listings: int
    requests: int
    active_rentals: int
    completed_rentals: int
    reviews: int
    estimated_rental_value_centavos: int


class AdminDashboard(BaseModel):
    metrics: AdminMetrics
    users: list[UserProfile]
    listings: list[ItemResponse]
    rentals: list[RentalRequestResponse]
    reviews: list[ReviewResponse]


class UserModerationUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    is_suspended: bool
    reason: str = Field(default="", max_length=500)


class ListingModerationUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    moderation_status: str = Field(pattern="^(active|hidden)$")
    reason: str = Field(default="", max_length=500)
