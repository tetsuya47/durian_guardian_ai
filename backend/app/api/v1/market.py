from __future__ import annotations

import logging
from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole
from app.services.market_price_service import MarketPriceService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/market", tags=["Durian Market Prices"])
allow_all = RoleChecker([r.value for r in UserRole])


@router.get("/latest")
async def get_latest_market_prices(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Retrieve the latest real farm-gate durian purchasing prices (giasaurieng.net)."""
    service = MarketPriceService(db)
    data = await service.get_latest_prices()
    if "_id" in data:
        data["_id"] = str(data["_id"])
    return success_response(
        data=data,
        message="Real farm-gate durian market prices retrieved successfully",
    )


@router.post("/crawl")
async def trigger_price_crawl(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Manually trigger fresh crawling of durian purchasing prices from giasaurieng.net."""
    service = MarketPriceService(db)
    data = await service.crawl_and_save_prices()
    if "_id" in data:
        data["_id"] = str(data["_id"])
    return success_response(
        data=data,
        message="Durian purchasing price crawl completed & updated in MongoDB",
    )
