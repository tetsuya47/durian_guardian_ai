"""Validation engine for model evaluation during and after training."""

import logging
from typing import Any, Callable, Dict, List, Optional

import torch
import torch.nn as nn
from torch.utils.data import DataLoader

from training.engine.base_engine import BaseEngine


class Validator(BaseEngine):
    """Evaluates model performance on validation data with configurable metrics."""

    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        loss_fn: Callable,
        val_loader: DataLoader,
        metrics: Optional[List[Callable]] = None,
        device: Optional[torch.device] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        super().__init__(model, config, device, logger)
        self.loss_fn = loss_fn
        self.val_loader = val_loader
        self.metrics = metrics or []

    def run(self) -> Dict[str, float]:
        self.model.eval()
        total_loss = 0.0
        all_outputs: List[torch.Tensor] = []
        all_targets: List[torch.Tensor] = []

        with torch.no_grad():
            for batch_idx, batch in enumerate(self.val_loader):
                images, labels = self.to_device(batch)
                outputs = self.model(images)
                loss = self.loss_fn(outputs, labels)
                total_loss += loss.item()

                all_outputs.append(outputs.cpu())
                all_targets.append(labels.cpu())

        avg_loss = total_loss / len(self.val_loader)
        results = {"loss": avg_loss}

        if all_outputs:
            outputs_tensor = torch.cat(all_outputs, dim=0)
            targets_tensor = torch.cat(all_targets, dim=0)

            for metric_fn in self.metrics:
                try:
                    metric_name = getattr(metric_fn, "__name__", str(metric_fn))
                    metric_value = metric_fn(outputs_tensor, targets_tensor)
                    results[metric_name] = metric_value
                except Exception as exc:
                    self.logger.warning("Metric %s failed: %s", metric_fn, exc)

        return results

    def run_for_metrics(self, metrics: List[Callable]) -> Dict[str, float]:
        saved_metrics = self.metrics
        self.metrics = metrics
        results = self.run()
        self.metrics = saved_metrics
        return results
