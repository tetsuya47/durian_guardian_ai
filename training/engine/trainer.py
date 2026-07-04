"""Production-ready training engine with mixed precision, gradient clipping, and checkpointing."""

import logging
import time
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Union

import torch
import torch.nn as nn
from torch.cuda.amp import autocast, GradScaler
from torch.utils.data import DataLoader

from training.engine.base_engine import BaseEngine
from training.utils.logger import Logger


class Trainer(BaseEngine):
    """Complete training loop with mixed precision, gradient accumulation,
    checkpointing, and metric tracking.

    Usage:
        trainer = Trainer(model, config, optimizer, loss_fn, train_loader, val_loader)
        trainer.train()
    """

    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        optimizer: torch.optim.Optimizer,
        loss_fn: Callable,
        train_loader: DataLoader,
        val_loader: DataLoader,
        scheduler: Any = None,
        callbacks: Optional[List[Any]] = None,
        device: Optional[torch.device] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        super().__init__(model, config, device, logger)
        self.optimizer = optimizer
        self.loss_fn = loss_fn
        self.train_loader = train_loader
        self.val_loader = val_loader
        self.scheduler = scheduler
        self.callbacks = callbacks or []

        train_cfg = config.get("training", {})
        self.epochs = train_cfg.get("epochs", 100)
        self.accumulation_steps = train_cfg.get("accumulation_steps", 1)
        self.gradient_clip = train_cfg.get("gradient_clip", None)
        self.mixed_precision = train_cfg.get("mixed_precision", "fp16")
        self.resume_from = train_cfg.get("resume_from", None)

        if hasattr(torch, "amp") and hasattr(torch.amp, "GradScaler"):
            self.scaler = torch.amp.GradScaler("cuda", enabled=(self.mixed_precision == "fp16"))
        else:
            self.scaler = GradScaler(enabled=(self.mixed_precision == "fp16"))
        self.current_epoch = 0
        self.global_step = 0
        self.best_metric = float("-inf")
        self.best_epoch = -1
        self.train_metrics: Dict[str, List[float]] = {}
        self.val_metrics: Dict[str, List[float]] = {}

        self._init_callbacks()
        self._maybe_resume()

    def _init_callbacks(self) -> None:
        for callback in self.callbacks:
            if hasattr(callback, "set_trainer"):
                callback.set_trainer(self)

    def _maybe_resume(self) -> None:
        if self.resume_from:
            path = Path(self.resume_from)
            if path.exists():
                self.load_checkpoint(path)
                self.logger.info("Resumed from checkpoint: %s", path)

    def run(self) -> Dict[str, Any]:
        return self.train()

    def train(self) -> Dict[str, Any]:
        self.logger.info("Starting training for %d epochs", self.epochs)
        self.model.train()

        for epoch in range(self.current_epoch, self.epochs):
            self.current_epoch = epoch
            epoch_start = time.time()

            train_metrics = self._train_epoch()
            val_metrics = self._validate_epoch()

            self._update_scheduler(val_metrics)

            self._log_epoch(epoch, train_metrics, val_metrics, epoch_start)

            self._run_callbacks("on_epoch_end", epoch, train_metrics, val_metrics)

            if self._check_early_stopping():
                self.logger.info("Early stopping triggered at epoch %d", epoch)
                break

        self.logger.info("Training completed. Best epoch: %d (%s: %.4f)",
                         self.best_epoch, "val_accuracy", self.best_metric)
        return {"best_metric": self.best_metric, "best_epoch": self.best_epoch}

    def _train_epoch(self) -> Dict[str, float]:
        self.model.train()
        total_loss = 0.0
        num_batches = len(self.train_loader)
        self.optimizer.zero_grad()

        for batch_idx, batch in enumerate(self.train_loader):
            images, labels = self.to_device(batch)
            loss = self._forward_pass(images, labels)

            loss = loss / self.accumulation_steps
            self.scaler.scale(loss).backward()

            if (batch_idx + 1) % self.accumulation_steps == 0:
                self._optimizer_step()
                self.optimizer.zero_grad()

            total_loss += loss.item() * self.accumulation_steps
            self.global_step += 1

        avg_loss = total_loss / num_batches
        return {"loss": avg_loss}

    def _forward_pass(self, images: torch.Tensor, labels: torch.Tensor) -> torch.Tensor:
        if self.mixed_precision == "fp16" and self.device.type == "cuda":
            with autocast():
                outputs = self.model(images)
                loss = self.loss_fn(outputs, labels)
        else:
            outputs = self.model(images)
            loss = self.loss_fn(outputs, labels)
        return loss

    def _optimizer_step(self) -> None:
        if self.gradient_clip is not None:
            self.scaler.unscale_(self.optimizer)
            torch.nn.utils.clip_grad_norm_(
                self.model.parameters(), self.gradient_clip
            )

        self.scaler.step(self.optimizer)
        self.scaler.update()

    def _validate_epoch(self) -> Dict[str, float]:
        self.model.eval()
        total_loss = 0.0
        correct = 0
        total = 0

        with torch.no_grad():
            for batch in self.val_loader:
                images, labels = self.to_device(batch)
                outputs = self.model(images)
                loss = self.loss_fn(outputs, labels)
                total_loss += loss.item()

                _, predicted = torch.max(outputs, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()

        avg_loss = total_loss / len(self.val_loader)
        accuracy = correct / total if total > 0 else 0.0
        return {"loss": avg_loss, "val_accuracy": accuracy}

    def _update_scheduler(self, val_metrics: Dict[str, float]) -> None:
        if self.scheduler is None:
            return
        if isinstance(self.scheduler, torch.optim.lr_scheduler.ReduceLROnPlateau):
            self.scheduler.step(val_metrics.get("loss", 0))
        else:
            self.scheduler.step()

    def _log_epoch(self, epoch: int, train_metrics: Dict[str, float],
                   val_metrics: Dict[str, float], start_time: float) -> None:
        elapsed = time.time() - start_time
        current_lr = self.optimizer.param_groups[0]["lr"]

        self.logger.info(
            "Epoch %3d/%d | train_loss: %.4f | val_loss: %.4f | val_acc: %.4f | lr: %.6f | %.2fs",
            epoch + 1, self.epochs,
            train_metrics.get("loss", 0),
            val_metrics.get("loss", 0),
            val_metrics.get("val_accuracy", 0),
            current_lr,
            elapsed,
        )

        for key, value in train_metrics.items():
            self.train_metrics.setdefault(key, []).append(value)
        for key, value in val_metrics.items():
            self.val_metrics.setdefault(key, []).append(value)

    def _run_callbacks(self, event: str, epoch: int,
                       train_metrics: Dict[str, float],
                       val_metrics: Dict[str, float]) -> None:
        for callback in self.callbacks:
            if hasattr(callback, event):
                getattr(callback, event)(epoch, train_metrics, val_metrics)

    def _check_early_stopping(self) -> bool:
        for callback in self.callbacks:
            if hasattr(callback, "early_stop") and callback.early_stop:
                return True
        return False

    def save_checkpoint(self, path: Union[str, Path], metric: float = 0.0, is_best: bool = False) -> None:
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)

        checkpoint = {
            "epoch": self.current_epoch,
            "global_step": self.global_step,
            "model_state_dict": self.model.state_dict(),
            "optimizer_state_dict": self.optimizer.state_dict(),
            "scaler_state_dict": self.scaler.state_dict(),
            "best_metric": self.best_metric,
            "best_epoch": self.best_epoch,
            "metric": metric,
            "is_best": is_best,
            "config": self.config,
        }
        if self.scheduler is not None:
            checkpoint["scheduler_state_dict"] = self.scheduler.state_dict()

        torch.save(checkpoint, str(path))
        self.logger.info("Checkpoint saved: %s (metric=%.4f)", path, metric)

    def load_checkpoint(self, path: Union[str, Path]) -> Dict[str, Any]:
        path = Path(path)
        if not path.exists():
            raise FileNotFoundError(f"Checkpoint not found: {path}")

        checkpoint = torch.load(str(path), map_location=self.device)
        self.model.load_state_dict(checkpoint["model_state_dict"])
        self.optimizer.load_state_dict(checkpoint["optimizer_state_dict"])
        self.scaler.load_state_dict(checkpoint["scaler_state_dict"])
        self.current_epoch = checkpoint.get("epoch", 0) + 1
        self.global_step = checkpoint.get("global_step", 0)
        self.best_metric = checkpoint.get("best_metric", float("-inf"))
        self.best_epoch = checkpoint.get("best_epoch", -1)

        if self.scheduler is not None and "scheduler_state_dict" in checkpoint:
            self.scheduler.load_state_dict(checkpoint["scheduler_state_dict"])

        self.logger.info("Loaded checkpoint from epoch %d (metric=%.4f)",
                         checkpoint.get("epoch", 0), checkpoint.get("metric", 0))
        return checkpoint
