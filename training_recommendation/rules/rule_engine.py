"""Rule Engine for Model 4: deterministic label generation for AI Recommendation Engine."""

from typing import Dict, Any
import numpy as np
import pandas as pd


PRIORITY_ACTIONS = {
    "Critical": {
        "code": 3,
        "action": "Immediate Treatment Required - Urgent intervention needed",
        "urgency_range": (0.80, 1.0),
        "loss_range": (30.0, 80.0),
        "check_days_range": (1, 3),
    },
    "High": {
        "code": 2,
        "action": "Schedule Treatment Within 7 Days",
        "urgency_range": (0.50, 0.80),
        "loss_range": (15.0, 40.0),
        "check_days_range": (4, 7),
    },
    "Medium": {
        "code": 1,
        "action": "Monitor and Re-inspect in 14 Days",
        "urgency_range": (0.20, 0.50),
        "loss_range": (5.0, 20.0),
        "check_days_range": (8, 14),
    },
    "Low": {
        "code": 0,
        "action": "Continue Regular Monitoring",
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

        risk_level = str(row.get("risk_level", "Low"))
        risk_map = {"Low": 0.0, "Medium": 0.35, "High": 0.60}
        score += risk_map.get(risk_level, 0.0)
        weight += 0.60

        health_status = str(row.get("health_status", "Healthy"))
        if health_status == "Diseased":
            score += 0.25
        elif health_status == "Monitoring":
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

        season = str(row.get("season", "Dry"))
        if season == "Rainy":
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
            return "Critical"
        elif score >= 0.40:
            return "High"
        elif score >= 0.15:
            return "Medium"
        else:
            return "Low"

    def _compute_urgency(self, priority_score: float, row: Dict[str, Any]) -> float:
        urgency = priority_score

        if str(row.get("health_status", "")) == "Diseased":
            urgency += 0.10

        season = str(row.get("season", "Dry"))
        if season == "Rainy":
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

        if str(row.get("health_status", "")) == "Diseased":
            base_loss += 10.0

        disease = str(row.get("predicted_disease", ""))
        severe_diseases = ["Anthracnose", "Phytophthora", "Stem Rot", "Root Rot", "Fruit Rot"]
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

        if str(row.get("season", "Dry")) == "Rainy":
            base_days = max(base_days - 3, 1)

        if str(row.get("health_status", "")) == "Diseased":
            base_days = max(base_days - 2, 1)

        return int(base_days)

    def get_label_metadata(self) -> Dict[str, Any]:
        return {
            "labels": {
                "priority": {
                    "type": "categorical",
                    "values": ["Low", "Medium", "High", "Critical"],
                    "codes": {"Low": 0, "Medium": 1, "High": 2, "Critical": 3},
                    "description": "Recommended priority level for action",
                },
                "priority_score": {
                    "type": "numerical",
                    "range": [0.0, 1.0],
                    "description": "Continuous priority score (0=lowest, 1=highest)",
                },
                "recommended_action": {
                    "type": "categorical",
                    "values": [
                        "Continue Regular Monitoring",
                        "Monitor and Re-inspect in 14 Days",
                        "Schedule Treatment Within 7 Days",
                        "Immediate Treatment Required - Urgent intervention needed",
                    ],
                    "description": "Recommended action text",
                },
                "urgency_score": {
                    "type": "numerical",
                    "range": [0.0, 1.0],
                    "description": "Urgency score (0=not urgent, 1=extremely urgent)",
                },
                "estimated_loss_pct": {
                    "type": "numerical",
                    "range": [0.0, 90.0],
                    "description": "Estimated yield loss percentage if no action taken",
                },
                "next_check_days": {
                    "type": "numerical",
                    "range": [1, 30],
                    "description": "Recommended days until next inspection",
                },
            },
            "rule_version": "1.0.0",
        }
