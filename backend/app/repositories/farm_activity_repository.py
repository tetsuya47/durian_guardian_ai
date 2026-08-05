from __future__ import annotations

from typing import Any
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.repositories.base import BaseRepository


class FarmActivityRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "farm_activities")

    async def get_recent_activities_for_tree(
        self, tree_id: str, limit: int = 10
    ) -> list[dict[str, Any]]:
        """Get recent farm activities affecting a specific tree_id, sorted newest first."""
        filter_query = {
            "$or": [
                {"tree_ids": tree_id},
                {"tree_ids": []},
                {"tree_ids": None},
            ]
        }
        docs, _ = await self.list(
            filter_query=filter_query,
            page=1,
            per_page=limit,
            sort=[("activity_date", -1)],
        )
        return docs

    async def get_last_activity_by_type(
        self, tree_id: str, activity_type: str
    ) -> dict[str, Any] | None:
        """Get the latest activity of a specific type (e.g. Pesticide, Fertilizer) for a tree."""
        filter_query = {
            "activity_type": {"$regex": f"^{activity_type}$", "$options": "i"},
            "$or": [
                {"tree_ids": tree_id},
                {"tree_ids": []},
                {"tree_ids": None},
            ]
        }
        docs, _ = await self.list(
            filter_query=filter_query,
            page=1,
            per_page=1,
            sort=[("activity_date", -1)],
        )
        return docs[0] if docs else None
