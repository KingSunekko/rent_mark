from datetime import date, datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from backend.schemas.item import ItemResponse


class RentalRequestCreate(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    client_request_id: UUID
    item_id: UUID
    start_date: date
    end_date: date
    message: str = Field(default="", max_length=2000)
    pickup_method: Literal["Community meetup", "Pickup from owner", "Local delivery"] = "Community meetup"

    @model_validator(mode="after")
    def validate_dates(self):
        if not 1 <= (self.end_date - self.start_date).days + 1 <= 365:
            raise ValueError("Choose an inclusive rental duration between 1 and 365 days")
        # The transaction checks today's date in Asia/Manila after idempotent
        # replay, allowing safe retries of a previously accepted request.
        return self


class RentalRequestResponse(BaseModel):
    id: UUID
    client_request_id: UUID
    item_id: UUID
    renter_id: UUID
    owner_id: UUID
    renter_name: str
    item_snapshot: ItemResponse
    start_date: date
    end_date: date
    duration_days: int
    daily_price_centavos: int
    total_centavos: int
    message: str
    pickup_method: str
    status: Literal["pending", "approved", "rejected", "active", "return_requested", "completed"]
    requested_at: datetime
    rejection_reason: str = ""
    approved_at: datetime | None = None
    rejected_at: datetime | None = None
    started_at: datetime | None = None
    return_requested_at: datetime | None = None
    completed_at: datetime | None = None


class RentalRequestTransition(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    status: Literal["approved", "rejected", "active", "return_requested", "completed"]
    rejection_reason: str = Field(default="", max_length=500)

    @model_validator(mode="after")
    def validate_reason(self):
        if self.status != "rejected" and self.rejection_reason:
            raise ValueError("A rejection reason is only valid when rejecting a request")
        return self
