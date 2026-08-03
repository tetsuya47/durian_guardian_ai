from __future__ import annotations

import math
import random
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.dependencies import get_current_user_id, get_current_user_role, RoleChecker
from app.core.exceptions import NotFoundException, ForbiddenException
from app.core.response import success_response
from app.database.mongodb import get_database
from app.repositories.iot_order_repository import IoTOrderRepository
from app.repositories.iot_device_repository import IoTDeviceRepository
from app.schemas.iot import (
    IoTEstimateRequest,
    IoTEstimateResponse,
    IoTDeviceRecommendation,
    IoTOrderCreate,
    IoTOrderOut,
    IoTOrderStatusUpdate,
)
from app.schemas.response_models import SuccessResponse, PaginatedResponse

router = APIRouter(prefix="/iot", tags=["IoT Equipment & Orders"])
admin_router = APIRouter(prefix="/admin/iot", tags=["Admin IoT Management"])


@router.get("/summary", response_model=SuccessResponse[dict])
async def get_iot_summary(
    farm_id: Optional[str] = Query(default=None),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    repo = IoTDeviceRepository(db)
    summary = await repo.get_summary(farm_id=farm_id)
    return success_response(data=summary)


@router.get("/devices", response_model=PaginatedResponse[dict])
async def list_iot_devices(
    farm_id: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    device_type: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    repo = IoTDeviceRepository(db)
    items, total = await repo.list_devices(farm_id=farm_id, status=status, device_type=device_type, page=page, per_page=per_page)
    return success_response(data=items, total=total, page=page, per_page=per_page)


@router.get("/my-devices")
async def list_user_iot_devices(
    farm_id: Optional[str] = Query(default=None),
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Retrieve real IoT devices belonging to current user's farms from MongoDB collection `iot_devices`."""
    from bson import ObjectId
    user_oid = ObjectId(user_id) if ObjectId.is_valid(user_id) else user_id
    user_doc = await db["users"].find_one({"_id": user_oid})
    user_role = (user_doc.get("role") or "").lower() if user_doc else "user"
    is_admin = user_role in ["admin", "system admin"]

    if is_admin:
        query: dict = {}
        if farm_id and farm_id != "all":
            query = {"$or": [{"farm_id": farm_id}, {"farm_id": ObjectId(farm_id) if ObjectId.is_valid(farm_id) else farm_id}]}
    else:
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

        farm_ids_str = [str(f["_id"]) for f in user_farms]
        farm_codes = [f.get("farm_code") for f in user_farms if f.get("farm_code")]
        farm_oids = [f["_id"] for f in user_farms]

        all_farm_keys = farm_ids_str + farm_codes + farm_oids

        if farm_id and farm_id != "all":
            query = {"farm_id": farm_id}
        else:
            query = {"$or": [{"farm_id": {"$in": all_farm_keys}}, {"farm_id": {"$in": farm_ids_str}}, {"farm_id": {"$in": farm_codes}}]}

    cursor = db["iot_devices"].find(query).sort("created_at", -1)
    docs = await cursor.to_list(length=100)

    farms = await db["farms"].find({}).to_list(100)
    farm_map = {str(f["_id"]): f.get("farm_name") for f in farms}
    for f in farms:
        if f.get("farm_code"):
            farm_map[f.get("farm_code")] = f.get("farm_name")

    items = []
    for d in docs:
        f_id = str(d.get("farm_id", ""))
        items.append({
            "id": str(d["_id"]),
            "device_code": d.get("device_code", "DEV-UNKNOWN"),
            "name": d.get("name") or d.get("device_name") or "Thiết bị Cảm biến IoT",
            "device_type": d.get("device_type", "Soil Sensor"),
            "farm_id": f_id,
            "farm_name": d.get("farm_name") or farm_map.get(f_id) or "Trang trại của tôi",
            "status": d.get("status", "Active"),
            "battery": d.get("battery", d.get("battery_level", 100)),
            "signal": d.get("signal", d.get("last_signal", "LoRa 5/5")),
            "soil_moisture": d.get("soil_moisture"),
            "pH": d.get("pH"),
            "EC": d.get("EC"),
            "temperature": d.get("temperature"),
            "humidity": d.get("humidity"),
            "last_sync": str(d.get("last_sync") or d.get("updated_at") or d.get("created_at") or ""),
        })

    return success_response(data={"items": items, "total": len(items)})


@router.post("/estimate", response_model=SuccessResponse[IoTEstimateResponse])
async def estimate_iot_equipment(data: IoTEstimateRequest):
    area = data.area_hectare
    zones = data.zone_count

    # Smart Estimator Algorithm rules:
    # 1. Soil Sensor: 1 per 0.5 ha (min 2)
    soil_qty = max(2, math.ceil(area / 0.5))
    # 2. Weather Station: 1 per 5.0 ha (min 1)
    weather_qty = max(1, math.ceil(area / 5.0))
    # 3. Gateway Hub: 1 per zone / 10 ha (min 1)
    gateway_qty = max(1, zones)
    # 4. Smart Valve: 1 per zone (min 1)
    valve_qty = max(1, zones)

    recommendations = [
        IoTDeviceRecommendation(
            device_type="soil_sensor",
            device_name="Cảm biến độ ẩm & NPK đất DurianSense Pro",
            recommended_quantity=soil_qty,
            unit_price=1200000.0,
            description="Đo độ ẩm, pH, nhiệt độ và NPK trực tiếp tại gốc sầu riêng",
        ),
        IoTDeviceRecommendation(
            device_type="weather_station",
            device_name="Trạm thời tiết vi khí hậu DGA-Weather 5G",
            recommended_quantity=weather_qty,
            unit_price=8500000.0,
            description="Đo lượng mưa, tốc độ gió, độ ẩm không khí và bức xạ nhiệt",
        ),
        IoTDeviceRecommendation(
            device_type="gateway_hub",
            device_name="Bộ trung tâm IoT Gateway Hub Edge AI",
            recommended_quantity=gateway_qty,
            unit_price=3500000.0,
            description="Thu thập dữ liệu cảm biến thời gian thực & kết nối AI Cloud",
        ),
        IoTDeviceRecommendation(
            device_type="smart_valve",
            device_name="Van tưới tự động thông minh DGA SmartValve",
            recommended_quantity=valve_qty,
            unit_price=1800000.0,
            description="Điều khiển đóng mở van tưới theo lịch trình AI khuyến nghị",
        ),
    ]

    total_cost = sum(r.recommended_quantity * r.unit_price for r in recommendations)

    return success_response(
        data=IoTEstimateResponse(
            area_hectare=area,
            tree_count=data.tree_count,
            zone_count=zones,
            recommendations=recommendations,
            total_estimated_cost=total_cost,
        ).model_dump(),
        message="Tính toán gói thiết bị IoT khuyến nghị thành công",
    )


@router.post("/orders", response_model=SuccessResponse[IoTOrderOut])
async def create_iot_order(
    data: IoTOrderCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    repo = IoTOrderRepository(db)
    
    # Fetch user info for name
    user_doc = await db["users"].find_one({"_id": user_id}) if user_id else None
    user_name = user_doc.get("full_name") if user_doc else "Chủ vườn"

    total_amount = sum(item.quantity * item.unit_price for item in data.items)
    order_code = f"ORD-{random.randint(100000, 999999)}"

    order_data = {
        "order_code": order_code,
        "user_id": user_id,
        "user_name": user_name,
        "farm_id": data.farm_id,
        "farm_name": data.farm_name,
        "area_hectare": data.area_hectare,
        "tree_count": data.tree_count,
        "items": [item.model_dump() for item in data.items],
        "total_amount": total_amount,
        "status": "Pending",
        "notes": data.notes,
    }

    created = await repo.create(order_data)
    return success_response(
        data=created,
        message="Gửi đơn mua thiết bị IoT thành công. Vui lòng chờ Admin duyệt đơn.",
        status_code=201,
    )


@router.get("/orders/my-orders", response_model=PaginatedResponse[IoTOrderOut])
async def list_my_iot_orders(
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    repo = IoTOrderRepository(db)
    items, total = await repo.list_by_user(user_id, page=page, per_page=per_page)
    return success_response(data=items, total=total, page=page, per_page=per_page)


@admin_router.get("/orders", response_model=PaginatedResponse[IoTOrderOut])
async def list_all_iot_orders_admin(
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=50, ge=1, le=100),
    status: Optional[str] = Query(default=None),
    role: str = Depends(RoleChecker(["Admin", "ADMIN"])),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    repo = IoTOrderRepository(db)
    items, total = await repo.list_all(page=page, per_page=per_page, status_filter=status)
    return success_response(data=items, total=total, page=page, per_page=per_page)


@admin_router.put("/orders/{order_id}/status", response_model=SuccessResponse[IoTOrderOut])
async def update_iot_order_status_admin(
    order_id: str,
    data: IoTOrderStatusUpdate,
    role: str = Depends(RoleChecker(["Admin", "ADMIN"])),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    repo = IoTOrderRepository(db)
    updated = await repo.update_status(order_id, status=data.status, admin_notes=data.admin_notes)
    if not updated:
        raise NotFoundException(f"Không tìm thấy đơn hàng ID {order_id}")
    return success_response(
        data=updated,
        message=f"Cập nhật trạng thái đơn hàng thành '{data.status}' thành công",
    )


@router.get("/fault-reports", response_model=SuccessResponse[list])
@admin_router.get("/fault-reports", response_model=SuccessResponse[list])
async def list_iot_fault_reports(
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    docs = await db["iot_fault_reports"].find({}).to_list(100)
    reports = []
    for d in docs:
        d["id"] = str(d.get("_id"))
        if "_id" in d:
            del d["_id"]
        reports.append(d)
    return success_response(data=reports)


@admin_router.put("/fault-reports/{report_id}/status", response_model=SuccessResponse[dict])
async def update_iot_fault_report_status(
    report_id: str,
    payload: dict,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    status = payload.get("status", "In_Progress")
    notes = payload.get("admin_notes", "")
    technician = payload.get("technician", "")

    update_fields: dict = {"status": status, "updated_at": datetime.now()}
    if notes:
        update_fields["admin_notes"] = notes
    if technician:
        update_fields["technician"] = technician

    # Find and update by report_code or id
    report_doc = await db["iot_fault_reports"].find_one({"$or": [{"report_code": report_id}, {"id": report_id}]})

    res = await db["iot_fault_reports"].update_one(
        {"$or": [{"report_code": report_id}, {"id": report_id}]},
        {"$set": update_fields}
    )

    # RELATIONAL SYNCHRONIZATION WITH `iot_devices` COLLECTION
    if report_doc:
        dev_code = report_doc.get("device_code")
        if dev_code:
            if status == "In_Progress":
                await db["iot_devices"].update_one(
                    {"device_code": dev_code},
                    {"$set": {"status": "Maintenance", "updated_at": datetime.now()}}
                )
            elif status == "Resolved":
                await db["iot_devices"].update_one(
                    {"device_code": dev_code},
                    {"$set": {"status": "Active", "battery_level": 100, "updated_at": datetime.now()}}
                )
            elif status in ["Pending", "Rejected"]:
                await db["iot_devices"].update_one(
                    {"device_code": dev_code},
                    {"$set": {"status": "Active", "updated_at": datetime.now()}}
                )

    return success_response(
        data={"report_id": report_id, "status": status, "admin_notes": notes, "technician": technician},
        message=f"Cập nhật trạng thái báo cáo sự cố MongoDB {report_id} và đồng bộ thiết bị thành công",
    )

