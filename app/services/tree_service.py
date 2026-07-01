from __future__ import annotations

import logging

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.exceptions import NotFoundException
from app.repositories import (
    DiseaseRepository,
    RiskRepository,
    TreeRepository,
)
from app.repositories.weather_repository import WeatherRepository
from app.schemas import TreeCreate, TreeUpdate

logger = logging.getLogger(__name__)


class TreeService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.repo = TreeRepository(db)
        self.disease_repo = DiseaseRepository(db)
        self.risk_repo = RiskRepository(db)
        self.weather_repo = WeatherRepository(db)

    async def list_trees(
        self,
        zone_id: str | None = None,
        farm_id: str | None = None,
        keyword: str | None = None,
        status: str | None = None,
        risk: str | None = None,
        page: int = 1,
        per_page: int = 20,
    ) -> tuple[list[dict], int]:
        logger.info("Listing trees (zone=%s, farm=%s, keyword=%s)", zone_id, farm_id, keyword)
        return await self.repo.list_filtered(
            zone_id=zone_id,
            farm_id=farm_id,
            keyword=keyword,
            status=status,
            risk_level=risk,
            page=page,
            per_page=per_page,
        )

    async def get_tree(self, tree_id: str) -> dict:
        tree = await self.repo.get(tree_id)
        if not tree:
            raise NotFoundException("Tree not found")
        return tree

    async def create_tree(self, data: TreeCreate) -> dict:
        tree_id = await self.repo.create(
            {
                "zone_id": data.zone_id,
                "tree_code": data.tree_code,
                "variety": data.variety,
                "planting_date": (
                    data.planting_date.isoformat() if data.planting_date else None
                ),
                "age": data.age,
                "gps_lat": data.gps_lat,
                "gps_lng": data.gps_lng,
            }
        )
        tree = await self.repo.get(tree_id)
        if not tree:
            raise NotFoundException("Tree not found after creation")
        logger.info("Tree created: %s", tree_id)
        return tree

    async def update_tree(self, tree_id: str, data: TreeUpdate) -> dict:
        update_data = data.model_dump(exclude_none=True)
        if "planting_date" in update_data and update_data["planting_date"]:
            update_data["planting_date"] = update_data["planting_date"].isoformat()
        tree = await self.repo.update(tree_id, update_data)
        if not tree:
            raise NotFoundException("Tree not found")
        logger.info("Tree updated: %s", tree_id)
        return tree

    async def delete_tree(self, tree_id: str) -> None:
        deleted = await self.repo.delete(tree_id)
        if not deleted:
            raise NotFoundException("Tree not found")
        logger.info("Tree deleted: %s", tree_id)

    async def get_digital_id(self, tree_id: str) -> dict:
        tree = await self.repo.get(tree_id)
        if not tree:
            raise NotFoundException("Tree not found")

        diseases, _ = await self.disease_repo.list_by_tree(tree_id, page=1, per_page=50)
        latest_risk = await self.risk_repo.get_latest_by_tree(tree_id)
        zone = None
        if tree.get("zone_id"):
            zone_doc = await self.db["zones"].find_one({"_id": tree["zone_id"]})
            if zone_doc:
                zone_doc["id"] = str(zone_doc.pop("_id"))
                zone = zone_doc

        farm = None
        if zone:
            farm_doc = await self.db["farms"].find_one({"_id": zone["farm_id"]})
            if farm_doc:
                farm_doc["id"] = str(farm_doc.pop("_id"))
                farm = farm_doc

        weather = None
        if farm:
            weather_docs = await self.weather_repo.list_by_farm(farm["id"], limit_days=7)
            weather = weather_docs if weather_docs else None

        recommendation = None
        if latest_risk:
            rec = await self.risk_repo.get(latest_risk["id"])
            if rec:
                recommendation = rec.get("recommendation")

        images = [d.get("image_url") for d in diseases if d.get("image_url")]

        logger.info("Digital ID fetched for tree %s", tree_id)
        return {
            "tree": tree,
            "disease_history": diseases,
            "latest_risk": latest_risk,
            "weather": weather,
            "images": images,
            "recommendation": recommendation,
        }
