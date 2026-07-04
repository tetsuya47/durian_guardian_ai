import os
import yaml
from pathlib import Path
from typing import Any, Dict


class ConfigLoader:
    """Loads YAML config with env interpolation and numeric coercion.

    Uses the same coercion logic as Model 1 (training.utils.config_loader)
    to ensure all string values that look numeric (e.g. '1e-8') are
    converted to int/float before use.
    """

    def __init__(self, config_path: str):
        self.config_path = Path(config_path).resolve()
        if not self.config_path.exists():
            raise FileNotFoundError(f"Config not found: {self.config_path}")
        self.config = self._load()

    def _load(self) -> Dict[str, Any]:
        with open(str(self.config_path), "r", encoding="utf-8") as f:
            content = f.read()
        content = self._interpolate_env(content)
        config = yaml.safe_load(content)
        if config is None:
            raise ValueError(f"Empty config file: {self.config_path}")
        return self._coerce_numeric(config)

    @staticmethod
    def _interpolate_env(text: str) -> str:
        import re
        pattern = re.compile(r"\$\{([^}]+)\}")

        def replacer(match):
            var = match.group(1)
            default = None
            if ":-" in var:
                var, default = var.split(":-", 1)
            value = os.environ.get(var, default)
            if value is None:
                raise ValueError(f"Environment variable '${var}' not set and no default provided")
            return value

        return pattern.sub(replacer, text)

    @staticmethod
    def _coerce_value(value: Any) -> Any:
        """Convert a string to int/float if it looks numeric (same as Model 1)."""
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
        """Recursively coerce string values that look numeric (same as Model 1)."""
        if isinstance(obj, dict):
            return {k: self._coerce_numeric(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [self._coerce_numeric(item) for item in obj]
        return self._coerce_value(obj)
