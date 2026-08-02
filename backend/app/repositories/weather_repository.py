from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class WeatherRepository(BaseRepository):
    """Repository for the ``weather_cache`` collection.

    Pure data access. No business logic. Follows the existing
    ``BaseRepository`` pattern used across the project.

    Documents are stored **flattened** (only the fields the DGA schema
    needs) — never the raw OpenWeather payload:

    .. code-block:: json

        {
          "_id": "weather_12.67_108.05",
          "farm_id": "...",
          "latitude": 12.67,
          "longitude": 108.05,
          "location_name": "Buôn Ma Thuột",
          "temperature": 23.8,
          "feels_like": 24.7,
          "humidity": 93,
          "pressure": 1008,
          "wind_speed": 0.7,
          "rainfall": 0.0,
          "clouds": 76,
          "visibility": 10000,
          "weather": "Clouds",
          "description": "Mây cụm",
          "icon": "04n",
          "updated_at": <UTC datetime>,
          "cache_expired_at": <UTC datetime = updated_at + TTL>,
          "forecast": [ ... optional ... ]
        }
    """

    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "weather_cache")

    @staticmethod
    def build_cache_key(lat: float, lon: float) -> str:
        return f"weather_{round(lat, 2)}_{round(lon, 2)}"

    @staticmethod
    def compute_cache_expired_at(
        updated_at: datetime | None = None, ttl_minutes: int = 15
    ) -> datetime:
        base = updated_at or datetime.now(timezone.utc)
        if base.tzinfo is None:
            base = base.replace(tzinfo=timezone.utc)
        return base + timedelta(minutes=ttl_minutes)

    async def get_by_coords(self, lat: float, lon: float) -> dict[str, Any] | None:
        return await self.collection.find_one({"_id": self.build_cache_key(lat, lon)})

    async def get_by_farm_id(self, farm_id: str) -> dict[str, Any] | None:
        return await self.collection.find_one({"farm_id": farm_id})

    async def create_weather(self, doc: dict[str, Any]) -> str:
        payload = dict(doc)
        payload.setdefault("updated_at", datetime.now(timezone.utc))
        payload.setdefault(
            "cache_expired_at",
            self.compute_cache_expired_at(payload["updated_at"]),
        )
        result = await self.collection.insert_one(payload)
        return str(result.inserted_id)

    async def update_weather(
        self,
        cache_key: str,
        fields: dict[str, Any],
        ttl_minutes: int = 15,
    ) -> dict[str, Any] | None:
        payload = dict(fields)
        payload["updated_at"] = datetime.now(timezone.utc)
        payload["cache_expired_at"] = self.compute_cache_expired_at(
            payload["updated_at"], ttl_minutes
        )
        result = await self.collection.find_one_and_update(
            {"_id": cache_key},
            {"$set": payload},
            return_document=True,
        )
        if result:
            return self._serialize(result)
        return None

    async def upsert_weather(
        self,
        doc: dict[str, Any],
        ttl_minutes: int = 15,
    ) -> None:
        payload = dict(doc)
        payload.setdefault(
            "_id",
            self.build_cache_key(
                payload.get("latitude", 0.0), payload.get("longitude", 0.0)
            ),
        )
        payload["updated_at"] = datetime.now(timezone.utc)
        payload["cache_expired_at"] = self.compute_cache_expired_at(
            payload["updated_at"], ttl_minutes
        )
        await self.collection.replace_one(
            {"_id": payload["_id"]}, payload, upsert=True
        )

    async def delete_expired(self) -> int:
        now = datetime.now(timezone.utc)
        result = await self.collection.delete_many(
            {"cache_expired_at": {"$lt": now}}
        )
        return result.deleted_count

    async def find_latest(self) -> dict[str, Any] | None:
        return await self.collection.find_one(sort=[("updated_at", -1)])
