from __future__ import annotations

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class FarmPerformanceRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "farm_performance")

    async def get_by_farm_and_season(
        self, farm_oid: ObjectId, season_oid: ObjectId
    ) -> dict | None:
        doc = await self.collection.find_one(
            {"farm_id": farm_oid, "season_id": season_oid}
        )
        if doc:
            return self._serialize(doc)
        return None

    async def list_by_farm(self, farm_oid: ObjectId) -> list[dict]:
        docs, _ = await self.list(
            {"farm_id": farm_oid}, page=1, per_page=100
        )
        return docs
