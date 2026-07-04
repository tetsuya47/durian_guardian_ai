"""Generate comprehensive Model 1 final report with per-class metrics."""
import json, sys, yaml
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

import torch
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, auc, precision_recall_curve
from training.models.registry import create_model_from_config
from training.datasets.loaders import ImageClassificationDataset
from training.datasets.preprocess import get_val_transform
from torch.utils.data import DataLoader

device = torch.device("cpu")

# Load config
config_path = PROJECT_ROOT / "training" / "configs" / "model1.yaml"
with open(config_path) as f:
    config = yaml.safe_load(f)

# Class names from cleaned dataset
class_names = sorted([
    d.name for d in (PROJECT_ROOT / "dataset_cleaned" / "Train").iterdir() if d.is_dir()
])
print(f"Classes ({len(class_names)}): {class_names}")

# Model
model = create_model_from_config(config)
checkpoint = torch.load(PROJECT_ROOT / "training" / "checkpoints" / "disease_detection" / "best_model.pt", map_location=device)
model.load_state_dict(checkpoint["model_state_dict"])
model = model.to(device)
model.eval()

# Test dataset
dataset_cfg = config["dataset"]
root = PROJECT_ROOT / dataset_cfg["root"]
test_dir = root / dataset_cfg["test_split"]
target_size = tuple(dataset_cfg.get("target_size", [224, 224]))
mean = tuple(dataset_cfg.get("mean", [0.485, 0.456, 0.406]))
std = tuple(dataset_cfg.get("std", [0.229, 0.224, 0.225]))
val_transform = get_val_transform(target_size, mean, std)

test_dataset = ImageClassificationDataset(root_dir=str(test_dir), transform=val_transform)
test_loader = DataLoader(test_dataset, batch_size=32, shuffle=False, num_workers=0)

# Run inference
all_preds = []
all_targets = []
all_probs = []

with torch.no_grad():
    for images, labels in test_loader:
        images = images.to(device)
        outputs = model(images)
        probs = torch.softmax(outputs, dim=1)
        preds = torch.argmax(outputs, dim=1)
        all_preds.extend(preds.cpu().numpy().tolist())
        all_targets.extend(labels.cpu().numpy().tolist())
        all_probs.extend(probs.cpu().numpy().tolist())

all_preds = np.array(all_preds)
all_targets = np.array(all_targets)
all_probs = np.array(all_probs)
n_classes = len(class_names)

# Classification report
report = classification_report(all_targets, all_preds, target_names=class_names, output_dict=True, digits=4)
print("\nPer-class metrics:")
for c in class_names:
    r = report[c]
    print(f"  {c:40s}  prec={r['precision']:.4f}  recall={r['recall']:.4f}  f1={r['f1-score']:.4f}  support={r['support']}")

print(f"\nOverall:  acc={report['accuracy']:.4f}  macro_f1={report['macro avg']['f1-score']:.4f}  weighted_f1={report['weighted avg']['f1-score']:.4f}")

# Confusion matrix
cm = confusion_matrix(all_targets, all_preds)
print("\nConfusion matrix:")
cm_str = "     " + "".join(f"{c[:6]:>6}" for c in class_names)
print(cm_str)
for i, row in enumerate(cm):
    print(f"{class_names[i][:6]:>5} " + "".join(f"{v:6d}" for v in row))

# ROC-AUC per class
print("\nPer-class ROC-AUC:")
for i in range(n_classes):
    fpr, tpr, _ = roc_curve(all_targets == i, all_probs[:, i])
    roc_auc = auc(fpr, tpr)
    print(f"  {class_names[i]:40s}  AUC={roc_auc:.4f}")

# PR-AUC per class
print("\nPer-class PR-AUC:")
for i in range(n_classes):
    precision, recall, _ = precision_recall_curve(all_targets == i, all_probs[:, i])
    pr_auc = auc(recall, precision)
    print(f"  {class_names[i]:40s}  PR-AUC={pr_auc:.4f}")

# Misclassifications
misclassified = np.where(all_preds != all_targets)[0]
print(f"\nMisclassifications: {len(misclassified)}/{len(all_targets)} ({100*len(misclassified)/len(all_targets):.2f}%)")
if len(misclassified) > 0:
    print("  First 20 misclassifications:")
    for idx in misclassified[:20]:
        true_name = class_names[all_targets[idx]]
        pred_name = class_names[all_preds[idx]]
        prob = all_probs[idx][all_preds[idx]]
        print(f"    True={true_name:30s} Pred={pred_name:30s} conf={prob:.4f}")

# Hard examples (low-confidence correct predictions)
print("\nHard examples (lowest confidence correct predictions):")
correct = np.where(all_preds == all_targets)[0]
confidences = all_probs[correct, all_preds[correct]]
hardest = correct[np.argsort(confidences)[:20]]
for idx in hardest:
    name = class_names[all_targets[idx]]
    conf = all_probs[idx][all_targets[idx]]
    print(f"    {name:30s}  conf={conf:.4f}")

# Summary
summary = {
    "num_classes": n_classes,
    "classes": class_names,
    "test_samples": len(all_targets),
    "accuracy": float(report["accuracy"]),
    "macro_f1": float(report["macro avg"]["f1-score"]),
    "weighted_f1": float(report["weighted avg"]["f1-score"]),
    "per_class": {c: report[c] for c in class_names},
    "confusion_matrix": cm.tolist(),
    "misclassified_count": int(len(misclassified)),
    "misclassified_pct": round(100*len(misclassified)/len(all_targets), 2),
}

report_path = PROJECT_ROOT / "training" / "reports" / "model1_final_evaluation.json"
with open(report_path, "w") as f:
    json.dump(summary, f, indent=2)
print(f"\nReport saved: {report_path}")
