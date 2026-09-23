from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field


class ItemRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ItemCategory(StrEnum):
    electronics = "electronics"
    tools = "tools"
    sports = "sports"
    school = "school"
    camping = "camping"
    events = "events"
    appliances = "appliances"
    other = "other"


class ItemCondition(StrEnum):
    excellent = "Excellent"
    good = "Good"
    fair = "Fair"


class ItemAvailability(StrEnum):
    available = "available"
    available_today = "availableToday"
    unavailable = "unavailable"


class ItemModerationStatus(StrEnum):
    active = "active"
    hidden = "hidden"
    under_review = "underReview"


class ItemCreate(ItemRequest):
    name: str = Field(min_length=2, max_length=120)
    description: str = Field(min_length=10, max_length=2000)
    category: ItemCategory
    condition: ItemCondition
    price_per_day: int = Field(ge=1, le=1_000_000)
    discount_percent: int = Field(default=0, ge=0, le=20, strict=True)
    availability: ItemAvailability = ItemAvailability.available
    image_paths: list[str] = Field(default_factory=list, max_length=5)
    city: str = Field(default="", max_length=120)
    barangay: str = Field(default="", max_length=120)
    meeting_point: str = Field(default="", max_length=200)
    pickup_instructions: str = Field(default="", max_length=1000)


class ItemUpdate(ItemRequest):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    description: str | None = Field(default=None, min_length=10, max_length=2000)
    category: ItemCategory | None = None
    condition: ItemCondition | None = None
    price_per_day: int | None = Field(default=None, ge=1, le=1_000_000)
    discount_percent: int | None = Field(default=None, ge=0, le=20, strict=True)
    availability: ItemAvailability | None = None
    image_paths: list[str] | None = Field(default=None, max_length=5)
    city: str | None = Field(default=None, max_length=120)
    barangay: str | None = Field(default=None, max_length=120)
    meeting_point: str | None = Field(default=None, max_length=200)
    pickup_instructions: str | None = Field(default=None, max_length=1000)


class ItemResponse(BaseModel):
    id: str
    owner_id: str
    owner_name: str
    name: str
    description: str
    category: ItemCategory
    condition: ItemCondition
    price_per_day: int
    discount_percent: int = 0
    availability: ItemAvailability
    community: str
    city: str = ""
    barangay: str = ""
    meeting_point: str = ""
    pickup_instructions: str = ""
    image_urls: list[str] = Field(default_factory=list)
    image_paths: list[str] = Field(default_factory=list)
    moderation_status: ItemModerationStatus
    created_at: datetime
    updated_at: datetime


class ItemImageResponse(BaseModel):
    path: str
    url: str


class ItemImageCleanup(ItemRequest):
    image_paths: list[str] = Field(min_length=1, max_length=5)
