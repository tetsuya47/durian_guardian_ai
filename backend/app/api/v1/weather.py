from __future__ import annotations

import logging
from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole
from app.schemas.response_models import SuccessResponse
from app.schemas.weather import WeatherCurrentResponse
from app.services.weather_service import WeatherService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/weather", tags=["Weather"])
allow_all = RoleChecker([r.value for r in UserRole])

# Backward-compatible fallback coordinates (Buôn Ma Thuột) used when no
# farm_id is supplied and lat/lon are not provided by the client. The
# service resolves farm coordinates itself when farm_id is present.
DEFAULT_LAT = WeatherService.DEFAULT_LAT
DEFAULT_LON = WeatherService.DEFAULT_LON


@router.get("/current", response_model=SuccessResponse[WeatherCurrentResponse])
async def get_current_weather(
    lat: float = Query(default=DEFAULT_LAT, description="Vĩ độ trang trại sầu riêng Buôn Ma Thuột"),
    lon: float = Query(default=DEFAULT_LON, description="Kinh độ trang trại sầu riêng Buôn Ma Thuột"),
    farm_id: str | None = Query(default=None, description="ID trang trại để tự lấy tọa độ GPS"),
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Fetch live weather data from OpenWeatherMap & Agri-Risk recommendation."""
    service = WeatherService(db)
    result = await service.get_current_weather(farm_id=farm_id, lat=lat, lon=lon)
    logger.info(
        "Weather data requested by user %s (farm_id=%s) coords=(%s, %s)",
        user_id, farm_id, lat, lon,
    )
    return success_response(
        data=WeatherCurrentResponse(**result),
        message="Current weather retrieved successfully",
    )
