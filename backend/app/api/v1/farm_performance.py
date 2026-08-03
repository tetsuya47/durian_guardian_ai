from __future__ import annotations

import logging
from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId

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
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    """Retrieve farm performance yield metrics. Non-admin users get only their own farms."""
    user_oid = ObjectId(user_id) if ObjectId.is_valid(user_id) else user_id
    user_doc = await db["users"].find_one({"_id": user_oid})
    user_role = (user_doc.get("role") or "").lower() if user_doc else "user"
    is_admin = user_role in ["admin", "system admin"]

    if is_admin:
        # Admin gets all farm performance records or all system farms
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

        if not items:
            farms = await db["farms"].find({}).to_list(length=100)
            for idx, f in enumerate(farms):
                farm_oid = f["_id"]
                tree_count = await db["trees"].count_documents({"farm_id": farm_oid}) or int(f.get("tree_count") or 0)
                targets = await db["farm_targets"].find({"farm_id": farm_oid}).to_list(10)
                target_yield_kg = sum(float(t.get("target_yield", 0)) for t in targets)
                yield_tons = round((target_yield_kg or (tree_count * 80)) / 1000.0, 1)
                area = float(f.get("area_hectare") or f.get("area") or 1.0)
                yield_per_ha = round(yield_tons / area, 1) if area > 0 else 0.0
                location = f.get("location") or f.get("province") or ""
                prov = f.get("province") or (location.split(",")[-1].strip() if "," in location else location) or "Cần Thơ"

                items.append({
                    "_id": str(farm_oid),
                    "farm_id": str(farm_oid),
                    "farm_code": f.get("farm_code") or f"FARM{idx + 1:03d}",
                    "farm_name": f.get("farm_name") or f"Farm {f.get('farm_code', idx + 1)}",
                    "owner_name": f.get("owner_name") or "Chủ nông trại",
                    "province": prov,
                    "area_hectare": area,
                    "tree_count": tree_count,
                    "yield_tons": yield_tons,
                    "yield_per_ha": yield_per_ha,
                    "growth_pct": 12.5,
                    "revenue_vnd": int(yield_tons * 75000000),
                    "tier": "Rất cao" if yield_per_ha >= 25.0 else ("Cao" if yield_per_ha >= 20.0 else "Trung bình"),
                })
    else:
        # Non-Admin User (Farmer): Fetch ONLY farms belonging to this user
        user_farms = await db["farms"].find({
            "$or": [
                {"owner_user_id": user_oid},
                {"owner_user_id": str(user_id)},
                {"user_id": user_id},
                {"user_id": str(user_id)},
                {"owner_id": user_id},
                {"owner_id": user_oid},
                {"created_by": user_id},
                {"created_by": str(user_id)},
            ]
        }).to_list(length=100)

        items = []
        for idx, f in enumerate(user_farms):
            farm_oid = f["_id"]
            tree_count = await db["trees"].count_documents({"farm_id": farm_oid}) or int(f.get("tree_count") or 0)
            targets = await db["farm_targets"].find({"farm_id": farm_oid}).to_list(10)
            target_yield_kg = sum(float(t.get("target_yield", 0)) for t in targets)
            yield_tons = round((target_yield_kg or (tree_count * 80)) / 1000.0, 1)
            area = float(f.get("area_hectare") or f.get("area") or 1.0)
            yield_per_ha = round(yield_tons / area, 1) if area > 0 else 0.0
            owner_n = user_doc.get("full_name") or user_doc.get("name") if user_doc else "Chủ nông trại"
            location = f.get("location") or f.get("province") or ""
            prov = f.get("province") or (location.split(",")[-1].strip() if "," in location else location) or "Cần Thơ"

            items.append({
                "_id": str(farm_oid),
                "farm_id": str(farm_oid),
                "farm_code": f.get("farm_code") or f"FARM{idx + 1:03d}",
                "farm_name": f.get("farm_name") or f"Farm {f.get('farm_code', idx + 1)}",
                "owner_name": owner_n,
                "province": prov,
                "area_hectare": area,
                "tree_count": tree_count,
                "yield_tons": yield_tons,
                "yield_per_ha": yield_per_ha,
                "growth_pct": 12.5,
                "revenue_vnd": int(yield_tons * 75000000),
                "tier": "Rất cao" if yield_per_ha >= 25.0 else ("Cao" if yield_per_ha >= 20.0 else "Trung bình"),
            })

    # Apply search filters if provided
    if keyword and items:
        kw = keyword.lower()
        items = [it for it in items if kw in it["farm_name"].lower() or kw in it["owner_name"].lower() or kw in it["farm_code"].lower()]
    if province and province != "all" and items:
        items = [it for it in items if it["province"] == province]

    return success_response(
        data={"items": items, "total": len(items)},
        message="Farm performance metrics retrieved successfully",
    )
