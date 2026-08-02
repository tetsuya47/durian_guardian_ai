from __future__ import annotations

from datetime import datetime, timezone
from bson import ObjectId
from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole
from app.schemas import FarmCreate, FarmOut, FarmUpdate, FarmRegisterWithIoTRequest
from app.schemas.response_models import MessageResponse, PaginatedResponse, SuccessResponse
from app.services import FarmService
from app.repositories.iot_order_repository import IoTOrderRepository

router = APIRouter(prefix="/farms", tags=["Farms"])

allow_all = RoleChecker([r.value for r in UserRole])


@router.get("", response_model=PaginatedResponse[FarmOut])
async def list_farms(
    keyword: str | None = Query(None),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = FarmService(db)
    items, total = await service.list_farms(user_id, page, per_page, keyword=keyword)
    return success_response(
        data={"items": items, "total": total, "page": page, "per_page": per_page}
    )


@router.get("/{farm_id}", response_model=SuccessResponse[FarmOut])
async def get_farm(
    farm_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = FarmService(db)
    farm = await service.get_farm(farm_id)
    return success_response(data=farm)


@router.post("", response_model=SuccessResponse[FarmOut])
async def create_farm(
    data: FarmCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = FarmService(db)
    farm = await service.create_farm(user_id, data)
    return success_response(data=farm, message="Farm created", status_code=201)


@router.post("/register-with-iot", response_model=SuccessResponse[dict])
async def register_farm_with_iot(
    data: FarmRegisterWithIoTRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    now = datetime.now(timezone.utc)
    user_doc = await db["users"].find_one({"_id": ObjectId(user_id)}) if ObjectId.is_valid(user_id) else None
    user_name = user_doc.get("full_name") or user_doc.get("fullname") or "Chủ vườn" if user_doc else "Chủ vườn"

    farm_count = await db["farms"].count_documents({})
    farm_code = f"FARM{farm_count + 1:03d}"

    company_doc = await db["companies"].find_one({})
    company_id = str(company_doc["_id"]) if company_doc else str(ObjectId())

    farm_doc = {
        "user_id": user_id,
        "company_id": company_id,
        "farm_code": farm_code,
        "farm_name": data.farm_name,
        "district": data.district,
        "gps_lat": data.gps_lat,
        "gps_lng": data.gps_lng,
        "area_hectare": data.area_hectare,
        "tree_count": data.tree_count,
        "durian_varieties": data.durian_varieties,
        "onboarding_status": "PENDING_IOT",
        "created_at": now,
        "updated_at": now,
    }
    insert_res = await db["farms"].insert_one(farm_doc)
    farm_id = str(insert_res.inserted_id)

    total_amount = sum(item.get("quantity", 0) * item.get("unit_price", 0) for item in data.iot_items)

    order_repo = IoTOrderRepository(db)
    order = await order_repo.create_order(
        user_id=user_id,
        user_name=user_name,
        farm_name=data.farm_name,
        area_hectare=data.area_hectare,
        tree_count=data.tree_count,
        items=data.iot_items,
        total_amount=total_amount,
    )

    return success_response(
        data={
            "farm_id": farm_id,
            "farm_code": farm_code,
            "onboarding_status": "PENDING_IOT",
            "order": order,
        },
        message="Đăng ký trang trại và gửi đơn mua thiết bị IoT thành công! Đơn hàng đang chờ Admin duyệt.",
        status_code=201,
    )


@router.post("/{farm_id}/activate-iot", response_model=SuccessResponse[dict])
async def activate_farm_iot(
    farm_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    query = {"_id": ObjectId(farm_id)} if ObjectId.is_valid(farm_id) else {"_id": farm_id}
    now = datetime.now(timezone.utc)
    
    await db["farms"].update_one(query, {"$set": {"onboarding_status": "ACTIVE", "updated_at": now}})
    
    return success_response(
        data={"farm_id": farm_id, "onboarding_status": "ACTIVE"},
        message="Kích hoạt trang trại & kết nối IoT thành công! Hệ thống Cảnh báo AI đã sẵn sàng hoạt động.",
    )


@router.put("/{farm_id}", response_model=SuccessResponse[FarmOut])
async def update_farm(
    farm_id: str,
    data: FarmUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = FarmService(db)
    farm = await service.update_farm(farm_id, data)
    return success_response(data=farm, message="Farm updated")


@router.delete("/{farm_id}", response_model=SuccessResponse[MessageResponse])
async def delete_farm(
    farm_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    service = FarmService(db)
    await service.delete_farm(farm_id)
    return success_response(message="Farm deleted")
