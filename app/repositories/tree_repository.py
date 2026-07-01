from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class TreeRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "trees")

    async def list_by_zone(
        self, zone_id: str, page: int = 1, per_page: int = 20
    ) -> tuple[list[dict], int]:
        return await self.list(
            filter_query={"zone_id": zone_id},
            page=page,
            per_page=per_page,
            sort=[("created_at", -1)],
        )

    async def list_filtered(
        self,
        zone_id: str | None = None,
        farm_id: str | None = None,
        keyword: str | None = None,
        status: str | None = None,
        risk_level: str | None = None,
        page: int = 1,
        per_page: int = 20,
    ) -> tuple[list[dict], int]:
        import re

        filter_query: dict = {}
        if zone_id:
            filter_query["zone_id"] = zone_id

        if keyword:
            filter_query["tree_code"] = {"$regex": re.escape(keyword), "$options": "i"}

        if farm_id:
            db = self.collection.database
            zone_ids = []
            async for z in db["zones"].find({"farm_id": farm_id}):
                zone_ids.append(str(z["_id"]))
            if zone_ids:
                filter_query["zone_id"] = {"$in": zone_ids}
            else:
                return [], 0

        if status or risk_level:
            return await self._list_with_joins(
                filter_query, status, risk_level, page, per_page
            )

        return await self.list(
            filter_query=filter_query,
            page=page,
            per_page=per_page,
            sort=[("created_at", -1)],
        )

    async def _list_with_joins(
        self,
        base_query: dict,
        status: str | None,
        risk_level: str | None,
        page: int,
        per_page: int,
    ) -> tuple[list[dict], int]:
        db = self.collection.database
        pipeline: list[dict] = [{"$match": base_query}] if base_query else []

        pipeline.append({"$sort": {"created_at": -1}})

        if status:
            lookup_disease = {
                "$lookup": {
                    "from": "disease_history",
                    "let": {"tree_id": "$_id"},
                    "pipeline": [
                        {"$match": {"$expr": {"$eq": ["$tree_id", {"$toString": "$$tree_id"}]}}},
                        {"$sort": {"created_at": -1}},
                        {"$limit": 1},
                    ],
                    "as": "latest_disease",
                }
            }
            pipeline.append(lookup_disease)
            if status == "healthy":
                pipeline.append({"$match": {"latest_disease.disease_name": "Healthy"}})
            elif status == "diseased":
                pipeline.append({
                    "$match": {
                        "$and": [
                            {"latest_disease": {"$ne": []}},
                            {"latest_disease.disease_name": {"$ne": "Healthy"}},
                        ]
                    }
                })

        if risk_level:
            lookup_risk = {
                "$lookup": {
                    "from": "risk_assessments",
                    "let": {"tree_id": "$_id"},
                    "pipeline": [
                        {"$match": {"$expr": {"$eq": ["$tree_id", {"$toString": "$$tree_id"}]}}},
                        {"$sort": {"created_at": -1}},
                        {"$limit": 1},
                    ],
                    "as": "latest_risk",
                }
            }
            pipeline.append(lookup_risk)

            risk_thresholds = {"low": 0.3, "medium": 0.6, "high": 0.0}
            threshold = risk_thresholds.get(risk_level, 0.0)
            if risk_level == "high":
                pipeline.append({"$match": {"latest_risk.risk_score": {"$gte": 0.7}}})
            elif risk_level == "medium":
                pipeline.append({
                    "$match": {
                        "latest_risk": {"$ne": []},
                        "latest_risk.risk_score": {"$gte": 0.3, "$lt": 0.7},
                    }
                })
            elif risk_level == "low":
                pipeline.append({
                    "$match": {
                        "$or": [
                            {"latest_risk": []},
                            {"latest_risk.risk_score": {"$lt": 0.3}},
                        ]
                    }
                })

        count_pipeline = list(pipeline)
        count_pipeline.append({"$count": "total"})
        count_cursor = db["trees"].aggregate(count_pipeline)
        count_result = await count_cursor.to_list(length=1)
        total = count_result[0]["total"] if count_result else 0

        pipeline.append({"$skip": (page - 1) * per_page})
        pipeline.append({"$limit": per_page})
        cursor = db["trees"].aggregate(pipeline)
        items = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            doc.pop("latest_disease", None)
            doc.pop("latest_risk", None)
            items.append(doc)
        return items, total

    async def get_by_code(self, tree_code: str) -> dict | None:
        doc = await self.collection.find_one({"tree_code": tree_code})
        if doc:
            return self._serialize(doc)
        return None

    async def count_all(self) -> int:
        return await self.collection.count_documents({})

    async def count_by_farms(self, farm_ids: list[str]) -> int:
        db = self.collection.database
        zone_ids = []
        async for z in db["zones"].find({"farm_id": {"$in": farm_ids}}):
            zone_ids.append(str(z["_id"]))
        if not zone_ids:
            return 0
        return await self.collection.count_documents({"zone_id": {"$in": zone_ids}})

    async def search_by_keyword(
        self, keyword: str, page: int = 1, per_page: int = 20
    ) -> tuple[list[dict], int]:
        import re

        pattern = re.escape(keyword)
        return await self.list(
            filter_query={"tree_code": {"$regex": pattern, "$options": "i"}},
            page=page,
            per_page=per_page,
            sort=[("created_at", -1)],
        )
