from __future__ import annotations

import logging
from typing import Any, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.iot_telemetry_repository import IoTTelemetryRepository
from app.ai.predictor_model3 import Model3Predictor

logger = logging.getLogger(__name__)


def generate_model4_ai_advice(telemetry: dict[str, Any], risk_level: str, risk_score: float) -> tuple[str, list[str]]:
    """Generate Model 4 AI Agronomist recommendations based on telemetry readings and 5% step Model 3 risk percentage."""
    moisture = telemetry.get("soil_moisture", 68.5)
    ph = telemetry.get("soil_ph", 6.2)
    temp = telemetry.get("temperature", 28.5)
    humidity = telemetry.get("humidity", 78.0)
    n = telemetry.get("nitrogen_ppm", 120.0)

    recommendations = []
    risk_percent = round(risk_score * 100, 1)
    step_bucket = int(risk_percent // 5) * 5  # Step of 5%: 0, 5, 10, 15, ..., 95

    # ── Dynamic 5% Increment Advice Mapping ─────────────────────────────────
    advice_buckets = {
        0: f"🌟 NÔNG TRẠI AN TOÀN TUYỆT ĐỐI (Rủi ro: {risk_percent}%): Chỉ số cảm biến ở vùng sinh học hoàn hảo. Cây sầu riêng khỏe mạnh.",
        5: f"🌟 NÔNG TRẠI RẤT TỐT (Rủi ro: {risk_percent}%): Vi khí hậu ổn định. Cơi đọt xanh mướt, rễ hấp thu dinh dưỡng tối ưu.",
        10: f"✅ NÔNG TRẠI ỔN ĐỊNH (Rủi ro: {risk_percent}%): Đạt chuẩn an toàn nông nghiệp vi sinh. Duy trì lịch tưới tự động 30s.",
        15: f"✅ NÔNG TRẠI AN TOÀN (Rủi ro: {risk_percent}%): Không phát hiện áp lực dịch bệnh. Khuyến nghị duy trì chăm sóc định kỳ.",
        20: f"⚠️ BẮT ĐẦU CHÚ Ý (Rủi ro: {risk_percent}%): Nhiệt độ & độ ẩm bắt đầu có biến động nhẹ. Theo dõi cơi đọt 7 ngày/lần.",
        25: f"⚠️ CẢNH BÁO NHẸ (Rủi ro: {risk_percent}%): Độ ẩm đất/không khí đang thay đổi. Nên rải 300g Vôi bột nâng pH rễ.",
        30: f"⚠️ NGUY CƠ NHẸ (Rủi ro: {risk_percent}%): Áp lực bào tử nấm nhẹ. Bổ sung vi sinh Trichoderma thúc đẩy hệ vi sinh đất.",
        35: f"🔔 NGUY CƠ TRUNG BÌNH THẤP (Rủi ro: {risk_percent}%): Điều kiện thời tiết thuận lợi cho Rầy nhảy & Bọ trĩ phát triển.",
        40: f"🔔 NGUY CƠ TRUNG BÌNH (Rủi ro: {risk_percent}%): Độ ẩm kéo dài kích thích nấm lá. Phun phòng ngừa Mancozeb / Hexaconazole.",
        45: f"🔔 NGUY CƠ TRUNG BÌNH CAO (Rủi ro: {risk_percent}%): Chỉ số nguy cơ vượt 45%. Giảm 20% lượng tưới & tỉa thoáng gầm cây.",
        50: f"⚡ CẢNH BÁO NẤM BỆNH (Rủi ro: {risk_percent}%): Mầm nấm Phytophthora bắt đầu xuất hiện. Phun bảo vệ mặt dưới lá.",
        55: f"⚡ CẢNH BÁO TĂNG CAO (Rủi ro: {risk_percent}%): Nguy cơ cháy lá đốm mắt cua & Thán thư. Tạm dừng bón đạm (N) dư thừa.",
        60: f"🔥 BÁO ĐỘNG BỆNH HẠI (Rủi ro: {risk_percent}%): Áp lực dịch bệnh vượt 60%! Kiểm tra cành gốc & khơi thông rãnh mương.",
        65: f"🔥 NGUY CƠ NẶNG (Rủi ro: {risk_percent}%): Nguy cơ xì mủ nứt thân & thối rễ tơ. Phun Fosetyl-Al quét trực tiếp thân gốc.",
        70: f"🔥 CẢNH BÁO NẤM NẶNG (Rủi ro: {risk_percent}%): Nấm bệnh tấn công cơi đọt & gốc cây. Phun luân phiên Metalaxyl + Mancozeb.",
        75: f"🚨 BÁO ĐỘNG ĐỎ CẤP 1 (Rủi ro: {risk_percent}%): Dịch bệnh Phytophthora lây lan nhanh! Cách ly vùng cây ốm ngay lập tức.",
        80: f"🚨 BÁO ĐỘNG ĐỎ CẤP 2 (Rủi ro: {risk_percent}%): Nguy cơ thối rễ hàng loạt! Phun đặc trị Ridomil Gold + Agrispon gấp.",
        85: f"🚨 NGUY CƠ NGHÊM TRỌNG (Rủi ro: {risk_percent}%): Dịch bệnh Phytophthora & Thối quả bùng phát toàn diện nông trại!",
        90: f"💀 BÁO ĐỘNG NGHÊM TRỌNG CẤP CAO (Rủi ro: {risk_percent}%): Cắt bỏ tiêu hủy cành nhiễm thối khô, rải Vôi sát trùng toàn vườn.",
        95: f"💀 THẢM HỌA DỊCH BỆNH (Rủi ro: {risk_percent}%): Can thiệp khẩn cấp toàn bộ hệ thống bảo vệ thực vật & khoanh vùng dập dịch!",
    }

    summary_advice = advice_buckets.get(step_bucket, f"⚠️ CẢNH BÁO BỆNH (Rủi ro: {risk_percent}%): Cần theo dõi chỉ số nông trại.")

    # ── Moisture Specific Rules ─────────────────────────────────────────────
    if moisture < 60.0:
        recommendations.append("💧 Độ ẩm đất thấp (< 60%). Cần kích hoạt hệ thống tưới phun mưa gốc 45 phút.")
    elif moisture > 80.0:
        recommendations.append("⚠️ Độ ẩm đất quá cao (> 80%). Cần khơi thông mương thoát nước tránh thối rễ tơ.")
    else:
        recommendations.append("✅ Độ ẩm đất lý tưởng (60-75%). Duy trì chế độ tưới định kỳ.")

    # ── Soil pH Specific Rules ──────────────────────────────────────────────
    if ph < 5.8:
        recommendations.append("🧪 Đất bị chua (pH < 5.8). Rải 500g Vôi bột / gốc để nâng pH đất về 6.0-6.5.")
    elif ph > 7.0:
        recommendations.append("🧪 Đất có tính kiềm nhẹ (pH > 7.0). Bổ sung phân hữu cơ vi sinh & Lưu huỳnh nguyên tố.")
    else:
        recommendations.append("✅ Độ pH đất cân bằng tốt (5.8 - 6.8). Rễ hấp thu dinh dưỡng tối ưu.")

    # ── Dynamic Recommendation per 5% step range ────────────────────────────
    if risk_percent >= 65.0:
        recommendations.append("🛡️ Phun trực tiếp Metalaxyl / Fosetyl-Al quét gốc & mặt dưới lá sầu riêng.")
    elif risk_percent >= 40.0:
        recommendations.append("🌿 Bổ sung phân bón lá giàu Kali & Lân phosphonate nâng cao sức đề kháng.")

    if temp > 32.0 and humidity > 80.0:
        recommendations.append("🚨 Cảnh báo Nấm Bệnh: Nhiệt độ cao (> 32°C) kết hợp độ ẩm cao (> 80%) tạo điều kiện cho nấm Phytophthora & Thán thư bùng phát.")

    if n < 100.0:
        recommendations.append("🌿 Chỉ số Đạm (N) thấp. Bổ sung NPK 20-20-15 hoặc phân gà nở vi sinh thúc cơi đọt.")
    elif n > 150.0 and risk_percent >= 40.0:
        recommendations.append("🚫 Đạm dư thừa trong điều kiện nguy cơ bệnh. Tạm dừng bón đạm; chuyển sang bón Kali & Lân.")

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

        # Dynamic features for Model 3
        temp = telemetry.get("temperature", 28.5)
        hum = telemetry.get("humidity", 78.0)
        rain = telemetry.get("rainfall", 0.0)
        moisture = telemetry.get("soil_moisture", 68.5)
        ph = telemetry.get("soil_ph", 6.2)

        # Dynamic health status determination based on sensor values
        if temp > 33.0 or hum > 85.0 or moisture < 55.0 or ph < 5.5:
            health_status = "Nguy cơ"
            pred_disease = "Nấm rễ Phytophthora"
            hist_count = 3.0
            hist_freq = 0.4
        elif temp > 31.0 or hum > 82.0 or moisture < 60.0 or ph < 5.8:
            health_status = "Bệnh nhẹ"
            pred_disease = "Thán thư"
            hist_count = 2.0
            hist_freq = 0.2
        else:
            health_status = "Khỏe mạnh"
            pred_disease = "Khỏe mạnh"
            hist_count = 1.0
            hist_freq = 0.05

        model3_risk_level = "Low"
        model3_risk_score = 0.12
        model3_probs = {"Low": 0.88, "Medium": 0.08, "High": 0.04}

        if self.model3:
            try:
                features = {
                    "variety": "Monthong",
                    "health_status": health_status,
                    "predicted_disease": pred_disease,
                    "season": "Mùa Mưa" if hum > 80.0 or rain > 0.0 else "Mùa Khô",
                    "temperature": temp,
                    "humidity": hum,
                    "rainfall": rain,
                    "tree_age": 5.0,
                    "density_per_hectare": 150.0,
                    "days_since_last_inspection": 3.0,
                    "days_since_last_treatment": 14.0,
                    "historical_disease_count": hist_count,
                    "historical_disease_frequency": hist_freq,
                    "confidence": 0.92,
                }
                m3_res = self.model3.predict(features)
                model3_risk_level = m3_res.get("risk_level", "Low")
                model3_risk_score = m3_res.get("risk_score", 0.12)
                model3_probs = m3_res.get("probabilities", model3_probs)
            except Exception as exc:
                logger.error("Model 3 inference error: %s", exc)

        # Run Model 4 AI Agronomist advice based on telemetry & risk percentage
        summary_advice, recs = generate_model4_ai_advice(telemetry, model3_risk_level, model3_risk_score)

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
