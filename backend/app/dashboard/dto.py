from __future__ import annotations

from pydantic import BaseModel


class FarmPerformanceDTO(BaseModel):
    average_farm_score: float | None = None
    farms_evaluated: int = 0
    total_farms: int = 0
    healthy_percent: float | None = None
    high_risk_count: int = 0
    total_target_yield: float | None = None
    total_actual_yield: float | None = None
    yield_achievement_pct: float | None = None
    overall_status: str | None = None
    ai_insight: str = (
        "Dữ liệu hiệu suất trang trại sẽ được AI phân tích "
        "trong phiên bản tiếp theo."
    )
