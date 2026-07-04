"""Classification metrics for model evaluation.

All metrics accept (predictions, targets) tensors and return scalar values.
"""

from typing import Dict, List, Optional, Tuple, Union

import torch
import numpy as np


def accuracy(predictions: torch.Tensor, targets: torch.Tensor) -> float:
    """Top-1 accuracy."""
    preds = torch.argmax(predictions, dim=1)
    correct = (preds == targets).sum().item()
    total = targets.size(0)
    return correct / total if total > 0 else 0.0


def top5_accuracy(predictions: torch.Tensor, targets: torch.Tensor) -> float:
    """Top-5 accuracy."""
    if predictions.size(1) < 5:
        return 0.0
    _, top5 = predictions.topk(5, dim=1)
    correct = top5.eq(targets.view(-1, 1)).sum().item()
    total = targets.size(0)
    return correct / total if total > 0 else 0.0


def precision(predictions: torch.Tensor, targets: torch.Tensor, average: str = "weighted") -> float:
    """Precision score."""
    preds = torch.argmax(predictions, dim=1).cpu().numpy()
    targets_np = targets.cpu().numpy()
    from sklearn.metrics import precision_score
    try:
        return float(precision_score(targets_np, preds, average=average, zero_division=0))
    except Exception:
        return 0.0


def recall(predictions: torch.Tensor, targets: torch.Tensor, average: str = "weighted") -> float:
    """Recall score."""
    preds = torch.argmax(predictions, dim=1).cpu().numpy()
    targets_np = targets.cpu().numpy()
    from sklearn.metrics import recall_score
    try:
        return float(recall_score(targets_np, preds, average=average, zero_division=0))
    except Exception:
        return 0.0


def f1_score(predictions: torch.Tensor, targets: torch.Tensor, average: str = "weighted") -> float:
    """F1 score."""
    preds = torch.argmax(predictions, dim=1).cpu().numpy()
    targets_np = targets.cpu().numpy()
    from sklearn.metrics import f1_score as sk_f1
    try:
        return float(sk_f1(targets_np, preds, average=average, zero_division=0))
    except Exception:
        return 0.0


def confusion_matrix(predictions: torch.Tensor, targets: torch.Tensor) -> np.ndarray:
    """Compute confusion matrix."""
    preds = torch.argmax(predictions, dim=1).cpu().numpy()
    targets_np = targets.cpu().numpy()
    from sklearn.metrics import confusion_matrix as sk_cm
    return sk_cm(targets_np, preds)


def roc_auc(predictions: torch.Tensor, targets: torch.Tensor) -> float:
    """ROC AUC score (one-vs-rest for multi-class)."""
    probs = torch.softmax(predictions, dim=1).cpu().numpy()
    targets_np = targets.cpu().numpy()
    num_classes = probs.shape[1]
    if num_classes == 2:
        probs = probs[:, 1]
    from sklearn.metrics import roc_auc_score as sk_auc
    try:
        if num_classes > 2:
            return float(sk_auc(targets_np, probs, multi_class="ovr", average="weighted"))
        return float(sk_auc(targets_np, probs))
    except Exception:
        return 0.0


def pr_curve(predictions: torch.Tensor, targets: torch.Tensor) -> Dict[str, list]:
    """Precision-Recall curve data."""
    probs = torch.softmax(predictions, dim=1).cpu().numpy()
    targets_np = targets.cpu().numpy()
    from sklearn.metrics import precision_recall_curve
    curves = {}
    num_classes = probs.shape[1]
    for i in range(num_classes):
        binary_target = (targets_np == i).astype(np.int32)
        precision_vals, recall_vals, _ = precision_recall_curve(binary_target, probs[:, i])
        curves[f"class_{i}"] = {
            "precision": precision_vals.tolist(),
            "recall": recall_vals.tolist(),
        }
    return curves


def classification_report(predictions: torch.Tensor, targets: torch.Tensor) -> Dict:
    """Full classification report."""
    preds = torch.argmax(predictions, dim=1).cpu().numpy()
    targets_np = targets.cpu().numpy()
    from sklearn.metrics import classification_report as sk_report
    report = sk_report(targets_np, preds, output_dict=True, zero_division=0)
    return report


METRIC_REGISTRY = {
    "accuracy": accuracy,
    "top5": top5_accuracy,
    "precision": precision,
    "recall": recall,
    "f1_score": f1_score,
    "confusion_matrix": confusion_matrix,
    "roc_auc": roc_auc,
    "pr_curve": pr_curve,
    "classification_report": classification_report,
}


def get_metric(name: str):
    if name not in METRIC_REGISTRY:
        raise ValueError(f"Unknown metric: '{name}'. Available: {list(METRIC_REGISTRY.keys())}")
    return METRIC_REGISTRY[name]


def compute_all_metrics(
    predictions: torch.Tensor,
    targets: torch.Tensor,
    metric_names: List[str],
) -> Dict[str, float]:
    results = {}
    for name in metric_names:
        try:
            metric_fn = get_metric(name)
            value = metric_fn(predictions, targets)
            if isinstance(value, (float, np.floating)):
                results[name] = float(value)
        except Exception as exc:
            import logging
            logging.getLogger("Metrics").warning("Failed to compute '%s': %s", name, exc)
    return results
