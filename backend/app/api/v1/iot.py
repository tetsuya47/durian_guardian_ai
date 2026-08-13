from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from fastapi import APIRouter, Depends, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.core.response import success_response
from app.schemas.iot_telemetry import IoTTelemetryCreate
from app.services.iot_service import IoTService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/iot", tags=["IoT Telemetry & Smart Farming"])


@router.post(
    "/telemetry",
    status_code=status.HTTP_201_CREATED,
    summary="Ingest 30-second simulated IoT telemetry & persist to MongoDB",
)
async def ingest_telemetry(
    payload: IoTTelemetryCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Save 30-second real-time sensor reading into MongoDB `iot_telemetry` collection."""
    service = IoTService(db)
    saved_doc = await service.ingest_telemetry(payload.model_dump())
    return success_response(
        data=saved_doc,
        message="IoT telemetry saved to persistent MongoDB collection successfully",
    )


@router.get(
    "/telemetry/latest",
    summary="Get latest IoT telemetry + Model 3 Risk Assessment + Model 4 AI Agronomist Advice",
)
async def get_latest_telemetry_analysis(
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Get the most recent IoT sensor reading and AI recommendations."""
    service = IoTService(db)
    analysis = await service.get_latest_analysis()
    return success_response(
        data=analysis,
        message="Latest IoT sensor readings and AI recommendations retrieved successfully",
    )


@router.get(
    "/telemetry/history",
    summary="Get historical IoT telemetry readings from MongoDB",
)
async def get_telemetry_history(
    limit: int = 50,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Retrieve up to 50 recent 30-second telemetry readings."""
    service = IoTService(db)
    history = await service.get_history(limit)
    return success_response(
        data=history,
        message=f"Retrieved {len(history)} recent IoT telemetry records",
    )


@router.get(
    "/my-devices",
    summary="Get authentic user IoT devices from MongoDB",
)
async def get_my_devices(
    farm_id: Optional[str] = Query(None),
    status_filter: Optional[str] = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Get active IoT devices stored in MongoDB `iot_devices` collection."""
    query: Dict[str, Any] = {}
    if farm_id and farm_id != "all":
        query["farm_id"] = farm_id
    if status_filter and status_filter != "all":
        query["status"] = status_filter

    cursor = db["iot_devices"].find(query).sort("created_at", -1).limit(100)
    devices = await cursor.to_list(length=100)

    # Format ObjectId to string
    items = []
    for d in devices:
        item = {**d, "id": str(d["_id"])}
        if "_id" in item:
            del item["_id"]
        # Format datetimes
        if isinstance(item.get("last_signal"), datetime):
            item["last_signal"] = item["last_signal"].isoformat()
        if isinstance(item.get("created_at"), datetime):
            item["created_at"] = item["created_at"].isoformat()
        if isinstance(item.get("updated_at"), datetime):
            item["updated_at"] = item["updated_at"].isoformat()
        items.append(item)

    return success_response(
        data={"items": items, "total": len(items)},
        message="Danh sách thiết bị IoT từ MongoDB",
    )


@router.get(
    "/products",
    summary="Get authentic IoT products catalog for store",
)
async def get_iot_products():
    """Returns IoT equipment available for purchase."""
    products = [
        {
            "id": "prod-1",
            "device_type": "soil_sensor",
            "name": "Cảm biến độ ẩm & NPK đất DurianSense Pro",
            "category": "Cảm biến đất",
            "price": 1200000,
            "rating": 4.9,
            "desc": "Đo độ ẩm đất 0-100%, nhiệt độ, pH và nồng độ NPK trực tiếp tại gốc sầu riêng.",
            "badge": "Bán chạy nhất",
            "icon": "sensors",
            "image_path": "assets/images/iot_soil_sensor.png",
            "image_url": "https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=600&q=80",
        },
        {
            "id": "prod-2",
            "device_type": "weather_station",
            "name": "Trạm thời tiết vi khí hậu DGA-Weather 5G",
            "category": "Trạm thời tiết",
            "price": 8500000,
            "rating": 5.0,
            "desc": "Đo lượng mưa, bức xạ UV, đốm nấm lá, độ ẩm không khí và tốc độ gió theo vùng.",
            "badge": "Công nghệ AI 5G",
            "icon": "thunderstorm",
            "image_path": "assets/images/iot_weather_station.png",
            "image_url": "https://images.unsplash.com/photo-1592833159057-651427233044?auto=format&fit=crop&w=600&q=80",
        },
        {
            "id": "prod-3",
            "device_type": "gateway_hub",
            "name": "Bộ trung tâm IoT Gateway Hub Edge AI",
            "category": "IoT Gateway",
            "price": 3500000,
            "rating": 4.8,
            "desc": "Thu thập dữ liệu LoRaWAN bán kính 5km, xử lý dữ liệu tại biên và đẩy lên đám mây.",
            "badge": "Kết nối 5km",
            "icon": "router",
            "image_path": "assets/images/iot_gateway_hub.png",
            "image_url": "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=600&q=80",
        },
        {
            "id": "prod-4",
            "device_type": "smart_valve",
            "name": "Van tưới bù áp thông minh SmartValve",
            "category": "Van tưới tự động",
            "price": 1800000,
            "rating": 4.9,
            "desc": "Điều khiển tưới bù áp tự động theo lịch khuyến nghị của AI Agronomist.",
            "badge": "Tiết kiệm 40% nước",
            "icon": "water_drop",
            "image_path": "assets/images/iot_smart_valve.png",
            "image_url": "https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?auto=format&fit=crop&w=600&q=80",
        },
        {
            "id": "prod-5",
            "device_type": "ai_camera",
            "name": "Camera AI 4K Giám Sát Cây Trồng",
            "category": "Camera nông nghiệp",
            "price": 2200000,
            "rating": 4.7,
            "desc": "Chụp ảnh và xử lý hình ảnh AI tại chỗ phát hiện sâu bệnh, bọ trĩ, thán thư.",
            "badge": "AI Edge 4K",
            "icon": "videocam",
            "image_path": "assets/images/iot_gateway_hub.png",
            "image_url": "https://images.unsplash.com/photo-1557597774-9d273605dfa9?auto=format&fit=crop&w=600&q=80",
        },
    ]
    return success_response(data=products, message="Danh mục thiết bị IoT")


@router.get(
    "/orders",
    summary="Get user IoT orders from MongoDB",
)
async def get_iot_orders(
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Retrieve orders stored in MongoDB `iot_orders` collection."""
    cursor = db["iot_orders"].find({}).sort("created_at", -1).limit(50)
    orders = await cursor.to_list(length=50)

    items = []
    for o in orders:
        item = {**o, "id": str(o["_id"])}
        if "_id" in item:
            del item["_id"]
        if isinstance(item.get("created_at"), datetime):
            item["created_at"] = item["created_at"].strftime("%d/%m/%Y %H:%M")
        if isinstance(item.get("updated_at"), datetime):
            item["updated_at"] = item["updated_at"].strftime("%d/%m/%Y %H:%M")
        items.append(item)

    return success_response(
        data={"items": items, "total": len(items)},
        message="Danh sách đơn hàng IoT từ MongoDB",
    )


@router.post(
    "/orders",
    status_code=status.HTTP_201_CREATED,
    summary="Create new IoT equipment order in MongoDB",
)
async def create_iot_order(
    payload: Dict[str, Any],
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Save newly created IoT order into MongoDB `iot_orders` collection."""
    now = datetime.now(timezone.utc)
    order_code = f"ORD-{int(now.timestamp())}"
    doc = {
        "order_code": payload.get("order_code", order_code),
        "user_name": payload.get("user_name", "Chủ vườn"),
        "farm_name": payload.get("farm_name", "Vườn Sầu Riêng"),
        "items": payload.get("items", []),
        "total_amount": payload.get("total_amount", 0.0),
        "status": "Pending",
        "delivery_address": payload.get("delivery_address", ""),
        "phone": payload.get("phone", ""),
        "created_at": now,
        "updated_at": now,
    }
    res = await db["iot_orders"].insert_one(doc)
    doc["id"] = str(res.inserted_id)
    del doc["_id"]
    doc["created_at"] = doc["created_at"].strftime("%d/%m/%Y %H:%M")
    doc["updated_at"] = doc["updated_at"].strftime("%d/%m/%Y %H:%M")

    return success_response(
        data=doc,
        message="Đặt mua thiết bị IoT thành công! Đơn hàng đang chờ xử lý.",
        status_code=201,
    )


@router.post(
    "/fault-report",
    status_code=status.HTTP_201_CREATED,
    summary="Submit IoT device fault report to MongoDB",
)
async def report_device_fault(
    payload: Dict[str, Any],
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Save device issue report into MongoDB `iot_fault_reports`."""
    now = datetime.now(timezone.utc)
    doc = {
        "device_code": payload.get("device_code", ""),
        "device_name": payload.get("device_name", ""),
        "farm_name": payload.get("farm_name", ""),
        "issue_title": payload.get("issue_title", ""),
        "description": payload.get("description", ""),
        "status": "Pending_Review",
        "created_at": now,
    }
    res = await db["iot_fault_reports"].insert_one(doc)
    doc["id"] = str(res.inserted_id)
    del doc["_id"]
    return success_response(
        data=doc,
        message="Gửi báo cáo sự cố thiết bị thành công! Kỹ thuật viên sẽ liên hệ sớm nhất.",
        status_code=201,
    )
