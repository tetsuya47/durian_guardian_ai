"""Tabular dataset loader for risk prediction (Model 3)."""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union

import numpy as np
import pandas as pd
import torch
from torch.utils.data import Dataset

from training.utils.logger import Logger


class TabularDataset(Dataset):
    """Dataset for tabular machine learning models (Random Forest, XGBoost, etc.).

    Supports both PyTorch tensor output for neural networks and
    raw numpy output for sklearn/xgboost models.
    """

    def __init__(
        self,
        data: Union[pd.DataFrame, str, Path],
        feature_columns: List[str],
        target_column: str,
        transform: Optional[callable] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        self.logger = logger or Logger.get_logger("TabularDataset")

        if isinstance(data, (str, Path)):
            self.dataframe = pd.read_csv(data)
        elif isinstance(data, pd.DataFrame):
            self.dataframe = data.copy()
        else:
            raise TypeError(f"Unsupported data type: {type(data)}")

        self.feature_columns = feature_columns
        self.target_column = target_column
        self.transform = transform

        self._validate_columns()
        self._handle_missing()

        self.features = self.dataframe[feature_columns].values.astype(np.float32)
        self.targets = self.dataframe[target_column].values

        if np.issubdtype(self.targets.dtype, np.str_) or self.targets.dtype == object:
            from sklearn.preprocessing import LabelEncoder
            self.label_encoder = LabelEncoder()
            self.targets = self.label_encoder.fit_transform(self.targets)
        else:
            self.label_encoder = None

        self.logger.info(
            "TabularDataset: %d samples, %d features, target=%s",
            len(self.features), len(feature_columns), target_column,
        )

    def _validate_columns(self) -> None:
        missing_features = [c for c in self.feature_columns if c not in self.dataframe.columns]
        if missing_features:
            raise ValueError(f"Missing feature columns: {missing_features}")
        if self.target_column not in self.dataframe.columns:
            raise ValueError(f"Target column not found: {self.target_column}")

    def _handle_missing(self) -> None:
        for col in self.feature_columns:
            if self.dataframe[col].isnull().any():
                self.dataframe[col] = self.dataframe[col].fillna(self.dataframe[col].mean())
                self.logger.debug("Filled missing values in '%s' with mean", col)

    @property
    def num_features(self) -> int:
        return len(self.feature_columns)

    @property
    def num_classes(self) -> int:
        return len(np.unique(self.targets))

    @property
    def class_distribution(self) -> Dict[Any, int]:
        unique, counts = np.unique(self.targets, return_counts=True)
        return dict(zip(unique, counts))

    def get_numpy(self) -> Tuple[np.ndarray, np.ndarray]:
        return self.features, self.targets

    def __len__(self) -> int:
        return len(self.features)

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor]:
        x = torch.tensor(self.features[idx], dtype=torch.float32)
        y = torch.tensor(self.targets[idx], dtype=torch.long)
        if self.transform:
            x = self.transform(x)
        return x, y
