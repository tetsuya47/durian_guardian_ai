#!/usr/bin/env python3
"""Model 3: Disease Risk Prediction — Single prediction from MongoDB data."""

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from training.utils.logger import Logger

MODEL3_DIR = ROOT / "training" / "model3"
EXPORTS_DIR = MODEL3_DIR / "exports"


def load_artifacts():
    import joblib
    model = joblib.load(str(EXPORTS_DIR / "model.pkl"))
    preprocessor = joblib.load(str(EXPORTS_DIR / "preprocessor.pkl"))
    with open(str(EXPORTS_DIR / "feature_columns.json")) as f:
        feature_columns = json.load(f)
    with open(str(EXPORTS_DIR / "metadata.json")) as f:
        metadata = json.load(f)
    return model, preprocessor, feature_columns, metadata


def predict_single(tree_data, model, preprocessor, feature_columns, logger):
    ordinal_encoder = preprocessor["ordinal_encoder"]
    scaler = preprocessor["scaler"]
    label_encoder = preprocessor["label_encoder"]
    cat_cols = preprocessor["cat_columns"]
    num_cols = preprocessor["num_columns"]

    row = {}
    for col in cat_cols:
        row[col] = tree_data.get(col, "unknown")
    for col in num_cols:
        row[col] = tree_data.get(col, 0)

    df = pd.DataFrame([row])

    for col in num_cols:
        if df[col].isna().any():
            df[col] = df[col].fillna(df[col].median())

    X_cat = ordinal_encoder.transform(df[cat_cols])
    cat_df = pd.DataFrame(
        X_cat, columns=[f"{c}_encoded" for c in cat_cols],
        index=df.index,
    )

    X_num = scaler.transform(df[num_cols])
    num_df = pd.DataFrame(
        X_num, columns=[f"{c}_scaled" for c in num_cols],
        index=df.index,
    )

    X_final = pd.concat([cat_df, num_df], axis=1)

    pred_class = model.predict(X_final)[0]
    pred_proba = model.predict_proba(X_final)[0]

    risk_level = label_encoder.inverse_transform([pred_class])[0]
    risk_score = float(pred_proba[pred_class])

    top_indices = np.argsort(pred_proba)[::-1]
    all_probs = {
        label_encoder.classes_[i]: float(pred_proba[i])
        for i in top_indices
    }

    feature_imp = model.feature_importances_
    top_feat_idx = np.argsort(feature_imp)[::-1][:5]
    top_factors = [
        {"feature": feature_columns[i], "importance": float(feature_imp[i])}
        for i in top_feat_idx
    ]

    result = {
        "risk_level": str(risk_level),
        "risk_score": float(risk_score),
        "probabilities": all_probs,
        "top_factors": top_factors,
    }

    return result


def main():
    parser = argparse.ArgumentParser(description="Model 3: Predict disease risk")
    parser.add_argument("--tree-id", type=str, default=None,
                        help="Inspect a specific tree by tree_code or tree_id")
    parser.add_argument("--show-factors", action="store_true", default=True)
    args = parser.parse_args()

    logger = Logger.get_logger("Model3Predict")

    model, preprocessor, feature_columns, metadata = load_artifacts()
    logger.info("Model loaded from %s", EXPORTS_DIR / "model.pkl")
    logger.info("Classes: %s", metadata["classes"])

    sample_data = {
        "temperature": 29.0,
        "humidity": 78.0,
        "rainfall": 35.0,
        "tree_age": 5,
        "variety": "Monthong",
        "health_status": "Healthy",
        "predicted_disease": "Healthy",
        "confidence": 85.0,
        "season": "Dry",
        "density_per_hectare": 50.0,
        "days_since_last_inspection": 60,
        "days_since_last_treatment": 120,
        "historical_disease_count": 0,
        "historical_disease_frequency": 0.0,
    }

    result = predict_single(sample_data, model, preprocessor, feature_columns, logger)

    print("\n" + "=" * 50)
    print("  MODEL 3: DISEASE RISK PREDICTION")
    print("=" * 50)
    print(f"  Risk Level : {result['risk_level']}")
    print(f"  Risk Score : {result['risk_score']:.4f}")
    print(f"  Probabilities:")
    for level, prob in result["probabilities"].items():
        print(f"    {level:>8s}: {prob:.4f}")
    print(f"  Top Factors:")
    for f in result["top_factors"][:5]:
        print(f"    - {f['feature']:35s} {f['importance']:.4f}")
    print("=" * 50)

    import json as j
    with open(str(MODEL3_DIR / "reports" / "sample_prediction.json"), "w") as f:
        j.dump(result, f, indent=2)
    logger.info("Sample prediction saved.")


if __name__ == "__main__":
    main()
