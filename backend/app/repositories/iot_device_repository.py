from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


class IoTDeviceRepository:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.collection = db["iot_devices"]

    async def get_summary(self, farm_id: Optional[str] = None) -> Dict[str, Any]:
        query = {"farm_id": farm_id} if farm_id else {}
        
        total_devices = await self.collection.count_documents(query)
        online_devices = await self.collection.count_documents({**query, "status": "Active"})
        offline_devices = await self.collection.count_documents({**query, "status": {"$in": ["In_Stock", "InStock", "Inactive"]}})
        maintenance_devices = await self.collection.count_documents({**query, "status": "Maintenance"})

        soil_sensors = await self.collection.count_documents({**query, "device_type": "soil_sensor"})
        weather_stations = await self.collection.count_documents({**query, "device_type": "weather_station"})
        gateway_hubs = await self.collection.count_documents({**query, "device_type": "gateway_hub"})
        smart_valves = await self.collection.count_documents({**query, "device_type": "smart_valve"})

        return {
            "total_devices": total_devices,
            "online_devices": online_devices,
            "offline_devices": offline_devices,
            "maintenance_devices": maintenance_devices,
            "active_devices": online_devices,
            "in_stock_devices": offline_devices,
            "by_type": {
                "soil_sensor": soil_sensors,
                "weather_station": weather_stations,
                "gateway_hub": gateway_hubs,
                "smart_valve": smart_valves,
            },
            "online_by_type": {
                "soil_sensor": soil_sensors_online,
                "weather_station": weather_stations_online,
                "gateway_hub": gateway_hubs_online,
                "smart_valve": smart_valves_online,
            },
            "offline_by_type": {
                "soil_sensor": soil_sensors_offline,
                "weather_station": weather_stations_offline,
                "gateway_hub": gateway_hubs_offline,
                "smart_valve": smart_valves_offline,
            },
        }

    async def list_devices(
        self,
        farm_id: Optional[str] = None,
        status: Optional[str] = None,
        device_type: Optional[str] = None,
        page: int = 1,
        per_page: int = 20,
    ) -> tuple[List[Dict[str, Any]], int]:
        query: Dict[str, Any] = {}
        if farm_id:
            query["farm_id"] = farm_id
        if status:
            query["status"] = status
        if device_type:
            query["device_type"] = device_type

        skip = (page - 1) * per_page
        total = await self.collection.count_documents(query)
        cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(per_page)
        docs = await cursor.to_list(length=per_page)
        return [self._serialize(d) for d in docs], total

    def _serialize(self, doc: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "id": str(doc["_id"]),
            "device_code": doc.get("device_code", ""),
            "device_name": doc.get("device_name", ""),
            "device_type": doc.get("device_type", ""),
            "unit_price": doc.get("unit_price", 0.0),
            "farm_id": doc.get("farm_id"),
            "farm_name": doc.get("farm_name"),
            "status": doc.get("status", "Active"),
            "battery_level": doc.get("battery_level", 100),
            "last_signal": doc.get("last_signal"),
            "created_at": doc.get("created_at"),
            "updated_at": doc.get("updated_at"),
        }
