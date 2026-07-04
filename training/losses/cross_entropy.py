"""Loss function factory with support for multiple loss types."""

import logging
from typing import Any, Dict, Optional

import torch
import torch.nn as nn


class LabelSmoothingCrossEntropy(nn.Module):
    """Cross entropy loss with label smoothing."""

    def __init__(self, smoothing: float = 0.1, reduction: str = "mean") -> None:
        super().__init__()
        self.smoothing = smoothing
        self.reduction = reduction

    def forward(self, predictions: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
        log_probs = torch.log_softmax(predictions, dim=-1)
        n_classes = predictions.size(-1)
        with torch.no_grad():
            smooth_targets = torch.full_like(log_probs, self.smoothing / (n_classes - 1))
            smooth_targets.scatter_(1, targets.unsqueeze(1), 1 - self.smoothing)
        loss = -(smooth_targets * log_probs).sum(dim=-1)
        if self.reduction == "mean":
            return loss.mean()
        if self.reduction == "sum":
            return loss.sum()
        return loss


class FocalLoss(nn.Module):
    """Focal loss for class imbalance."""

    def __init__(self, alpha: float = 0.25, gamma: float = 2.0, reduction: str = "mean") -> None:
        super().__init__()
        self.alpha = alpha
        self.gamma = gamma
        self.reduction = reduction

    def forward(self, predictions: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
        ce_loss = torch.nn.functional.cross_entropy(predictions, targets, reduction="none")
        pt = torch.exp(-ce_loss)
        focal_loss = self.alpha * (1 - pt) ** self.gamma * ce_loss
        if self.reduction == "mean":
            return focal_loss.mean()
        if self.reduction == "sum":
            return focal_loss.sum()
        return focal_loss


LOSS_REGISTRY = {
    "CrossEntropyLoss": nn.CrossEntropyLoss,
    "BCEWithLogitsLoss": nn.BCEWithLogitsLoss,
    "MSELoss": nn.MSELoss,
    "L1Loss": nn.L1Loss,
    "LabelSmoothingCrossEntropy": LabelSmoothingCrossEntropy,
    "FocalLoss": FocalLoss,
}


def create_loss(config: Dict[str, Any]) -> nn.Module:
    loss_config = config.get("loss", {})
    loss_name = loss_config.get("name", "CrossEntropyLoss")
    loss_params = loss_config.get("params", {})

    if loss_name not in LOSS_REGISTRY:
        raise ValueError(
            f"Unknown loss: '{loss_name}'. Available: {list(LOSS_REGISTRY.keys())}"
        )

    coerced = {}
    for key, value in loss_params.items():
        if isinstance(value, str):
            try:
                if "." in value or "e" in value.lower():
                    coerced[key] = float(value)
                else:
                    coerced[key] = int(value)
            except (ValueError, TypeError):
                coerced[key] = value
        else:
            coerced[key] = value

    loss_class = LOSS_REGISTRY[loss_name]
    return loss_class(**coerced)
