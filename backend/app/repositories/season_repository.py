from __future__ import annotations

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class SeasonRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "seasons")

    async def get_latest_by_farm(self, farm_oid: ObjectId) -> dict | None:
        # Business rule — priority order:
        #   1. Active season (status == "active")
        #   2. Highest season_year
        #   3. Newest created_at
        doc = await self.collection.find_one(
            {"farm_id": farm_oid, "status": "active"}
        )
        if doc:
            return self._serialize(doc)

        cursor = (
            self.collection.find({"farm_id": farm_oid})
            .sort([("season_year", -1), ("created_at", -1)])
            .limit(1)
        )
        docs = await cursor.to_list(length=1)
        if docs:
            return self._serialize(docs[0])
        return None

    async def get_by_farm_and_season(
        self, farm_oid: ObjectId, season_oid: ObjectId
    ) -> dict | None:
        doc = await self.collection.find_one(
            {"farm_id": farm_oid, "_id": season_oid}
        )
        if doc:
            return self._serialize(doc)
        return None
