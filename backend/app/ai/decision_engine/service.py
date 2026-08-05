from __future__ import annotations

import logging
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.ai.decision_engine.context_engine import ContextEngine, DecisionContext
from app.ai.decision_engine.rule_engine import RuleEngine
from app.ai.decision_engine.recommendation_generator import RecommendationGenerator
from app.ai.decision_engine.ai_agronomist import AIAgronomist

logger = logging.getLogger(__name__)


class AIDecisionEngineService:
    """Master Service for Model 4 AI Decision Engine & AI Agronomist.

    Combines:
    1. Knowledge Base (MongoDB)
    2. Context Engine (Aggregates Disease, Risk, Weather, History, Farm Activities)
    3. Rule Engine (Rule-based evaluation)
    4. Recommendation Generator (Structured Output)
    5. AI Agronomist (Natural Language Vietnamese Advice)
    """

    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.context_engine = ContextEngine(db)
        self.rule_engine = RuleEngine(db)
        self.recommendation_generator = RecommendationGenerator(db)
        self.ai_agronomist = AIAgronomist()

    async def run_decision_engine(
        self,
        tree_id: str,
        disease_name: str,
        confidence: float,
        severity: str,
        risk_score: float = 0.0,
        risk_level: str = "Low",
        weather_info: dict[str, Any] | None = None,
    ) -> tuple[dict[str, Any], str]:
        """Runs the full AI Decision Engine pipeline.

        Returns:
            tuple of (structured_recommendation_dict, natural_language_agronomist_text)
        """
        # Step 1: Build Context
        context: DecisionContext = await self.context_engine.build_context(
            tree_id=tree_id,
            disease_name=disease_name,
            confidence=confidence,
            severity=severity,
            risk_score=risk_score,
            risk_level=risk_level,
            weather_info=weather_info,
        )

        # Step 2: Evaluate Rules
        rule_eval_result = await self.rule_engine.evaluate_rules(context)

        # Step 3: Generate Structured Recommendation Output
        structured_rec = await self.recommendation_generator.generate_recommendation(
            context, rule_eval_result
        )

        # Step 4: AI Agronomist Natural Language Translation
        agronomist_text = self.ai_agronomist.synthesize(context, structured_rec)

        structured_rec["agronomist_text"] = agronomist_text

        logger.info(
            "AI Decision Engine successfully produced output for tree %s (disease=%s)",
            tree_id,
            disease_name,
        )
        return structured_rec, agronomist_text
