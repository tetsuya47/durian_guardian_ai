"""Rule Engine for Model 4: deterministic label generation for AI Recommendation Engine."""

from typing import Dict, Any
import numpy as np
import pandas as pd


PRIORITY_ACTIONS = {
    "Rất cao": {
        "code": 3,
        "action": "Cần điều trị ngay - Cần can thiệp khẩn cấp",
        "urgency_range": (0.80, 1.0),
        "loss_range": (30.0, 80.0),
        "check_days_range": (1, 3),
    },
    "Cao": {
        "code": 2,
        "action": "Lên lịch điều trị trong 7 ngày",
        "urgency_range": (0.50, 0.80),
        "loss_range": (15.0, 40.0),
        "check_days_range": (4, 7),
    },
    "Trung bình": {
        "code": 1,
        "action": "Theo dõi và kiểm tra lại sau 14 ngày",
        "urgency_range": (0.20, 0.50),
        "loss_range": (5.0, 20.0),
        "check_days_range": (8, 14),
    },
    "Thấp": {
        "code": 0,
        "action": "Tiếp tục theo dõi định kỳ",
        "urgency_range": (0.0, 0.20),
        "loss_range": (0.0, 8.0),
        "check_days_range": (15, 30),
    },
}


class RecommendationRuleEngine:
    """Deterministic rule engine that computes recommendation labels from features.

    All labels are computed at dataset-build time and never stored in MongoDB.
    """

    def __init__(self):
        self.action_map = PRIORITY_ACTIONS

    def compute_labels(self, row: Dict[str, Any]) -> Dict[str, Any]:
        """Compute all recommendation labels from a feature row.

        Returns dict with keys:
          priority_score, priority, priority_code, recommended_action,
          urgency_score, estimated_loss_pct, next_check_days
        """
        priority_score = self._compute_priority_score(row)
        priority_label = self._score_to_priority(priority_score)
        priority_config = self.action_map[priority_label]

        urgency_score = self._compute_urgency(priority_score, row)
        estimated_loss = self._compute_estimated_loss(priority_score, row)
        next_check = self._compute_next_check_days(priority_score, row)

        return {
            "priority_score": round(priority_score, 4),
            "priority": priority_label,
            "priority_code": priority_config["code"],
            "recommended_action": priority_config["action"],
            "urgency_score": round(urgency_score, 4),
            "estimated_loss_pct": round(estimated_loss, 2),
            "next_check_days": int(next_check),
        }

    def _compute_priority_score(self, row: Dict[str, Any]) -> float:
        """Compute 0-1 priority score from all features."""
        score = 0.0
        weight = 0.0

        risk_level = str(row.get("risk_level", "Thấp"))
        risk_map = {"Thấp": 0.0, "Trung bình": 0.35, "Cao": 0.60}
        score += risk_map.get(risk_level, 0.0)
        weight += 0.60

        health_status = str(row.get("health_status", "Khỏe mạnh"))
        if health_status == "Bị bệnh":
            score += 0.25
        elif health_status == "Đang theo dõi":
            score += 0.10
        weight += 0.25

        alert_count = row.get("alert_count", 0)
        if pd.notna(alert_count) and alert_count > 0:
            score += min(alert_count, 5) * 0.04
        weight += 0.20

        hist_count = row.get("historical_disease_count", 0)
        if pd.notna(hist_count) and hist_count > 0:
            score += min(hist_count, 5) * 0.03
        weight += 0.15

        humidity = row.get("humidity")
        if pd.notna(humidity) and humidity > 80:
            score += 0.05
            weight += 0.05

        rainfall = row.get("rainfall")
        if pd.notna(rainfall) and rainfall > 50:
            score += 0.05
            weight += 0.05

        season = str(row.get("season", "Khô"))
        if season == "Mưa":
            score += 0.05
            weight += 0.05

        confidence = row.get("confidence", 100)
        if pd.notna(confidence) and confidence < 80:
            score += 0.05
            weight += 0.05

        days_since = row.get("days_since_last_inspection")
        if pd.notna(days_since) and days_since > 90:
            score += 0.05
            weight += 0.05

        if weight > 0:
            score = score / weight

        return min(score, 1.0)

    def _score_to_priority(self, score: float) -> str:
        if score >= 0.70:
            return "Rất cao"
        elif score >= 0.40:
            return "Cao"
        elif score >= 0.15:
            return "Trung bình"
        else:
            return "Thấp"

    def _compute_urgency(self, priority_score: float, row: Dict[str, Any]) -> float:
        urgency = priority_score

        if str(row.get("health_status", "")) == "Bị bệnh":
            urgency += 0.10

        season = str(row.get("season", "Khô"))
        if season == "Mưa":
            urgency += 0.05

        humidity = row.get("humidity")
        if pd.notna(humidity) and humidity > 85:
            urgency += 0.05

        recent_treatment = row.get("last_treatment_days")
        if pd.notna(recent_treatment) and recent_treatment < 30:
            urgency -= 0.05

        return min(max(urgency, 0.0), 1.0)

    def _compute_estimated_loss(self, priority_score: float, row: Dict[str, Any]) -> float:
        base_loss = priority_score * 60.0

        if str(row.get("health_status", "")) == "Bị bệnh":
            base_loss += 10.0

        disease = str(row.get("predicted_disease", ""))
        severe_diseases = ["Thán thư", "Bệnh thối rễ Phytophthora", "Thối thân", "Thối rễ", "Thối quả"]
        if disease in severe_diseases:
            base_loss += 10.0

        hist_count = row.get("historical_disease_count", 0)
        if pd.notna(hist_count):
            base_loss += min(hist_count, 10) * 2.0

        alert_count = row.get("alert_count", 0)
        if pd.notna(alert_count):
            base_loss += min(alert_count, 10) * 1.5

        return min(base_loss, 90.0)

    def _compute_next_check_days(self, priority_score: float, row: Dict[str, Any]) -> int:
        if priority_score >= 0.70:
            base_days = 2
        elif priority_score >= 0.40:
            base_days = 7
        elif priority_score >= 0.15:
            base_days = 14
        else:
            base_days = 30

        if str(row.get("season", "Khô")) == "Mưa":
            base_days = max(base_days - 3, 1)

        if str(row.get("health_status", "")) == "Bị bệnh":
            base_days = max(base_days - 2, 1)

        return int(base_days)

    def get_label_metadata(self) -> Dict[str, Any]:
        return {
            "labels": {
                "priority": {
                    "type": "categorical",
                    "values": ["Thấp", "Trung bình", "Cao", "Rất cao"],
                    "codes": {"Thấp": 0, "Trung bình": 1, "Cao": 2, "Rất cao": 3},
                    "description": "Mức độ ưu tiên khuyến nghị cho hành động",
                },
                "priority_score": {
                    "type": "numerical",
                    "range": [0.0, 1.0],
                    "description": "Điểm ưu tiên liên tục (0=thấp nhất, 1=cao nhất)",
                },
                "recommended_action": {
                    "type": "categorical",
                    "values": [
                        "Tiếp tục theo dõi định kỳ",
                        "Theo dõi và kiểm tra lại sau 14 ngày",
                        "Lên lịch điều trị trong 7 ngày",
                        "Cần điều trị ngay - Cần can thiệp khẩn cấp",
                    ],
                    "description": "Hành động khuyến nghị",
                },
                "urgency_score": {
                    "type": "numerical",
                    "range": [0.0, 1.0],
                    "description": "Điểm khẩn cấp (0=không khẩn cấp, 1=rất khẩn cấp)",
                },
                "estimated_loss_pct": {
                    "type": "numerical",
                    "range": [0.0, 90.0],
                    "description": "Tỷ lệ mất mùa ước tính nếu không hành động",
                },
                "next_check_days": {
                    "type": "numerical",
                    "range": [1, 30],
                    "description": "Số ngày khuyến nghị cho lần kiểm tra tiếp theo",
                },
            },
            "rule_version": "1.0.0-vi",
        }
