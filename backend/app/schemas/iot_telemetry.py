from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional
from pydantic import BaseModel, Field


class IoTTelemetryCreate(BaseModel):
    soil_moisture: float = Field(..., description="Soil moisture percentage (50-90%)", example=68.5)
    soil_ph: float = Field(..., description="Soil pH value (5.0-7.5)", example=6.2)
    temperature: float = Field(..., description="Ambient temperature (°C)", example=28.5)
    humidity: float = Field(..., description="Ambient humidity percentage (50-100%)", example=78.0)
    light_intensity: float = Field(..., description="Light intensity in Lux", example=45000.0)
    rainfall: float = Field(default=0.0, description="Rainfall in mm", example=2.5)
    nitrogen_ppm: float = Field(default=120.0, description="Soil Nitrogen level (ppm)", example=125.0)
    phosphorus_ppm: float = Field(default=45.0, description="Soil Phosphorus level (ppm)", example=48.0)
    potassium_ppm: float = Field(default=180.0, description="Soil Potassium level (ppm)", example=185.0)
    device_id: str = Field(default="SENS-DURIAN-01", description="IoT sensor station ID")
    farm_id: Optional[str] = Field(default=None, description="Associated Farm ID")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class IoTTelemetryResponse(BaseModel):
    id: str
    soil_moisture: float
    soil_ph: float
    temperature: float
    humidity: float
    light_intensity: float
    rainfall: float
    nitrogen_ppm: float
    phosphorus_ppm: float
    potassium_ppm: float
    device_id: str
    farm_id: Optional[str] = None
    timestamp: datetime


class IoTAIAnalysisResponse(BaseModel):
    telemetry: IoTTelemetryResponse
    model3_risk_level: str
    model3_risk_score: float
    model3_probabilities: dict[str, float]
    model4_ai_advice: str
    model4_recommendations: list[str]
