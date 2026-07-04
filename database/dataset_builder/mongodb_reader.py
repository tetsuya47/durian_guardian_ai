"""MongoDB dataset builder for reading training data from database.

Used for Model 3 (Risk Prediction) to load feature data from MongoDB
collections and build training datasets.
"""

import logging

from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import pandas as pd

from training.utils.logger import Logger


class MongoDBDatasetBuilder:
    """Builds training datasets from MongoDB collections.

    Reads data from inspections, trees, zones, farms collections,
    joins them into feature tables, and prepares for ML training.
    """

    def __init__(
        self,
        mongodb_uri: str = "mongodb://localhost:27017",
        database_name: str = "durian_guardian_ai",
        logger: Optional[logging.Logger] = None,
    ) -> None:
        self.mongodb_uri = mongodb_uri
        self.database_name = database_name
        self.logger = logger or Logger.get_logger("MongoDBDatasetBuilder")
        self.client = None
        self.db = None

    def connect(self) -> None:
        from pymongo import MongoClient
        self.client = MongoClient(self.mongodb_uri)
        self.db = self.client[self.database_name]
        self.logger.info("Connected to MongoDB: %s/%s", self.mongodb_uri, self.database_name)

    def close(self) -> None:
        if self.client:
            self.client.close()
            self.logger.info("MongoDB connection closed")

    def build_risk_dataset(self) -> pd.DataFrame:
        """Build risk prediction dataset by joining multiple collections.

        Returns:
            DataFrame with features and target columns for risk prediction.
        """
        if self.db is None:
            self.connect()

        inspections = list(self.db.inspections.find({}, {
            "_id": 0, "tree_id": 1, "farm_id": 1, "disease_id": 1,
            "inspection_date": 1, "temperature": 1, "humidity": 1,
            "rainfall": 1, "health_status": 1, "predicted_disease": 1,
            "confidence": 1,
        }))

        df = pd.DataFrame(inspections)

        if df.empty:
            self.logger.warning("No inspection data found in MongoDB")
            return df

        trees = {str(t["_id"]): t for t in self.db.trees.find({})}
        farms = {str(f["_id"]): f for f in self.db.farms.find({})}
        zones_list = list(self.db.zones.find({}))
        zones = {str(z["_id"]): z for z in zones_list}

        df["tree_age"] = df["tree_id"].apply(
            lambda x: trees.get(str(x), {}).get("tree_age", 0)
        )
        df["tree_variety"] = df["tree_id"].apply(
            lambda x: trees.get(str(x), {}).get("variety", "unknown")
        )
        df["zone_id"] = df["tree_id"].apply(
            lambda x: trees.get(str(x), {}).get("zone_id", None)
        )
        df["zone_type"] = df["zone_id"].apply(
            lambda x: zones.get(str(x), {}).get("zone_type", "unknown")
        )
        df["soil_type"] = df["zone_id"].apply(
            lambda x: zones.get(str(x), {}).get("soil_type", "unknown")
        )
        df["irrigation_type"] = df["zone_id"].apply(
            lambda x: zones.get(str(x), {}).get("irrigation_type", "unknown")
        )
        df["area_hectare"] = df["farm_id"].apply(
            lambda x: farms.get(str(x), {}).get("area_hectare", 0)
        )

        self.logger.info("Built risk dataset: %d samples, %d features",
                         len(df), len(df.columns))
        return df

    def build_disease_history_dataset(self) -> pd.DataFrame:
        """Build disease history dataset for temporal analysis."""
        if self.db is None:
            self.connect()

        history = list(self.db.disease_history.find({}, {
            "_id": 0, "tree_id": 1, "disease": 1, "date": 1,
            "action": 1,
        }))
        df = pd.DataFrame(history)
        self.logger.info("Built disease history dataset: %d records", len(df))
        return df

    def save_dataset(self, df: pd.DataFrame, output_path: str) -> None:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(path, index=False)
        self.logger.info("Dataset saved to %s (%d rows, %d cols)",
                         path, len(df), len(df.columns))
