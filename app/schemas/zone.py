from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class ZoneCreate(BaseModel):
    farm_id: str
    name: str = Field(..., min_length=1, max_length=255)


class ZoneUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)


class ZoneOut(BaseModel):
    id: str
    farm_id: str
    name: str
    created_at: datetime
