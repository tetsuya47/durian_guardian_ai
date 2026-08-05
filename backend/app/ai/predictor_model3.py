"""Model 3: Random Forest Disease Risk Predictor for FastAPI Backend.

Singleton thread-safe inference wrapper for Model 3 artifacts stored in
`training/model3/exports/`.
"""
from __future__ import annotations

import json
import logging
import threading
from pathlib import Path
from typing import Any, Optional

import joblib
import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)

import os

# Base exports directory with flexible multi-path resolution
def _get_model3_exports_dir() -> Path:
    env_dir = os.getenv("MODEL3_EXPORTS_DIR")
    if env_dir and Path(env_dir).exists():
        return Path(env_dir)

    # 1. Local path inside backend (recommended for Render)
    local_dir = Path(__file__).resolve().parent / "model3_exports"
    if local_dir.exists():
        return local_dir

    # 2. Standard path relative to repo root
    repo_dir = (
        Path(__file__).resolve().parent.parent.parent.parent
        / "training"
        / "model3"
        / "exports"
    )
    if repo_dir.exists():
        return repo_dir

    # 3. Secondary path inside backend or export dir
    backend_dir = (
        Path(__file__).resolve().parent.parent.parent
        / "training"
        / "model3"
        / "exports"
    )
    if backend_dir.exists():
        return backend_dir

    return local_dir

_EXPORTS_DIR = _get_model3_exports_dir()


class Model3Predictor:
    """Thread-safe singleton predictor for Model 3 (Random Forest Disease Risk)."""

    _instance: Optional["Model3Predictor"] = None
    _lock = threading.Lock()

    def __new__(cls) -> "Model3Predictor":
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    instance = super().__new__(cls)
                    instance._initialized = False
                    cls._instance = instance
        return cls._instance

    def __init__(self) -> None:
        if self._initialized:
            return
        with self._lock:
            if self._initialized:
                return
            self._load_artifacts()
            self._initialized = True
            logger.info("Model3Predictor initialized successfully from %s", _EXPORTS_DIR)

    def _load_artifacts(self) -> None:
        model_path = _EXPORTS_DIR / "model.pkl"
        preproc_path = _EXPORTS_DIR / "preprocessor.pkl"
        feat_path = _EXPORTS_DIR / "feature_columns.json"
        meta_path = _EXPORTS_DIR / "metadata.json"

        if not model_path.exists() or not preproc_path.exists():
            raise RuntimeError(f"Model 3 export artifacts missing at {_EXPORTS_DIR}")

        try:
            self._model = joblib.load(str(model_path))
            self._preprocessor = joblib.load(str(preproc_path))
            with open(feat_path, "r", encoding="utf-8") as f:
                self._feature_columns = json.load(f)
            with open(meta_path, "r", encoding="utf-8") as f:
                self._metadata = json.load(f)
            logger.info(
                "Model 3 artifacts loaded: model=%s, features=%d",
                type(self._model).__name__,
                len(self._feature_columns),
            )
        except Exception as exc:
            raise RuntimeError(f"Failed to load Model 3 artifacts: {exc}") from exc

    def predict(self, tree_data: dict[str, Any]) -> dict[str, Any]:
        """Run Random Forest risk prediction on tree & weather feature dict.

        Args:
            tree_data: Dict containing 14 input features. Missing features will
                       be filled with safe defaults.

        Returns:
            Dict containing:
                - risk_level: str ("Khỏe mạnh", "Nguy cơ", "Bệnh nhẹ", "Bệnh nặng")
                - risk_score: float (0.0 to 1.0)
                - probabilities: dict[str, float]
                - top_factors: list[dict[str, Any]] (top 5 feature importances)
        """
        cat_cols = self._preprocessor["cat_columns"]
        num_cols = self._preprocessor["num_columns"]
        ordinal_encoder = self._preprocessor["ordinal_encoder"]
        scaler = self._preprocessor["scaler"]
        label_encoder = self._preprocessor["label_encoder"]

        # Build single-row feature input
        row: dict[str, Any] = {}
        for col in cat_cols:
            row[col] = str(tree_data.get(col, "unknown"))
        for col in num_cols:
            val = tree_data.get(col, 0)
            try:
                row[col] = float(val) if val is not None else 0.0
            except (ValueError, TypeError):
                row[col] = 0.0

        df = pd.DataFrame([row])

        # Fill NaNs for numerical features
        for col in num_cols:
            if df[col].isna().any():
                df[col] = df[col].fillna(0.0)

        # Ordinal encode categorical features & scale numerical features
        try:
            X_cat = ordinal_encoder.transform(df[cat_cols])
            cat_df = pd.DataFrame(
                X_cat,
                columns=[f"{c}_encoded" for c in cat_cols],
                index=df.index,
            )

            X_num = scaler.transform(df[num_cols])
            num_df = pd.DataFrame(
                X_num,
                columns=[f"{c}_scaled" for c in num_cols],
                index=df.index,
            )

            X_final = pd.concat([cat_df, num_df], axis=1)

            pred_class = int(self._model.predict(X_final)[0])
            pred_proba = self._model.predict_proba(X_final)[0]

            risk_level = str(label_encoder.inverse_transform([pred_class])[0])

            # Class probabilities
            top_indices = np.argsort(pred_proba)[::-1]
            probabilities = {
                str(label_encoder.classes_[i]): round(float(pred_proba[i]), 4)
                for i in top_indices
            }

            # Calculate Weighted Disease Risk Severity Score (0.0 to 1.0)
            # Classes in model.pkl: ['Cao', 'Thấp', 'Trung bình']
            weighted_risk_score = 0.0
            for i, cls_name in enumerate(label_encoder.classes_):
                cls_str = str(cls_name).lower()
                prob = float(pred_proba[i])
                if "cao" in cls_str or "high" in cls_str or "nặng" in cls_str:
                    weighted_risk_score += prob * 0.85
                elif "trung bình" in cls_str or "medium" in cls_str or "moderate" in cls_str or "nguy cơ" in cls_str:
                    weighted_risk_score += prob * 0.45
                else: # Thấp / Low
                    weighted_risk_score += prob * 0.05

            # Top 5 feature importances
            feature_imp = self._model.feature_importances_
            top_feat_idx = np.argsort(feature_imp)[::-1][:5]
            top_factors = [
                {
                    "feature": self._feature_columns[i],
                    "importance": round(float(feature_imp[i]), 4),
                }
                for i in top_feat_idx
            ]

            return {
                "risk_level": risk_level,
                "risk_score": round(weighted_risk_score, 4),
                "probabilities": probabilities,
                "top_factors": top_factors,
            }
        except Exception as exc:
            logger.error("Error during Model 3 inference: %s", exc, exc_info=True)
            return {
                "risk_level": "Nguy cơ",
                "risk_score": 0.5,
                "probabilities": {"Nguy cơ": 0.5, "Khỏe mạnh": 0.5},
                "top_factors": [],
            }
