"""Risk Prediction Service integrating Model 3 Random Forest inference with MongoDB data."""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.ai.predictor_model3 import Model3Predictor
from app.repositories.tree_repository import TreeRepository
from app.repositories.weather_repository import WeatherRepository
from app.repositories.detection_result_repository import DetectionResultRepository
from app.services.weather_service import WeatherService

logger = logging.getLogger(__name__)


class RiskPredictionService:
    """Service orchestrating multi-modal feature assembly and Model 3 Random Forest risk inference."""

    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.tree_repo = TreeRepository(db)
        self.weather_repo = WeatherRepository(db)
        self.detection_repo = DetectionResultRepository(db)
        self.weather_service = WeatherService(db)
        self._predictor = Model3Predictor()

    async def predict_tree_risk(
        self,
        tree_id: str | None = None,
        lat: float = WeatherService.DEFAULT_LAT,
        lon: float = WeatherService.DEFAULT_LON,
        override_weather: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Fetch tree metadata, history, & weather_cache to build feature vector and run Model 3.

        Returns:
            Dict containing:
                - risk_level: str
                - risk_score: float
                - probabilities: dict
                - top_factors: list
                - weather_used: dict
                - tree_info: dict
        """
        # 1. Fetch live or cached weather
        weather_data = override_weather
        if not weather_data:
            try:
                weather_data = await self.weather_service.get_current_weather(
                    lat=lat, lon=lon
                )
            except Exception as exc:
                logger.warning("Failed to fetch weather for risk prediction: %s", exc)
                weather_data = {}

        temp = float(weather_data.get("temp_celsius", 28.0))
        humidity = float(weather_data.get("humidity_percent", 75.0))
        rainfall = float(weather_data.get("rainfall_mm", 10.0))

        # 2. Fetch Tree entity if tree_id provided
        tree = None
        if tree_id and ObjectId.is_valid(tree_id):
            tree = await self.tree_repo.get(tree_id)

        tree_age = 5
        variety = "Monthong"
        health_status = "Khỏe mạnh"
        if tree:
            variety = tree.get("variety", "Monthong")
            health_status = tree.get("health_status", "Khỏe mạnh")
            created_at = tree.get("created_at")
            if isinstance(created_at, datetime):
                now = datetime.now(timezone.utc)
                diff_years = max(1, now.year - created_at.year)
                tree_age = diff_years

        # 3. Fetch latest detection result / inspection for tree
        predicted_disease = "Khỏe mạnh"
        confidence = 85.0
        historical_count = 0
        days_since_inspection = 30
        days_since_treatment = 60

        if tree_id:
            try:
                latest_dets = await self.detection_repo.list_by_tree(tree_id, limit=5)
                if latest_dets:
                    latest = latest_dets[0]
                    predicted_disease = latest.get("prediction", "Khỏe mạnh")
                    confidence = float(latest.get("confidence", 85.0))
                    historical_count = len(latest_dets)

                    last_date = latest.get("created_at")
                    if isinstance(last_date, datetime):
                        now = datetime.now(timezone.utc)
                        days_since_inspection = max(0, (now - last_date).days)
            except Exception as exc:
                logger.warning("Failed to fetch tree detection history: %s", exc)

        # 4. Determine season based on current month
        month = datetime.now(timezone.utc).month
        season = "Mưa" if 5 <= month <= 10 else "Khô"

        # 5. Assemble 14 input features matching Model 3 schema
        feature_dict = {
            "temperature": temp,
            "humidity": humidity,
            "rainfall": rainfall,
            "tree_age": tree_age,
            "variety": variety,
            "health_status": health_status,
            "predicted_disease": predicted_disease,
            "confidence": confidence,
            "season": season,
            "density_per_hectare": 50.0,
            "days_since_last_inspection": days_since_inspection,
            "days_since_last_treatment": days_since_treatment,
            "historical_disease_count": historical_count,
            "historical_disease_frequency": round(historical_count / max(1, tree_age), 2),
        }

        # 6. Run Model 3 Random Forest inference
        prediction_result = self._predictor.predict(feature_dict)

        # Map Model 3 risk level to DGA Fungal Risk format
        risk_level_raw = prediction_result["risk_level"]
        fungal_risk_map = {
            "Khỏe mạnh": "LOW",
            "Nguy cơ": "MEDIUM",
            "Bệnh nhẹ": "MEDIUM",
            "Bệnh nặng": "HIGH",
        }
        fungal_disease_risk = fungal_risk_map.get(risk_level_raw, "MEDIUM")

        prediction_result["fungal_disease_risk"] = fungal_disease_risk
        prediction_result["weather_used"] = {
            "temperature": temp,
            "humidity": humidity,
            "rainfall": rainfall,
        }
        prediction_result["tree_info"] = {
            "tree_id": tree_id,
            "variety": variety,
            "tree_age": tree_age,
        }

        logger.info(
            "Model 3 Risk Prediction completed for tree_id=%s: level=%s, score=%.4f",
            tree_id,
            risk_level_raw,
            prediction_result["risk_score"],
        )

        return prediction_result
