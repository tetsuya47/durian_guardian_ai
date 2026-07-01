from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class ZoneRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "zones")

    async def list_by_farm(
        self, farm_id: str, page: int = 1, per_page: int = 20, keyword: str | None = None
    ) -> tuple[list[dict], int]:
        import re

        filter_query: dict = {"farm_id": farm_id}
        if keyword:
            filter_query["name"] = {"$regex": re.escape(keyword), "$options": "i"}
        return await self.list(
            filter_query=filter_query,
            page=page,
            per_page=per_page,
            sort=[("created_at", -1)],
        )
