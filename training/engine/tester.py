"""Test engine for final model evaluation with comprehensive reporting."""

import json
import logging
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

import torch
import torch.nn as nn
from torch.utils.data import DataLoader

from training.engine.base_engine import BaseEngine


class Tester(BaseEngine):
    """Final model testing with comprehensive metric computation and report generation."""

    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        loss_fn: Callable,
        test_loader: DataLoader,
        metrics: Optional[List[Callable]] = None,
        device: Optional[torch.device] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        super().__init__(model, config, device, logger)
        self.loss_fn = loss_fn
        self.test_loader = test_loader
        self.metrics = metrics or []

    def run(self) -> Dict[str, Any]:
        self.model.eval()
        total_loss = 0.0
        all_outputs: List[torch.Tensor] = []
        all_targets: List[torch.Tensor] = []

        with torch.no_grad():
            for batch in self.test_loader:
                images, labels = self.to_device(batch)
                outputs = self.model(images)
                loss = self.loss_fn(outputs, labels)
                total_loss += loss.item()
                all_outputs.append(outputs.cpu())
                all_targets.append(labels.cpu())

        results: Dict[str, Any] = {
            "test_loss": total_loss / len(self.test_loader),
        }

        if all_outputs:
            outputs_tensor = torch.cat(all_outputs, dim=0)
            targets_tensor = torch.cat(all_targets, dim=0)
            probabilities = torch.softmax(outputs_tensor, dim=1)
            predictions = torch.argmax(outputs_tensor, dim=1)

            results["predictions"] = predictions.numpy().tolist()
            results["targets"] = targets_tensor.numpy().tolist()
            results["probabilities"] = probabilities.numpy().tolist()

            for metric_fn in self.metrics:
                try:
                    metric_name = getattr(metric_fn, "__name__", str(metric_fn))
                    metric_value = metric_fn(outputs_tensor, targets_tensor)
                    results[metric_name] = metric_value
                    if isinstance(metric_value, float):
                        self.logger.info("  %s: %.4f", metric_name, metric_value)
                except Exception as exc:
                    self.logger.warning("Metric %s failed: %s", metric_fn, exc)

        return results

    def save_report(self, results: Dict[str, Any], output_path: str) -> None:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        report = {k: v for k, v in results.items()
                  if k not in ("predictions", "probabilities")}
        report["num_samples"] = len(results.get("targets", []))

        with open(str(path), "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        self.logger.info("Test report saved to %s", path)
