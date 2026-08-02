from __future__ import annotations

import logging
from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/farm-performance", tags=["Farm Performance"])
allow_all = RoleChecker([r.value for r in UserRole])


@router.get("")
async def list_farm_performances(
    keyword: str | None = Query(None),
    province: str | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Retrieve all farm performance yield metrics from MongoDB collection `farm_performance`."""
    query: dict = {}
    if keyword:
        import re
        query["$or"] = [
            {"farm_name": {"$regex": re.escape(keyword), "$options": "i"}},
            {"owner_name": {"$regex": re.escape(keyword), "$options": "i"}},
            {"farm_code": {"$regex": re.escape(keyword), "$options": "i"}},
        ]
    if province and province != "all":
        query["province"] = province

    docs = await db["farm_performance"].find(query).sort("yield_per_ha", -1).to_list(length=100)

    items = []
    for d in docs:
        d["_id"] = str(d["_id"])
        if "farm_id" in d and d["farm_id"]:
            d["farm_id"] = str(d["farm_id"])
        if "season_id" in d and d["season_id"]:
            d["season_id"] = str(d["season_id"])
        items.append(d)

    return success_response(
        data={"items": items, "total": len(items)},
        message="Farm performance metrics retrieved successfully",
    )
