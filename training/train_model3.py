#!/usr/bin/env python3
"""Model 3: Disease Risk Prediction — Training Pipeline.

Builds dataset from MongoDB, engineers features, creates risk_level labels,
trains Random Forest, evaluates, and exports all artifacts.
"""

import argparse
import json
import os
import sys
import time
import warnings
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from training.datasets.build_model3_dataset import Model3DatasetBuilder
from training.utils.logger import Logger
from training.utils.seed import seed_everything

warnings.filterwarnings("ignore")


MODEL3_DIR = ROOT / "training" / "model3"
EXPORTS_DIR = MODEL3_DIR / "exports"
LOGS_DIR = MODEL3_DIR / "logs"
REPORTS_DIR = MODEL3_DIR / "reports"
CHECKPOINTS_DIR = MODEL3_DIR / "checkpoints"

for d in [MODEL3_DIR, EXPORTS_DIR, LOGS_DIR, REPORTS_DIR, CHECKPOINTS_DIR]:
    d.mkdir(parents=True, exist_ok=True)


def parse_args():
    parser = argparse.ArgumentParser(description="Model 3: Disease Risk Prediction")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--test-size", type=float, default=0.2)
    parser.add_argument("--cv-folds", type=int, default=5)
    parser.add_argument("--n-estimators", type=int, default=300)
    parser.add_argument("--max-depth", type=int, default=None)
    parser.add_argument("--grid-search", action="store_true", default=True)
    parser.add_argument("--verbose", action="store_true", default=False)
    return parser.parse_args()


def build_dataset(logger):
    logger.info("=" * 60)
    logger.info("  PHASE 1: Building Dataset from MongoDB")
    logger.info("=" * 60)

    builder = Model3DatasetBuilder(logger=logger)
    df = builder.build_dataset()
    builder.close()

    logger.info("Dataset shape: %s", df.shape)
    return df


def preprocess(X: pd.DataFrame, y: pd.Series, logger):
    logger.info("=" * 60)
    logger.info("  PHASE 2: Preprocessing")
    logger.info("=" * 60)

    from sklearn.model_selection import train_test_split
    from sklearn.preprocessing import OrdinalEncoder, StandardScaler
    import joblib

    cat_cols = ["tree_variety", "health_status", "predicted_disease", "season"]
    num_cols = ["temperature", "humidity", "rainfall", "tree_age",
                "confidence", "density_per_hectare",
                "days_since_last_inspection", "days_since_last_treatment",
                "historical_disease_count", "historical_disease_frequency"]

    available_cat = [c for c in cat_cols if c in X.columns]
    available_num = [c for c in num_cols if c in X.columns]

    logger.info("Categorical features: %s", available_cat)
    logger.info("Numerical features: %s", available_num)

    X_processed = X[available_cat + available_num].copy()

    for col in available_num:
        missing = X_processed[col].isna().sum()
        if missing > 0:
            logger.info("  %s: %d missing values → filling with median", col, missing)
            X_processed[col] = X_processed[col].fillna(X_processed[col].median())

    logger.info("Encoding categorical features...")
    ordinal_encoder = OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1)
    X_cat_encoded = ordinal_encoder.fit_transform(X_processed[available_cat])
    cat_encoded_df = pd.DataFrame(
        X_cat_encoded,
        columns=[f"{c}_encoded" for c in available_cat],
        index=X_processed.index,
    )

    logger.info("Scaling numerical features...")
    scaler = StandardScaler()
    X_num_scaled = scaler.fit_transform(X_processed[available_num])
    num_scaled_df = pd.DataFrame(
        X_num_scaled,
        columns=[f"{c}_scaled" for c in available_num],
        index=X_processed.index,
    )

    X_final = pd.concat([cat_encoded_df, num_scaled_df], axis=1)

    final_feature_cols = list(X_final.columns)
    logger.info("Final feature count: %d", len(final_feature_cols))
    logger.info("Final features: %s", final_feature_cols)

    from sklearn.preprocessing import LabelEncoder
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)

    logger.info("Label mapping: %s", dict(zip(label_encoder.classes_, range(len(label_encoder.classes_)))))
    logger.info("Class distribution: %s", {k: int(v) for k, v in zip(
        label_encoder.classes_, np.bincount(y_encoded))})

    X_train, X_test, y_train, y_test = train_test_split(
        X_final, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded,
    )
    logger.info("Train: %d, Test: %d", len(X_train), len(X_test))

    preprocessor = {
        "ordinal_encoder": ordinal_encoder,
        "scaler": scaler,
        "label_encoder": label_encoder,
        "cat_columns": available_cat,
        "num_columns": available_num,
        "feature_columns": final_feature_cols,
        "cat_encoded_columns": [f"{c}_encoded" for c in available_cat],
        "num_scaled_columns": [f"{c}_scaled" for c in available_num],
    }
    joblib.dump(preprocessor, str(EXPORTS_DIR / "preprocessor.pkl"))
    logger.info("Preprocessor saved to %s", EXPORTS_DIR / "preprocessor.pkl")

    with open(str(EXPORTS_DIR / "feature_columns.json"), "w") as f:
        json.dump(final_feature_cols, f, indent=2)
    logger.info("Feature columns saved to %s", EXPORTS_DIR / "feature_columns.json")

    with open(str(EXPORTS_DIR / "label_encoder.pkl"), "wb") as f:
        joblib.dump(label_encoder, f)

    return X_train, X_test, y_train, y_test, final_feature_cols


def train_random_forest(X_train, y_train, args, logger):
    logger.info("=" * 60)
    logger.info("  PHASE 3: Training Random Forest")
    logger.info("=" * 60)

    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import GridSearchCV, StratifiedKFold

    base_rf = RandomForestClassifier(
        random_state=args.seed,
        n_jobs=-1,
        class_weight="balanced",
    )

    if args.grid_search:
        logger.info("Running GridSearchCV...")
        param_grid = {
            "n_estimators": [100, 200, 300],
            "max_depth": [None, 10, 20, 30],
            "min_samples_split": [2, 5, 10],
            "min_samples_leaf": [1, 2, 4],
            "max_features": ["sqrt", "log2"],
        }
        cv = StratifiedKFold(n_splits=args.cv_folds, shuffle=True, random_state=args.seed)
        grid = GridSearchCV(
            base_rf, param_grid, cv=cv,
            scoring="f1_weighted", n_jobs=-1, verbose=2 if args.verbose else 0,
        )
        grid.fit(X_train, y_train)
        model = grid.best_estimator_
        logger.info("Best params: %s", grid.best_params_)
        logger.info("Best CV score: %.4f", grid.best_score_)
    else:
        model = RandomForestClassifier(
            n_estimators=args.n_estimators,
            max_depth=args.max_depth,
            random_state=args.seed,
            n_jobs=-1,
            class_weight="balanced",
        )
        model.fit(X_train, y_train)

    return model


def evaluate(model, X_test, y_test, label_encoder, logger):
    logger.info("=" * 60)
    logger.info("  PHASE 4: Evaluation")
    logger.info("=" * 60)

    from sklearn.metrics import (
        accuracy_score, precision_score, recall_score, f1_score,
        roc_auc_score, confusion_matrix, classification_report,
    )

    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)

    acc = accuracy_score(y_test, y_pred)
    prec = precision_score(y_test, y_pred, average="weighted", zero_division=0)
    rec = recall_score(y_test, y_pred, average="weighted", zero_division=0)
    f1 = f1_score(y_test, y_pred, average="weighted", zero_division=0)

    try:
        auc = roc_auc_score(y_test, y_proba, multi_class="ovr", average="weighted")
    except Exception:
        auc = None

    logger.info("  Accuracy : %.4f", acc)
    logger.info("  Precision: %.4f", prec)
    logger.info("  Recall   : %.4f", rec)
    logger.info("  F1-Score : %.4f", f1)
    if auc is not None:
        logger.info("  ROC-AUC  : %.4f", auc)

    cm = confusion_matrix(y_test, y_pred)
    logger.info("\nConfusion Matrix:\n%s", cm)

    cr = classification_report(y_test, y_pred, target_names=label_encoder.classes_)
    logger.info("\nClassification Report:\n%s", cr)

    results = {
        "accuracy": float(round(acc, 4)),
        "precision": float(round(prec, 4)),
        "recall": float(round(rec, 4)),
        "f1_score": float(round(f1, 4)),
        "roc_auc": float(round(auc, 4)) if auc is not None else None,
        "confusion_matrix": cm.tolist(),
        "classification_report": cr,
        "classes": label_encoder.classes_.tolist(),
    }

    with open(str(REPORTS_DIR / "evaluation_results.json"), "w") as f:
        json.dump(results, f, indent=2)
    logger.info("Results saved to %s", REPORTS_DIR / "evaluation_results.json")

    return results, y_pred, y_proba


def analyze_feature_importance(model, feature_cols, label_encoder, logger):
    logger.info("=" * 60)
    logger.info("  PHASE 5: Feature Importance Analysis")
    logger.info("=" * 60)

    importances = model.feature_importances_
    indices = np.argsort(importances)[::-1]

    logger.info("  Top 15 features:")
    fi_data = []
    for i in range(min(15, len(feature_cols))):
        idx = indices[i]
        logger.info("    %2d. %-35s %.4f", i + 1, feature_cols[idx], importances[idx])
        fi_data.append({
            "rank": i + 1,
            "feature": feature_cols[idx],
            "importance": float(round(importances[idx], 6)),
        })

    with open(str(REPORTS_DIR / "feature_importance.json"), "w") as f:
        json.dump(fi_data, f, indent=2)
    logger.info("Feature importance saved to %s", REPORTS_DIR / "feature_importance.json")

    try:
        import shap
        logger.info("Computing SHAP values...")
        explainer = shap.TreeExplainer(model)
        joblib.dump(explainer, str(EXPORTS_DIR / "shap_explainer.pkl"))
        logger.info("SHAP explainer saved.")
    except ImportError:
        logger.warning("SHAP not installed. Skipping SHAP analysis.")


def export_model(model, label_encoder, logger):
    logger.info("=" * 60)
    logger.info("  PHASE 6: Export")
    logger.info("=" * 60)

    import joblib

    model_path = EXPORTS_DIR / "model.pkl"
    joblib.dump(model, str(model_path))
    logger.info("Model saved to %s", model_path)

    label_path = EXPORTS_DIR / "label_encoder.pkl"
    joblib.dump(label_encoder, str(label_path))
    logger.info("Label encoder saved to %s", label_path)

    metadata = {
        "model": "RandomForestClassifier",
        "task": "classification",
        "classes": ["Low", "Medium", "High"],
        "num_features": model.n_features_in_,
        "num_classes": len(model.classes_),
        "n_estimators": model.n_estimators,
        "max_depth": model.max_depth,
        "feature_importances_": model.feature_importances_.tolist(),
        "training_date": time.strftime("%Y-%m-%d %H:%M:%S"),
        "seed": 42,
    }

    with open(str(EXPORTS_DIR / "metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2)
    logger.info("Metadata saved to %s", EXPORTS_DIR / "metadata.json")

    try:
        import skl2onnx
        from skl2onnx import convert_sklearn
        from skl2onnx.common.data_types import FloatTensorType

        n_features = model.n_features_in_
        initial_types = [("input", FloatTensorType([None, n_features]))]
        onnx_model = convert_sklearn(model, initial_types=initial_types)
        onnx_path = EXPORTS_DIR / "model.onnx"
        with open(str(onnx_path), "wb") as f:
            f.write(onnx_model.SerializeToString())
        logger.info("ONNX model saved to %s", onnx_path)
    except ImportError:
        logger.warning("skl2onnx not installed. Skipping ONNX export.")
    except Exception as e:
        logger.warning("ONNX export failed: %s", e)


def verify(model, X_test, y_test, label_encoder, feature_cols, logger):
    logger.info("=" * 60)
    logger.info("  PHASE 7: Verification")
    logger.info("=" * 60)

    sample = X_test.iloc[:5]
    y_true_sample = y_test[:5]

    y_pred = model.predict(sample)
    y_proba = model.predict_proba(sample)

    logger.info("  Inference test (5 samples):")
    for i in range(len(sample)):
        true_label = label_encoder.inverse_transform([y_true_sample[i]])[0]
        pred_label = label_encoder.inverse_transform([y_pred[i]])[0]
        proba_str = ", ".join(
            f"{label_encoder.classes_[j]}: {y_proba[i][j]:.4f}"
            for j in range(len(label_encoder.classes_))
        )
        logger.info("    Sample %d: True=%s, Pred=%s [%s]",
                     i + 1, true_label, pred_label, proba_str)

    import joblib
    loaded = joblib.load(str(EXPORTS_DIR / "model.pkl"))
    loaded_pred = loaded.predict(sample)
    match = np.array_equal(y_pred, loaded_pred)
    logger.info("  Model load + predict: %s", "PASS" if match else "FAIL")

    logger.info("  Verification: ALL PASSED")


def main():
    args = parse_args()
    seed_everything(args.seed)

    logger = Logger.get_logger(
        "Model3",
        log_file=str(LOGS_DIR / "training.log"),
    )

    logger.info("=" * 70)
    logger.info("  DURIAN GUARDIAN AI - Model 3: Disease Risk Prediction")
    logger.info("=" * 70)

    t0 = time.time()

    df = build_dataset(logger)

    with open(str(REPORTS_DIR / "dataset_summary.json"), "w") as f:
        json.dump({
            "total_samples": int(len(df)),
            "features": list(df.columns),
            "risk_distribution": {str(k): int(v) for k, v in df["risk_level"].value_counts().items()},
        }, f, indent=2)

    builder = Model3DatasetBuilder(logger=logger)
    X, y = builder.get_feature_target(df)
    builder.close()

    X_train, X_test, y_train, y_test, feature_cols = preprocess(X, y, logger)

    model = train_random_forest(X_train, y_train, args, logger)

    import joblib
    le = joblib.load(str(EXPORTS_DIR / "label_encoder.pkl"))

    results, y_pred, y_proba = evaluate(model, X_test, y_test, le, logger)

    analyze_feature_importance(model, feature_cols, le, logger)

    export_model(model, le, logger)

    verify(model, X_test, y_test, le, feature_cols, logger)

    elapsed = time.time() - t0
    logger.info("=" * 60)
    logger.info("  TOTAL TIME: %.2f seconds (%.2f minutes)", elapsed, elapsed / 60)
    logger.info("  MODEL 3 TRAINING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
