from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, StrictBool, model_validator


class NotificationResponse(BaseModel):
    id: UUID
    user_id: UUID
    kind: Literal["request", "status", "return_update", "review", "system"]
    title: str
    message: str
    related_request_id: UUID | None = None
    related_review_id: UUID | None = None
    is_read: bool
    is_deleted: bool
    created_at: datetime


class NotificationUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    is_read: StrictBool | None = None
    is_deleted: StrictBool | None = None

    @model_validator(mode="after")
    def require_change(self):
        if self.is_read is None and self.is_deleted is None:
            raise ValueError("Provide a notification change")
        return self


class NotificationBulkRead(BaseModel):
    model_config = ConfigDict(extra="forbid")
    notification_ids: list[UUID] = Field(min_length=1, max_length=100)
    is_read: StrictBool
