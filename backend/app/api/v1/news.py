from __future__ import annotations

import logging
from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/news", tags=["News & Videos"])
allow_all = RoleChecker([r.value for r in UserRole])


@router.get("")
async def get_news_articles(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Retrieve agriculture news articles from MongoDB."""
    articles = await db["news"].find().sort("created_at", -1).to_list(length=20)
    for doc in articles:
        doc["_id"] = str(doc["_id"])
    return success_response(
        data=articles,
        message="News articles retrieved successfully",
    )


@router.get("/videos")
async def get_videos(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Retrieve agriculture video items from MongoDB."""
    videos = await db["videos"].find().sort("created_at", -1).to_list(length=20)
    for doc in videos:
        doc["_id"] = str(doc["_id"])
    return success_response(
        data=videos,
        message="Videos retrieved successfully",
    )
