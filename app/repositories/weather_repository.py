from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class WeatherRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "weather_history")

    async def list_by_farm(
        self, farm_id: str, limit_days: int = 7
    ) -> list[dict]:
        cursor = (
            self.collection.find({"farm_id": farm_id})
            .sort("weather_date", -1)
            .limit(limit_days)
        )
        docs = []
        async for doc in cursor:
            docs.append(self._serialize(doc))
        return docs
