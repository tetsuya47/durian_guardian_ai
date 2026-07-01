from __future__ import annotations

import logging

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories import (
    DiseaseRepository,
    FarmRepository,
    NotificationRepository,
    RiskRepository,
    TreeRepository,
)
from app.repositories.weather_repository import WeatherRepository
from app.schemas import AlertBrief, DashboardOut, DetectionBrief, KpiData, RiskTrendItem

logger = logging.getLogger(__name__)


class DashboardService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.farm_repo = FarmRepository(db)
        self.tree_repo = TreeRepository(db)
        self.disease_repo = DiseaseRepository(db)
        self.risk_repo = RiskRepository(db)
        self.notification_repo = NotificationRepository(db)
        self.weather_repo = WeatherRepository(db)

    async def get_dashboard(self, user_id: str) -> DashboardOut:
        farms, _ = await self.farm_repo.list_by_owner(user_id, page=1, per_page=100)
        total_farms = len(farms)

        farm_ids = [f["id"] for f in farms]
        total_trees = await self.tree_repo.count_by_farms(farm_ids) if farm_ids else 0
        diseased_trees = await self.disease_repo.count_diseased()
        healthy_trees = max(0, total_trees - diseased_trees)
        high_risk_trees = await self.risk_repo.count_high_risk(threshold=0.7)

        recent_detection = await self._get_recent_detections()
        alerts = await self._get_alerts()
        weather = await self._get_weather(farm_ids)
        risk_trend = await self._get_risk_trend()

        return DashboardOut(
            kpi=KpiData(
                total_farms=total_farms,
                total_trees=total_trees,
                healthy_trees=healthy_trees,
                diseased_trees=diseased_trees,
                high_risk_trees=high_risk_trees,
            ),
            recent_detection=recent_detection,
            alerts=alerts,
            weather=weather,
            risk_trend=risk_trend,
        )

    async def _get_recent_detections(self) -> list[DetectionBrief]:
        docs, _ = await self.disease_repo.list(
            page=1, per_page=10, sort=[("created_at", -1)]
        )
        result = []
        for doc in docs:
            tree = await self.tree_repo.get(doc["tree_id"])
            tree_code = tree["tree_code"] if tree else "N/A"
            result.append(
                DetectionBrief(
                    disease=doc["disease_name"],
                    confidence=doc["confidence"],
                    severity=doc["severity"],
                    tree_code=tree_code,
                    created_at=doc["created_at"],
                )
            )
        return result

    async def _get_alerts(self) -> list[AlertBrief]:
        docs, _ = await self.notification_repo.list(
            page=1, per_page=20, sort=[("created_at", -1)]
        )
        return [
            AlertBrief(
                title=doc["title"],
                content=doc["content"],
                created_at=doc["created_at"],
            )
            for doc in docs
        ]

    async def _get_weather(self, farm_ids: list[str]) -> dict:
        if not farm_ids:
            farm_ids = ["1"]
        farm_id = farm_ids[0]
        try:
            docs = await self.weather_repo.list_by_farm(farm_id, limit_days=7)
            if not docs:
                return {"note": "No weather data available"}
            return {"farm_id": farm_id, "days": docs}
        except Exception as e:
            logger.warning("Failed to fetch weather: %s", e)
            return {"note": "Weather data unavailable"}

    async def _get_risk_trend(self) -> list[RiskTrendItem]:
        pipeline = [
            {
                "$group": {
                    "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
                    "avg_risk": {"$avg": "$risk_score"},
                }
            },
            {"$sort": {"_id": 1}},
            {"$limit": 14},
        ]
        try:
            cursor = self.db["risk_assessments"].aggregate(pipeline)
            items = []
            async for doc in cursor:
                items.append(
                    RiskTrendItem(date=str(doc["_id"]), avg_risk=round(doc["avg_risk"], 4))
                )
            return items
        except Exception as e:
            logger.warning("Failed to compute risk trend: %s", e)
            return []

    async def get_heatmap(self) -> list[dict]:
        import random

        items = []
        pipeline = [
            {"$sort": {"created_at": -1}},
            {"$group": {"_id": "$tree_id", "risk_score": {"$first": "$risk_score"}}},
        ]
        try:
            cursor = self.db["risk_assessments"].aggregate(pipeline)
            async for doc in cursor:
                tree = await self.tree_repo.get(doc["_id"])
                if tree and tree.get("gps_lat") and tree.get("gps_lng"):
                    risk_val = doc["risk_score"]
                    if risk_val >= 0.7:
                        status = "High"
                    elif risk_val >= 0.3:
                        status = "Medium"
                    else:
                        status = "Low"
                    items.append(
                        {
                            "tree_id": doc["_id"],
                            "lat": tree["gps_lat"],
                            "lng": tree["gps_lng"],
                            "risk": round(risk_val * 100),
                            "status": status,
                        }
                    )
        except Exception as e:
            logger.warning("Failed to compute heatmap: %s", e)

        if not items:
            items = [
                {"tree_id": "mock_1", "lat": 10.8231, "lng": 106.6297, "risk": 92, "status": "High"},
                {"tree_id": "mock_2", "lat": 10.8235, "lng": 106.6300, "risk": 45, "status": "Medium"},
                {"tree_id": "mock_3", "lat": 10.8228, "lng": 106.6293, "risk": 15, "status": "Low"},
            ]
        return items
