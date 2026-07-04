"""Model 4: AI Recommendation Engine — training pipeline with full evaluation."""

import argparse
import json
import sys
import time
import yaml
from pathlib import Path
from datetime import datetime
from typing import Dict, Tuple

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import (classification_report, confusion_matrix,
                             accuracy_score, precision_score, recall_score,
                             f1_score, roc_auc_score,
                             r2_score, mean_absolute_error, mean_squared_error)
from sklearn.preprocessing import OrdinalEncoder, StandardScaler
from sklearn.inspection import permutation_importance

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from training.utils.logger import Logger

TRAIN_DIR = ROOT / "training_recommendation"
DATASETS_DIR = TRAIN_DIR / "datasets"
EXPORTS_DIR = TRAIN_DIR / "exports"
REPORTS_DIR = TRAIN_DIR / "reports"
LOGS_DIR = TRAIN_DIR / "logs"
CHECKPOINTS_DIR = TRAIN_DIR / "checkpoints"

CAT_COLS = [
    "health_status", "predicted_disease", "detection_prediction",
    "alert_type", "alert_priority", "season", "risk_level",
]
NUM_COLS = [
    "temperature", "humidity", "rainfall", "tree_age", "area_hectare",
    "confidence", "detection_confidence", "disease_history_count",
    "last_treatment_days", "alert_count", "days_since_last_inspection",
    "historical_disease_count", "historical_disease_frequency",
    "density_per_hectare", "priority_score",
]
CLASSIFICATION_TARGET = "priority_code"
REGRESSION_TARGETS = ["urgency_score", "estimated_loss_pct", "next_check_days"]


def load_config(path: str) -> dict:
    with open(path, "r") as f:
        return yaml.safe_load(f)


def preprocess(df: pd.DataFrame, logger, cat_cols=None, num_cols=None,
               fit=False, preprocessors=None):
    if cat_cols is None:
        cat_cols = CAT_COLS
    if num_cols is None:
        num_cols = NUM_COLS
    if preprocessors is None:
        preprocessors = {}

    available_cat = [c for c in cat_cols if c in df.columns]
    available_num = [c for c in num_cols if c in df.columns]

    X_cat = df[available_cat].fillna("unknown").astype(str).copy()
    if fit:
        cat_encoder = OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1)
        X_cat_encoded = cat_encoder.fit_transform(X_cat)
        preprocessors["cat_encoder"] = cat_encoder
        preprocessors["cat_columns"] = available_cat
    else:
        X_cat_encoded = preprocessors["cat_encoder"].transform(X_cat)

    cat_df = pd.DataFrame(
        X_cat_encoded,
        columns=[f"{c}_encoded" for c in available_cat],
        index=df.index,
    )

    X_num = df[available_num].copy()
    for col in available_num:
        if X_num[col].isna().any():
            if fit:
                fill_val = X_num[col].median()
                preprocessors.setdefault("num_fill", {})[col] = fill_val
            else:
                fill_val = preprocessors["num_fill"][col]
            X_num[col] = X_num[col].fillna(fill_val)

    if fit:
        scaler = StandardScaler()
        X_num_scaled = scaler.fit_transform(X_num)
        preprocessors["scaler"] = scaler
        preprocessors["num_columns"] = available_num
    else:
        X_num_scaled = preprocessors["scaler"].transform(X_num)

    num_df = pd.DataFrame(
        X_num_scaled,
        columns=[f"{c}_scaled" for c in available_num],
        index=df.index,
    )

    X = pd.concat([cat_df, num_df], axis=1)
    logger.info("Preprocessed features: %d columns", X.shape[1])
    return X, preprocessors


def train_classifier(X_train, y_train, config: dict, logger) -> RandomForestClassifier:
    params = config.get("classification", {})
    clf = RandomForestClassifier(
        n_estimators=params.get("n_estimators", 300),
        max_depth=params.get("max_depth", None),
        min_samples_split=params.get("min_samples_split", 5),
        min_samples_leaf=params.get("min_samples_leaf", 2),
        class_weight=params.get("class_weight", "balanced"),
        random_state=params.get("random_state", 42),
        n_jobs=-1,
    )
    clf.fit(X_train, y_train)
    return clf


def train_regressor(X_train, y_train, target: str, config: dict, logger) -> RandomForestRegressor:
    params = config.get("regression", {})
    reg = RandomForestRegressor(
        n_estimators=params.get("n_estimators", 200),
        max_depth=params.get("max_depth", 15),
        min_samples_split=params.get("min_samples_split", 5),
        min_samples_leaf=params.get("min_samples_leaf", 2),
        random_state=params.get("random_state", 42),
        n_jobs=-1,
    )
    reg.fit(X_train, y_train)
    return reg


def evaluate_classifier_full(model, X, y, split_name: str, logger) -> dict:
    y_pred = model.predict(X)
    y_proba = model.predict_proba(X)

    acc = accuracy_score(y, y_pred)
    cm = confusion_matrix(y, y_pred)
    cr = classification_report(y, y_pred, output_dict=True)

    n_classes = len(model.classes_)
    roc_auc = None
    if n_classes == 2:
        roc_auc = float(roc_auc_score(y, y_proba[:, 1]))
    elif n_classes > 2:
        roc_auc = float(roc_auc_score(y, y_proba, multi_class="ovr"))

    precision = precision_score(y, y_pred, average="weighted", zero_division=0)
    recall = recall_score(y, y_pred, average="weighted", zero_division=0)
    f1 = f1_score(y, y_pred, average="weighted", zero_division=0)

    logger.info("[%s] Classification: acc=%.4f, precision=%.4f, recall=%.4f, f1=%.4f, roc_auc=%s",
                split_name, acc, precision, recall, f1,
                f"{roc_auc:.4f}" if roc_auc else "N/A")
    logger.info("[%s] Confusion Matrix:\n%s", split_name, cm)

    return {
        "accuracy": float(acc),
        "precision": float(precision),
        "recall": float(recall),
        "f1": float(f1),
        "roc_auc": roc_auc,
        "confusion_matrix": cm.tolist(),
        "classification_report": cr,
        "predictions": y_pred.tolist(),
    }


def evaluate_regressor_full(model, X, y, target: str, split_name: str, logger) -> dict:
    y_pred = model.predict(X)

    r2 = r2_score(y, y_pred)
    mae = mean_absolute_error(y, y_pred)
    rmse = float(np.sqrt(mean_squared_error(y, y_pred)))
    mape_val = None
    mask = y > 0
    if mask.sum() > 0:
        mape_val = float(np.mean(np.abs((y[mask] - y_pred[mask]) / y[mask])) * 100)

    logger.info("[%s] %s: R2=%.4f, MAE=%.4f, RMSE=%.4f%s",
                split_name, target, r2, mae, rmse,
                f", MAPE={mape_val:.2f}%" if mape_val else "")

    return {
        "r2": float(r2),
        "mae": float(mae),
        "rmse": rmse,
        "mape": mape_val,
        "predictions": y_pred.tolist(),
    }


def extract_feature_importance(models: dict, feature_names: list, logger) -> dict:
    importance_data = {}

    if "classifier" in models:
        clf = models["classifier"]
        importances = clf.feature_importances_
        indices = np.argsort(importances)[::-1]
        importance_data["classifier"] = {
            "feature_importances_": [
                {"feature": feature_names[i], "importance": float(importances[i])}
                for i in indices
            ]
        }

    for target in REGRESSION_TARGETS:
        name = f"regressor_{target}"
        if name in models:
            reg = models[name]
            importances = reg.feature_importances_
            indices = np.argsort(importances)[::-1]
            importance_data[name] = {
                "feature_importances_": [
                    {"feature": feature_names[i], "importance": float(importances[i])}
                    for i in indices
                ]
            }

    return importance_data


def check_overfitting(metrics: dict, logger) -> dict:
    findings = []
    overfitting_detected = False

    if "classification" in metrics:
        train_acc = metrics["classification"].get("train", {}).get("accuracy", 0)
        val_acc = metrics["classification"].get("val", {}).get("accuracy", 0)
        test_acc = metrics["classification"].get("test", {}).get("accuracy", 0)

        gap_train_val = train_acc - val_acc
        gap_train_test = train_acc - test_acc

        if gap_train_val > 0.05:
            overfitting_detected = True
            findings.append(f"Classification train-val gap: {gap_train_val:.4f} (> 0.05)")
        if gap_train_test > 0.05:
            overfitting_detected = True
            findings.append(f"Classification train-test gap: {gap_train_test:.4f} (> 0.05)")

        if not findings:
            findings.append(f"Classification gaps: train-val={gap_train_val:.4f}, train-test={gap_train_test:.4f} (OK)")

    for target in REGRESSION_TARGETS:
        if target in metrics.get("regression", {}):
            train_r2 = metrics["regression"][target].get("train", {}).get("r2", 0)
            val_r2 = metrics["regression"][target].get("val", {}).get("r2", 0)
            test_r2 = metrics["regression"][target].get("test", {}).get("r2", 0)

            gap_train_val = train_r2 - val_r2
            gap_train_test = train_r2 - test_r2

            if gap_train_val > 0.05:
                overfitting_detected = True
                findings.append(f"{target} train-val R2 gap: {gap_train_val:.4f} (> 0.05)")
            if gap_train_test > 0.05:
                overfitting_detected = True
                findings.append(f"{target} train-test R2 gap: {gap_train_test:.4f} (> 0.05)")

            if gap_train_val <= 0.05 and gap_train_test <= 0.05:
                findings.append(f"{target} R2 gaps: train-val={gap_train_val:.4f}, train-test={gap_train_test:.4f} (OK)")

    if overfitting_detected:
        logger.warning("OVERFITTING DETECTED: %s", "; ".join(findings))
    else:
        logger.info("Overfitting check: %s", "; ".join(findings))

    return {"overfitting_detected": overfitting_detected, "details": findings}


def save_checkpoints(models: dict, preprocessors: dict, metrics: dict, is_best: bool, logger):
    import joblib
    CHECKPOINTS_DIR.mkdir(parents=True, exist_ok=True)

    prefix = "best" if is_best else "last"
    for name, model in models.items():
        path = CHECKPOINTS_DIR / f"{prefix}_{name}.pkl"
        joblib.dump(model, str(path))

    preproc_path = CHECKPOINTS_DIR / f"{prefix}_preprocessor.pkl"
    joblib.dump(preprocessors, str(preproc_path))

    meta_path = CHECKPOINTS_DIR / f"{prefix}_metrics.json"
    with open(meta_path, "w") as f:
        json.dump(metrics, f, indent=2, default=str)


def main():
    parser = argparse.ArgumentParser(description="Model 4: AI Recommendation Engine Training")
    parser.add_argument("--config", type=str,
                        default=str(TRAIN_DIR / "configs" / "model4.yaml"),
                        help="Path to model config YAML")
    parser.add_argument("--dataset", type=str, default=None,
                        help="Path to dataset CSV (overrides config)")
    args = parser.parse_args()

    config = load_config(args.config)
    train_cfg = config.get("training", {})
    dataset_path = args.dataset or str(ROOT / config["dataset"]["train"])

    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOGS_DIR / f"train_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    logger = Logger.get_logger("Model4Train", log_file=str(log_file))

    logger.info("=" * 60)
    logger.info("  MODEL 4: AI RECOMMENDATION ENGINE — FULL TRAINING")
    logger.info("=" * 60)
    logger.info("Config: %s", args.config)
    logger.info("Dataset: %s", dataset_path)

    ts_start = time.time()

    df = pd.read_csv(dataset_path)
    logger.info("Loaded dataset: %d rows, %d cols", len(df), len(df.columns))

    test_size = train_cfg.get("test_size", 0.20)
    val_size = train_cfg.get("val_size", 0.15)
    seed = train_cfg.get("seed", 42)

    train_val, test = train_test_split(df, test_size=test_size, random_state=seed)
    val_frac = val_size / (1 - test_size)
    train, val = train_test_split(train_val, test_size=val_frac, random_state=seed)
    logger.info("Split: Train=%d, Val=%d, Test=%d", len(train), len(val), len(test))

    X_train, preprocessors = preprocess(train, logger, fit=True)
    X_val, _ = preprocess(val, logger, fit=False, preprocessors=preprocessors)
    X_test, _ = preprocess(test, logger, fit=False, preprocessors=preprocessors)

    logger.info("Training classifier (RandomForest, %d estimators)...",
                config.get("classification", {}).get("n_estimators", 300))
    ts_clf = time.time()
    clf = train_classifier(X_train, train[CLASSIFICATION_TARGET].values, config, logger)
    clf_time = time.time() - ts_clf
    logger.info("Classifier trained in %.2fs", clf_time)

    regressors = {}
    reg_times = {}
    for target in REGRESSION_TARGETS:
        logger.info("Training regressor for %s...", target)
        ts_reg = time.time()
        reg = train_regressor(X_train, train[target].values, target, config, logger)
        reg_time = time.time() - ts_reg
        regressors[target] = reg
        reg_times[target] = reg_time
        logger.info("  %s trained in %.2fs", target, reg_time)

    models = {"classifier": clf}
    for target in REGRESSION_TARGETS:
        models[f"regressor_{target}"] = regressors[target]

    total_train_time = time.time() - ts_start
    logger.info("Total training time: %.2fs (%.2f min)", total_train_time, total_train_time / 60)

    feature_names = list(X_train.columns)
    logger.info("Extracting feature importances...")
    importance_data = extract_feature_importance(models, feature_names, logger)

    splits = {
        "train": (X_train, train),
        "val": (X_val, val),
        "test": (X_test, test),
    }

    eval_results = {"classification": {}, "regression": {target: {} for target in REGRESSION_TARGETS}}
    for split_name, (X, data) in splits.items():
        y_cls = data[CLASSIFICATION_TARGET].values
        eval_results["classification"][split_name] = evaluate_classifier_full(
            clf, X, y_cls, f"Classification/{split_name}", logger
        )
        for target in REGRESSION_TARGETS:
            y_reg = data[target].values
            eval_results["regression"][target][split_name] = evaluate_regressor_full(
                regressors[target], X, y_reg, target, f"{target}/{split_name}", logger
            )

    logger.info("Checking for overfitting...")
    overfitting = check_overfitting(eval_results, logger)

    logger.info("Saving best and last checkpoints...")
    save_checkpoints(models, preprocessors, eval_results, is_best=True, logger=logger)
    save_checkpoints(models, preprocessors, eval_results, is_best=False, logger=logger)

    logger.info("Saving artifacts...")
    import joblib
    EXPORTS_DIR.mkdir(parents=True, exist_ok=True)
    for name, model in models.items():
        joblib.dump(model, str(EXPORTS_DIR / f"{name}.pkl"))
    joblib.dump(preprocessors, str(EXPORTS_DIR / "preprocessor.pkl"))

    priority_codes = {"Low": 0, "Medium": 1, "High": 2, "Critical": 3}
    label_encoder_data = {
        "classes": sorted(priority_codes.keys()),
        "mapping": priority_codes,
        "inverse_mapping": {v: k for k, v in priority_codes.items()},
    }
    with open(EXPORTS_DIR / "label_encoder.pkl", "w") as f:
        json.dump(label_encoder_data, f, indent=2)

    with open(EXPORTS_DIR / "feature_columns.json", "w") as f:
        json.dump(feature_names, f, indent=2)

    metadata = {
        "model": "Model4_Recommendation",
        "task": "multi_task",
        "classification_target": CLASSIFICATION_TARGET,
        "regression_targets": REGRESSION_TARGETS,
        "num_features": len(feature_names),
        "feature_columns": feature_names,
        "classification_classes": clf.classes_.tolist(),
        "cat_columns": CAT_COLS,
        "num_columns": NUM_COLS,
        "training_date": str(datetime.now()),
        "seed": seed,
        "train_samples": len(train),
        "val_samples": len(val),
        "test_samples": len(test),
        "training_time_seconds": total_train_time,
        "training_time_minutes": total_train_time / 60,
        "classification_training_time_seconds": clf_time,
        "regression_training_times": reg_times,
        "test_evaluation": eval_results,
        "overfitting_check": overfitting,
    }

    with open(EXPORTS_DIR / "metadata.json", "w") as f:
        json.dump(metadata, f, indent=2, default=str)

    config_snapshot = {}
    for name, model in models.items():
        config_snapshot[name] = {k: str(v) if isinstance(v, Path) else v
                                 for k, v in model.get_params().items()}
    with open(EXPORTS_DIR / "model_config.json", "w") as f:
        json.dump(config_snapshot, f, indent=2, default=str)

    training_summary = {
        "training_completed": True,
        "training_date": str(datetime.now()),
        "dataset": str(dataset_path),
        "config": str(args.config),
        "samples": {"train": len(train), "val": len(val), "test": len(test)},
        "features": len(feature_names),
        "training_time_seconds": total_train_time,
        "classification_test_accuracy": eval_results["classification"]["test"]["accuracy"],
        "classification_test_f1": eval_results["classification"]["test"]["f1"],
        "regression_test_metrics": {
            target: eval_results["regression"][target]["test"]
            for target in REGRESSION_TARGETS
        },
        "overfitting_detected": overfitting["overfitting_detected"],
        "artifact_paths": {
            "exports": str(EXPORTS_DIR),
            "checkpoints": str(CHECKPOINTS_DIR),
            "reports": str(REPORTS_DIR),
        },
    }
    with open(EXPORTS_DIR / "training_summary.json", "w") as f:
        json.dump(training_summary, f, indent=2, default=str)

    logger.info("Feature importance for classifier:")
    for item in importance_data.get("classifier", {}).get("feature_importances_", [])[:10]:
        logger.info("  %s: %.4f", item["feature"], item["importance"])

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    with open(REPORTS_DIR / "evaluation_report.json", "w") as f:
        json.dump(eval_results, f, indent=2, default=str)

    with open(REPORTS_DIR / "feature_importance.json", "w") as f:
        json.dump(importance_data, f, indent=2, default=str)

    with open(REPORTS_DIR / "training_summary.json", "w") as f:
        json.dump(training_summary, f, indent=2, default=str)

    logger.info("=" * 60)
    logger.info("  TRAINING COMPLETE")
    logger.info("  Test Accuracy: %.4f", eval_results["classification"]["test"]["accuracy"])
    logger.info("  Test F1: %.4f", eval_results["classification"]["test"]["f1"])
    for target in REGRESSION_TARGETS:
        t_metrics = eval_results["regression"][target]["test"]
        logger.info("  %s: R2=%.4f, MAE=%.4f", target, t_metrics["r2"], t_metrics["mae"])
    logger.info("  Time: %.2fs (%.2f min)", total_train_time, total_train_time / 60)
    logger.info("  Artifacts: %s", EXPORTS_DIR)
    logger.info("  Checkpoints: %s", CHECKPOINTS_DIR)
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
