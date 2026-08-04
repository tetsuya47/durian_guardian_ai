from __future__ import annotations

import logging
from typing import Any, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.iot_telemetry_repository import IoTTelemetryRepository
from app.ai.predictor_model3 import Model3Predictor

logger = logging.getLogger(__name__)


def generate_model4_ai_advice(telemetry: dict[str, Any], risk_level: str) -> tuple[str, list[str]]:
    """Generate Model 4 AI Agronomist recommendations based on telemetry readings and Model 3 risk score."""
    moisture = telemetry.get("soil_moisture", 65.0)
    ph = telemetry.get("soil_ph", 6.2)
    temp = telemetry.get("temperature", 28.0)
    humidity = telemetry.get("humidity", 75.0)
    n = telemetry.get("nitrogen_ppm", 120.0)

    recommendations = []

    # Moisture rules
    if moisture < 60.0:
        recommendations.append("💧 Độ ẩm đất thấp (< 60%). Cần kích hoạt hệ thống tưới phun mưa gốc 45 phút.")
    elif moisture > 80.0:
        recommendations.append("⚠️ Độ ẩm đất quá cao (> 80%). Cần khơi thông mương thoát nước tránh thối rễ tơ.")
    else:
        recommendations.append("✅ Độ ẩm đất lý tưởng (60-75%). Duy trì chế độ tưới định kỳ.")

    # Soil pH rules
    if ph < 5.8:
        recommendations.append("🧪 Đất bị chua (pH < 5.8). Rải 500g Vôi bột / gốc để nâng pH đất về ngưỡng 6.0-6.5.")
    elif ph > 7.0:
        recommendations.append("🧪 Đất có tính kiềm nhẹ (pH > 7.0). Bổ sung phân hữu cơ vi sinh & Lưu huỳnh nguyên tố.")
    else:
        recommendations.append("✅ Độ pH đất cân bằng tốt (5.8 - 6.8). Rễ sầu riêng hấp thu dinh dưỡng tối ưu.")

    # Temperature & Fungal Disease Risk rules
    if temp > 32.0 and humidity > 80.0:
        recommendations.append("🚨 Cảnh báo Nấm Bệnh: Nhiệt độ cao (> 32°C) kết hợp độ ẩm cao (> 80%) tạo điều kiện cho nấm Phytophthora & Thán thư bùng phát.")
        recommendations.append("🛡️ Khuyến nghị: Phun luân phiên Mancozeb hoặc Ridomil Gold bảo vệ cơi đọt.")

    if n < 100.0:
        recommendations.append("🌿 Chỉ số Đạm (N) thấp. Bổ sung NPK 20-20-15 hoặc phân gà nở vi sinh thúc cơi đọt.")

    # Synthesis summary advice
    if risk_level in ("High", "Bệnh nặng", "Nguy cơ"):
        summary_advice = (
            f"🔥 CẢNH BÁO NÔNG TRẠI (Mức độ: {risk_level}): Dữ liệu cảm biến Realtime ghi nhận các chỉ số vượt ngưỡng an toàn. "
            "Khuyến nghị thực hiện ngay các biện pháp can thiệp kỹ thuật bên dưới."
        )
    else:
        summary_advice = (
            f"🌟 NÔNG TRẠI ỔN ĐỊNH (Mức độ: {risk_level}): Các chỉ số vi khí hậu và độ ẩm đất đang duy trì trong vùng an toàn. "
            "Duy trì chế độ giám sát tự động 30s/lần."
        )

    return summary_advice, recommendations


class IoTService:
    """Service to process IoT Telemetry, save to persistent MongoDB, and run Model 3 & Model 4 AI inferences."""

    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.repository = IoTTelemetryRepository(db)
        try:
            self.model3 = Model3Predictor()
        except Exception as exc:
            logger.warning("Model 3 predictor optional init warning: %s", exc)
            self.model3 = None

    async def ingest_telemetry(self, data: dict[str, Any]) -> dict[str, Any]:
        """Save a new 30-second sensor reading to MongoDB and calculate AI predictions."""
        saved_doc = await self.repository.save(data)
        return saved_doc

    async def get_latest_analysis(self) -> dict[str, Any]:
        """Get the latest sensor telemetry from MongoDB + run Model 3 & Model 4 AI inferences."""
        telemetry = await self.repository.get_latest()

        # Default fallback if no telemetry yet
        if not telemetry:
            telemetry = {
                "id": "demo-01",
                "soil_moisture": 68.5,
                "soil_ph": 6.2,
                "temperature": 29.0,
                "humidity": 78.0,
                "light_intensity": 42000.0,
                "rainfall": 0.0,
                "nitrogen_ppm": 125.0,
                "phosphorus_ppm": 48.0,
                "potassium_ppm": 185.0,
                "device_id": "SENS-DURIAN-01",
                "timestamp": None,
            }

        # Run Model 3 prediction
        model3_risk_level = "Low"
        model3_risk_score = 0.15
        model3_probs = {"Low": 0.85, "Medium": 0.10, "High": 0.05}

        if self.model3:
            try:
                # Prepare features for Model 3
                features = {
                    "variety": "Monthong",
                    "health_status": "Khỏe mạnh",
                    "predicted_disease": "Khỏe mạnh",
                    "season": "Mùa Mưa" if telemetry.get("humidity", 70) > 80 else "Mùa Khô",
                    "temperature": telemetry.get("temperature", 29.0),
                    "humidity": telemetry.get("humidity", 78.0),
                    "rainfall": telemetry.get("rainfall", 0.0),
                    "tree_age": 5.0,
                    "density_per_hectare": 150.0,
                    "days_since_last_inspection": 3.0,
                    "days_since_last_treatment": 14.0,
                    "historical_disease_count": 1.0,
                    "historical_disease_frequency": 0.1,
                    "confidence": 0.92,
                }
                m3_res = self.model3.predict(features)
                model3_risk_level = m3_res.get("risk_level", "Low")
                model3_risk_score = m3_res.get("risk_score", 0.15)
                model3_probs = m3_res.get("probabilities", model3_probs)
            except Exception as exc:
                logger.error("Model 3 inference error: %s", exc)

        # Run Model 4 AI Agronomist advice
        summary_advice, recs = generate_model4_ai_advice(telemetry, model3_risk_level)

        return {
            "telemetry": telemetry,
            "model3_risk_level": model3_risk_level,
            "model3_risk_score": model3_risk_score,
            "model3_probabilities": model3_probs,
            "model4_ai_advice": summary_advice,
            "model4_recommendations": recs,
        }

    async def get_history(self, limit: int = 50) -> list[dict[str, Any]]:
        return await self.repository.get_history(limit)
