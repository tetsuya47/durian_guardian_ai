"""Risk Prediction Model (Model 3).

Supports scikit-learn and XGBoost/LightGBM/CatBoost models
for tabular disease risk prediction.
"""

from typing import Any, Dict, List, Optional, Tuple, Union

import numpy as np
import pandas as pd


class RiskPredictionModel:
    """Wrapper for tabular ML models (Random Forest, XGBoost, etc.).

    Provides unified interface across different ML libraries.
    """

    def __init__(
        self,
        model_type: str = "xgboost",
        params: Optional[Dict[str, Any]] = None,
    ) -> None:
        self.model_type = model_type
        self.params = params or {}
        self.model = None
        self.feature_importances_ = None
        self.label_encoder = None

    def _create_model(self):
        if self.model_type == "random_forest":
            from sklearn.ensemble import RandomForestClassifier
            params = {
                "n_estimators": 100,
                "max_depth": 10,
                "min_samples_split": 5,
                "random_state": 42,
                "n_jobs": -1,
                **self.params,
            }
            return RandomForestClassifier(**params)

        if self.model_type == "xgboost":
            try:
                import xgboost as xgb
            except ImportError:
                raise ImportError("xgboost not installed. pip install xgboost")
            params = {
                "n_estimators": 1000,
                "max_depth": 8,
                "learning_rate": 0.01,
                "subsample": 0.8,
                "colsample_bytree": 0.8,
                "random_state": 42,
                "n_jobs": -1,
                "tree_method": "hist",
                **self.params,
            }
            return xgb.XGBClassifier(**params)

        if self.model_type == "lightgbm":
            try:
                import lightgbm as lgb
            except ImportError:
                raise ImportError("lightgbm not installed. pip install lightgbm")
            params = {
                "n_estimators": 1000,
                "max_depth": 8,
                "learning_rate": 0.01,
                "subsample": 0.8,
                "colsample_bytree": 0.8,
                "random_state": 42,
                "n_jobs": -1,
                "verbose": -1,
                **self.params,
            }
            return lgb.LGBMClassifier(**params)

        if self.model_type == "catboost":
            try:
                from catboost import CatBoostClassifier
            except ImportError:
                raise ImportError("catboost not installed. pip install catboost")
            params = {
                "iterations": 1000,
                "depth": 8,
                "learning_rate": 0.01,
                "random_seed": 42,
                "verbose": 0,
                **self.params,
            }
            return CatBoostClassifier(**params)

        if self.model_type == "mlp":
            from sklearn.neural_network import MLPClassifier
            params = {
                "hidden_layer_sizes": (256, 128, 64),
                "activation": "relu",
                "max_iter": 1000,
                "random_state": 42,
                **self.params,
            }
            return MLPClassifier(**params)

        raise ValueError(f"Unknown model type: '{self.model_type}'")

    def fit(self, X: Union[np.ndarray, pd.DataFrame], y: Union[np.ndarray, pd.Series]) -> "RiskPredictionModel":
        if isinstance(y, pd.Series) and y.dtype == "object":
            from sklearn.preprocessing import LabelEncoder
            self.label_encoder = LabelEncoder()
            y = self.label_encoder.fit_transform(y)

        self.model = self._create_model()
        self.model.fit(X, y)

        if hasattr(self.model, "feature_importances_"):
            self.feature_importances_ = self.model.feature_importances_

        return self

    def predict(self, X: Union[np.ndarray, pd.DataFrame]) -> np.ndarray:
        if self.model is None:
            raise RuntimeError("Model not trained. Call fit() first.")
        return self.model.predict(X)

    def predict_proba(self, X: Union[np.ndarray, pd.DataFrame]) -> np.ndarray:
        if self.model is None:
            raise RuntimeError("Model not trained. Call fit() first.")
        if hasattr(self.model, "predict_proba"):
            return self.model.predict_proba(X)
        raise AttributeError(f"{self.model_type} does not support predict_proba")

    def evaluate(self, X: Union[np.ndarray, pd.DataFrame],
                 y: Union[np.ndarray, pd.Series]) -> Dict[str, float]:
        from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

        y_pred = self.predict(X)
        if self.label_encoder:
            y = self.label_encoder.transform(y) if isinstance(y, pd.Series) and y.dtype == "object" else y

        return {
            "accuracy": float(accuracy_score(y, y_pred)),
            "precision": float(precision_score(y, y_pred, average="weighted", zero_division=0)),
            "recall": float(recall_score(y, y_pred, average="weighted", zero_division=0)),
            "f1_score": float(f1_score(y, y_pred, average="weighted", zero_division=0)),
        }

    def save(self, path: str) -> None:
        import joblib
        import os
        os.makedirs(os.path.dirname(path), exist_ok=True)
        joblib.dump({"model": self.model, "label_encoder": self.label_encoder,
                     "model_type": self.model_type, "feature_importances_": self.feature_importances_},
                    path)

    def load(self, path: str) -> "RiskPredictionModel":
        import joblib
        data = joblib.load(path)
        self.model = data["model"]
        self.label_encoder = data.get("label_encoder")
        self.model_type = data.get("model_type", self.model_type)
        self.feature_importances_ = data.get("feature_importances_")
        return self
