from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.farm_activity_repository import FarmActivityRepository
from app.repositories.tree_repository import TreeRepository
from app.repositories.detection_result_repository import DetectionResultRepository

logger = logging.getLogger(__name__)


@dataclass
class DecisionContext:
    tree_id: str
    disease_name: str
    disease_code: str | None = None
    confidence: float = 0.0
    severity: str = "Low"
    risk_score: float = 0.0
    risk_level: str = "Low"

    # Weather context
    rain_today: bool = False
    rain_tomorrow: bool = False
    rainfall_mm: float = 0.0
    humidity: float = 70.0
    temp_celsius: float = 28.0

    # Tree history & recurrence
    tree_age_years: int = 5
    growth_stage: str = "vegetative"
    tree_recurrence_count: int = 0
    days_since_last_scan: int = 999

    # Farm Activity context
    last_pesticide_activity: dict[str, Any] | None = None
    last_fertilizer_activity: dict[str, Any] | None = None
    days_since_last_spray: int = 999
    days_since_last_fertilizer: int = 999
    days_to_harvest: int = 999


class ContextEngine:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.farm_activity_repo = FarmActivityRepository(db)
        self.tree_repo = TreeRepository(db)
        self.detection_repo = DetectionResultRepository(db)

    async def build_context(
        self,
        tree_id: str,
        disease_name: str,
        confidence: float,
        severity: str,
        risk_score: float = 0.0,
        risk_level: str = "Low",
        weather_info: dict[str, Any] | None = None,
    ) -> DecisionContext:
        """Aggregates Disease Result, Risk Score, Weather, Tree History, Farm Activity & Growth Stage."""
        now = datetime.now(timezone.utc)

        # 1. Weather info
        weather_info = weather_info or {}
        rain_today = bool(weather_info.get("rain_today", False))
        rain_tomorrow = bool(weather_info.get("rain_tomorrow", False))
        rainfall_mm = float(weather_info.get("rainfall_mm", 0.0))
        humidity = float(weather_info.get("humidity", 75.0))
        temp_celsius = float(weather_info.get("temp_celsius", 28.0))

        # 2. Tree Info & History
        tree_info = await self.tree_repo.get(tree_id) or {}
        growth_stage = tree_info.get("growth_stage", "vegetative")
        tree_age = int(tree_info.get("age_years", 5))

        # Scan History / Recurrence
        recent_scans, _ = await self.detection_repo.list(
            filter_query={"tree_id": tree_id, "disease": disease_name},
            per_page=50,
        )
        recurrence_count = len(recent_scans)

        days_since_last_scan = 999
        if recent_scans:
            last_scan_dt = recent_scans[0].get("created_at")
            if isinstance(last_scan_dt, datetime):
                days_since_last_scan = (now - last_scan_dt).days

        # 3. Farm Activities (Pesticide & Fertilizer)
        last_pesticide = await self.farm_activity_repo.get_last_activity_by_type(
            tree_id, "Pesticide"
        )
        last_fertilizer = await self.farm_activity_repo.get_last_activity_by_type(
            tree_id, "Fertilizer"
        )

        days_since_last_spray = 999
        if last_pesticide and "activity_date" in last_pesticide:
            p_date = last_pesticide["activity_date"]
            if isinstance(p_date, datetime):
                days_since_last_spray = (now - p_date).days

        days_since_last_fertilizer = 999
        if last_fertilizer and "activity_date" in last_fertilizer:
            f_date = last_fertilizer["activity_date"]
            if isinstance(f_date, datetime):
                days_since_last_fertilizer = (now - f_date).days

        context = DecisionContext(
            tree_id=tree_id,
            disease_name=disease_name,
            confidence=confidence,
            severity=severity,
            risk_score=risk_score,
            risk_level=risk_level,
            rain_today=rain_today,
            rain_tomorrow=rain_tomorrow,
            rainfall_mm=rainfall_mm,
            humidity=humidity,
            temp_celsius=temp_celsius,
            tree_age_years=tree_age,
            growth_stage=growth_stage,
            tree_recurrence_count=recurrence_count,
            days_since_last_scan=days_since_last_scan,
            last_pesticide_activity=last_pesticide,
            last_fertilizer_activity=last_fertilizer,
            days_since_last_spray=days_since_last_spray,
            days_since_last_fertilizer=days_since_last_fertilizer,
        )

        logger.info(
            "Built Decision Context for tree %s: disease=%s, risk=%.1f%%, spray_ago=%dd",
            tree_id,
            disease_name,
            risk_score,
            days_since_last_spray,
        )
        return context
