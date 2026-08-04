from __future__ import annotations

import logging
from typing import Any
from fastapi import APIRouter, Depends, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.core.response import success_response
from app.schemas.iot_telemetry import IoTTelemetryCreate
from app.services.iot_service import IoTService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/iot", tags=["IoT Telemetry & Smart Farming"])


@router.post(
    "/telemetry",
    status_code=status.HTTP_201_CREATED,
    summary="Ingest 30-second simulated IoT telemetry & persist to MongoDB",
)
async def ingest_telemetry(
    payload: IoTTelemetryCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Save 30-second real-time sensor reading into MongoDB `iot_telemetry` collection."""
    service = IoTService(db)
    saved_doc = await service.ingest_telemetry(payload.model_dump())
    return success_response(
        data=saved_doc,
        message="IoT telemetry saved to persistent MongoDB collection successfully",
    )


@router.get(
    "/telemetry/latest",
    summary="Get latest IoT telemetry + Model 3 Risk Assessment + Model 4 AI Agronomist Advice",
)
async def get_latest_telemetry_analysis(
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Get the most recent IoT sensor reading and AI recommendations."""
    service = IoTService(db)
    analysis = await service.get_latest_analysis()
    return success_response(
        data=analysis,
        message="Latest IoT sensor readings and AI recommendations retrieved successfully",
    )


@router.get(
    "/telemetry/history",
    summary="Get historical IoT telemetry readings from MongoDB",
)
async def get_telemetry_history(
    limit: int = 50,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Retrieve up to 50 recent 30-second telemetry readings."""
    service = IoTService(db)
    history = await service.get_history(limit)
    return success_response(
        data=history,
        message=f"Retrieved {len(history)} recent IoT telemetry records",
    )
