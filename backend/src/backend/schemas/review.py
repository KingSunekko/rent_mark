from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ReviewCreate(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    rental_request_id: UUID
    rating: int = Field(ge=1, le=5)
    comment: str = Field(default="", max_length=300)


class ReviewResponse(BaseModel):
    id: UUID
    rental_request_id: UUID
    item_id: UUID
    renter_id: UUID
    owner_id: UUID
    renter_name: str
    owner_name: str
    item_name: str
    rating: int
    comment: str
    created_at: datetime
