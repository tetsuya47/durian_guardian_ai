from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any
from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole
from app.repositories.farm_activity_repository import FarmActivityRepository
from app.schemas.response_models import SuccessResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/farm-activities", tags=["Farm Activities"])
allow_all = RoleChecker([r.value for r in UserRole])


@router.get("", response_model=SuccessResponse[list[dict[str, Any]]])
async def list_farm_activities(
    tree_id: str | None = Query(None),
    farm_id: str | None = Query(None),
    activity_type: str | None = Query(None),
    category: str | None = Query(None),
    year: int | None = Query(None),
    month: int | None = Query(None),
    season: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """List farm activities with optional farm_id, year, month, season filters."""
    repo = FarmActivityRepository(db)
    filter_query: dict[str, Any] = {}
    if tree_id:
        filter_query["$or"] = [{"tree_ids": tree_id}, {"tree_ids": []}, {"tree_ids": None}]
    if farm_id and farm_id != "all":
        filter_query["farm_id"] = farm_id
    if activity_type:
        filter_query["activity_type"] = {"$regex": f"^{activity_type}$", "$options": "i"}
    if category and category != "all":
        filter_query["category"] = category
    if year:
        filter_query["year"] = year
    if month:
        filter_query["month"] = month
    if season and season != "all":
        filter_query["$or"] = [{"season": season}, {"crop_season": season}]

    docs, total = await repo.list(
        filter_query=filter_query,
        page=page,
        per_page=per_page,
        sort=[("activity_date", -1)],
    )
    return success_response(data=docs, message=f"Retrieved {len(docs)} activities (total {total})")


@router.post("", response_model=SuccessResponse[dict[str, Any]])
async def create_farm_activity(
    activity_data: dict[str, Any],
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Log a new farm activity (Tưới, Bón phân, Phun thuốc, Cắt cành, Thu hoạch, etc.)."""
    repo = FarmActivityRepository(db)
    now = datetime.now(timezone.utc)
    activity_data["created_at"] = now
    activity_data["updated_at"] = now
    if "activity_date" not in activity_data or not activity_data["activity_date"]:
        activity_data["activity_date"] = now

    activity_id = await repo.create(activity_data)
    activity_data["id"] = activity_id
    logger.info("Farm Activity created by user %s: %s", user_id, activity_data.get("activity_type"))
    return success_response(data=activity_data, message="Farm activity logged successfully")


@router.get("/today-summary", response_model=SuccessResponse[dict[str, Any]])
async def get_today_summary(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Returns today's completed task summary for Dashboard (e.g. 4/8 tasks completed)."""
    now = datetime.now(timezone.utc)
    start_of_day = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)

    repo = FarmActivityRepository(db)
    today_docs, _ = await repo.list(
        filter_query={"activity_date": {"$gte": start_of_day}},
        per_page=100,
    )

    types_completed = {doc.get("activity_type", "Khác") for doc in today_docs}
    completed_count = len(types_completed)
    total_target_tasks = max(8, completed_count + 3)

    return success_response(
        data={
            "completed_count": completed_count,
            "total_target": total_target_tasks,
            "summary_text": f"Hôm nay: {completed_count}/{total_target_tasks} công việc",
            "completed_types": sorted(list(types_completed)),
            "tasks": [
                {"name": "Tưới nước", "done": "Irrigation" in types_completed or "Tưới" in types_completed},
                {"name": "Bón phân", "done": "Fertilizer" in types_completed or "Bón phân" in types_completed},
                {"name": "Phun thuốc", "done": "Pesticide" in types_completed or "Phun thuốc" in types_completed},
                {"name": "AI Scan", "done": "Inspection" in types_completed or "Kiểm tra bệnh" in types_completed},
            ],
        },
        message="Today summary retrieved",
    )


@router.get("/tree-timeline/{tree_id}", response_model=SuccessResponse[list[dict[str, Any]]])
async def get_tree_timeline(
    tree_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Retrieve combined timeline (Scan, Bón, Phun, Thu hoạch, IoT) for a single tree."""
    repo = FarmActivityRepository(db)
    activities = await repo.get_recent_activities_for_tree(tree_id, limit=30)
    return success_response(data=activities, message=f"Retrieved timeline for tree {tree_id}")


@router.get("/logs", response_model=SuccessResponse[list[dict[str, Any]]])
async def list_farm_logs(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Retrieve farm logs for approval."""
    cursor = db["farm_logs"].find({}).sort("created_at", -1)
    docs = await cursor.to_list(100)
    for d in docs:
        d["_id"] = str(d["_id"])
        d["id"] = d["_id"]
    return success_response(data=docs, message=f"Retrieved {len(docs)} farm logs")


@router.put("/logs/{log_id}", response_model=SuccessResponse[dict[str, Any]])
async def update_farm_log(
    log_id: str,
    update_data: dict[str, Any],
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Update status of a farm log (e.g. 'Đã phê duyệt' or 'Yêu cầu làm lại')."""
    from bson import ObjectId
    oid = ObjectId(log_id) if ObjectId.is_valid(log_id) else log_id
    await db["farm_logs"].update_one({"_id": oid}, {"$set": update_data})
    doc = await db["farm_logs"].find_one({"_id": oid})
    if doc:
        doc["_id"] = str(doc["_id"])
        doc["id"] = doc["_id"]
    return success_response(data=doc or {}, message="Farm log updated successfully")

