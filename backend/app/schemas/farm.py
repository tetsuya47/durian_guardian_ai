from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class FarmCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    address: str | None = Field(None, max_length=500)
    gps_lat: float | None = Field(None, ge=-90, le=90)
    gps_lng: float | None = Field(None, ge=-180, le=180)
    area: float | None = Field(None, ge=0)
    farm_code: str = Field(..., min_length=1)
    company_id: str | None = Field(None)
    district: str = Field(..., min_length=1)
    tree_count: int = Field(default=0, ge=0)
    durian_varieties: list[str] = Field(default_factory=list)
    onboarding_status: str = Field(default="PENDING_IOT")


class FarmUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    address: str | None = Field(None, max_length=500)
    gps_lat: float | None = Field(None, ge=-90, le=90)
    gps_lng: float | None = Field(None, ge=-180, le=180)
    area: float | None = Field(None, ge=0)
    farm_code: str | None = Field(None, min_length=1)
    company_id: str | None = Field(None)
    district: str | None = Field(None)
    tree_count: int | None = Field(None, ge=0)
    durian_varieties: list[str] | None = Field(None)
    onboarding_status: str | None = Field(None)


class FarmRegisterWithIoTRequest(BaseModel):
    farm_name: str = Field(..., min_length=1, max_length=255)
    area_hectare: float = Field(..., ge=0.1)
    district: str = Field(..., min_length=1)
    gps_lat: float = Field(..., ge=-90, le=90)
    gps_lng: float = Field(..., ge=-180, le=180)
    tree_count: int = Field(..., ge=1)
    durian_varieties: list[str] = Field(default_factory=lambda: ["Ri6"])
    iot_items: list[dict] = Field(default_factory=list)


class FarmOut(BaseModel):
    id: str
    name: str
    address: str | None
    gps_lat: float | None
    gps_lng: float | None
    area: float | None
    district: str | None = None
    tree_count: int | None = 0
    durian_varieties: list[str] = Field(default_factory=list)
    onboarding_status: str = "PENDING_IOT"
    iot_summary: dict | None = None
    created_at: datetime
