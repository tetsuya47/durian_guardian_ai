# Project AI Snapshot

**Generated:** 2026-07-04 19:45 UTC+7
**Project:** Durian Guardian AI
**Root:** `./` (repository root)

---

## Architecture Overview

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Model 1   │     │   Model 2    │     │    Model 3       │     │    Model 4       │
│  Disease    │     │  Image       │     │  Risk Assessment │     │  Recommendation  │
│  Detection  │     │  Quality     │     │  (Tabular RF)    │     │  (Multi-task RF) │
│  (Efficient-│     │  (MobileNet) │     │  3 classes:      │     │  1 classifier +  │
│   Net-B0)   │     │  2 classes:  │     │  Low/Med/High    │     │  3 regressors    │
│  11 classes │     │  Good/Bad    │     │                  │     │  4 priorities    │
└──────┬──────┘     └──────┬───────┘     └────────┬─────────┘     └────────┬─────────┘
       │                   │                      │                        │
       │                   │                      │                        │
       ▼                   ▼                      ▼                        ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            MongoDB (durian_guardian_ai)                          │
│  10 collections: inspections(10K), trees(6K), farms(10), disease_history(2136), │
│  alerts(875), detection_results(10K), zones(100), diseases(15), users(50), comps│
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## Model 1 — Disease Detection

| Attribute | Value |
|-----------|-------|
| **Architecture** | EfficientNet-B0 |
| **Task** | 11-class image classification |
| **Classes** | Anthracnose, Canker, Fruit Rot, Healthy, Mealybug, Pink Disease, Sooty Mold, Stem Blight, Stem Cracking, Thrips |
| **Test Accuracy** | 0.9423 |
| **Checkpoints** | 52 `.pt` files (best + last + 50 epochs) |
| **Exports** | `.pt`, `.torchscript`, `.onnx` (with `.onnx.data`) |
| **Reports** | Classification report, confusion matrix, ROC curve, AUC per class, prediction examples |
| **Path** | `training/` |
| **Predict Script** | `training/predict.py` |
| **Audit** | 10/10 predictions correct (confidence 0.61–0.93) |

## Model 2 — Image Quality

| Attribute | Value |
|-----------|-------|
| **Architecture** | MobileNet V3 Small |
| **Task** | Binary classification: Good vs Bad quality |
| **Test Accuracy** | 0.8711 |
| **Test ROC-AUC** | 0.938 |
| **Checkpoints** | `best_model.pt`, `last_model.pt` (13.1 MB each) |
| **Exports** | `.pt`, `.torchscript`, `.onnx` |
| **Reports** | Evaluation report (JSON), classification report (TXT), model info |
| **Path** | `training_quality/` |
| **Predict Script** | `training_quality/predict.py` |
| **Audit** | 20/20 predictions valid (Good/Bad), 0 errors |

## Model 3 — Risk Assessment

| Attribute | Value |
|-----------|-------|
| **Architecture** | RandomForestClassifier (300 trees) |
| **Task** | 3-class risk classification: Low, Medium, High |
| **Features** | 13 (temperature, humidity, rainfall, tree_age, health_status, etc.) |
| **Exports** | `model.pkl` (41.8 MB), `preprocessor.pkl`, `label_encoder.pkl`, `feature_columns.json`, `metadata.json` |
| **Reports** | Evaluation results, feature importance, dataset summary, sample prediction |
| **Path** | `training/model3/` |
| **Predict Script** | `training/predict_model3.py` |
| **Audit** | 20/20 predictions valid (Low/Medium/High), 0 errors |

## Model 4 — Recommendation Engine

| Attribute | Value |
|-----------|-------|
| **Architecture** | Multi-task Random Forest: 1 classifier + 3 regressors |
| **Tasks** | Priority (4-class), Urgency (regression), Loss % (regression), Next Check Days (regression) |
| **Training Data** | 10,000 rows (6,500/1,500/2,000 split) |
| **Test Accuracy** | 1.0000 (perfect confusion matrix) |
| **Test R²** | Urgency=0.999, Loss=0.999, Check Days=1.000 |
| **Checkpoints** | 12 files (best + last for each sub-model) |
| **Exports** | `classifier.pkl`, 3 regressor `.pkl`, `preprocessor.pkl`, `feature_columns.json`, `label_encoder.pkl`, `metadata.json` (967 KB), `model_config.json`, `training_summary.json` |
| **Reports** | Evaluation report (884 KB), feature importance, sample prediction, training summary |
| **Rule Engine** | `training_recommendation/rules/rule_engine.py` (computes ground-truth labels) |
| **Path** | `training_recommendation/` |
| **Predict Script** | `training_recommendation/predict.py` |
| **Audit** | 20/20 predictions valid, 0 errors |

---

## Database

| Collection | Documents |
|------------|-----------|
| inspections | 10,000 |
| detection_results | 10,000 |
| trees | 6,000 |
| disease_history | 2,136 |
| alerts | 875 |
| zones | 100 |
| users | 50 |
| diseases | 15 |
| companies | 10 |
| farms | 10 |

**Connection:** MongoDB via `database/config.py` (localhost:27017, auth support)

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/audit_model4.py` | Audits MongoDB for Model 4 feature availability |
| `scripts/check_database.py` | Database inspection and diagnostics |
| `scripts/import_excel_to_mongodb.py` | Bulk data import |
| `scripts/preprocess.py` | Data preprocessing |
| `scripts/reset_database.py` | Database reset utility |
| `scripts/split_dataset.py` | Dataset split utility |

---

## Backup

All artifacts backed up to `AI_Backup/` (131 files across Model1–4, root reports, and database config).

---

## Reports

| File | Description |
|------|-------------|
| `MODEL1_RETRAIN_REPORT.md` | Model 1 retraining results |
| `MODEL2_COMPLETION_REPORT.md` | Model 2 training completion |
| `MODEL2_IMPLEMENTATION_REPORT.md` | Model 2 implementation details |
| `MODEL3_COMPLETION_REPORT.md` | Model 3 training completion |
| `MODEL3_DATABASE_AUDIT.md` | Model 3 database audit |
| `MODEL4_COMPLETION_REPORT.md` | Model 4 training completion |
| `MODEL4_PRETRAIN_REPORT.md` | Model 4 pre-training infrastructure |
| `PROJECT_AI_SNAPSHOT.md` | This file |

---

## Audit Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Project structure audit | ✅ Complete |
| 2 | Model 1 prediction test (10/10) | ✅ PASS |
| 3 | Model 2 prediction test (20/20) | ✅ PASS |
| 4 | Model 3 prediction test (20/20) | ✅ PASS |
| 5 | Model 4 prediction test (20/20) | ✅ PASS |
| 6 | End-to-end pipeline test | ✅ PASS |
| 7 | Artifact inventory (131 files) | ✅ Complete |
| 8 | Backup to AI_Backup/ (131 files) | ✅ Complete |
| 9 | Project snapshot | ✅ This file |
| 10 | Final audit report | 📝 Pending |
