"""Early stopping callback to prevent overfitting."""

from typing import Any, Dict

from training.callbacks.callback_base import Callback


class EarlyStopping(Callback):
    """Stop training when a monitored metric stops improving."""

    def __init__(
        self,
        monitor: str = "val_accuracy",
        patience: int = 15,
        mode: str = "max",
        min_delta: float = 0.001,
        verbose: bool = True,
    ) -> None:
        self.monitor = monitor
        self.patience = patience
        self.mode = mode
        self.min_delta = min_delta
        self.verbose = verbose
        self.best_metric = float("-inf") if mode == "max" else float("inf")
        self.counter = 0
        self.early_stop = False

    def on_epoch_end(self, epoch: int, train_metrics: Dict[str, float],
                     val_metrics: Dict[str, float]) -> None:
        current_metric = val_metrics.get(self.monitor, 0.0)

        if self.mode == "max":
            improvement = current_metric - self.best_metric > self.min_delta
        else:
            improvement = self.best_metric - current_metric > self.min_delta

        if improvement:
            self.best_metric = current_metric
            self.counter = 0
        else:
            self.counter += 1
            if self.counter >= self.patience:
                self.early_stop = True
                if self.verbose:
                    import logging
                    logging.getLogger("EarlyStopping").info(
                        "Triggered at epoch %d (metric=%.4f, best=%.4f, patience=%d)",
                        epoch + 1, current_metric, self.best_metric, self.patience,
                    )
