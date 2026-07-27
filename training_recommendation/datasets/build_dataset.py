"""Build Model 4 recommendation dataset from MongoDB with feature engineering and rule-based labels."""

import sys
import json
from pathlib import Path
from typing import Dict, Optional, Tuple
from datetime import datetime

import numpy as np
import pandas as pd
from pymongo import MongoClient

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))

from database.config import settings
from training.utils.logger import Logger
from training_recommendation.rules.rule_engine import RecommendationRuleEngine

SEASON_MAP = {1: "Khô", 2: "Khô", 3: "Khô", 4: "Khô",
              5: "Mưa", 6: "Mưa", 7: "Mưa", 8: "Mưa",
              9: "Mưa", 10: "Mưa", 11: "Mưa", 12: "Khô"}

FEATURE_COLS = [
    "temperature", "humidity", "rainfall", "tree_age", "area_hectare",
    "confidence", "detection_confidence", "disease_history_count",
    "last_treatment_days", "alert_count", "days_since_last_inspection",
    "historical_disease_count", "historical_disease_frequency",
    "density_per_hectare", "priority_score",
    "health_status", "predicted_disease", "detection_prediction",
    "alert_type", "alert_priority", "season", "risk_level",
]

CATEGORICAL_COLS = [
    "health_status", "predicted_disease", "detection_prediction",
    "alert_type", "alert_priority", "season", "risk_level",
]

TARGET_LABELS = [
    "priority", "priority_score", "priority_code", "recommended_action",
    "urgency_score", "estimated_loss_pct", "next_check_days",
]


class Model4DatasetBuilder:
    def __init__(self, logger=None):
        self.logger = logger or Logger.get_logger("Model4DatasetBuilder")
        self.rule_engine = RecommendationRuleEngine()
        self.client = None
        self.db = None

    def connect(self):
        uri = settings.mongodb_uri_with_credentials
        kwargs = settings.connection_kwargs
        self.client = MongoClient(uri, **kwargs)
        self.client.admin.command("ping")
        self.db = self.client[settings.DATABASE_NAME]
        self.logger.info("Connected to MongoDB: %s", settings.DATABASE_NAME)

    def close(self):
        if self.client:
            self.client.close()

    def _load_inspections(self) -> pd.DataFrame:
        fields = {
            "_id": 0, "inspection_code": 1, "tree_id": 1, "farm_id": 1,
            "inspection_date": 1, "temperature": 1, "humidity": 1,
            "rainfall": 1, "rainfall_mm": 1,
            "health_status": 1, "predicted_disease": 1, "confidence": 1,
        }
        docs = list(self.db.inspections.find({}, fields))
        df = pd.DataFrame(docs)
        if "rainfall_mm" in df.columns and "rainfall" not in df.columns:
            df.rename(columns={"rainfall_mm": "rainfall"}, inplace=True)
        elif "rainfall_mm" in df.columns and "rainfall" in df.columns:
            df["rainfall"] = df["rainfall"].fillna(df["rainfall_mm"])
            df.drop(columns=["rainfall_mm"], inplace=True)
        df["inspection_date"] = pd.to_datetime(df["inspection_date"])
        df = df.sort_values(["tree_id", "inspection_date"])
        self.logger.info("Loaded %d inspections", len(df))
        return df

    def _load_trees(self) -> pd.DataFrame:
        fields = {"_id": 1, "tree_code": 1, "farm_id": 1, "zone_id": 1,
                  "variety": 1, "planting_date": 1, "tree_age": 1, "status": 1}
        docs = list(self.db.trees.find({}, fields))
        df = pd.DataFrame(docs)
        df.rename(columns={"_id": "tree_id"}, inplace=True)
        self.logger.info("Loaded %d trees", len(df))
        return df

    def _load_farms(self) -> pd.DataFrame:
        fields = {"_id": 1, "farm_code": 1, "area_hectare": 1, "tree_count": 1}
        docs = list(self.db.farms.find({}, fields))
        df = pd.DataFrame(docs)
        df.rename(columns={"_id": "farm_id"}, inplace=True)
        self.logger.info("Loaded %d farms", len(df))
        return df

    def _load_detection_results(self) -> pd.DataFrame:
        fields = {"_id": 0, "inspection_id": 1, "prediction": 1, "confidence": 1}
        docs = list(self.db.detection_results.find({}, fields))
        df = pd.DataFrame(docs)
        df.rename(columns={"prediction": "detection_prediction",
                           "confidence": "detection_confidence"}, inplace=True)
        self.logger.info("Loaded %d detection results", len(df))
        return df

    def _load_disease_history(self) -> pd.DataFrame:
        fields = {"_id": 0, "tree_id": 1, "disease": 1, "date": 1, "action": 1}
        docs = list(self.db.disease_history.find({}, fields))
        df = pd.DataFrame(docs)
        df["date"] = pd.to_datetime(df["date"])
        self.logger.info("Loaded %d disease history records", len(df))
        return df

    def _load_alerts(self) -> pd.DataFrame:
        fields = {"_id": 0, "tree_id": 1, "farm_id": 1, "alert_type": 1,
                  "priority": 1, "date": 1}
        docs = list(self.db.alerts.find({}, fields))
        df = pd.DataFrame(docs)
        df.rename(columns={"priority": "alert_priority"}, inplace=True)
        df["date"] = pd.to_datetime(df["date"])
        self.logger.info("Loaded %d alerts", len(df))
        return df

    def _load_model3_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Compute Model 3 risk features by loading model and running batch prediction."""
        try:
            import joblib
            model3_dir = ROOT / "training" / "model3" / "exports"
            model_path = model3_dir / "model.pkl"
            preproc_path = model3_dir / "preprocessor.pkl"
            if not model_path.exists():
                self.logger.warning("Model 3 model not found at %s", model_path)
                return pd.DataFrame()

            model = joblib.load(str(model_path))
            preprocessor = joblib.load(str(preproc_path))

            ordinal_encoder = preprocessor["ordinal_encoder"]
            scaler = preprocessor["scaler"]
            label_encoder = preprocessor["label_encoder"]
            cat_cols = preprocessor["cat_columns"]
            num_cols = preprocessor["num_columns"]

            available_cat = [c for c in cat_cols if c in df.columns]
            available_num = [c for c in num_cols if c in df.columns]
            missing_cat = [c for c in cat_cols if c not in df.columns]
            missing_num = [c for c in num_cols if c not in df.columns]
            if missing_cat:
                self.logger.warning("Missing Model 3 cat_cols: %s", missing_cat)
            if missing_num:
                self.logger.warning("Missing Model 3 num_cols: %s", missing_num)

            X_cat = df[available_cat].fillna("unknown").copy()
            for col in available_cat:
                X_cat[col] = X_cat[col].astype(str)

            X_num = df[available_num].copy()
            for col in available_num:
                if X_num[col].isna().any():
                    X_num[col] = X_num[col].fillna(X_num[col].median())

            cat_encoded = ordinal_encoder.transform(X_cat)
            cat_df = pd.DataFrame(
                cat_encoded,
                columns=[f"{c}_encoded" for c in available_cat],
                index=df.index,
            )

            num_scaled = scaler.transform(X_num)
            num_df = pd.DataFrame(
                num_scaled,
                columns=[f"{c}_scaled" for c in available_num],
                index=df.index,
            )

            X_final = pd.concat([cat_df, num_df], axis=1)

            pred_classes = model.predict(X_final)
            pred_probas = model.predict_proba(X_final)

            risk_levels = label_encoder.inverse_transform(pred_classes)
            risk_scores = np.max(pred_probas, axis=1)

            result = pd.DataFrame({
                "risk_score": risk_scores,
                "risk_level": risk_levels,
            }, index=df.index)

            self.logger.info("Model 3 predictions computed: %d rows", len(result))
            self.logger.info("Risk distribution:\n%s", result["risk_level"].value_counts())
            return result

        except Exception as e:
            self.logger.warning("Could not load Model 3 features: %s", e)
            import traceback
            self.logger.warning(traceback.format_exc())
            return pd.DataFrame()

    def build_dataset(self) -> pd.DataFrame:
        if self.db is None:
            self.connect()

        inspections = self._load_inspections()
        trees = self._load_trees()
        farms = self._load_farms()
        detection_results = self._load_detection_results()
        disease_history = self._load_disease_history()
        alerts = self._load_alerts()

        self.logger.info("Joining inspections with trees...")
        df = inspections.merge(trees, on="tree_id", how="left", suffixes=("", "_tree"))
        self.logger.info("  After tree join: %d rows", len(df))

        self.logger.info("Joining with farms...")
        df = df.merge(farms, on="farm_id", how="left", suffixes=("", "_farm"))

        self.logger.info("Joining with detection results via inspection_id...")
        insp_to_code = inspections[["inspection_code"]].reset_index()
        insp_to_code.rename(columns={"index": "_insp_idx"}, inplace=True)
        self.logger.info("  Need detection_results.inspection_id which requires lookup...")

        lookup = list(self.db.inspections.find(
            {}, {"_id": 1, "inspection_code": 1}
        ))
        id_map = {str(d["_id"]): d["inspection_code"] for d in lookup}
        detection_results["inspection_code"] = detection_results["inspection_code"] = (
            detection_results.get("inspection_id", pd.Series(dtype=str)).astype(str).map(id_map)
        )
        df = df.merge(
            detection_results.drop(columns=["inspection_id"], errors="ignore"),
            on="inspection_code", how="left", suffixes=("", "_detect"),
        )
        self.logger.info("  After detection join: %d rows", len(df))

        self.logger.info("Computing disease history features...")
        disease_count_by_tree = disease_history.groupby("tree_id").size().to_dict()
        disease_date_by_tree = disease_history.groupby("tree_id")["date"].max().to_dict()

        df["disease_history_count"] = df["tree_id"].map(disease_count_by_tree).fillna(0).astype(int)

        max_treatment = df["tree_id"].map(disease_date_by_tree)
        df["last_treatment_days"] = (df["inspection_date"] - max_treatment).dt.days
        df["last_treatment_days"] = df["last_treatment_days"].where(
            (df["last_treatment_days"].notna()) & (df["last_treatment_days"] >= 0),
            None,
        )

        df["days_since_last_treatment"] = df["last_treatment_days"]

        df["historical_disease_count"] = df["tree_id"].map(disease_count_by_tree).fillna(0).astype(int)

        df["historical_disease_frequency"] = np.where(
            df["tree_age"].notna() & (df["tree_age"] > 0),
            df["historical_disease_count"] / df["tree_age"],
            df["historical_disease_count"],
        )

        self.logger.info("Computing alert features...")
        alert_count_by_tree = alerts.groupby("tree_id").size().to_dict()
        alert_type_by_tree = alerts.groupby("tree_id")["alert_type"].apply(
            lambda x: x.mode().iloc[0] if not x.mode().empty else None
        ).to_dict()
        alert_priority_by_tree = alerts.groupby("tree_id")["alert_priority"].apply(
            lambda x: x.mode().iloc[0] if not x.mode().empty else None
        ).to_dict()

        df["alert_count"] = df["tree_id"].map(alert_count_by_tree).fillna(0).astype(int)
        df["alert_type"] = df["tree_id"].map(alert_type_by_tree).fillna("None")
        df["alert_priority"] = df["tree_id"].map(alert_priority_by_tree).fillna("None")

        self.logger.info("Computing derived features...")
        df["season"] = df["inspection_date"].dt.month.map(SEASON_MAP)

        df["density_per_hectare"] = np.where(
            (df["area_hectare"].notna()) & (df["area_hectare"] > 0),
            df["tree_count"] / df["area_hectare"],
            np.nan,
        )

        df["days_since_last_inspection"] = (
            df.groupby("tree_id")["inspection_date"].diff().dt.days
        )

        self.logger.info("Loading Model 3 risk features...")
        model3_df = self._load_model3_features(df)
        if not model3_df.empty:
            for col in ["risk_score", "risk_level"]:
                df[col] = model3_df[col]
            df["risk_score"] = df["risk_score"].fillna(0.0)
            df["risk_level"] = df["risk_level"].fillna("Thấp")
        else:
            self.logger.warning("Model 3 features not available, computing fallback risk...")
            df["risk_score"] = 0.0
            df["risk_level"] = "Thấp"

        self.logger.info("Computing rule-based recommendation labels...")
        labels_list = []
        for _, row in df.iterrows():
            labels = self.rule_engine.compute_labels(row.to_dict())
            labels_list.append(labels)
        labels_df = pd.DataFrame(labels_list)
        df = pd.concat([df, labels_df], axis=1)

        self.logger.info("Dataset built: %d samples, %d features, %d targets",
                         len(df), len(FEATURE_COLS), len(TARGET_LABELS))
        self.logger.info("Priority distribution:\n%s", df["priority"].value_counts())

        return df

    def split_dataset(self, df: pd.DataFrame, val_frac: float = 0.15,
                      test_frac: float = 0.15, seed: int = 42
                      ) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
        np.random.seed(seed)
        indices = np.random.permutation(len(df))
        n_val = int(len(df) * val_frac)
        n_test = int(len(df) * test_frac)

        val_idx = indices[:n_val]
        test_idx = indices[n_val:n_val + n_test]
        train_idx = indices[n_val + n_test:]

        train_df = df.iloc[train_idx].copy().reset_index(drop=True)
        val_df = df.iloc[val_idx].copy().reset_index(drop=True)
        test_df = df.iloc[test_idx].copy().reset_index(drop=True)

        self.logger.info("Split: train=%d, val=%d, test=%d",
                         len(train_df), len(val_df), len(test_df))
        return train_df, val_df, test_df

    def save_dataset(self, df: pd.DataFrame, path: str):
        p = Path(path)
        p.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(p, index=False)
        self.logger.info("Dataset saved to %s (%d rows)", p, len(df))

    def get_feature_target_split(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.DataFrame]:
        available_features = [c for c in FEATURE_COLS if c in df.columns]
        missing_features = [c for c in FEATURE_COLS if c not in df.columns]
        if missing_features:
            self.logger.warning("Missing feature columns: %s", missing_features)

        available_targets = [c for c in TARGET_LABELS if c in df.columns]
        missing_targets = [c for c in TARGET_LABELS if c not in df.columns]
        if missing_targets:
            self.logger.warning("Missing target columns: %s", missing_targets)

        X = df[available_features].copy()
        y = df[available_targets].copy()

        self.logger.info("Features (%d): %s", len(available_features), available_features)
        self.logger.info("Targets (%d): %s", len(available_targets), available_targets)

        return X, y


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Build Model 4 recommendation dataset")
    parser.add_argument("--output", type=str,
                        default=str(ROOT / "training_recommendation" / "datasets" / "recommendation_dataset.csv"),
                        help="Output CSV path")
    args = parser.parse_args()

    builder = Model4DatasetBuilder()
    df = builder.build_dataset()
    builder.save_dataset(df, args.output)
    builder.close()
    print(f"Dataset built successfully: {len(df)} rows -> {args.output}")
