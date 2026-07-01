from __future__ import annotations

import logging

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.exceptions import NotFoundException
from app.repositories import FarmRepository
from app.schemas import FarmCreate, FarmUpdate

logger = logging.getLogger(__name__)


class FarmService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.repo = FarmRepository(db)

    async def list_farms(
        self,
        user_id: str,
        page: int = 1,
        per_page: int = 20,
        keyword: str | None = None,
    ) -> tuple[list[dict], int]:
        logger.info("Listing farms for user %s (page=%d, keyword=%s)", user_id, page, keyword)
        return await self.repo.list_by_owner(user_id, page, per_page, keyword=keyword)

    async def get_farm(self, farm_id: str) -> dict:
        farm = await self.repo.get(farm_id)
        if not farm:
            raise NotFoundException("Farm not found")
        return farm

    async def create_farm(self, user_id: str, data: FarmCreate) -> dict:
        farm_id = await self.repo.create(
            {
                "name": data.name,
                "address": data.address,
                "gps_lat": data.gps_lat,
                "gps_lng": data.gps_lng,
                "area": data.area,
                "owner_id": user_id,
            }
        )
        farm = await self.repo.get(farm_id)
        if not farm:
            raise NotFoundException("Farm not found after creation")
        logger.info("Farm created: %s by user %s", farm_id, user_id)
        return farm

    async def update_farm(self, farm_id: str, data: FarmUpdate) -> dict:
        update_data = data.model_dump(exclude_none=True)
        farm = await self.repo.update(farm_id, update_data)
        if not farm:
            raise NotFoundException("Farm not found")
        logger.info("Farm updated: %s", farm_id)
        return farm

    async def delete_farm(self, farm_id: str) -> None:
        deleted = await self.repo.delete(farm_id)
        if not deleted:
            raise NotFoundException("Farm not found")
        logger.info("Farm deleted: %s", farm_id)
