from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

logger = logging.getLogger(__name__)


class IoTTelemetryRepository:
    """Repository for persisting & querying IoT sensor telemetry in MongoDB collection `iot_telemetry`."""

    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.collection = db["iot_telemetry"]

    async def save(self, data: dict[str, Any]) -> dict[str, Any]:
        """Save a new 30-second sensor reading to MongoDB."""
        doc = dict(data)
        if "timestamp" not in doc or not doc["timestamp"]:
            doc["timestamp"] = datetime.now(timezone.utc)

        result = await self.collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        doc["id"] = str(result.inserted_id)
        logger.info("Saved IoT telemetry reading to MongoDB ID: %s", doc["id"])
        return doc

    async def get_latest(self) -> Optional[dict[str, Any]]:
        """Get the most recent IoT sensor reading from MongoDB."""
        doc = await self.collection.find_one(sort=[("timestamp", -1)])
        if doc:
            doc["id"] = str(doc["_id"])
        return doc

    async def get_history(self, limit: int = 50) -> list[dict[str, Any]]:
        """Get past IoT sensor readings ordered by most recent."""
        cursor = self.collection.find().sort("timestamp", -1).limit(limit)
        items = []
        async for doc in cursor:
            doc["id"] = str(doc["_id"])
            items.append(doc)
        return items
