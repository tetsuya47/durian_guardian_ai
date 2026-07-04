"""Base engine class for all training/evaluation components."""

import logging
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, Dict, Optional, Union

import torch
import torch.nn as nn

from training.utils.logger import Logger


class BaseEngine(ABC):
    """Abstract base class for all training engine components."""

    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        device: Optional[torch.device] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        self.model = model
        self.config = config
        self.device = device or torch.device("cpu")
        self.logger = logger or Logger.get_logger(self.__class__.__name__)
        self.model.to(self.device)

    @abstractmethod
    def run(self, *args, **kwargs) -> Any:
        """Execute the engine's main function."""
        pass

    def save_state(self, path: Union[str, Path]) -> None:
        """Save engine state to disk."""
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        state = {"model_state_dict": self.model.state_dict()}
        torch.save(state, str(path))
        self.logger.info("State saved to %s", path)

    def load_state(self, path: Union[str, Path]) -> None:
        """Load engine state from disk."""
        path = Path(path)
        if not path.exists():
            raise FileNotFoundError(f"State not found: {path}")
        state = torch.load(str(path), map_location=self.device)
        self.model.load_state_dict(state["model_state_dict"])
        self.logger.info("State loaded from %s", path)

    def to_device(self, batch: Any) -> Any:
        """Move batch data to the configured device.

        Supports dict, list, tuple, and torch.Tensor.
        """
        if isinstance(batch, torch.Tensor):
            return batch.to(self.device, non_blocking=True)
        if isinstance(batch, dict):
            return {k: self.to_device(v) for k, v in batch.items()}
        if isinstance(batch, (list, tuple)):
            return [self.to_device(item) for item in batch]
        return batch
