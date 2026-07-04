"""Learning rate scheduler factory with warmup support."""

import logging
import math
from typing import Any, Dict, Optional

import torch
from torch.optim.lr_scheduler import _LRScheduler

import warnings
warnings.filterwarnings("ignore", category=UserWarning)


class WarmupCosineSchedule(_LRScheduler):
    """Cosine LR scheduler with linear warmup."""

    def __init__(
        self,
        optimizer: torch.optim.Optimizer,
        warmup_steps: int,
        total_steps: int,
        min_lr: float = 1e-6,
        last_epoch: int = -1,
    ) -> None:
        self.warmup_steps = warmup_steps
        self.total_steps = total_steps
        self.min_lr = min_lr
        super().__init__(optimizer, last_epoch)

    def get_lr(self):
        step = self.last_epoch
        if step < self.warmup_steps:
            return [base_lr * (step + 1) / (self.warmup_steps + 1) for base_lr in self.base_lrs]
        progress = (step - self.warmup_steps) / max(1, self.total_steps - self.warmup_steps)
        return [
            self.min_lr + 0.5 * (base_lr - self.min_lr) * (1 + math.cos(math.pi * progress))
            for base_lr in self.base_lrs
        ]


class LinearWarmup(_LRScheduler):
    """Linear warmup scheduler wrapper."""

    def __init__(self, optimizer: torch.optim.Optimizer, warmup_steps: int,
                 main_scheduler: Optional[_LRScheduler] = None, last_epoch: int = -1) -> None:
        self.warmup_steps = warmup_steps
        self.main_scheduler = main_scheduler
        super().__init__(optimizer, last_epoch)

    def get_lr(self):
        if self.last_epoch < self.warmup_steps:
            return [
                base_lr * (self.last_epoch + 1) / (self.warmup_steps + 1)
                for base_lr in self.base_lrs
            ]
        if self.main_scheduler:
            return self.main_scheduler.get_last_lr()
        return [group["lr"] for group in self.optimizer.param_groups]

    def step(self, epoch=None):
        super().step(epoch)
        if self.main_scheduler and self.last_epoch >= self.warmup_steps:
            self.main_scheduler.step(epoch)


SCHEDULER_REGISTRY = {
    "CosineAnnealingLR": torch.optim.lr_scheduler.CosineAnnealingLR,
    "CosineAnnealingWarmRestarts": torch.optim.lr_scheduler.CosineAnnealingWarmRestarts,
    "StepLR": torch.optim.lr_scheduler.StepLR,
    "MultiStepLR": torch.optim.lr_scheduler.MultiStepLR,
    "ReduceLROnPlateau": torch.optim.lr_scheduler.ReduceLROnPlateau,
    "ExponentialLR": torch.optim.lr_scheduler.ExponentialLR,
    "OneCycleLR": torch.optim.lr_scheduler.OneCycleLR,
    "WarmupCosineSchedule": WarmupCosineSchedule,
}


def _coerce_params(params: Dict[str, Any]) -> Dict[str, Any]:
    coerced = {}
    for key, value in params.items():
        if isinstance(value, str):
            try:
                if "." in value or "e" in value.lower():
                    coerced[key] = float(value)
                else:
                    coerced[key] = int(value)
            except (ValueError, TypeError):
                coerced[key] = value
        elif isinstance(value, (list, tuple)):
            coerced[key] = [_coerce_params({str(i): v})[str(i)] if isinstance(v, dict) else _coerce_value(v) for v in value]
        else:
            coerced[key] = value
    return coerced


def _coerce_value(value: Any) -> Any:
    if isinstance(value, str):
        try:
            if "." in value or "e" in value.lower():
                return float(value)
            return int(value)
        except (ValueError, TypeError):
            return value
    return value


def create_scheduler(
    optimizer: torch.optim.Optimizer,
    config: Dict[str, Any],
    steps_per_epoch: Optional[int] = None,
) -> Optional[object]:
    logger = logging.getLogger("SchedulerFactory")

    sched_config = config.get("scheduler", {})
    sched_name = sched_config.get("name", None)
    if not sched_name or sched_name == "none":
        return None

    if sched_name not in SCHEDULER_REGISTRY:
        raise ValueError(
            f"Unknown scheduler: '{sched_name}'. Available: {list(SCHEDULER_REGISTRY.keys())}"
        )

    sched_params = _coerce_params(sched_config.get("params", {}).copy())
    warmup_epochs = _coerce_value(sched_config.get("warmup_epochs", 0))

    logger.info("=== Scheduler params ===")
    logger.info("  name: %s", sched_config.get("name"))
    logger.info("  warmup_epochs: type=%s value=%r", type(warmup_epochs).__name__, warmup_epochs)
    for key, value in sched_params.items():
        logger.info("  %s: type=%s value=%r", key, type(value).__name__, value)

    if sched_name == "OneCycleLR" and steps_per_epoch:
        sched_params["steps_per_epoch"] = steps_per_epoch
        epochs = config.get("training", {}).get("epochs", 100)
        sched_params["epochs"] = epochs

    sched_class = SCHEDULER_REGISTRY[sched_name]

    try:
        scheduler = sched_class(optimizer, **sched_params)
    except TypeError as exc:
        logging.getLogger("Scheduler").warning(
            "Failed to create '%s' with params %s: %s",
            sched_name, sched_params, exc,
        )
        scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=50)

    if warmup_epochs > 0:
        total_epochs = _coerce_value(config.get("training", {}).get("epochs", 100))
        min_lr = _coerce_value(sched_config.get("params", {}).get("eta_min", 1e-6))
        scheduler = WarmupCosineSchedule(
            optimizer,
            warmup_steps=warmup_epochs,
            total_steps=total_epochs,
            min_lr=min_lr,
        )

    return scheduler
