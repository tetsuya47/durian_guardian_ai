from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class DetectionResult(BaseModel):
    disease: str
    confidence: float = Field(..., ge=0, le=1)
    severity: str


class DetectionResponse(BaseModel):
    tree_id: str
    image_url: str
    detection: DetectionResult
    created_at: datetime


class DiseaseHistoryOut(BaseModel):
    id: str
    tree_id: str
    disease_name: str
    severity: str
    confidence: float
    image_url: str | None
    created_at: datetime
