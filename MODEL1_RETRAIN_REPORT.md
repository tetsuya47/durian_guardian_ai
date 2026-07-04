# Model 1 Retrain Report

## Summary
- **Model**: EfficientNet-B0
- **Classes**: 11 (added `Healthy`)
- **Dataset**: `Ten_Classes_of_Durian_Leaf_Diseases/Ten_Classes_of_Durian_Leaf_Diseases`
- **Training set**: 4,131 images (after deduplication)
- **Validation set**: 576 images (after deduplication)
- **Test set**: 537 images (after deduplication)
- **Training epochs**: 50 (fresh start)
- **Device**: CPU

## Test Set Performance
| Metric | Value |
|---|---|
| Accuracy | 94.23% |
| Precision (weighted) | 94.67% |
| Recall (weighted) | 94.23% |
| F1-Score (weighted) | 94.21% |
| Top-5 Accuracy | 99.81% |
| ROC-AUC (weighted) | 99.36% |

## Per-Class Metrics
| Class | Precision | Recall | F1-Score | Support | AUC |
|---|---|---|---|---|---|
| anthracnose_disease | 1.00 | 0.97 | 0.98 | 63 | 0.9981 |
| canker_disease | 0.88 | 1.00 | 0.94 | 15 | 1.0000 |
| fruit_rot | 0.97 | 1.00 | 0.98 | 30 | 1.0000 |
| Healthy | 1.00 | 1.00 | 1.00 | 74 | 1.0000 |
| mealybug_infestation | 0.98 | 0.88 | 0.93 | 65 | 0.9927 |
| pink_disease | 0.79 | 0.82 | 0.81 | 33 | 0.9651 |
| sooty_mold | 0.94 | 0.81 | 0.87 | 62 | 0.9779 |
| stem_blight | 0.82 | 1.00 | 0.90 | 46 | 0.9962 |
| stem_cracking_gummosis | 0.89 | 1.00 | 0.94 | 58 | 0.9980 |
| thrips_disease | 1.00 | 0.90 | 0.95 | 29 | 0.9995 |
| yellow_leaf | 1.00 | 1.00 | 1.00 | 62 | 1.0000 |

## Model Info
- **Parameters**: 4,021,639 (all trainable)
- **Model size**: 15.5 MB
- **Input**: 224x224x3
- **Pretrained**: True (freeze_backbone=False)

## Exports
- **PyTorch** (`model.pt`): PASS
- **TorchScript** (`model.torchscript`): PASS
- **ONNX** (`model.onnx`): PASS

## Pipeline Verification
- `predict.py`: PASS (single image inference)
- `predict_folder.py`: PASS (batch inference, 74/74 Healthy)
- `gradcam.py`: PASS (heatmap + overlay)
- `scripts/validate_model.py`: PASS (all 3 formats + single prediction)
- `scripts/evaluate_model.py`: PASS (all reports generated)

## Artifacts Generated
- `training/reports/classification_report.json` + `.txt`
- `training/reports/confusion_matrix.csv` + `.png`
- `training/reports/roc_curve.png`
- `training/reports/precision_recall_curve.png`
- `training/reports/auc_per_class.json`
- `training/reports/model_info.json`
- `training/reports/class_distribution.png`
- `training/reports/prediction_examples.png`
- `training/reports/overlay.png` + `heatmap.png`
- `training/checkpoints/disease_detection/best_model.pt`
- `training/exports/disease_detection/model.pt`
- `training/exports/disease_detection/model.torchscript`
- `training/exports/disease_detection/model.onnx`
