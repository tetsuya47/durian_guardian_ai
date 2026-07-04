from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, Tuple, Union

import torch
import torch.nn as nn

from training_quality.utils.logger import Logger


class BaseEngine(ABC):
    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        device: Optional[torch.device] = None,
        logger=None,
    ):
        self.model = model
        self.config = config
        self.device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.logger = logger or Logger.get_logger(self.__class__.__name__)
        self.model.to(self.device)

    @abstractmethod
    def run(self, *args, **kwargs) -> Any:
        ...

    def to_device(self, batch: Any) -> Any:
        if isinstance(batch, torch.Tensor):
            return batch.to(self.device)
        elif isinstance(batch, (list, tuple)):
            return tuple(self.to_device(b) for b in batch)
        elif isinstance(batch, dict):
            return {k: self.to_device(v) for k, v in batch.items()}
        return batch

    def save_state(self, path: str):
        torch.save(self.model.state_dict(), path)

    def load_state(self, path: str):
        self.model.load_state_dict(torch.load(path, map_location=self.device))
