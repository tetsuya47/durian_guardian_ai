import csv
import time
from pathlib import Path
from typing import Any, Callable, Dict, Optional

import torch
import torch.nn as nn
from torch.cuda.amp import GradScaler
from torch.utils.data import DataLoader
from sklearn.metrics import roc_auc_score, precision_score, recall_score, f1_score

from training_quality.engine.base_engine import BaseEngine
from training_quality.utils.logger import Logger


class Trainer(BaseEngine):
    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        optimizer: torch.optim.Optimizer,
        loss_fn: Callable,
        train_loader: DataLoader,
        val_loader: DataLoader,
        scheduler: Any = None,
        device: Optional[torch.device] = None,
        logger=None,
        start_epoch: int = 0,
        best_metric: float = 0.0,
        best_epoch: int = -1,
        global_step: int = 0,
    ):
        super().__init__(model, config, device, logger)
        self.optimizer = optimizer
        self.loss_fn = loss_fn
        self.train_loader = train_loader
        self.val_loader = val_loader
        self.scheduler = scheduler

        tc = config.get("training", {})
        self.epochs = tc.get("epochs", 30)
        self.accumulation_steps = tc.get("accumulation_steps", 1)
        self.gradient_clip = tc.get("gradient_clip", None)
        self.mixed_precision = tc.get("mixed_precision", None)
        self.use_amp = self.mixed_precision and str(self.device) != "cpu"

        self.early_stop_patience = tc.get("early_stop_patience", 10)
        self.early_stop_min_delta = tc.get("early_stop_min_delta", 0.001)
        self._patience_counter = 0
        self._best_val_loss = float("inf")

        self.scaler = GradScaler(enabled=self.use_amp)
        self.start_epoch = start_epoch
        self.best_metric = best_metric
        self.best_epoch = best_epoch
        self.global_step = global_step
        self.early_stopped = False

        self.checkpoint_dir = Path("training_quality/checkpoints")
        self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
        self.log_dir = Path("training_quality/logs")
        self.log_dir.mkdir(parents=True, exist_ok=True)

        self.csv_path = self.log_dir / "training_log.csv"
        self._init_csv()

        self.tb_writer = None
        try:
            from torch.utils.tensorboard import SummaryWriter
            tb_dir = Path("training_quality/tensorboard")
            tb_dir.mkdir(parents=True, exist_ok=True)
            self.tb_writer = SummaryWriter(str(tb_dir))
        except Exception:
            pass

    def _init_csv(self):
        if self.start_epoch > 0 and self.csv_path.exists():
            return
        with open(str(self.csv_path), "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([
                "epoch", "train_loss", "val_loss", "val_accuracy",
                "val_precision", "val_recall", "val_f1", "val_roc_auc",
                "lr", "time_seconds",
            ])

    def _train_epoch(self) -> Dict[str, float]:
        self.model.train()
        total_loss = 0.0
        num_batches = 0

        for batch_idx, (images, labels) in enumerate(self.train_loader):
            images = images.to(self.device)
            labels = labels.to(self.device)

            with torch.amp.autocast(device_type=str(self.device), enabled=self.use_amp):
                outputs = self.model(images)
                loss = self.loss_fn(outputs, labels)
                loss = loss / self.accumulation_steps

            self.scaler.scale(loss).backward()

            if (batch_idx + 1) % self.accumulation_steps == 0:
                if self.gradient_clip:
                    self.scaler.unscale_(self.optimizer)
                    torch.nn.utils.clip_grad_norm_(self.model.parameters(), self.gradient_clip)
                self.scaler.step(self.optimizer)
                self.scaler.update()
                self.optimizer.zero_grad()
                self.global_step += 1

            total_loss += loss.item() * self.accumulation_steps
            num_batches += 1

        return {"train_loss": total_loss / max(num_batches, 1)}

    @torch.no_grad()
    def _validate_epoch(self) -> Dict[str, float]:
        self.model.eval()
        total_loss = 0.0
        all_preds = []
        all_targets = []
        all_probs = []

        for images, labels in self.val_loader:
            images = images.to(self.device)
            labels = labels.to(self.device)
            outputs = self.model(images)
            loss = self.loss_fn(outputs, labels)
            total_loss += loss.item()
            probs = torch.softmax(outputs, dim=1)
            preds = torch.argmax(outputs, dim=1)
            all_preds.append(preds.cpu())
            all_targets.append(labels.cpu())
            all_probs.append(probs.cpu())

        preds = torch.cat(all_preds)
        targets = torch.cat(all_targets)
        probs = torch.cat(all_probs)

        metrics = {
            "val_loss": total_loss / max(len(self.val_loader), 1),
            "val_accuracy": (preds == targets).sum().item() / max(targets.size(0), 1),
        }

        targets_np = targets.numpy()
        preds_np = preds.numpy()
        probs_np = probs.numpy()

        metrics["val_precision"] = float(precision_score(targets_np, preds_np, zero_division=0))
        metrics["val_recall"] = float(recall_score(targets_np, preds_np, zero_division=0))
        metrics["val_f1"] = float(f1_score(targets_np, preds_np, zero_division=0))
        try:
            metrics["val_roc_auc"] = float(roc_auc_score(targets_np, probs_np[:, 1]))
        except Exception:
            metrics["val_roc_auc"] = 0.0

        return metrics

    def _update_scheduler(self, val_metrics: Dict[str, float]):
        if self.scheduler is None:
            return
        if isinstance(self.scheduler, torch.optim.lr_scheduler.ReduceLROnPlateau):
            self.scheduler.step(val_metrics.get("val_loss", 0))
        else:
            self.scheduler.step()

    def _check_early_stopping(self, val_loss: float) -> bool:
        if val_loss < self._best_val_loss - self.early_stop_min_delta:
            self._best_val_loss = val_loss
            self._patience_counter = 0
        else:
            self._patience_counter += 1
        if self._patience_counter >= self.early_stop_patience:
            self.logger.info("  Early stopping triggered after %d epochs without improvement.", self._patience_counter)
            return True
        return False

    def run(self, *args, **kwargs) -> Any:
        return self.train()

    def train(self) -> Dict[str, Any]:
        self.logger.info("=" * 70)
        self.logger.info("  MODEL 2: IMAGE QUALITY ASSESSMENT - TRAINING")
        self.logger.info("  Epochs: %d | Device: %s | Batch: %d | AMP: %s",
                         self.epochs, self.device,
                         self.config.get("training", {}).get("batch_size", 64),
                         self.use_amp)
        self.logger.info("=" * 70)

        total_start = time.time()

        for epoch in range(self.start_epoch, self.epochs):
            epoch_start = time.time()

            train_metrics = self._train_epoch()
            val_metrics = self._validate_epoch()
            self._update_scheduler(val_metrics)

            current_lr = self.optimizer.param_groups[0]["lr"]
            epoch_time = time.time() - epoch_start
            elapsed = time.time() - total_start
            eta_seconds = (elapsed / (epoch + 1 - self.start_epoch)) * (self.epochs - epoch - 1)
            eta_str = f"{int(eta_seconds // 60):02d}:{int(eta_seconds % 60):02d}"

            is_best = val_metrics.get("val_accuracy", 0) > self.best_metric
            if is_best:
                self.best_metric = val_metrics.get("val_accuracy", 0)
                self.best_epoch = epoch

            self._log_epoch(epoch, train_metrics, val_metrics, current_lr, epoch_time, eta_str)
            self._save_checkpoint(epoch, is_best)

            if self._check_early_stopping(val_metrics.get("val_loss", 0)):
                self.early_stopped = True
                break

        total_time = time.time() - total_start
        self.logger.info("=" * 70)
        self.logger.info("  TRAINING COMPLETE")
        self.logger.info("  Total time: %d m %d s", int(total_time // 60), int(total_time % 60))
        self.logger.info("  Best val_accuracy: %.4f at epoch %d", self.best_metric, self.best_epoch + 1)
        if self.early_stopped:
            self.logger.info("  Stopped by: EarlyStopping")
        self.logger.info("=" * 70)

        if self.tb_writer is not None:
            self.tb_writer.close()

        return {
            "best_metric": self.best_metric,
            "best_epoch": self.best_epoch + 1,
            "total_time": total_time,
            "early_stopped": self.early_stopped,
        }

    def _log_epoch(self, epoch: int, train_metrics: dict, val_metrics: dict,
                   lr: float, epoch_time: float, eta_str: str):
        msg = (
            f"Epoch {epoch + 1:3d}/{self.epochs} | "
            f"Loss: {train_metrics.get('train_loss', 0):.4f} | "
            f"Val Loss: {val_metrics.get('val_loss', 0):.4f} | "
            f"Acc: {val_metrics.get('val_accuracy', 0):.4f} | "
            f"Prec: {val_metrics.get('val_precision', 0):.4f} | "
            f"Rec: {val_metrics.get('val_recall', 0):.4f} | "
            f"F1: {val_metrics.get('val_f1', 0):.4f} | "
            f"AUC: {val_metrics.get('val_roc_auc', 0):.4f} | "
            f"LR: {lr:.6f} | "
            f"ETA: {eta_str}"
        )
        is_current_best = val_metrics.get("val_accuracy", 0) >= self.best_metric
        if epoch == 0:
            self.best_metric = val_metrics.get("val_accuracy", 0)
        prefix = "  [BEST] " if is_current_best else "         "
        self.logger.info("%s%s", prefix, msg)

        with open(str(self.csv_path), "a", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([
                epoch + 1,
                f"{train_metrics.get('train_loss', 0):.6f}",
                f"{val_metrics.get('val_loss', 0):.6f}",
                f"{val_metrics.get('val_accuracy', 0):.6f}",
                f"{val_metrics.get('val_precision', 0):.6f}",
                f"{val_metrics.get('val_recall', 0):.6f}",
                f"{val_metrics.get('val_f1', 0):.6f}",
                f"{val_metrics.get('val_roc_auc', 0):.6f}",
                f"{lr:.8f}",
                f"{epoch_time:.2f}",
            ])

        if self.tb_writer is not None:
            self.tb_writer.add_scalar("Loss/train", train_metrics.get("train_loss", 0), epoch)
            self.tb_writer.add_scalar("Loss/val", val_metrics.get("val_loss", 0), epoch)
            self.tb_writer.add_scalar("Metrics/accuracy", val_metrics.get("val_accuracy", 0), epoch)
            self.tb_writer.add_scalar("Metrics/precision", val_metrics.get("val_precision", 0), epoch)
            self.tb_writer.add_scalar("Metrics/recall", val_metrics.get("val_recall", 0), epoch)
            self.tb_writer.add_scalar("Metrics/f1", val_metrics.get("val_f1", 0), epoch)
            self.tb_writer.add_scalar("Metrics/roc_auc", val_metrics.get("val_roc_auc", 0), epoch)
            self.tb_writer.add_scalar("LR", lr, epoch)

    def _save_checkpoint(self, epoch: int, is_best: bool):
        ckpt = {
            "epoch": epoch + 1,
            "global_step": self.global_step,
            "model_state_dict": self.model.state_dict(),
            "optimizer_state_dict": self.optimizer.state_dict(),
            "scaler_state_dict": self.scaler.state_dict(),
            "best_metric": self.best_metric,
            "best_epoch": self.best_epoch,
            "config": self.config,
        }
        if self.scheduler is not None and not isinstance(self.scheduler, torch.optim.lr_scheduler.ReduceLROnPlateau):
            ckpt["scheduler_state_dict"] = self.scheduler.state_dict()

        last_path = self.checkpoint_dir / "last_model.pt"
        torch.save(ckpt, str(last_path))

        if is_best:
            best_path = self.checkpoint_dir / "best_model.pt"
            torch.save(ckpt, str(best_path))
