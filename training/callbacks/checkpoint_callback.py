"""Checkpoint callback for saving model checkpoints during training."""

from pathlib import Path
from typing import Any, Dict, Optional

from training.callbacks.callback_base import Callback


class ModelCheckpoint(Callback):
    """Saves model checkpoints based on monitored metric.

    Supports saving best model, last model, and periodic checkpoints.
    """

    def __init__(
        self,
        monitor: str = "val_accuracy",
        mode: str = "max",
        save_best_only: bool = True,
        save_last: bool = True,
        save_freq: int = 1,
        checkpoint_dir: str = "training/checkpoints",
        verbose: bool = True,
    ) -> None:
        self.monitor = monitor
        self.mode = mode
        self.save_best_only = save_best_only
        self.save_last = save_last
        self.save_freq = save_freq
        self.checkpoint_dir = Path(checkpoint_dir)
        self.verbose = verbose
        self.best_metric = float("-inf") if mode == "max" else float("inf")
        self.trainer = None
        self.early_stop = False

        self.checkpoint_dir.mkdir(parents=True, exist_ok=True)

    def set_trainer(self, trainer: Any) -> None:
        self.trainer = trainer

    def on_epoch_end(self, epoch: int, train_metrics: Dict[str, float],
                     val_metrics: Dict[str, float]) -> None:
        if self.trainer is None:
            return

        current_metric = val_metrics.get(self.monitor, 0.0)
        is_best = False

        if self.mode == "max":
            is_best = current_metric > self.best_metric
        else:
            is_best = current_metric < self.best_metric

        if is_best:
            self.best_metric = current_metric
            self.trainer.best_metric = current_metric
            self.trainer.best_epoch = epoch

            if self.save_best_only:
                best_path = self.checkpoint_dir / "best_model.pt"
                self.trainer.save_checkpoint(best_path, current_metric, is_best=True)
                if self.verbose:
                    import logging
                    logging.getLogger("Checkpoint").info(
                        "Best model saved: %s (%.4f)", best_path, current_metric
                    )

        if self.save_last:
            last_path = self.checkpoint_dir / "last_model.pt"
            self.trainer.save_checkpoint(last_path, current_metric)

        if (epoch + 1) % self.save_freq == 0:
            epoch_path = self.checkpoint_dir / f"epoch_{epoch + 1:03d}.pt"
            self.trainer.save_checkpoint(epoch_path, current_metric)
