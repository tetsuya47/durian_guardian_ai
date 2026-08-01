from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field


class AddressDTO(BaseModel):
    province: str | None = None
    district: str | None = None
    ward: str | None = None
    detail: str | None = None


class FarmerProfileDTO(BaseModel):
    user_id: str
    user_code: str
    full_name: str
    email: str | None = None
    phone: str | None = None
    role: str
    status: str | None = None
    address: AddressDTO | None = None
    avatar: str | None = None
    farm_name: str | None = None
    company_name: str | None = None
    created_at: datetime | None = None


class FarmOverviewDTO(BaseModel):
    total_farms: int = 0
    total_zones: int = 0
    total_trees: int = 0
    total_area_hectare: float = 0
    districts: list[str] = Field(default_factory=list)


class InspectionStatsDTO(BaseModel):
    total_inspections: int = 0
    last_inspection: datetime | None = None


class DetectionStatsDTO(BaseModel):
    healthy: int = 0
    diseased: int = 0
    detection_rate: float = 0


class InspectionOverviewDTO(BaseModel):
    inspection: InspectionStatsDTO
    detection: DetectionStatsDTO


class AlertOverviewDTO(BaseModel):
    total_alerts: int = 0
    critical: int = 0
    warning: int = 0
    normal: int = 0
    raw_priority: dict[str, int] = Field(default_factory=dict)


class NeighborOverviewDTO(BaseModel):
    sent_requests: int = 0
    received_requests: int = 0
    pending: int = 0
    waiting_source_consent: int = 0
    waiting_target_consent: int = 0
    contact_shared: int = 0
    rejected: int = 0
    cancelled: int = 0


class ActivityDTO(BaseModel):
    type: str
    source: str
    timestamp: datetime
    entity_id: str | None = None
    entity_code: str | None = None
    detail: str


class FarmerOverviewDTO(BaseModel):
    profile: FarmerProfileDTO
    farm: FarmOverviewDTO
    inspection: InspectionOverviewDTO
    alerts: AlertOverviewDTO
    neighbor: NeighborOverviewDTO
    activities: list[ActivityDTO] = Field(default_factory=list)
