from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


class IoTOrderRepository:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.collection = db["iot_orders"]

    async def create(self, data: Dict[str, Any]) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        doc = {
            **data,
            "status": data.get("status", "Pending"),
            "created_at": now,
            "updated_at": now,
        }
        res = await self.collection.insert_one(doc)
        doc["_id"] = res.inserted_id
        return self._serialize(doc)

    async def get_by_id(self, order_id: str) -> Optional[Dict[str, Any]]:
        try:
            oid = ObjectId(order_id)
        except Exception:
            return None
        doc = await self.collection.find_one({"_id": oid})
        return self._serialize(doc) if doc else None

    async def list_by_user(self, user_id: str, page: int = 1, per_page: int = 20) -> tuple[List[Dict[str, Any]], int]:
        skip = (page - 1) * per_page
        query = {"user_id": user_id}
        total = await self.collection.count_documents(query)
        cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(per_page)
        docs = await cursor.to_list(length=per_page)
        return [self._serialize(d) for d in docs], total

    async def list_all(self, page: int = 1, per_page: int = 50, status_filter: Optional[str] = None) -> tuple[List[Dict[str, Any]], int]:
        skip = (page - 1) * per_page
        query = {}
        if status_filter:
            query["status"] = status_filter
        total = await self.collection.count_documents(query)
        cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(per_page)
        docs = await cursor.to_list(length=per_page)
        return [self._serialize(d) for d in docs], total

    async def update_status(self, order_id: str, status: str, admin_notes: Optional[str] = None) -> Optional[Dict[str, Any]]:
        try:
            oid = ObjectId(order_id)
        except Exception:
            return None
        now = datetime.now(timezone.utc)
        update_fields: Dict[str, Any] = {"status": status, "updated_at": now}
        if admin_notes is not None:
            update_fields["admin_notes"] = admin_notes
        doc = await self.collection.find_one_and_update(
            {"_id": oid},
            {"$set": update_fields},
            return_document=True,
        )
        return self._serialize(doc) if doc else None

    def _serialize(self, doc: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "id": str(doc["_id"]),
            "order_code": doc.get("order_code", f"ORD-{str(doc['_id'])[-6:].upper()}"),
            "user_id": doc.get("user_id", ""),
            "user_name": doc.get("user_name"),
            "farm_id": doc.get("farm_id"),
            "farm_name": doc.get("farm_name", ""),
            "area_hectare": doc.get("area_hectare", 0.0),
            "tree_count": doc.get("tree_count", 0),
            "items": doc.get("items", []),
            "total_amount": doc.get("total_amount", 0.0),
            "status": doc.get("status", "Pending"),
            "notes": doc.get("notes"),
            "admin_notes": doc.get("admin_notes"),
            "created_at": doc.get("created_at", datetime.now(timezone.utc)),
            "updated_at": doc.get("updated_at", datetime.now(timezone.utc)),
        }
