"""Logging callbacks for CSV and TensorBoard."""

import csv
from pathlib import Path
from typing import Any, Dict

from torch.utils.tensorboard import SummaryWriter

from training.callbacks.callback_base import Callback


class CSVLogger(Callback):
    """Logs training metrics to CSV file."""

    def __init__(self, filename: str = "training/logs/training_log.csv") -> None:
        self.filename = Path(filename)
        self.filename.parent.mkdir(parents=True, exist_ok=True)
        self.file_handle = None
        self.writer = None
        self.initialized = False

    def on_epoch_end(self, epoch: int, train_metrics: Dict[str, float],
                     val_metrics: Dict[str, float]) -> None:
        if not self.initialized:
            self.file_handle = open(self.filename, "w", newline="", encoding="utf-8")
            fieldnames = ["epoch"]
            fieldnames += [f"train_{k}" for k in train_metrics.keys()]
            fieldnames += [f"val_{k}" for k in val_metrics.keys()]
            self.writer = csv.DictWriter(self.file_handle, fieldnames=fieldnames)
            self.writer.writeheader()
            self.initialized = True

        row = {"epoch": epoch + 1}
        for key, value in train_metrics.items():
            row[f"train_{key}"] = value
        for key, value in val_metrics.items():
            row[f"val_{key}"] = value
        self.writer.writerow(row)
        self.file_handle.flush()

    def close(self) -> None:
        if self.file_handle:
            self.file_handle.close()
            self.initialized = False


class TensorBoard(Callback):
    """Logs metrics to TensorBoard."""

    def __init__(self, log_dir: str = "training/tensorboard") -> None:
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.writer = SummaryWriter(log_dir=str(self.log_dir))

    def on_epoch_end(self, epoch: int, train_metrics: Dict[str, float],
                     val_metrics: Dict[str, float]) -> None:
        for key, value in train_metrics.items():
            self.writer.add_scalar(f"train/{key}", value, epoch)
        for key, value in val_metrics.items():
            self.writer.add_scalar(f"val/{key}", value, epoch)

    def close(self) -> None:
        self.writer.close()


class GradientNormMonitor(Callback):
    """Monitors gradient norms during training."""

    def __init__(self, log_freq: int = 10) -> None:
        self.log_freq = log_freq
        self.trainer = None

    def set_trainer(self, trainer: Any) -> None:
        self.trainer = trainer

    def on_batch_end(self, batch_idx: int, loss: float) -> None:
        if self.trainer is None or batch_idx % self.log_freq != 0:
            return
        total_norm = 0.0
        for p in self.trainer.model.parameters():
            if p.grad is not None:
                param_norm = p.grad.detach().data.norm(2)
                total_norm += param_norm.item() ** 2
        total_norm = total_norm ** 0.5

        if hasattr(self.trainer, "logger"):
            self.trainer.logger.debug("Batch %d | grad_norm: %.4f", batch_idx, total_norm)


class ReduceLROnPlateau(Callback):
    """Reduce learning rate when a metric stops improving."""

    def __init__(self, monitor: str = "val_loss", factor: float = 0.5,
                 patience: int = 5, min_lr: float = 1e-7, verbose: bool = True) -> None:
        self.monitor = monitor
        self.factor = factor
        self.patience = patience
        self.min_lr = min_lr
        self.verbose = verbose
        self.best_metric = float("inf")
        self.counter = 0
        self.trainer = None

    def set_trainer(self, trainer: Any) -> None:
        self.trainer = trainer

    def on_epoch_end(self, epoch: int, train_metrics: Dict[str, float],
                     val_metrics: Dict[str, float]) -> None:
        if self.trainer is None:
            return

        current_metric = val_metrics.get(self.monitor, 0.0)
        if current_metric < self.best_metric:
            self.best_metric = current_metric
            self.counter = 0
        else:
            self.counter += 1
            if self.counter >= self.patience:
                current_lr = self.trainer.optimizer.param_groups[0]["lr"]
                new_lr = max(current_lr * self.factor, self.min_lr)
                for param_group in self.trainer.optimizer.param_groups:
                    param_group["lr"] = new_lr
                self.counter = 0
                if self.verbose:
                    import logging
                    logging.getLogger("ReduceLROnPlateau").info(
                        "Reduced LR to %.6f", new_lr
                    )
