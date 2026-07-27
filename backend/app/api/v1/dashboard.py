from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.dashboard.service import DashboardService
from app.database.mongodb import get_database
from app.models import UserRole
from app.schemas.dashboard import DashboardOut, FarmDashboardOut, WidgetsOut
from app.schemas.response_models import SuccessResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

allow_all = RoleChecker([r.value for r in UserRole])


@router.get("", response_model=SuccessResponse[DashboardOut])
async def get_dashboard(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    service = DashboardService(db)
    result = await service.get_dashboard(user_id)
    logger.info("Dashboard fetched for user %s", user_id)
    return success_response(data=result.model_dump())


@router.get("/heatmap", response_model=SuccessResponse[dict])
async def get_heatmap(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = DashboardService(db)
    result = await service.get_heatmap()
    logger.info("Heatmap fetched for user %s", user_id)
    return success_response(data=result)


@router.get("/widgets", response_model=SuccessResponse[WidgetsOut])
async def get_widgets(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = DashboardService(db)
    result = await service.get_widgets()
    logger.info("Dashboard widgets fetched for user %s", user_id)
    return success_response(data=result.model_dump())


@router.get("/farm/{farm_id}", response_model=SuccessResponse[FarmDashboardOut])
async def get_farm_dashboard(
    farm_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = DashboardService(db)
    result = await service.get_farm_dashboard(farm_id)
    logger.info("Farm dashboard fetched for farm %s by user %s", farm_id, user_id)
    return success_response(data=result.model_dump())
