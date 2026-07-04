# Model 2: Image Quality Assessment — Implementation Report

## Overview

Model 2 is a binary image quality classifier that determines whether an input image is **Good** (usable for disease detection) or **Bad** (degraded/poor quality). It is implemented as a fully independent module at `training_quality/` — completely separate from Model 1.

---

## Architecture

| Component | Detail |
|-----------|--------|
| **Task** | Binary classification (Good / Bad) |
| **Backbone** | MobileNetV3 Small (torchvision, pretrained on ImageNet) |
| **Classifier head** | Linear(256) → Hardswish → Dropout(0.3) → Linear(2) |
| **Input size** | 224×224×3 |
| **Parameters** | 1,075,234 (all trainable, ~4× smaller than EfficientNet-B0) |
| **Model size** | ~4.3 MB |

The classifier head replaces the original MobileNetV3 Small classifier head, adapting it from 1000 ImageNet classes to 2 quality classes.

---

## Dataset Generator

### Source
- All 5,244 images from the 11-class durian leaf dataset (`Ten_Classes_of_Durian_Leaf_Diseases/Ten_Classes_of_Durian_Leaf_Diseases/Train`, `Validation`, `Test`)
- Balanced stratified split: 80% Train, 10% Validation, 10% Test

### Good Class (5,244 images)
- Original source images, saved as-is.

### Bad Class (10,488 images)
- 2 degraded variants generated per source image using random degradation transforms:

| Degradation | Parameters | Probability |
|-------------|-----------|-------------|
| Gaussian Blur | kernel=3/5/7, σ=[0.5, 3.0] | 25% |
| Motion Blur | kernel=5/9/15 | 20% |
| Underexposure | γ=[1.5, 3.0] | 20% |
| Gaussian Noise | std=[0.02, 0.08] | 20% |
| JPEG Compression | quality=[5, 25] | 20% |
| Random Crop + Resize | scale=[0.4, 0.7] | 15% |
| Occlusion | 1–4 black boxes, size=5–20% | 15% |
| Low Resolution | scale=[0.15, 0.4] | 15% |

### Dataset Stats
| Split | Good | Bad | Total |
|-------|------|-----|-------|
| Train | 4,195 | 8,390 | 12,585 |
| Validation | 524 | 1,048 | 1,572 |
| Test | 525 | 1,050 | 1,575 |
| **Total** | **5,244** | **10,488** | **15,732** |

---

## Module Structure

```
training_quality/
├── __init__.py
├── train.py                          # Main training entry point
├── predict.py                        # Single-image quality prediction
├── predict_folder.py                 # Batch quality prediction
├── export.py                         # ONNX + TorchScript export
│
├── configs/
│   └── model2.yaml                   # Full model configuration
│
├── dataset/
│   ├── __init__.py
│   ├── quality_generator.py          # Dataset generator (Good/Bad)
│   └── quality_dataset.py            # Dataset class + transforms
│
├── models/
│   ├── __init__.py
│   └── quality_model.py              # ImageQualityModel (MobileNetV3 Small)
│
├── engine/
│   ├── __init__.py
│   ├── base_engine.py                # Abstract base engine
│   ├── trainer.py                    # Training loop
│   └── evaluator.py                  # Test evaluation with metrics
│
├── utils/
│   ├── __init__.py
│   ├── config_loader.py              # YAML config loader with env vars
│   └── logger.py                     # Logging factory
│
├── dataset_quality/                  # Generated dataset (ignored by git)
│   ├── Train/{Good,Bad}
│   ├── Validation/{Good,Bad}
│   └── Test/{Good,Bad}
│
├── checkpoints/                      # Training checkpoints
├── exports/                          # Exported models
├── logs/                             # Training logs
└── reports/                          # Evaluation reports
```

---

## Configuration (`configs/model2.yaml`)

Key settings:
- **Optimizer**: AdamW (lr=1e-3, weight_decay=0.01)
- **Scheduler**: CosineAnnealingLR (T_max=30) with 3-epoch warmup
- **Loss**: CrossEntropyLoss (2 classes)
- **Batch size**: 64
- **Epochs**: 30
- **Mixed precision**: FP16 (auto-disabled on CPU)
- **Gradient clipping**: 1.0

---

## Commands

### Generate dataset only
```bash
python training_quality/train.py --generate-only
```

### Train from scratch (generates dataset first)
```bash
python training_quality/train.py
```

### Train with custom config
```bash
python training_quality/train.py --config training_quality/configs/model2.yaml
```

### Predict single image
```bash
python training_quality/predict.py path/to/image.jpg
```

### Predict folder
```bash
python training_quality/predict_folder.py path/to/image/folder
```

### Export to ONNX + TorchScript
```bash
python training_quality/export.py
```

### Export with custom checkpoint
```bash
python training_quality/export.py --checkpoint training_quality/checkpoints/best_model.pt
```

---

## Expected Training Time & Performance

- **Dataset generation**: ~42 minutes (5,244 source → 15,732 quality images)
- **Training time** (CPU): ~15–20 minutes for 30 epochs at batch size 64
- **Expected test accuracy**: >95% (binary quality is a simpler task than 11-class disease classification)
- **Output formats**: PyTorch (.pt), TorchScript (.torchscript), ONNX (.onnx)

---

## Independence from Model 1

- All code lives under `training_quality/` — no changes to any `training/` files
- No shared state, no shared checkpoints, no shared configs
- Can be trained, evaluated, and deployed independently
- The dataset generator reads from the original dataset directory (read-only) and produces its own independent quality dataset

---

## Metrics (binary classification)

| Metric | Description |
|--------|-------------|
| Accuracy | Overall fraction of correct predictions |
| Precision | TP / (TP + FP) — how many "Bad" predictions are truly Bad |
| Recall | TP / (TP + FN) — how many actual Bad images are caught |
| F1-Score | Harmonic mean of precision and recall |
| ROC-AUC | Area under the ROC curve |
| Specificity | TN / (TN + FP) — how many Good images are correctly kept |
