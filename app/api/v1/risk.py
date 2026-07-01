from __future__ import annotations

from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.schemas import RiskInput
from app.services import RiskService

router = APIRouter(prefix="/risk", tags=["Risk Assessment"])


@router.post("/calculate")
async def calculate_risk(
    data: RiskInput,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    service = RiskService(db)
    result = await service.calculate(data.tree_id, data)
    return success_response(
        data=result.model_dump(),
        message="Risk calculated",
    )
