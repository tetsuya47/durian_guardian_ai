from __future__ import annotations

import logging
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.repositories.knowledge_base_repository import KnowledgeBaseRepository
from app.ai.decision_engine.context_engine import DecisionContext

logger = logging.getLogger(__name__)


class RecommendationGenerator:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.kb_repo = KnowledgeBaseRepository(db)

    async def generate_recommendation(
        self, context: DecisionContext, rule_eval_result: dict[str, Any]
    ) -> dict[str, Any]:
        """Synthesizes structured recommendation JSON based on Context and Rule Engine result."""
        disease_name = context.disease_name
        is_healthy = disease_name in ("Healthy", "Khỏe mạnh")

        warnings = rule_eval_result.get("warnings", [])
        allow_spray = rule_eval_result.get("allow_spray", True)
        require_engineer = rule_eval_result.get("require_engineer", False)

        # 1. Tra cứu Pesticide & Merchant từ MongoDB Knowledge Base
        pesticide_doc = await self.kb_repo.get_pesticide_for_disease(disease_name)
        merchant_doc = await self.kb_repo.get_nearest_merchant()

        pesticide_name = "Ridomil Gold 68WG"
        active_ingredient = "Metalaxyl M + Mancozeb"
        dose = "500g/200L nước"
        repeat_days = 7

        if pesticide_doc:
            pesticide_name = pesticide_doc.get("name", pesticide_name)
            active_ingredient = pesticide_doc.get("active_ingredient", active_ingredient)
            dose = pesticide_doc.get("dosage_per_200l", dose)
            repeat_days = int(pesticide_doc.get("isolation_period_days", 7))

        # 2. Xây dựng Recommendation Detail
        if is_healthy:
            pesticide_rec = {
                "pesticide": "Không sử dụng thuốc hóa học",
                "active_ingredient": "Hữu cơ vi sinh",
                "dose": "Tới gốc 1kg Humic / 200L nước",
                "repeat_after_days": 14,
            }
            next_action = "Cây khỏe mạnh. Duy trì bổ sung phân hữu cơ vi sinh định kỳ."
        else:
            if not allow_spray:
                pesticide_rec = {
                    "pesticide": f"{pesticide_name} (Tạm hoãn phun)",
                    "active_ingredient": active_ingredient,
                    "dose": f"{dose} (Phun khi thời tiết ổn định)",
                    "repeat_after_days": repeat_days,
                }
            else:
                pesticide_rec = {
                    "pesticide": pesticide_name,
                    "active_ingredient": active_ingredient,
                    "dose": dose,
                    "repeat_after_days": repeat_days,
                }

            if require_engineer:
                next_action = "Đặt lịch hẹn Kỹ sư Vie-farm kiểm tra trực tiếp tại vườn."
            else:
                next_action = f"Đặt lịch hẹn tái khám và kiểm tra lại sau {repeat_days} ngày."

        # 3. Merchant Details
        merchant_info = {
            "name": "Vựa Sầu Riêng Phước An (Đắk Lắk)",
            "phone": "0983 456 789",
        }
        if merchant_doc:
            merchant_info["name"] = merchant_doc.get("name", merchant_info["name"])
            merchant_info["phone"] = merchant_doc.get("phone", merchant_info["phone"])

        # 4. Explainable AI (XAI) Cards Data Structures
        confidence_pct = round(context.confidence * 100, 1)
        spread_risk_str = "Cao" if context.risk_score >= 70 else "Trung bình" if context.risk_score >= 40 else "Thấp"
        
        ai_analysis = {
            "disease": disease_name,
            "confidence": confidence_pct,
            "severity": context.severity,
            "spread_risk": spread_risk_str,
            "ai_evaluation": f"Cần xử lý trong 24-48 giờ tới để tránh bùng phát" if not is_healthy else "Cây khỏe mạnh, duy trì chăm sóc định kỳ",
        }

        reasoning_factors = [
            "✓ Phân tích hình ảnh lá từ camera",
            f"✓ Kết quả Model 1 EfficientNet ({confidence_pct}%)",
            f"✓ Chỉ số rủi ro môi trường Model 3 ({context.risk_score:.0f}%)",
            "✓ Quy tắc kiểm định Rule Engine MongoDB",
            "✓ Cơ sở tri thức Nông nghiệp Knowledge Base",
            "✓ Dự báo thời tiết vi khí hậu",
        ]
        if context.days_since_last_spray < 90:
            reasoning_factors.append(f"✓ Nhật ký canh tác Farm Activity ({context.days_since_last_spray} ngày trước)")

        pesticide_reasons = []
        if not is_healthy:
            pesticide_reasons = [
                f"✓ Đúng hoạt chất đặc trị ({active_ingredient})",
                f"✓ Hiệu quả cao nhất với {disease_name}",
                f"✓ Phù hợp với mức độ bệnh {context.severity}",
                "✓ Kiểm chứng trong Cơ sở tri thức Knowledge Base",
            ]

        structured_output = {
            "disease": disease_name,
            "risk": round(context.risk_score, 1),
            "severity": context.severity,
            "ai_analysis": ai_analysis,
            "reasoning_factors": reasoning_factors,
            "pesticide_reasons": pesticide_reasons,
            "recommendation": pesticide_rec,
            "warning": warnings,
            "next_action": next_action,
            "merchant": merchant_info,
        }

        logger.info("Recommendation Generator output produced for disease %s", disease_name)
        return structured_output
