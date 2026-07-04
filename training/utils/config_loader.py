"""Configuration loader for YAML-based hyperparameter management."""

import logging
import os
from pathlib import Path
from typing import Any, Dict, Optional

import yaml


logger = logging.getLogger("ConfigLoader")


class ConfigLoader:
    """Loads and validates YAML configuration files.

    Supports nested config access via dot notation and provides
    environment variable interpolation and numeric type coercion.
    """

    def __init__(self, config_path: str) -> None:
        self.config_path = Path(config_path)
        if not self.config_path.exists():
            raise FileNotFoundError(f"Config not found: {config_path}")
        self._config: Dict[str, Any] = self._load()
        self._validate()

    def _load(self) -> Dict[str, Any]:
        with open(self.config_path, "r", encoding="utf-8") as f:
            raw = yaml.safe_load(f)
        if raw is None:
            raise ValueError(f"Empty config file: {self.config_path}")
        interpolated = self._interpolate_env(raw)
        return self._coerce_numeric(interpolated)

    @staticmethod
    def _coerce_value(value: Any) -> Any:
        """Convert a value to int or float if it looks numeric."""
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            stripped = value.strip()
            if not stripped:
                return value
            try:
                if "." in stripped or "e" in stripped.lower():
                    return float(stripped)
                return int(stripped)
            except (ValueError, TypeError):
                return value
        return value

    def _coerce_numeric(self, obj: Any) -> Any:
        """Recursively coerce string values that look numeric to int/float."""
        if isinstance(obj, dict):
            return {k: self._coerce_numeric(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [self._coerce_numeric(item) for item in obj]
        return self._coerce_value(obj)

    def _interpolate_env(self, obj: Any) -> Any:
        if isinstance(obj, str):
            if obj.startswith("${") and obj.endswith("}"):
                env_var = obj[2:-1]
                default = None
                if ":-" in env_var:
                    env_var, default = env_var.split(":-", 1)
                return os.environ.get(env_var, default)
            return obj
        if isinstance(obj, dict):
            return {k: self._interpolate_env(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [self._interpolate_env(item) for item in obj]
        return obj

    def _validate(self) -> None:
        required_keys = ["model", "dataset", "training"]
        for key in required_keys:
            if key not in self._config:
                raise ValueError(f"Missing required config section: '{key}'")

    def get(self, key: str, default: Any = None) -> Any:
        keys = key.split(".")
        value = self._config
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        return value

    def get_model_config(self) -> Dict[str, Any]:
        return self._config.get("model", {})

    def get_dataset_config(self) -> Dict[str, Any]:
        return self._config.get("dataset", {})

    def get_training_config(self) -> Dict[str, Any]:
        return self._config.get("training", {})

    def get_augmentation_config(self) -> Dict[str, Any]:
        return self._config.get("augmentation", {})

    def get_optimizer_config(self) -> Dict[str, Any]:
        return self._config.get("optimizer", {})

    def get_scheduler_config(self) -> Dict[str, Any]:
        return self._config.get("scheduler", {})

    def get_loss_config(self) -> Dict[str, Any]:
        return self._config.get("loss", {})

    def get_metrics_config(self) -> list:
        return self._config.get("metrics", [])

    def get_callbacks_config(self) -> list:
        return self._config.get("callbacks", [])

    def get_export_config(self) -> Dict[str, Any]:
        return self._config.get("export", {})

    def get_logging_config(self) -> Dict[str, Any]:
        return self._config.get("logging", {})

    @property
    def config(self) -> Dict[str, Any]:
        return self._config

    def to_dict(self) -> Dict[str, Any]:
        return self._config.copy()
