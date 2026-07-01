from __future__ import annotations

import logging

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.exceptions import NotFoundException
from app.repositories import ZoneRepository
from app.schemas import ZoneCreate, ZoneUpdate

logger = logging.getLogger(__name__)


class ZoneService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.repo = ZoneRepository(db)

    async def list_zones(
        self,
        farm_id: str | None = None,
        keyword: str | None = None,
        page: int = 1,
        per_page: int = 20,
    ) -> tuple[list[dict], int]:
        if farm_id:
            logger.info("Listing zones for farm %s", farm_id)
            return await self.repo.list_by_farm(farm_id, page, per_page, keyword=keyword)
        import re

        filter_query = None
        if keyword:
            filter_query = {"name": {"$regex": re.escape(keyword), "$options": "i"}}
        logger.info("Listing all zones (keyword=%s)", keyword)
        return await self.repo.list(
            filter_query=filter_query,
            page=page,
            per_page=per_page,
            sort=[("created_at", -1)],
        )

    async def get_zone(self, zone_id: str) -> dict:
        zone = await self.repo.get(zone_id)
        if not zone:
            raise NotFoundException("Zone not found")
        return zone

    async def create_zone(self, data: ZoneCreate) -> dict:
        zone_id = await self.repo.create(
            {"farm_id": data.farm_id, "name": data.name}
        )
        zone = await self.repo.get(zone_id)
        if not zone:
            raise NotFoundException("Zone not found after creation")
        logger.info("Zone created: %s", zone_id)
        return zone

    async def update_zone(self, zone_id: str, data: ZoneUpdate) -> dict:
        update_data = data.model_dump(exclude_none=True)
        zone = await self.repo.update(zone_id, update_data)
        if not zone:
            raise NotFoundException("Zone not found")
        logger.info("Zone updated: %s", zone_id)
        return zone

    async def delete_zone(self, zone_id: str) -> None:
        deleted = await self.repo.delete(zone_id)
        if not deleted:
            raise NotFoundException("Zone not found")
        logger.info("Zone deleted: %s", zone_id)
