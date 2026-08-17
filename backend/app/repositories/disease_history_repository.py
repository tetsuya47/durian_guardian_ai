from __future__ import annotations

from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.repositories.base import BaseRepository


class DiseaseHistoryRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "disease_history")

    def _build_enrichment_stages(self) -> list[dict]:
        return [
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": True}},
            {
                "$addFields": {
                    "tree_code": "$tree_info.tree_code",
                }
            },
            {"$project": {"tree_info": 0}},
        ]

    async def get_all(
        self, page: int = 1, per_page: int = 20, keyword: str | None = None, filter_query: dict | None = None
    ) -> tuple[list[dict[str, Any]], int]:
        import re
        query: dict = filter_query.copy() if filter_query else {}
        if keyword:
            conditions: list[dict] = [
                {"disease": {"$regex": re.escape(keyword), "$options": "i"}},
                {"action": {"$regex": re.escape(keyword), "$options": "i"}},
            ]

            matching_tree_ids = []
            cursor = self.collection.database["trees"].find(
                {"tree_code": {"$regex": re.escape(keyword), "$options": "i"}},
                {"_id": 1}
            )
            async for t in cursor:
                matching_tree_ids.append(t["_id"])

            if matching_tree_ids:
                conditions.append({"tree_id": {"$in": matching_tree_ids}})

            if "$or" in query:
                query = {"$and": [query, {"$or": conditions}]}
            else:
                query["$or"] = conditions

        pipeline = [{"$match": query}, {"$sort": {"date": -1}}]
        pipeline.extend(self._build_enrichment_stages())

        count_pipeline = [{"$match": query}, {"$count": "total"}]
        count_cursor = self.collection.aggregate(count_pipeline)
        count_result = await count_cursor.to_list(length=1)
        total = count_result[0]["total"] if count_result else 0

        pipeline.append({"$skip": (page - 1) * per_page})
        pipeline.append({"$limit": per_page})

        cursor = self.collection.aggregate(pipeline)
        items = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            items.append(doc)
        return items, total

    async def get_by_id(self, id: str) -> dict[str, Any] | None:
        return await self.get(id)

    async def get_kpi_stats(self) -> dict:
        total_records = await self.collection.count_documents({})
        processed = await self.collection.count_documents(
            {"action": {"$in": ["Treatment Applied", "Đã điều trị"]}}
        )
        unique_diseases = len(await self.collection.distinct("disease"))
        return {
            "total_records": total_records,
            "processed_records": processed,
            "unprocessed_records": total_records - processed,
            "unique_diseases": unique_diseases,
        }
