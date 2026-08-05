from __future__ import annotations

import re
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.repositories.base import BaseRepository


class KnowledgeBaseRepository:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.diseases = BaseRepository(db, "diseases")
        self.fertilizers = BaseRepository(db, "fertilizers")
        self.pesticides = BaseRepository(db, "pesticides")
        self.growth_stages = BaseRepository(db, "growth_stages")
        self.weather_rules = BaseRepository(db, "weather_rules")
        self.recommendation_rules = BaseRepository(db, "recommendation_rules")
        self.merchants = BaseRepository(db, "merchants")

    async def get_disease_by_name(self, disease_name: str) -> dict[str, Any] | None:
        """Find disease info by name or code from diseases collection."""
        escaped = re.escape(disease_name)
        filter_query = {
            "$or": [
                {"name": {"$regex": escaped, "$options": "i"}},
                {"name_vi": {"$regex": escaped, "$options": "i"}},
                {"name_en": {"$regex": escaped, "$options": "i"}},
                {"code": {"$regex": escaped, "$options": "i"}},
            ]
        }
        doc = await self.db["diseases"].find_one(filter_query)
        if doc and "_id" in doc:
            doc["id"] = str(doc.pop("_id"))
        return doc

    async def get_pesticide_for_disease(self, disease_code_or_name: str) -> dict[str, Any] | None:
        """Get recommended pesticide from pesticides collection."""
        escaped = re.escape(disease_code_or_name)
        doc = await self.db["pesticides"].find_one(
            {
                "$or": [
                    {"target_diseases": {"$regex": escaped, "$options": "i"}},
                    {"target_disease_codes": {"$regex": escaped, "$options": "i"}},
                ]
            }
        )
        if not doc:
            # Fallback to any default pesticide
            doc = await self.db["pesticides"].find_one({})
        if doc and "_id" in doc:
            doc["id"] = str(doc.pop("_id"))
        return doc

    async def get_fertilizer_recommendation(self, growth_stage: str) -> dict[str, Any] | None:
        """Get fertilizer recommendation for a growth stage."""
        escaped = re.escape(growth_stage)
        doc = await self.db["fertilizers"].find_one(
            {"target_stage": {"$regex": escaped, "$options": "i"}}
        )
        if doc and "_id" in doc:
            doc["id"] = str(doc.pop("_id"))
        return doc

    async def get_active_weather_rules(self) -> list[dict[str, Any]]:
        return await self.get_weather_rules()
    
    async def get_recommendation_rules(self) -> list[dict[str, Any]]:
        """Fetch all recommendation rules from MongoDB recommendation_rules collection."""
        cursor = self.db["recommendation_rules"].find({"is_active": True})
        rules = []
        async for doc in cursor:
            if "_id" in doc:
                doc["id"] = str(doc.pop("_id"))
            rules.append(doc)
        return rules

    async def get_weather_rules(self) -> list[dict[str, Any]]:
        """Fetch all weather rules from MongoDB weather_rules collection."""
        cursor = self.db["weather_rules"].find({"is_active": True})
        rules = []
        async for doc in cursor:
            if "_id" in doc:
                doc["id"] = str(doc.pop("_id"))
            rules.append(doc)
        return rules

    async def get_nearest_merchant(self, district: str | None = None) -> dict[str, Any] | None:
        """Fetch merchant depot from merchants collection."""
        filter_query = {}
        if district:
            filter_query = {"district": {"$regex": re.escape(district), "$options": "i"}}
        doc = await self.db["merchants"].find_one(filter_query)
        if not doc:
            doc = await self.db["merchants"].find_one({})
        if doc and "_id" in doc:
            doc["id"] = str(doc.pop("_id"))
        return doc
