"""Build Model 3 training dataset from MongoDB with feature engineering and label creation."""

import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd
from pymongo import MongoClient

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))

from database.config import settings
from training.utils.logger import Logger


SEASON_MAP = {1: "Khô", 2: "Khô", 3: "Khô", 4: "Khô",
              5: "Mưa", 6: "Mưa", 7: "Mưa", 8: "Mưa",
              9: "Mưa", 10: "Mưa", 11: "Mưa", 12: "Khô"}

# Vietnamese health status values (matching DB schema)
HEALTH_STATUS_DISEASED = "Bị bệnh"

# Vietnamese risk level labels
RISK_LEVEL_LOW = "Thấp"
RISK_LEVEL_MEDIUM = "Trung bình"
RISK_LEVEL_HIGH = "Cao"


class Model3DatasetBuilder:
    def __init__(self, logger=None):
        self.logger = logger or Logger.get_logger("Model3DatasetBuilder")
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
            "disease_id": 1, "inspection_date": 1, "temperature": 1,
            "humidity": 1, "rainfall_mm": 1, "rainfall": 1,
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

    def _load_disease_history(self) -> pd.DataFrame:
        fields = {"_id": 0, "tree_id": 1, "disease": 1, "date": 1, "action": 1}
        docs = list(self.db.disease_history.find({}, fields))
        df = pd.DataFrame(docs)
        df["date"] = pd.to_datetime(df["date"])
        self.logger.info("Loaded %d disease history records", len(df))
        return df

    def _compute_season(self, month) -> str:
        return SEASON_MAP.get(month, "Khô")

    def _compute_risk_level(self, row) -> str:
        score = 0.0

        if row.get("health_status") == HEALTH_STATUS_DISEASED:
            score += 0.35

        if pd.notna(row.get("humidity")):
            if row["humidity"] > 85:
                score += 0.15
            elif row["humidity"] > 75:
                score += 0.08

        if pd.notna(row.get("rainfall")):
            if row["rainfall"] > 60:
                score += 0.10
            elif row["rainfall"] > 40:
                score += 0.05

        if pd.notna(row.get("temperature")):
            if row["temperature"] > 33:
                score += 0.10
            elif row["temperature"] > 30:
                score += 0.05

        hist_count = row.get("historical_disease_count", 0)
        if pd.notna(hist_count):
            score += min(hist_count, 3) * 0.05

        dsl_treatment = row.get("days_since_last_treatment")
        if pd.notna(dsl_treatment):
            if dsl_treatment < 30:
                score += 0.10
            elif dsl_treatment < 90:
                score += 0.05

        dsl_inspection = row.get("days_since_last_inspection")
        if pd.notna(dsl_inspection) and dsl_inspection > 60:
            score += 0.05

        if pd.notna(row.get("confidence")) and row["confidence"] < 85:
            score += 0.05

        if row.get("season") == "Mưa":
            score += 0.05

        if score < 0.20:
            return RISK_LEVEL_LOW
        elif score < 0.50:
            return RISK_LEVEL_MEDIUM
        else:
            return RISK_LEVEL_HIGH

    def compute_risk_score(self, row) -> float:
        score = 0.0

        if row.get("health_status") == HEALTH_STATUS_DISEASED:
            score += 0.35

        if pd.notna(row.get("humidity")):
            if row["humidity"] > 85:
                score += 0.15
            elif row["humidity"] > 75:
                score += 0.08

        if pd.notna(row.get("rainfall")):
            if row["rainfall"] > 60:
                score += 0.10
            elif row["rainfall"] > 40:
                score += 0.05

        if pd.notna(row.get("temperature")):
            if row["temperature"] > 33:
                score += 0.10
            elif row["temperature"] > 30:
                score += 0.05

        hist_count = row.get("historical_disease_count", 0)
        if pd.notna(hist_count):
            score += min(hist_count, 3) * 0.05

        dsl_treatment = row.get("days_since_last_treatment")
        if pd.notna(dsl_treatment):
            if dsl_treatment < 30:
                score += 0.10
            elif dsl_treatment < 90:
                score += 0.05

        dsl_inspection = row.get("days_since_last_inspection")
        if pd.notna(dsl_inspection) and dsl_inspection > 60:
            score += 0.05

        if pd.notna(row.get("confidence")) and row["confidence"] < 85:
            score += 0.05

        if row.get("season") == "Mưa":
            score += 0.05

        return min(score, 1.0)

    def build_dataset(self) -> pd.DataFrame:
        if self.db is None:
            self.connect()

        inspections = self._load_inspections()
        trees = self._load_trees()
        farms = self._load_farms()
        disease_history = self._load_disease_history()

        self.logger.info("Joining inspections with trees...")
        df = inspections.merge(trees, on="tree_id", how="left", suffixes=("", "_tree"))
        self.logger.info("  After tree join: %d rows", len(df))

        self.logger.info("Joining with farms...")
        df = df.merge(farms, on="farm_id", how="left", suffixes=("", "_farm"))

        self.logger.info("Computing features...")

        df["season"] = df["inspection_date"].dt.month.map(self._compute_season)

        df["density_per_hectare"] = np.where(
            (df["area_hectare"].notna()) & (df["area_hectare"] > 0),
            df["tree_count"] / df["area_hectare"],
            np.nan,
        )

        disease_count_by_tree = disease_history.groupby("tree_id").size().to_dict()

        disease_date_by_tree = {}
        for tid, grp in disease_history.groupby("tree_id"):
            disease_date_by_tree[tid] = grp["date"].max()

        self.logger.info("Computing temporal features per tree...")
        df = df.sort_values(["tree_id", "inspection_date"])

        df["days_since_last_inspection"] = df.groupby("tree_id")["inspection_date"].diff().dt.days

        df["historical_disease_count"] = df["tree_id"].map(disease_count_by_tree).fillna(0).astype(int)

        max_treatment = df["tree_id"].map(disease_date_by_tree)
        df["days_since_last_treatment"] = (df["inspection_date"] - max_treatment).dt.days
        df["days_since_last_treatment"] = df["days_since_last_treatment"].where(
            (df["days_since_last_treatment"].notna()) & (df["days_since_last_treatment"] >= 0),
            None,
        )

        df["historical_disease_frequency"] = np.where(
            df["tree_age"].notna() & (df["tree_age"] > 0),
            df["historical_disease_count"] / df["tree_age"],
            df["historical_disease_count"],
        )

        self.logger.info("Computing risk_level labels...")
        df["risk_score"] = df.apply(self.compute_risk_score, axis=1)
        df["risk_level"] = df.apply(self._compute_risk_level, axis=1)

        self.logger.info("Dataset built: %d samples, %d features", len(df), len(df.columns))
        self.logger.info("Risk distribution:\n%s", df["risk_level"].value_counts())

        return df

    def get_feature_target(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        feature_cols = [
            "temperature", "humidity", "rainfall", "tree_age",
            "variety", "health_status", "predicted_disease",
            "confidence", "season", "density_per_hectare",
            "days_since_last_inspection", "days_since_last_treatment",
            "historical_disease_count", "historical_disease_frequency",
        ]
        available = [c for c in feature_cols if c in df.columns]
        missing = [c for c in feature_cols if c not in df.columns]
        if missing:
            self.logger.warning("Missing feature columns: %s", missing)

        X = df[available].copy()
        y = df["risk_level"].copy()

        self.logger.info("Features (%d): %s", len(available), available)
        self.logger.info("Target distribution:\n%s", y.value_counts())

        return X, y

    def save_dataset(self, df: pd.DataFrame, path: str):
        p = Path(path)
        p.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(p, index=False)
        self.logger.info("Dataset saved to %s (%d rows)", p, len(df))
