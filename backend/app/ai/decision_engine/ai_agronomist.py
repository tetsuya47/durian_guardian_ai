from __future__ import annotations

import logging
from typing import Any
from app.ai.decision_engine.context_engine import DecisionContext

logger = logging.getLogger(__name__)


class AIAgronomist:
    """AI Agronomist Natural Language Synthesizer.

    Converts structured recommendation + Context into a clear, professional,
    deterministic Vietnamese agronomist advice paragraph.
    No LLM hallucination - purely structured rule-based translation.
    """

    def synthesize(
        self, context: DecisionContext, recommendation: dict[str, Any]
    ) -> str:
        disease = context.disease_name
        is_healthy = disease in ("Healthy", "Khỏe mạnh")

        if is_healthy:
            return (
                "🌱 AI AGRONOMIST: Cây sầu riêng đang ở trạng thái khỏe mạnh, tán lá xanh tốt. "
                "Duy trì chế độ tưới nước đều đặn và bổ sung phân hữu cơ vi sinh định kỳ để tăng đề kháng."
            )

        severity_vi = "trung bình"
        if context.severity == "High" or context.severity == "Nặng":
            severity_vi = "cao"
        elif context.severity == "Low" or context.severity == "Nhẹ":
            severity_vi = "nhẹ"

        rec_details = recommendation.get("recommendation", {})
        pesticide = rec_details.get("pesticide", "thuốc đặc trị")
        dose = rec_details.get("dose", "theo liều lượng chỉ định")
        repeat_days = rec_details.get("repeat_after_days", 7)

        warnings = recommendation.get("warning", [])
        warning_str = ""
        if warnings:
            warning_str = " " + " ".join(warnings)

        sentences = [
            f"⚡ AI AGRONOMIST: Cây có nguy cơ mắc bệnh {disease} ở mức {severity_vi} (Rủi ro bùng phát: {context.risk_score:.0f}%).",
            warning_str,
            f"Khuyến nghị sử dụng {pesticide} với liều lượng {dose}.",
            f"Kiểm tra lại cây và đánh giá sự hồi phục sau {repeat_days} ngày.",
        ]

        # Clean double spaces
        text = " ".join([s.strip() for s in sentences if s.strip()])
        return text
