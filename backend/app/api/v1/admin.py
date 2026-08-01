from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole
from app.schemas.farmer_overview import FarmerOverviewDTO
from app.schemas.response_models import SuccessResponse
from app.services.farmer_overview_service import FarmerOverviewService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["Admin"])

admin_only = RoleChecker([UserRole.enterprise_admin.value])


@router.get("/users/{user_id}/overview", response_model=SuccessResponse[FarmerOverviewDTO])
async def get_farmer_overview(
    user_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(admin_only),
):
    service = FarmerOverviewService(db)
    result = await service.get_overview(user_id)
    logger.info("Farmer overview fetched for user %s by admin %s", user_id, current_user_id)
    return success_response(data=result.model_dump())
