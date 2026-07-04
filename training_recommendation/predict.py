"""Model 4: AI Recommendation Engine — prediction from features."""

import json
import sys
from pathlib import Path
from typing import Dict, Any, Optional

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from training.utils.logger import Logger

EXPORTS_DIR = ROOT / "training_recommendation" / "exports"

PRIORITY_MAP = {0: "Low", 1: "Medium", 2: "High", 3: "Critical"}

ACTION_MAP = {
    0: "Continue Regular Monitoring",
    1: "Monitor and Re-inspect in 14 Days",
    2: "Schedule Treatment Within 7 Days",
    3: "Immediate Treatment Required - Urgent intervention needed",
}


def load_artifacts():
    import joblib
    model = joblib.load(str(EXPORTS_DIR / "classifier.pkl"))
    regressors = {}
    for name in ["urgency_score", "estimated_loss_pct", "next_check_days"]:
        regressors[name] = joblib.load(str(EXPORTS_DIR / f"regressor_{name}.pkl"))
    preprocessor = joblib.load(str(EXPORTS_DIR / "preprocessor.pkl"))
    with open(EXPORTS_DIR / "metadata.json") as f:
        metadata = json.load(f)
    return model, regressors, preprocessor, metadata


def predict(features: Dict[str, Any], model, regressors, preprocessor, logger=None):
    cat_cols = preprocessor.get("cat_columns", [])
    num_cols = preprocessor.get("num_columns", [])

    row = {}
    for col in cat_cols:
        row[col] = str(features.get(col, "unknown"))
    for col in num_cols:
        val = features.get(col)
        if val is None or (isinstance(val, float) and np.isnan(val)):
            row[col] = preprocessor["num_fill"].get(col, 0)
        else:
            row[col] = val

    df = pd.DataFrame([row])

    cat_encoded = preprocessor["cat_encoder"].transform(df[cat_cols])
    cat_df = pd.DataFrame(cat_encoded, columns=[f"{c}_encoded" for c in cat_cols])

    num_scaled = preprocessor["scaler"].transform(df[num_cols])
    num_df = pd.DataFrame(num_scaled, columns=[f"{c}_scaled" for c in num_cols])

    X = pd.concat([cat_df, num_df], axis=1)

    priority_code = int(model.predict(X)[0])
    priority_label = PRIORITY_MAP.get(priority_code, "Unknown")
    priority_proba = model.predict_proba(X)[0]

    result = {
        "priority": priority_label,
        "priority_code": priority_code,
        "recommended_action": ACTION_MAP.get(priority_code, "Unknown"),
        "priority_probabilities": {
            str(cls): float(prob) for cls, prob in zip(model.classes_, priority_proba)
        },
    }

    for target_name, reg in regressors.items():
        pred_val = float(reg.predict(X)[0])
        if target_name == "next_check_days":
            pred_val = max(1, int(round(pred_val)))
        elif target_name == "estimated_loss_pct":
            pred_val = max(0.0, min(100.0, pred_val))
        elif target_name == "urgency_score":
            pred_val = max(0.0, min(1.0, pred_val))
        result[target_name] = pred_val

    return result


def main():
    logger = Logger.get_logger("Model4Predict")
    model, regressors, preprocessor, metadata = load_artifacts()
    logger.info("Model 4 artifacts loaded successfully")

    sample_features = {
        "temperature": 29.0,
        "humidity": 78.0,
        "rainfall": 35.0,
        "tree_age": 5,
        "area_hectare": 25.0,
        "confidence": 85.0,
        "detection_confidence": 87.0,
        "disease_history_count": 0,
        "last_treatment_days": 120,
        "alert_count": 0,
        "days_since_last_inspection": 60,
        "historical_disease_count": 0,
        "historical_disease_frequency": 0.0,
        "density_per_hectare": 50.0,
        "priority_score": 0.0,
        "health_status": "Healthy",
        "predicted_disease": "Healthy",
        "detection_prediction": "Healthy",
        "alert_type": "None",
        "alert_priority": "None",
        "season": "Dry",
        "risk_level": "Low",
    }

    result = predict(sample_features, model, regressors, preprocessor, logger)

    print("\n" + "=" * 50)
    print("  MODEL 4: AI RECOMMENDATION ENGINE")
    print("=" * 50)
    print(f"  Priority          : {result['priority']} (code={result['priority_code']})")
    print(f"  Recommended Action : {result['recommended_action']}")
    print(f"  Urgency Score      : {result['urgency_score']:.4f}")
    print(f"  Estimated Loss     : {result['estimated_loss_pct']:.2f}%")
    print(f"  Next Check (days)  : {result['next_check_days']}")
    print(f"  Probabilities:")
    for cls_name, prob in sorted(result["priority_probabilities"].items(), key=lambda x: -x[1]):
        print(f"    {PRIORITY_MAP.get(int(cls_name), cls_name)}: {prob:.4f}")
    print("=" * 50)

    report_dir = ROOT / "training_recommendation" / "reports"
    report_dir.mkdir(parents=True, exist_ok=True)
    with open(report_dir / "sample_prediction.json", "w") as f:
        json.dump(result, f, indent=2)
    logger.info("Sample prediction saved.")


if __name__ == "__main__":
    main()
