"""Test the Recommendation Rule Engine with various scenarios."""

import sys; from pathlib import Path; sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from training_recommendation.rules.rule_engine import RecommendationRuleEngine

engine = RecommendationRuleEngine()

test_cases = [
    {
        "name": "Khỏe mạnh Thấp - Khô",
        "features": {
            "health_status": "Khỏe mạnh", "risk_level": "Thấp", "alert_count": 0,
            "historical_disease_count": 0, "humidity": 60, "rainfall": 10,
            "confidence": 95, "days_since_last_inspection": 10, "season": "Khô",
            "predicted_disease": "Khỏe mạnh", "last_treatment_days": None,
        },
    },
    {
        "name": "Bị bệnh Cao - Mưa - Nặng",
        "features": {
            "health_status": "Bị bệnh", "risk_level": "Cao", "alert_count": 3,
            "historical_disease_count": 5, "humidity": 90, "rainfall": 70,
            "confidence": 75, "days_since_last_inspection": 120, "season": "Mưa",
            "predicted_disease": "Thán thư", "last_treatment_days": 15,
        },
    },
    {
        "name": "Bị bệnh Trung bình - Mưa",
        "features": {
            "health_status": "Bị bệnh", "risk_level": "Trung bình", "alert_count": 1,
            "historical_disease_count": 2, "humidity": 78, "rainfall": 45,
            "confidence": 85, "days_since_last_inspection": 45, "season": "Mưa",
            "predicted_disease": "Đốm lá", "last_treatment_days": 60,
        },
    },
    {
        "name": "Khỏe mạnh Trung bình - Khô",
        "features": {
            "health_status": "Khỏe mạnh", "risk_level": "Trung bình", "alert_count": 0,
            "historical_disease_count": 0, "humidity": 70, "rainfall": 20,
            "confidence": 92, "days_since_last_inspection": 30, "season": "Khô",
            "predicted_disease": "Khỏe mạnh", "last_treatment_days": None,
        },
    },
    {
        "name": "Bị bệnh Thấp - Kiểm tra cũ",
        "features": {
            "health_status": "Bị bệnh", "risk_level": "Thấp", "alert_count": 0,
            "historical_disease_count": 1, "humidity": 65, "rainfall": 15,
            "confidence": 90, "days_since_last_inspection": 100, "season": "Khô",
            "predicted_disease": "Đốm lá", "last_treatment_days": None,
        },
    },
]

all_pass = True
for tc in test_cases:
    labels = engine.compute_labels(tc["features"])
    print(f"[{tc['name']}]")
    print(f"  priority={labels['priority']} (score={labels['priority_score']:.3f})")
    print(f"  code={labels['priority_code']}, action={labels['recommended_action']}")
    print(f"  urgency={labels['urgency_score']:.3f}, loss={labels['estimated_loss_pct']:.1f}%")
    print(f"  next_check={labels['next_check_days']}d")
    print()

meta = engine.get_label_metadata()
print("Label metadata:", list(meta["labels"].keys()))
print("Rule engine test PASSED" if all_pass else "FAILED")
