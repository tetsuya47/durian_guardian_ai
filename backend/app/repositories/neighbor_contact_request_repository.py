from __future__ import annotations

from typing import Any

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class NeighborContactRequestRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "neighbor_contact_requests")

    def _build_enrichment_stages(self) -> list[dict]:
        return [
            {
                "$lookup": {
                    "from": "farms",
                    "localField": "source_farm_id",
                    "foreignField": "_id",
                    "as": "source_farm",
                }
            },
            {"$unwind": {"path": "$source_farm", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "farms",
                    "localField": "target_farm_id",
                    "foreignField": "_id",
                    "as": "target_farm",
                }
            },
            {"$unwind": {"path": "$target_farm", "preserveNullAndEmptyArrays": True}},
            {
                "$addFields": {
                    "source_farm_name": "$source_farm.farm_name",
                    "target_farm_name": "$target_farm.farm_name",
                }
            },
            {"$project": {"source_farm": 0, "target_farm": 0}},
        ]

    async def count_by_status(self, user_oid: ObjectId) -> dict[str, int]:
        pipeline = [
            {
                "$match": {
                    "$or": [
                        {"source_user_id": user_oid},
                        {"target_user_id": user_oid},
                    ]
                }
            },
            {"$group": {"_id": "$status", "count": {"$sum": 1}}},
        ]
        cursor = self.collection.aggregate(pipeline)
        counts: dict[str, int] = {}
        async for doc in cursor:
            counts[str(doc["_id"])] = int(doc["count"])
        return counts

    async def count_by_direction(self, user_oid: ObjectId) -> tuple[int, int]:
        sent = await self.collection.count_documents({"source_user_id": user_oid})
        received = await self.collection.count_documents({"target_user_id": user_oid})
        return sent, received

    async def list_latest(
        self, user_oid: ObjectId, limit: int = 10
    ) -> list[dict[str, Any]]:
        pipeline = [
            {
                "$match": {
                    "$or": [
                        {"source_user_id": user_oid},
                        {"target_user_id": user_oid},
                    ]
                }
            },
            {"$sort": {"updated_at": -1}},
            {"$limit": limit},
        ]
        pipeline.extend(self._build_enrichment_stages())
        items = []
        async for doc in self.collection.aggregate(pipeline):
            doc["id"] = str(doc.pop("_id"))
            items.append(doc)
        return items
