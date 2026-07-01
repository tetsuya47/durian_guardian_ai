from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories import RiskRepository
from app.schemas import RiskInput, RiskResult


class RiskService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.repo = RiskRepository(db)

    async def calculate(self, tree_id: str, data: RiskInput) -> RiskResult:
        result = self._mock_calculate(data)

        await self.repo.create(
            {
                "tree_id": tree_id,
                "risk_score": result.risk_score,
                "explanation": result.explanation,
                "recommendation": result.recommendation,
            }
        )

        return result

    def _mock_calculate(self, data: RiskInput) -> RiskResult:
        score = 0.0
        severity_val = 0.5

        if data.disease.lower() == "healthy":
            severity_val = 0.05
        elif data.disease.lower() in ("phytophthora", "root rot"):
            severity_val = 0.8

        score += data.confidence * severity_val * 0.4

        if data.humidity is not None and data.humidity > 85:
            score += 0.15
        if data.rainfall is not None and data.rainfall > 30:
            score += 0.15
        if data.history_count > 3:
            score += 0.2
        elif data.history_count > 1:
            score += 0.1

        score = min(score, 1.0)
        score = round(score, 4)

        if score < 0.3:
            explanation = "Low risk conditions. Tree appears healthy."
            recommendation = "Continue regular monitoring."
        elif score < 0.6:
            explanation = "Moderate risk detected. Some factors may affect tree health."
            recommendation = "Increase monitoring frequency. Consider preventive treatment."
        else:
            explanation = "High risk! Multiple factors indicate potential disease outbreak."
            recommendation = (
                "Immediate intervention required. Isolate affected area. "
                "Apply treatment and consult agricultural expert."
            )

        return RiskResult(
            risk_score=score,
            explanation=explanation,
            recommendation=recommendation,
        )
