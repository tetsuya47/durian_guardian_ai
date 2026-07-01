from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.ai.service import OllamaService
from app.repositories import (
    DiseaseRepository,
    TreeRepository,
    WeatherRepository,
)
from app.repositories.zone_repository import ZoneRepository


class ChatService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.tree_repo = TreeRepository(db)
        self.disease_repo = DiseaseRepository(db)
        self.weather_repo = WeatherRepository(db)
        self.zone_repo = ZoneRepository(db)
        self.ollama = OllamaService()

    async def ask(self, question: str, tree_id: str) -> str:
        tree = await self.tree_repo.get(tree_id)
        tree_info = f"Tree #{tree_id}"
        if tree:
            tree_info = (
                f"Tree Code: {tree.get('tree_code', 'N/A')}, "
                f"Variety: {tree.get('variety', 'N/A')}, "
                f"Age: {tree.get('age', 'N/A')} years"
            )

        diseases, _ = await self.disease_repo.list_by_tree(
            tree_id, page=1, per_page=5
        )
        disease_info = "No disease history"
        if diseases:
            disease_info = "; ".join(
                f"{d['disease_name']} (severity: {d['severity']}, "
                f"confidence: {d['confidence']})"
                for d in diseases
            )

        farm_id = "1"
        if tree and "zone_id" in tree:
            zone = await self.zone_repo.get(tree["zone_id"])
            if zone:
                farm_id = zone.get("farm_id", "1")

        weather_data = await self.weather_repo.list_by_farm(farm_id, limit_days=3)
        weather_info = "No weather data"
        if weather_data:
            weather_info = "; ".join(
                f"{w.get('weather_date', 'N/A')}: "
                f"temp={w.get('temperature', 'N/A')}C, "
                f"humidity={w.get('humidity', 'N/A')}%, "
                f"rainfall={w.get('rainfall', 'N/A')}mm"
                for w in weather_data
            )

        prompt = (
            f"You are an AI Agronomist specializing in durian farming. "
            f"Answer the following question based on the data provided.\n\n"
            f"Farmer Question: {question}\n\n"
            f"Tree Information:\n{tree_info}\n\n"
            f"Disease History:\n{disease_info}\n\n"
            f"Weather Data (last 3 days):\n{weather_info}\n\n"
            f"Provide practical, actionable advice for the farmer."
        )

        return await self.ollama.chat(prompt)
