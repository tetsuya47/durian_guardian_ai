from __future__ import annotations

import logging
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.repositories.knowledge_base_repository import KnowledgeBaseRepository
from app.ai.decision_engine.context_engine import DecisionContext

logger = logging.getLogger(__name__)


class RuleEngine:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.kb_repo = KnowledgeBaseRepository(db)

    async def evaluate_rules(self, context: DecisionContext) -> dict[str, Any]:
        """Evaluates Context against MongoDB rules (recommendation_rules, weather_rules).

        Returns:
            dict containing:
            - warnings: list[str]
            - override_actions: list[str]
            - allow_spray: bool
            - allow_fertilize: bool
            - allow_harvest: bool
            - require_engineer: bool
        """
        warnings: list[str] = []
        override_actions: list[str] = []
        allow_spray = True
        allow_fertilize = True
        allow_harvest = True
        require_engineer = False

        # Load MongoDB rules
        weather_rules = await self.kb_repo.get_weather_rules()
        recommendation_rules = await self.kb_repo.get_recommendation_rules()

        # --- Rule 1: Repeat Pesticide Prohibition (< 7 days) ---
        if context.days_since_last_spray < 7:
            last_prod = "thuốc"
            if context.last_pesticide_activity:
                last_prod = context.last_pesticide_activity.get("product_name", "thuốc")
            warnings.append(
                f"Lưu ý: Đã phun {last_prod} {context.days_since_last_spray} ngày trước. Không phun lặp lại cùng loại thuốc dưới 7 ngày."
            )
            allow_spray = False

        # --- Rule 2: Weather Rain Check (Rain today or rain tomorrow) ---
        if context.rain_tomorrow or context.rain_today:
            warnings.append(
                "Dự báo thời tiết có mưa trong vòng 24 giờ tới. Không nên tiến hành phun thuốc hôm nay để tránh trôi thuốc."
            )
            allow_spray = False

        # --- Rule 3: Repeat Fertilizer Prohibition (< 1 day) ---
        if context.days_since_last_fertilizer < 1:
            warnings.append(
                "Vườn đã được bón phân hôm nay. Không bón thêm phân hóa học để tránh hiện tượng cháy rễ."
            )
            allow_fertilize = False

        # --- Rule 4: PHI Pre-Harvest Interval Check ---
        if context.growth_stage == "pre_harvest":
            if context.days_to_harvest < 14:
                warnings.append(
                    "Thời gian cách ly (PHI) thu hoạch chưa đủ. Tuyệt đối không phun thuốc bảo vệ thực vật hóa học đậm đặc."
                )
                allow_spray = False
                allow_harvest = False

        # --- Rule 5: Recurrence Check (> 3 times) ---
        if context.tree_recurrence_count >= 3:
            warnings.append(
                f"Cảnh báo: Cây sầu riêng này đã có tiền sử tái phát bệnh {context.tree_recurrence_count} lần."
            )
            override_actions.append(
                "Yêu cầu Kỹ sư nông nghiệp Vie-farm trực tiếp kiểm tra mẫu đất và bộ rễ tại vườn."
            )
            require_engineer = True

        # --- Evaluate Custom MongoDB Rules ---
        for rule in recommendation_rules:
            condition = rule.get("condition", {})
            msg = rule.get("warning_message")
            min_risk = condition.get("min_risk_score", 0)

            if context.risk_score >= min_risk and min_risk > 0 and msg:
                if msg not in warnings:
                    warnings.append(msg)

        logger.info(
            "Rule Engine Evaluated: allow_spray=%s, allow_fertilize=%s, warnings_count=%d",
            allow_spray,
            allow_fertilize,
            len(warnings),
        )

        return {
            "warnings": warnings,
            "override_actions": override_actions,
            "allow_spray": allow_spray,
            "allow_fertilize": allow_fertilize,
            "allow_harvest": allow_harvest,
            "require_engineer": require_engineer,
        }
