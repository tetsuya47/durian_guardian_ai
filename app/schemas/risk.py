from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class RiskInput(BaseModel):
    tree_id: str
    disease: str
    confidence: float = Field(..., ge=0, le=1)
    humidity: float | None = None
    rainfall: float | None = None
    history_count: int = 0


class RiskAssessmentOut(BaseModel):
    id: str
    tree_id: str
    risk_score: float
    explanation: str | None
    recommendation: str | None
    created_at: datetime


class RiskResult(BaseModel):
    risk_score: float
    explanation: str | None
    recommendation: str | None
