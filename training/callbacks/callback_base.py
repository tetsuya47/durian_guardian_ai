"""Callback system for training lifecycle hooks."""

from pathlib import Path
from typing import Any, Dict, List, Optional

import torch


class Callback:
    """Base callback class with lifecycle hooks."""

    def on_training_start(self, trainer: Any) -> None:
        pass

    def on_training_end(self, trainer: Any) -> None:
        pass

    def on_epoch_start(self, epoch: int, trainer: Any) -> None:
        pass

    def on_epoch_end(self, epoch: int, train_metrics: Dict[str, float],
                     val_metrics: Dict[str, float]) -> None:
        pass

    def on_batch_start(self, batch_idx: int, batch: Any) -> None:
        pass

    def on_batch_end(self, batch_idx: int, loss: float) -> None:
        pass


class CallbackManager:
    """Manages all callbacks and dispatches events."""

    def __init__(self, callbacks: Optional[List[Callback]] = None) -> None:
        self.callbacks = callbacks or []

    def add(self, callback: Callback) -> None:
        self.callbacks.append(callback)

    def on_training_start(self, trainer: Any) -> None:
        for cb in self.callbacks:
            cb.on_training_start(trainer)

    def on_training_end(self, trainer: Any) -> None:
        for cb in self.callbacks:
            cb.on_training_end(trainer)

    def on_epoch_start(self, epoch: int, trainer: Any) -> None:
        for cb in self.callbacks:
            cb.on_epoch_start(epoch, trainer)

    def on_epoch_end(self, epoch: int, train_metrics: Dict[str, float],
                     val_metrics: Dict[str, float]) -> None:
        for cb in self.callbacks:
            cb.on_epoch_end(epoch, train_metrics, val_metrics)

    def on_batch_start(self, batch_idx: int, batch: Any) -> None:
        for cb in self.callbacks:
            cb.on_batch_start(batch_idx, batch)

    def on_batch_end(self, batch_idx: int, loss: float) -> None:
        for cb in self.callbacks:
            cb.on_batch_end(batch_idx, loss)
