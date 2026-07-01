from __future__ import annotations

from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.weather.service import WeatherService

router = APIRouter(prefix="/weather", tags=["Weather"])


@router.get("/{farm_id}")
async def get_weather(
    farm_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    service = WeatherService(db)
    result = await service.get_weather(farm_id)
    return success_response(data=result.model_dump())
