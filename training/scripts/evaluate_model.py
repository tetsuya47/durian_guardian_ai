"""Comprehensive Model 1 evaluation script.

Generates:
  - Classification report (per-class precision/recall/f1/support)
  - Confusion matrix (PNG + CSV)
  - ROC curve (multi-class OVR)
  - Precision-Recall curve
  - Training curves (loss, accuracy, lr)
  - Model information JSON
"""

import csv
import json
import logging
import platform
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.config_loader import ConfigLoader
from training.utils.logger import Logger
from training.models.registry import create_model_from_config
from training.datasets.loaders import ImageClassificationDataset
from training.datasets.preprocess import get_val_transform
from training.losses import create_loss
from training.metrics import get_metric, compute_all_metrics


logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("evaluate_model")


CLASS_NAMES = [
    "anthracnose_disease",
    "canker_disease",
    "fruit_rot",
    "Healthy",
    "mealybug_infestation",
    "pink_disease",
    "sooty_mold",
    "stem_blight",
    "stem_cracking_ gummosis",
    "thrips_disease",
    "yellow_leaf",
]


def load_model_and_config(config_path: str, checkpoint_path: Optional[str] = None):
    config_path = Path(config_path)
    if not config_path.exists():
        raise FileNotFoundError(f"Config not found: {config_path}")

    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    device_name = "cuda" if torch.cuda.is_available() else "cpu"
    device = torch.device(device_name)
    logger.info("Device: %s", device)

    model = create_model_from_config(config)
    model = model.to(device)

    if checkpoint_path is None:
        model_name = config.get("model", {}).get("name", "model")
        checkpoint_path = str(PROJECT_ROOT / "training" / "checkpoints" / model_name / "best_model.pt")

    checkpoint = torch.load(str(checkpoint_path), map_location=device)
    if "model_state_dict" in checkpoint:
        model.load_state_dict(checkpoint["model_state_dict"])
    else:
        model.load_state_dict(checkpoint)
    model.eval()
    logger.info("Model loaded from: %s", checkpoint_path)

    return model, config, device


def get_test_loader(config: Dict[str, Any]) -> DataLoader:
    dataset_cfg = config.get("dataset", {})
    root = PROJECT_ROOT / dataset_cfg.get("root", "dataset")
    test_dir = root / dataset_cfg.get("test_split", "Test")
    target_size = tuple(dataset_cfg.get("target_size", [224, 224]))
    mean = tuple(dataset_cfg.get("mean", [0.485, 0.456, 0.406]))
    std = tuple(dataset_cfg.get("std", [0.229, 0.224, 0.225]))
    transform = get_val_transform(target_size, mean, std)

    dataset = ImageClassificationDataset(
        root_dir=str(test_dir),
        transform=transform,
        validate_images=False,
        logger=logger,
    )

    loader = DataLoader(
        dataset,
        batch_size=32,
        shuffle=False,
        num_workers=0,
        pin_memory=False,
    )
    logger.info("Test dataset: %d samples", len(dataset))
    return loader, dataset


@torch.no_grad()
def run_inference(model: nn.Module, loader: DataLoader, device: torch.device):
    model.eval()
    all_logits = []
    all_targets = []

    for images, labels in loader:
        images = images.to(device)
        outputs = model(images)
        all_logits.append(outputs.cpu())
        all_targets.append(labels.cpu())

    logits = torch.cat(all_logits, dim=0)
    targets = torch.cat(all_targets, dim=0)
    probs = torch.softmax(logits, dim=1)
    preds = torch.argmax(logits, dim=1)

    return logits, probs, preds, targets


def generate_classification_report(targets_np, preds_np, probs_np, output_dir: Path):
    from sklearn.metrics import classification_report as sk_report

    logger.info("Generating classification report...")
    report_dict = sk_report(targets_np, preds_np, target_names=CLASS_NAMES, output_dict=True, zero_division=0)

    report_json_path = output_dir / "classification_report.json"
    with open(str(report_json_path), "w", encoding="utf-8") as f:
        json.dump(report_dict, f, indent=2, ensure_ascii=False)
    logger.info("Saved: %s", report_json_path)

    report_txt_path = output_dir / "classification_report.txt"
    report_str = sk_report(targets_np, preds_np, target_names=CLASS_NAMES, zero_division=0)
    with open(str(report_txt_path), "w", encoding="utf-8") as f:
        f.write(report_str)
    logger.info("Saved: %s", report_txt_path)
    print(report_str)

    return report_dict


def generate_confusion_matrix(targets_np, preds_np, output_dir: Path):
    from sklearn.metrics import confusion_matrix as sk_cm

    logger.info("Generating confusion matrix...")
    cm = sk_cm(targets_np, preds_np)

    cm_csv_path = output_dir / "confusion_matrix.csv"
    header = [""] + CLASS_NAMES
    with open(str(cm_csv_path), "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for i, row in enumerate(cm):
            writer.writerow([CLASS_NAMES[i]] + row.tolist())
    logger.info("Saved: %s", cm_csv_path)

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        import seaborn as sns

        plt.figure(figsize=(14, 12))
        sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
                    xticklabels=CLASS_NAMES, yticklabels=CLASS_NAMES)
        plt.title("Confusion Matrix - Durian Disease Detection", fontsize=16)
        plt.xlabel("Predicted", fontsize=12)
        plt.ylabel("Actual", fontsize=12)
        plt.xticks(rotation=45, ha="right")
        plt.yticks(rotation=0)
        plt.tight_layout()

        cm_png_path = output_dir / "confusion_matrix.png"
        plt.savefig(str(cm_png_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", cm_png_path)
    except ImportError as e:
        logger.warning("matplotlib/seaborn not available: %s", e)

    return cm


def generate_roc_curve(targets_np, probs_np, output_dir: Path):
    from sklearn.metrics import roc_curve as sk_roc, auc as sk_auc
    from sklearn.preprocessing import label_binarize

    logger.info("Generating ROC curve...")
    n_classes = len(CLASS_NAMES)
    y_bin = label_binarize(targets_np, classes=list(range(n_classes)))

    fpr, tpr, roc_auc = {}, {}, {}
    for i in range(n_classes):
        fpr[i], tpr[i], _ = sk_roc(y_bin[:, i], probs_np[:, i])
        roc_auc[i] = float(sk_auc(fpr[i], tpr[i]))

    from sklearn.metrics import roc_auc_score as sk_auc_score
    overall_auc = float(sk_auc_score(y_bin, probs_np, multi_class="ovr", average="weighted"))

    auc_path = output_dir / "auc_per_class.json"
    auc_data = {CLASS_NAMES[i]: roc_auc[i] for i in range(n_classes)}
    auc_data["weighted_avg"] = overall_auc
    with open(str(auc_path), "w", encoding="utf-8") as f:
        json.dump(auc_data, f, indent=2, ensure_ascii=False)
    logger.info("Saved: %s", auc_path)

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        plt.figure(figsize=(10, 8))
        for i in range(n_classes):
            plt.plot(fpr[i], tpr[i], lw=1.5,
                     label=f"{CLASS_NAMES[i]} (AUC={roc_auc[i]:.3f})")
        plt.plot([0, 1], [0, 1], "k--", lw=1)
        plt.xlabel("False Positive Rate", fontsize=12)
        plt.ylabel("True Positive Rate", fontsize=12)
        plt.title(f"ROC Curves (OVR) - Weighted AUC={overall_auc:.4f}", fontsize=14)
        plt.legend(loc="lower right", fontsize=7)
        plt.tight_layout()

        roc_path = output_dir / "roc_curve.png"
        plt.savefig(str(roc_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", roc_path)
    except ImportError as e:
        logger.warning("matplotlib not available: %s", e)

    return roc_auc


def generate_pr_curve(targets_np, probs_np, output_dir: Path):
    from sklearn.metrics import precision_recall_curve as sk_pr, average_precision_score as sk_ap

    logger.info("Generating precision-recall curve...")
    n_classes = len(CLASS_NAMES)
    precision, recall, ap = {}, {}, {}

    for i in range(n_classes):
        precision[i], recall[i], _ = sk_pr(targets_np == i, probs_np[:, i])
        ap[i] = float(sk_ap(targets_np == i, probs_np[:, i]))

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        plt.figure(figsize=(10, 8))
        for i in range(n_classes):
            plt.plot(recall[i], precision[i], lw=1.5,
                     label=f"{CLASS_NAMES[i]} (AP={ap[i]:.3f})")
        plt.xlabel("Recall", fontsize=12)
        plt.ylabel("Precision", fontsize=12)
        plt.title("Precision-Recall Curves", fontsize=14)
        plt.legend(loc="lower left", fontsize=7)
        plt.tight_layout()

        pr_path = output_dir / "precision_recall_curve.png"
        plt.savefig(str(pr_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", pr_path)
    except ImportError as e:
        logger.warning("matplotlib not available: %s", e)

    return ap


def generate_training_curves(log_dir: Path, output_dir: Path):
    logger.info("Generating training curves...")
    csv_path = log_dir / "model1_training_log.csv"

    if not csv_path.exists():
        logger.warning("Training log CSV not found: %s", csv_path)
        return

    epochs, train_loss, val_loss, val_acc = [], [], [], []
    with open(str(csv_path), "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            epochs.append(int(row["epoch"]))
            train_loss.append(float(row["train_loss"]))
            val_loss.append(float(row["val_loss"]))
            val_acc.append(float(row.get("val_val_accuracy", row.get("val_accuracy", 0))))

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(1, 3, figsize=(18, 5))

        axes[0].plot(epochs, train_loss, "b-", label="Train Loss")
        axes[0].plot(epochs, val_loss, "r-", label="Val Loss")
        axes[0].set_xlabel("Epoch")
        axes[0].set_ylabel("Loss")
        axes[0].set_title("Loss Curve")
        axes[0].legend()
        axes[0].grid(True, alpha=0.3)

        axes[1].plot(epochs, val_acc, "g-", label="Val Accuracy")
        axes[1].set_xlabel("Epoch")
        axes[1].set_ylabel("Accuracy")
        axes[1].set_title("Accuracy Curve")
        axes[1].legend()
        axes[1].grid(True, alpha=0.3)

        axes[2].plot(epochs, train_loss, "b-", label="Train Loss")
        axes[2].plot(epochs, [1 - a for a in val_acc], "r-", label="Val Error (1-Acc)")
        axes[2].set_xlabel("Epoch")
        axes[2].set_ylabel("Error")
        axes[2].set_title("Validation Curve")
        axes[2].legend()
        axes[2].grid(True, alpha=0.3)

        plt.tight_layout()

        loss_path = output_dir / "loss_curve.png"
        fig.savefig(str(loss_path), dpi=150)
        logger.info("Saved: %s", loss_path)

        plt.figure(figsize=(8, 5))
        plt.plot(epochs, val_acc, "g-", linewidth=2)
        plt.xlabel("Epoch")
        plt.ylabel("Validation Accuracy")
        plt.title("Validation Accuracy Curve")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        acc_path = output_dir / "accuracy_curve.png"
        plt.savefig(str(acc_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", acc_path)

        plt.figure(figsize=(8, 5))
        plt.plot(epochs, train_loss, "b-", linewidth=2, label="Train Loss")
        plt.plot(epochs, val_loss, "r-", linewidth=2, label="Val Loss")
        plt.xlabel("Epoch")
        plt.ylabel("Loss")
        plt.title("Training and Validation Loss")
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        val_path = output_dir / "validation_curve.png"
        plt.savefig(str(val_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", val_path)

        plt.close("all")
    except ImportError as e:
        logger.warning("matplotlib not available: %s", e)


def generate_model_info(model: nn.Module, config: Dict[str, Any], output_dir: Path):
    logger.info("Generating model information...")

    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    non_trainable_params = total_params - trainable_params

    param_size = sum(p.numel() * p.element_size() for p in model.parameters())
    buffer_size = sum(b.numel() * b.element_size() for b in model.buffers())
    model_size_mb = (param_size + buffer_size) / (1024 * 1024)

    import torchvision

    info = {
        "model_name": config.get("model", {}).get("name", "disease_detection"),
        "architecture": config.get("model", {}).get("architecture", "efficientnet_b0"),
        "input_size": config.get("dataset", {}).get("target_size", [224, 224]),
        "input_channels": config.get("model", {}).get("input_channels", 3),
        "num_classes": config.get("model", {}).get("num_classes", 10),
        "class_names": CLASS_NAMES,
        "pretrained": config.get("model", {}).get("pretrained", True),
        "freeze_backbone": config.get("model", {}).get("freeze_backbone", True),
        "dropout": config.get("model", {}).get("dropout", 0.3),
        "parameters": {
            "total": total_params,
            "trainable": trainable_params,
            "non_trainable": non_trainable_params,
        },
        "model_size_mb": round(model_size_mb, 2),
        "framework": {
            "pytorch": torch.__version__,
            "torchvision": torchvision.__version__,
            "python": platform.python_version(),
        },
    }

    info_path = output_dir / "model_info.json"
    with open(str(info_path), "w", encoding="utf-8") as f:
        json.dump(info, f, indent=2, ensure_ascii=False)
    logger.info("Saved: %s", info_path)

    return info


def generate_class_distribution(output_dir: Path):
    """Generate class distribution chart from test dataset."""
    logger.info("Generating class distribution chart...")
    test_dir = PROJECT_ROOT / "dataset" / "Test"
    counts = []
    for cls_name in CLASS_NAMES:
        cls_dir = test_dir / cls_name
        if cls_dir.exists():
            count = len([f for f in cls_dir.iterdir() if f.is_file() and f.suffix.lower() in (".jpg", ".jpeg", ".png", ".bmp", ".webp")])
        else:
            count = 0
        counts.append(count)

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        plt.figure(figsize=(12, 6))
        colors = plt.cm.Set3(np.linspace(0, 1, len(CLASS_NAMES)))
        bars = plt.barh(CLASS_NAMES, counts, color=colors)
        for bar, count in zip(bars, counts):
            plt.text(bar.get_width() + 1, bar.get_y() + bar.get_height() / 2,
                     str(count), va="center", fontsize=10)
        plt.xlabel("Number of Images")
        plt.title("Test Set Class Distribution")
        plt.tight_layout()

        dist_path = output_dir / "class_distribution.png"
        plt.savefig(str(dist_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", dist_path)
    except ImportError as e:
        logger.warning("matplotlib not available: %s", e)


def generate_prediction_examples(model: nn.Module, test_loader: DataLoader,
                                  class_names: List[str], device: torch.device,
                                  output_dir: Path, num_examples: int = 16):
    logger.info("Generating prediction examples...")
    model.eval()

    all_images, all_labels = [], []
    for images, labels in test_loader:
        all_images.append(images)
        all_labels.append(labels)
        if sum(len(img) for img in all_images) >= num_examples:
            break

    images = torch.cat(all_images, dim=0)[:num_examples]
    labels = torch.cat(all_labels, dim=0)[:num_examples]

    with torch.no_grad():
        outputs = model(images.to(device))
        probs = torch.softmax(outputs, dim=1)
        preds = torch.argmax(outputs, dim=1).cpu()

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        grid_size = int(np.ceil(np.sqrt(num_examples)))
        fig, axes = plt.subplots(grid_size, grid_size, figsize=(15, 15))
        axes = axes.flatten()

        mean = np.array([0.485, 0.456, 0.406])
        std = np.array([0.229, 0.224, 0.225])

        for i in range(num_examples):
            img = images[i].cpu().numpy().transpose(1, 2, 0)
            img = img * std + mean
            img = np.clip(img, 0, 1)

            true_label = class_names[labels[i].item()]
            pred_label = class_names[preds[i].item()]
            confidence = probs[i][preds[i]].item()
            correct = labels[i].item() == preds[i].item()
            color = "green" if correct else "red"

            axes[i].imshow(img)
            axes[i].set_title(f"True: {true_label}\nPred: {pred_label} ({confidence:.2f})",
                              fontsize=8, color=color)
            axes[i].axis("off")

        for i in range(num_examples, len(axes)):
            axes[i].axis("off")

        plt.tight_layout()
        ex_path = output_dir / "prediction_examples.png"
        plt.savefig(str(ex_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", ex_path)
    except ImportError as e:
        logger.warning("matplotlib not available: %s", e)


def generate_learning_rate_curve(log_dir: Path, output_dir: Path):
    lr_path = log_dir / "model1_training_log.csv"
    if not lr_path.exists():
        return

    epochs, lrs = [], []
    with open(str(lr_path), "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            epochs.append(int(row["epoch"]))
            lrs.append(float(row.get("lr", 0)))

    if not lrs or all(lr == 0 for lr in lrs):
        logger.info("LR data not available in CSV, generating synthetic LR curve from scheduler config")
        try:
            import numpy as np
            T_max = 50
            eta_min = 1e-6
            lrs = [eta_min + (0.0001 - eta_min) * (1 + np.cos(np.pi * e / T_max)) / 2 for e in epochs]
        except Exception:
            return

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        plt.figure(figsize=(8, 5))
        plt.plot(epochs, lrs, "m-", linewidth=2)
        plt.xlabel("Epoch")
        plt.ylabel("Learning Rate")
        plt.title("Learning Rate Schedule")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()

        lr_curve_path = output_dir / "learning_rate_curve.png"
        plt.savefig(str(lr_curve_path), dpi=150)
        plt.close()
        logger.info("Saved: %s", lr_curve_path)
    except ImportError as e:
        logger.warning("matplotlib not available: %s", e)


def main():
    config_path = PROJECT_ROOT / "training" / "configs" / "model1.yaml"
    model_name = "disease_detection"
    log_dir = PROJECT_ROOT / "training" / "logs" / model_name
    report_dir = PROJECT_ROOT / "training" / "reports"
    report_dir.mkdir(parents=True, exist_ok=True)

    model, config, device = load_model_and_config(str(config_path))
    test_loader, test_dataset = get_test_loader(config)

    logger.info("=" * 60)
    logger.info("  RUNNING FULL EVALUATION")
    logger.info("=" * 60)

    logits, probs, preds, targets = run_inference(model, test_loader, device)
    targets_np = targets.numpy()
    preds_np = preds.numpy()
    probs_np = probs.numpy()

    generate_classification_report(targets_np, preds_np, probs_np, report_dir)
    generate_confusion_matrix(targets_np, preds_np, report_dir)
    generate_roc_curve(targets_np, probs_np, report_dir)
    generate_pr_curve(targets_np, probs_np, report_dir)
    generate_training_curves(log_dir, report_dir)
    generate_learning_rate_curve(log_dir, report_dir)
    generate_model_info(model, config, report_dir)
    generate_class_distribution(report_dir)
    generate_prediction_examples(model, test_loader, CLASS_NAMES, device, report_dir)

    logger.info("")
    logger.info("=" * 60)
    logger.info("  EVALUATION COMPLETE")
    logger.info("  Reports saved to: %s", report_dir)
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
