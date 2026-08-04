# AI System Full Analysis — Durian Guardian AI

- **Date:** 2026-08-03
- **Role:** Chief AI Architect
- **Mode:** Read-only analysis. No source code modified, no models retrained, no commit, no push.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`

---

## 1. Executive Summary

The Durian Guardian AI system is a **multi-model agricultural AI platform** for durian disease diagnosis, risk prediction, and agronomist assistance. It consists of:

| Model | Task | Architecture | Status |
|---|---|---|---|
| **Model 1** | Disease Detection (11 classes) | EfficientNet-B0 | ✅ Trained + **integrated in backend** |
| **Model 2** | Image Quality (Good/Bad) | MobileNetV3-Small | ✅ Trained + exported, **NOT wired** (OpenCV heuristics used instead) |
| **Model 3** | Disease Risk (Low/Med/High) | RandomForest (300 trees) | ✅ Trained + **integrated** (risk endpoint + weather) |
| **Model 4** | Recommendation (priority + 3 regressors) | Multi-task Random Forest | ✅ Trained + exported, **NOT integrated** |
| **Model 4 (RAG)** | AI Agronomist chat | Ollama llama3.2 + ChromaDB | ⚠️ Framework stub only — backend chat is a keyword rule engine |

**Verdict: ⚠️ PARTIALLY READY.** The core deliverables (disease detection and risk prediction) are production-viable and run real inference. Image quality and recommendation engines are trained but disconnected from the API; the "AI Agronomist" is a mock/rule-based implementation. Runtime profiling and integration audits confirm the detection pipeline works but reveal architectural latency risks (synchronous CPU inference on the event loop, cold model load, unbounded image sizes).

---

## 2. Objective & Scope

**Objective:** Produce a full, evidence-based analysis of the complete AI system across the `backend/`, `training/`, `training_quality/`, `training_recommendation/`, `dga_mobile/`, `frontend/`, `database/`, `dataset/`, and `docs/` workspaces, covering models, integration, data pipelines, deployment, performance, security, and gaps.

**Scope (included):** all 4 models + RAG plan, AI backend services/APIs, mobile + web clients, weather integration, recommendation path, datasets, training infra, evaluation, runtime performance, security.

**Constraints:** read-only. Nothing modified, retrained, committed, or deployed.

---

## 3. System Architecture Overview

```
                    ┌────────────────────────────────────────────────────┐
                    │                 Clients                              │
                    │  dga_mobile (Flutter)      frontend (React)         │
                    └──────────────┬──────────────────────┬──────────────┘
                                   │ REST /api/v1         │
                    ┌──────────────▼──────────────────────▼──────────────┐
                    │              FastAPI Backend (backend/)             │
                    │  routers: ai, weather, chat, alerts, history, ...   │
                    │  services: AIService, RiskPredictionService,        │
                    │            WeatherService, ChatService, ...         │
                    │  ai/: DiseasePredictor (M1), Model3Predictor (M3)   │
                    │  utils/: OpenWeatherClient                           │
                    └──────┬──────────────┬───────────────────┬───────────┘
                           │              │                   │
                 MongoDB (motor)    OpenWeatherMap API    /uploads static
                 (weather_cache,    (httpx, async)        (detected images)
                  inspections,
                  detection_results,
                  disease_history,
                  alerts, trees...)
                           │
              ┌────────────▼────────────┐
              │  Training (offline)      │
              │  training/       M1, M3  │
              │  training_quality/  M2   │
              │  training_recommendation/ M4 │
              └─────────────────────────┘
```

**Key architectural facts**
- Backend is FastAPI (uvicorn), MongoDB via motor, HTTP via httpx. Auth = JWT (HS256) + role checker.
- Model artifacts are **not** inside `backend/`; predictors resolve paths relative to the project root (`training/checkpoints/...`, `training/model3/exports/`).
- All AI predictors are **thread-safe singletons** (loaded once, reused).
- Client apps consume only the HTTP API — no on-device ML.

---

## 4. Model 1 — Disease Detection (EfficientNet-B0)

**Status: ✅ TRAINED + INTEGRATED (production-viable)**

### 4.1 Architecture & Training
- Architecture: `torchvision.efficientnet_b0` (ImageNet weights) with classifier head replaced `Linear(1280 → 11)`. (`backend/app/ai/predictor.py:90-97`, `training/models/registry.py`)
- Input: RGB 224×224, ImageNet normalization `mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]`. No augmentation at inference (correct).
- Optimizer AdamW lr 1e-4, wd 0.01; scheduler CosineAnnealingLR (T_max 50) + 5-epoch warmup; loss CrossEntropy + label smoothing 0.1; mixed precision fp16; batch 32; 50 epochs; EarlyStopping (patience 15, monitor val_accuracy). (`training/configs/model1.yaml`)
- Parameters: **4,021,639**; state-dict export ≈ 15.5–16.4 MB; full checkpoint ≈ 48.7 MB. (`training/reports/model_info.json`)
- Best epoch 49, best val accuracy 0.8871.

### 4.2 Classes (11)
`anthracnose_disease, canker_disease, fruit_rot, Healthy, mealybug_infestation, pink_disease, sooty_mold, stem_blight, stem_cracking_ gummosis, thrips_disease, yellow_leaf` — with Vietnamese display names (`DISEASE_NAME_VI`) and a static severity map. ⚠️ **Label typo:** `stem_cracking_ gummosis` (space in class name) is baked consistently into every artifact.

### 4.3 Metrics (test, 537 samples)
| Metric | Value |
|---|---|
| Accuracy | **0.9423** |
| Macro F1 | 0.9362 |
| Weighted F1 | 0.9421 |
| Weakest class | pink_disease (F1 0.806) |
| Strongest | Healthy / yellow_leaf (F1 1.0) |

Per-class precision/recall/F1 in `training/reports/classification_report.json`. ROC AUC per class in `training/reports/auc_per_class.json`.

### 4.4 Artifacts & Parity
- `training/checkpoints/disease_detection/best_model.pt` + `last_model.pt` (identical tensors, verified).
- `training/exports/disease_detection/model.pt` (identical to best), `model.onnx` (+`.data`, opset 17, dynamic batch; logits match torch to 1.13e-6), `model.torchscript`.
- Backend loads `best_model.pt` with `load_state_dict(strict=True)`.

### 4.5 Inference logic
- Returns `disease`, `disease_vi`, `confidence` (top-1 softmax), `severity` (none/low/medium/high), `top5`.
- Severity = static map + **heuristic escalation**: non-Healthy predictions with confidence ≥ 0.85 bump low/medium → next level. Not learned, not validated. (`predictor.py:212-216`)

### 4.6 Risks
- Training image dataset **absent from repo** (`Ten_Classes_of_Durian_Leaf_Diseases/` not present; only a CSV exists per prior audit) → evaluation not locally reproducible.
- Severity mapping + confidence threshold (0.85) empirically unvalidated; a positive canker sample scored only 0.477 confidence in live tests.
- Label typo requires display-layer handling or full retrain to fix.

---

## 5. Model 2 — Image Quality (MobileNetV3-Small)

**Status: ✅ TRAINED + EXPORTED — ❌ NOT INTEGRATED (replaced by OpenCV heuristics)**

### 5.1 Architecture & Training
- Architecture: `mobilenet_v3_small`, 2 classes (Good/Bad), pretrained, dropout 0.3, **1,075,234 params**, 4.15 MB. (`training_quality/configs/model2.yaml`, `training_quality/reports/model_info.json`)
- AdamW lr 1e-3, 30 epochs, batch 64, fp16, CosineAnnealingLR + 3-epoch warmup, deterministic seed 42.
- **Synthetic dataset:** good durian images degraded via `quality_generator.py` (gaussian/motion blur, underexposure, overexposure, gaussian noise, JPEG compression, random crop, occlusion, low-resolution), `bad_samples_per_good: 2`, split 80/10/10. The `dataset_quality/` folder is **not in the repo**.

### 5.2 Metrics (test)
| Metric | Value |
|---|---|
| Accuracy | **0.8711** |
| Precision | 0.899 |
| Recall | 0.9086 |
| F1 | 0.9038 |
| ROC AUC | 0.9381 |

⚠️ **Anomaly:** `training_quality/reports/evaluation_report.json` shows `test_loss: 0.4563` yet `targets` array is all zeros and `test_accuracy` in model_info differs from the evaluation flow — the eval report appears stale/inconsistent with the final model_info.

### 5.3 Artifacts
- `training_quality/checkpoints/{best,last}_model.pt`, `training_quality/exports/model.{pt,torchscript,onnx,onnx.data}`.

### 5.4 Integration status — CRITICAL FINDING
`backend/app/ai/service.py:53-165` `_analyze_quality()` does **NOT** load Model 2. It uses **classical OpenCV rules**:
- Blur: Laplacian variance < 1.0
- Brightness: mean < 5 (dark) or > 252 (too bright)
- Plant foliage masks: HSV green (28–90°), yellow (12–28°), copper (5–12°); foliage_ratio thresholds
- Rejection: skin/blue/red ratios, low saturation
- `passed = not blur AND brightness=="good" AND leaf_detected`

The trained MobileNetV3 quality model is fully disconnected from the running system. ⚠️ Also: `training/configs/model2.yaml` (efficientnet_b0 regression, MSELoss, 30 epochs, freeze_backbone) **contradicts** the actual `training_quality/` implementation (mobilenet_v3_small classification) — two divergent Model-2 configs exist.

---

## 6. Model 3 — Disease Risk Prediction (Random Forest)

**Status: ✅ TRAINED + INTEGRATED (risk endpoint + weather service)**

### 6.1 Architecture & Training
- Model: `sklearn RandomForestClassifier`, 300 estimators, 5-fold CV config, 14 features. (`training/configs/model3.yaml`)
- Labels (3 classes, Vietnamese): **Trung bình (4028), Cao (3517), Thấp (2455)** over 10,000 MongoDB-derived samples. Trained **2026-07-27**.
- Feature importance (top): `health_status` (0.233), `humidity` (0.161), `predicted_disease` (0.152), `rainfall` (0.093), `temperature` (0.088). (`training/model3/reports/feature_importance.json`)

### 6.2 Metrics (test, 2,000 samples)
| Metric | Value |
|---|---|
| Accuracy | **0.9410** |
| Precision | 0.941 |
| Recall | 0.941 |
| F1 | 0.9408 |
| ROC AUC | **0.9901** |

### 6.3 Artifacts
`training/model3/exports/`: `model.pkl`, `preprocessor.pkl` (ordinal encoder + scaler + label encoder), `feature_columns.json` (14 cols), `metadata.json`.

### 6.4 Backend integration
- `backend/app/ai/predictor_model3.py` — thread-safe `Model3Predictor` singleton; fills missing features with safe defaults; returns `risk_level`, `risk_score` (max-class prob), `probabilities`, `top_factors` (top-5 importances). Fallback returns `risk_level="Nguy cơ", score=0.5` on error.
- `backend/app/services/risk_prediction_service.py` — assembles the 14 features from **live weather** (or cache), tree metadata, latest detection results, season (Mưa May–Oct / Khô), and detection history; runs inference; adds `fungal_disease_risk`, `weather_used`, `tree_info`.
- Exposed via `POST /api/v1/ai/risk-prediction`.
- Also consumed by `WeatherService._analyze_durian_risk()` for the `fungal_disease_risk` + `agricultural_advice` in weather responses.

### 6.5 ⚠️ Integration inconsistency (label mapping)
The service layer maps risk levels via:
```python
fungal_risk_map = {"Khỏe mạnh": "LOW", "Nguy cơ": "MEDIUM", "Bệnh nhẹ": "MEDIUM", "Bệnh nặng": "HIGH"}
```
But the actual trained label encoder emits **Cao / Thấp / Trung bình**. None of those keys match the map, so `.get()` falls through to the default **"MEDIUM"** every time. The mapping keys are stale (they match the predictor docstring, which also lists the wrong labels). **Result: `fungal_disease_risk` is effectively always MEDIUM.** Requires correction (map Cao→HIGH, Trung bình→MEDIUM, Thấp→LOW).

---

## 7. Model 4 — Recommendation Engine & AI Agronomist

**Status: ✅ TRAINED (recommendation) — ❌ NOT INTEGRATED; RAG/LLM = ⚠️ STUB**

### 7.1 Recommendation Engine (multi-task Random Forest)
- **Task:** `priority_code` classification (4 classes: Thấp/Trung bình/Cao/Rất cao) + 3 regressions: `urgency_score` [0,1], `estimated_loss_pct` [0,90], `next_check_days` [1,30]. (`training_recommendation/configs/model4.yaml`)
- **Features: 22** (7 categorical: health_status, predicted_disease, detection_prediction, alert_type, alert_priority, season, risk_level; 15 numerical: temperature, humidity, rainfall, tree_age, area_hectare, confidence, detection_confidence, disease_history_count, last_treatment_days, alert_count, days_since_last_inspection, historical_disease_count, historical_disease_frequency, density_per_hectare, priority_score). Note: **2 features (risk_score, risk_level) are Model 3 outputs** → Model 4 depends on Model 3 at inference.
- Training: RF Classifier (300 trees, balanced) + 3 RF Regressors (200 trees, depth 15); OrdinalEncoder + StandardScaler; 80/15/5 → train 6500 / val 1500 / test 2000. Train time 2.66 s.
- **Metrics (test):** classification **accuracy 1.0, F1 1.0** (perfect — labels are rule-generated, so this is expected, not impressive).
- **Labels are deterministic** from `training_recommendation/rules/rule_engine.py` (`PRIORITY_ACTIONS`, version 1.0.0, thresholds critical 0.70 / high 0.40 / medium 0.15). The dataset builder labels rows by rules, so the "model" largely recovers the rule labels.
- Artifacts: `exports/` classifier.pkl, regressor_{urgency_score,estimated_loss_pct,next_check_days}.pkl, preprocessor.pkl, label_encoder.pkl, feature_columns.json, metadata.json + checkpoints.
- **Dataset `recommendation_dataset.csv` is NOT in the repo** (built from MongoDB at train time).
- **Backend integration: NONE.** No endpoint serves this engine. `reports/model4/feature_list.json` + `database_audit.json` document the intended feature sources (inspections 10,000; detection_results 10,000 with `model:"YOLOv11"` seeded data; disease_history 2,136; alerts 875).

### 7.2 AI Agronomist (RAG + LLM) — PLANNED
- `training/models/llm/rag_pipeline.py` implements a framework: Ollama `nomic-embed-text` embeddings, ChromaDB vector store, Ollama `llama3.2` ChatOllama, prompt templates, and a knowledge base (`training/models/llm/knowledge/*.md`: durian_diseases, treatment_guide, pest_control, farm_management).
- **Never invoked anywhere.** `backend/app/services/chat_service.py` `OllamaService` is a **mock** (`_mock_chat()` canned text), and `ChatService.ask()` is a **hard-coded keyword intent router** (user counts, IoT stats, farm info, phytophthora, NPK, anthracnose, mealybug) with a hard-coded fallback; `self.ollama.chat()` is never even called.
- Dependencies (`langchain-ollama`, `chromadb`, `langchain-chroma`, `langchain-community`) are **not in `backend/requirements.txt`**.

---

## 8. Dataset Analysis

| Dataset | Location | Size | Present in repo? |
|---|---|---|---|
| Enterprise dataset (Excel) | `dataset/DGA_Enterprise_Dataset.xlsx` | 1,084,892 B | ✅ |
| Seed dataset (CSV) | `dataset/DGA_seed_dataset_10000.csv` | 2,244,460 B | ✅ |
| Model 1 images (11-class leaves) | `Ten_Classes_of_Durian_Leaf_Diseases/` | — | ❌ **absent** |
| Model 2 synthetic quality images | `training_quality/dataset_quality/` | — | ❌ **absent** (generator code exists) |
| Model 3 training dataset | MongoDB `inspections` (10,000) | — | ❌ (DB-derived; CSV not committed) |
| Model 4 dataset | `training_recommendation/datasets/recommendation_dataset.csv` | — | ❌ **absent** |

**MongoDB data landscape** (from `reports/model4/database_audit.json`): companies 10, farms 10, zones 100, trees 6,000, users 50, diseases 15, inspections 10,000, detection_results 10,000, disease_history 2,136, alerts 875.

⚠️ **Reproducibility risk:** every training dataset except the two seed files lives outside the repo. Model 1/2/4 artifacts cannot be regenerated or re-evaluated locally without their data.

---

## 9. Data Pipeline

- **Model 3/4:** `database/dataset_builder/mongodb_reader.py` + `training/datasets/build_model3_dataset.py` pull inspections (temp/humidity/rainfall/health/disease/confidence), tree metadata (age/variety), farm (area), detection results, disease history, and alerts → 14 (M3) / 22 (M4) features. Labels for M4 come from the rule engine.
- **Model 1:** folder-split image classification loader (`ImageClassificationDataset`) with corruption detection/removal and class-distribution reporting. Augmentation pipeline: flips, rotation ±30°, ColorJitter, RandomAffine, RandomPerspective, GaussianBlur, RandAugment (n=2, m=9).
- **Model 2:** synthetic degradation generator (see §5.1).
- **Live runtime data flow:** `/ai/detect` → validation → OpenCV quality gate → M1 inference → write inspection (PROCESSING→COMPLETED) → write detection_result → update tree (health_status, risk_score, last_inspection) → append disease_history → auto-alert if severity high.

---

## 10. Training Infrastructure & Framework

- `training/` is a full PyTorch framework: `engine/{trainer,tester,validator,inference,export_manager,base_engine}`, `models/registry.py` (ModelFactory), `optimizers`, `schedulers`, `losses`, `metrics`, `callbacks` (ModelCheckpoint, EarlyStopping, CSVLogger, TensorBoard, ReduceLROnPlateau, GradientNormMonitor), `datasets/{loaders,augmentations,preprocess,samplers}`, `utils` (config_loader, seed, logger).
- Config-driven via YAML (`training/configs/{model1,model2,model3,model4}.yaml`); unified entry point `training/train.py`.
- `training_quality/` and `training_recommendation/` are independent, smaller pipelines (own train/export/evaluate; sklearn for tabular).
- Environment: Python 3.13.12, torch 2.11.0+cpu, torchvision 0.26.0+cpu (CPU-only; no CUDA observed).
- Extra tooling: `training/gradcam.py`, `training/predict_folder.py`, `training/scripts/*` (export_onnx, evaluate_model, validate_model, dataset_cleaner, dataset_audit, forensic_check_excel, final_report...).

---

## 11. Evaluation & Model Metrics (summary)

| Model | Task | Key metric | Test set | Notes |
|---|---|---|---|---|
| M1 | 11-class disease | Acc 0.9423 / F1 0.942 | 537 | pink_disease weakest |
| M2 | Quality Good/Bad | Acc 0.8711 / AUC 0.9381 | synthetic | eval report anomaly |
| M3 | Risk 3-class | Acc 0.941 / AUC 0.9901 | 2,000 | strong |
| M4 | Priority 4-class | Acc 1.0 / F1 1.0 | 2,000 | labels are rule-generated |

Backend test suite includes `backend/tests/test_model3_integration.py` (Model 3 is the only AI model covered by an automated integration test).

---

## 12. AI Backend Services

| Service | File | Responsibility |
|---|---|---|
| `AIService` | `backend/app/ai/service.py` | Image validation, OpenCV quality gate, M1 inference, DB persistence (inspection, detection_result, tree update, disease_history, alert) |
| `OllamaService` | same | **Mock** chat response |
| `DiseasePredictor` | `backend/app/ai/predictor.py` | M1 singleton inference |
| `Model3Predictor` | `backend/app/ai/predictor_model3.py` | M3 singleton inference |
| `RiskPredictionService` | `backend/app/services/risk_prediction_service.py` | Feature assembly → M3 |
| `WeatherService` | `backend/app/services/weather_service.py` | Cache-aside weather + M3 risk analysis |
| `ChatService` | `backend/app/services/chat_service.py` | Keyword intent router + role-based farm-scope guard |
| `DetectionResultService` | `backend/app/services/detection_result_service.py` | CRUD over detection_results |

Notable quality: `AIService.detect_disease()` has graceful fallback tree selection, phased DB writes with FAILED rollback marking, and high-severity auto-alerting.

---

## 13. AI API Surface

| Method | Path | Description | Real AI? |
|---|---|---|---|
| POST | `/api/v1/ai/detect` | Upload image + tree_id → M1 detection | ✅ M1 |
| POST | `/api/v1/ai/image-quality` | Upload → quality check | ⚠️ OpenCV, not M2 |
| POST | `/api/v1/ai/risk-prediction` | tree_id + coords → M3 risk | ✅ M3 |
| GET | `/api/v1/weather/current` | Weather + fungal risk | ✅ M3 (weather) |
| POST | `/api/v1/chat` | Ask agronomist | ❌ rule/mock |
| GET | `/api/v1/detection-results`, `/disease-history`, `/alerts` | AI-output CRUD/history | — |

All AI endpoints require JWT auth + role check; `/ai/*` uses `allow_all` (any authenticated role).

---

## 14. AI Mobile Integration (Flutter — `dga_mobile/`)

- Consumes `/ai/detect` (`ApiEndpoints.aiDetect`) and `/ai/image-quality`; disease detection UI (`features/disease_detection/`) includes image selection/editor, analysis loading, AI result card, disease details, quick recommendations.
- Weather card consumes `/weather/current` and renders `fungal_disease_risk` (HIGH/MEDIUM/LOW) + `agricultural_advice`.
- Recommendation page (`features/recommendation/`) calls `POST /chat` with a **hard-coded question and dummy tree_id** (`60d5ec49f1b2c56b402c56b5`), then applies **client-side fallback heuristics** (disease name → canned Mancozeb/Metalaxyl advice, risk level, care schedules, material table). The `aiNotes` shown to users come from the mock chat answer.
- History/compare pages render `riskScore` from persisted disease logs.
- **Not used on mobile:** `/ai/risk-prediction`, M3 endpoint (dashboard risk shown is mock/static: `mock_dashboard_datasource.dart`, `mock_dashboard_repository.dart`).

---

## 15. AI Frontend Integration (React — `frontend/`)

- `WeatherCard.tsx` consumes `/weather/current` (temp, humidity, wind, `fungal_disease_risk`, `agricultural_advice`).
- Pages: `Sidebar.tsx` links `AiChatbot` (`/ai-chatbot`), `AiAlerts` (`/ai-alerts`); `Settings.tsx` offers OpenWeatherMap/AccuWeather provider options.
- IoT pages reference weather stations (device catalog, orders, setup guide) — not AI inference.

---

## 16. Weather Integration

**Well-engineered, real integration.**

- `OpenWeatherClient` (`backend/app/utils/openweather_client.py`): async httpx, timeout 8 s, 1 retry on 5xx/429 with backoff, immediate 401 failure, `lang=vi`, metric units. Raises `OpenWeatherClientError`.
- `WeatherRepository` (`weather_cache` collection): flattened DGA schema (never raw payload), cache key `weather_{lat:.2f}_{lon:.2f}`, TTL 15 min, upsert + expired cleanup.
- `WeatherService`: cache-aside (fresh → return cached; miss → API → upsert; API failure → stale cache or fallback dict), farm-coordinate resolution (`gps_lat/gps_lng` or `latitude/longitude`), optional normalized forecast (8 entries), then `_analyze_durian_risk()` runs **Model 3** with a fixed sample feature vector and maps result → LOW/MEDIUM/HIGH + advice (see §6.5 label-mapping bug). Rule-based fallback (humidity/temp thresholds) if M3 unavailable.
- `OPENWEATHER_API_KEY` is **set** in `backend/.env` (32-char). Default config value is empty.
- Default coords: Buôn Ma Thuột 12.6667, 108.0500.

---

## 17. Recommendation Integration

- **Trained Model 4 (multi-task RF) is not served by any backend endpoint.** No import of `training_recommendation` anywhere in `backend/`.
- Actual recommendation paths today:
  1. `AIService._build_recommendation()` — one static template string (Healthy vs "theo dõi & xử lý").
  2. Mobile `recommendation_remote_datasource.dart` — `/chat` mock + client-side hardcoded Mancozeb/Metalaxyl advice, hardcoded weather (31°C/80%/2mm/10m/s), risk from disease-name string matching.
  3. IoT endpoint (`/api/v1/iot/.../recommendations`) — static device recommendations (quantity/price), unrelated to ML.
- The `priority_code / urgency_score / estimated_loss_pct / next_check_days` predictions from the trained engine are unused.

---

## 18. Image Quality Handling

Two parallel, conflicting implementations:
1. **Trained M2 (MobileNetV3, acc 0.8711)** — exported, unused.
2. **OpenCV heuristic gate** (`_analyze_quality`) — actually enforced pre-inference: rejects dark (<5 mean brightness) → 400 "Ảnh quá tối", blur (Laplacian <1.0) → 400 "Ảnh quá mờ", non-leaf (foliage/skin/blue/red masks) → 400 "không phải lá/cây sầu riêng".

The heuristic gate is the active layer and behaves deterministically without a model dependency, but it bypasses the trained model entirely and uses hardcoded HSV thresholds.

---

## 19. Alert & Notification Pipeline

- On `severity == "high"` from M1: auto-creates alert (`ALT{code}`), `alert_type="Bệnh nghiêm trọng"`, priority "Cao", links inspection + detection_result + disease_history, stores recommendation text.
- Alerts are exposed via `/api/v1/alerts` CRUD; notifications service (`notification_service.py`, `notification_repository.py`) exists for the wider notification surface. Tree `risk_score` updated from severity map (none 10 / low 40 / medium 70 / high 90).

---

## 20. Model Artifacts & Deployment

| Artifact | Path | Size/Format | Used by backend |
|---|---|---|---|
| M1 checkpoint | `training/checkpoints/disease_detection/best_model.pt` | 48.7 MB `.pt` | ✅ |
| M1 exports | `training/exports/disease_detection/{model.pt,model.onnx(+data),model.torchscript}` | ~16 MB | ❌ (`.pt` used, not ONNX) |
| M2 | `training_quality/{checkpoints,exports}/` | 4.15 MB model | ❌ |
| M3 | `training/model3/exports/{model.pkl,preprocessor.pkl,feature_columns.json,label_encoder.pkl,metadata.json}` | small | ✅ (joblib) |
| M4 | `training_recommendation/{exports,checkpoints}/` | small | ❌ |
| `model1_deployment/` | README only | — | — (no deployment package/scripts) |

**Deployment gaps**
- No Dockerfile / docker-compose for the AI stack; `model1_deployment/` contains only a README.
- No model version registry — backend loads a fixed path; checkpoint fingerprint only in `training/reports/model_info.json`.
- `backend/requirements.txt` is **missing `opencv-python`** and an explicit `numpy`, but `AIService._analyze_quality` imports `cv2`/`numpy` directly → fresh installs fail at runtime for `/ai/detect`.
- ONNX exports exist but backend still uses raw PyTorch (no onnxruntime serving path).

---

## 21. Performance & Runtime Profiling (evidence from `docs/reports/AI_RUNTIME_PROFILING_REPORT.md`)

**Verdict from profiling:** the model is fast; the bottleneck is architectural.

| Stage | Measured |
|---|---|
| Cold `DiseasePredictor()` init (torch.load) | 158–210 ms, **blocks event loop on first request** |
| Warm M1 `predict()` 512×512 | ~39 ms; 1024×1024 ~41 ms |
| M1 forward (CPU) | ~50–90 ms (input-independent, fixed 224×224) |
| Decode+preprocess 4000×3000 | ~146 ms; 8000×6000 **~464 ms + ~183 MB transient RSS** |
| `/ai/detect` warm small | 41 ms wall (reports only `processing_time_ms=27`) |
| `/ai/detect` cold (first ever) | 643–673 ms |
| Concurrent `/health` blocked during infer | **193–397 ms** |
| CPU utilization | **751%** (8 threads pinned, oversubscription) |

**Root causes:** (1) synchronous model load + CPU inference inside async handlers on the single event loop; (2) unbounded upload resolution; (3) 8-thread oversubscription; (4) reported `processing_time_ms` measures only `predict()`, not end-to-end.

**Recommended fixes (analysis only, not applied):** preload model at startup (lifespan), offload inference via `asyncio.to_thread`, enforce upload size/dimension caps, cap torch threads, report true end-to-end latency, reuse client connections.

---

## 22. Monitoring & Observability

- Structured logging (`app/core/logging.py`, per-service loggers, AI inference latency logged).
- TensorBoard logs + CSVLogger produced during training (`training/tensorboard/model1`, `training/logs/`).
- No metrics/health probes beyond `GET /health`; no OpenTelemetry/prometheus; no model drift/performance monitoring in production.
- No alerting on model failures (exception → 400 fallback hides real errors).

---

## 23. Security & Governance

**Strengths**
- JWT auth (HS256, refresh token), role-based access control; `/chat` enforces farm-scope ownership rules for non-admins; password hashing via bcrypt.
- Input validation on `/ai/detect` (extension allowlist + `Image.verify()` + corrupted-file handling → 400). Better than prior audit state.
- Weather payloads flattened — raw OpenWeather responses never stored/exposed.
- Upload dir mounted read-only as static; files saved with UUID names.

**Weaknesses**
- Hardcoded default JWT secret `"change-this-to-a-secure-random-string"` in `config.py` (only guarded in production ENV).
- Hardcoded fallback ObjectId / default tree inserted into DB if none exists (`service.py:180-205`).
- Model path resolution relative to project root is deployment-fragile.
- `backend/.env` contains a live OpenWeather API key (32 chars) — ensure `.env` is gitignored (`.gitignore` present) and not committed.
- AI endpoints use `allow_all` (any role) — acceptable but coarse.
- No model version pinning or artifact checksum verification at load.

---

## 24. Integration Matrix

| Component | M1 Detect | M2 Quality | M3 Risk | M4 Recommend | RAG/LLM Chat | Weather |
|---|---|---|---|---|---|---|
| Backend API | ✅ `/ai/detect` | ⚠️ OpenCV rule | ✅ `/ai/risk-prediction` | ❌ none | ❌ rule/mock | ✅ `/weather/current` |
| Mobile app | ✅ | ✅ (endpoint) | ❌ not called | ⚠️ `/chat`+heuristics | ⚠️ via `/chat` | ✅ |
| Web app | ⚠️ via detection-results UI | — | ⚠️ weather risk only | — | ✅ `/ai-chatbot` (rule) | ✅ |
| Tests | ⚠️ manual | — | ✅ `test_model3_integration.py` | ❌ | ❌ | ✅ repo tests |
| Data write-through | ✅ inspections/detection_results/disease_history/alerts | — | ✅ weather_cache | ❌ | — | ✅ weather_cache |

---

## 25. Gaps, Risks & Anomalies

**Critical**
1. **M3 label-mapping bug** — trained classes (Cao/Thấp/Trung bình) don't match service maps (Khỏe mạnh/Nguy cơ/Bệnh nhẹ/Bệnh nặng) → `fungal_disease_risk` always falls to MEDIUM.
2. **M2 and M4 trained but disconnected** — quality gate is OpenCV heuristics; recommendation engine has zero endpoints.
3. **Chat is a mock** — "AI Agronomist" is a hard-coded keyword router; `OllamaService` never called; RAG pipeline is an unused stub.
4. **Event-loop blocking + unbounded uploads** — sync inference + cold model load in async handlers; documented 193–397 ms whole-API freezes.
5. **`opencv-python` missing from `backend/requirements.txt`** despite runtime import.

**High**
6. Training datasets (M1 images, M2 synthetic, M4 CSV) **absent from repo** → no reproducibility.
7. Two divergent Model-2 configs (`training/configs/model2.yaml` vs `training_quality/configs/model2.yaml`).
8. Stale/conflicting eval artifacts (`training_quality/reports/evaluation_report.json` targets all zero).
9. Seed `detection_results` tagged `model:"YOLOv11"` while the live model is EfficientNet-B0 — historical data/model naming drift.
10. No deployment packaging (Docker/CI) for the AI stack; `model1_deployment/` is README-only.

**Medium**
11. Label typo `stem_cracking_ gummosis` baked into all artifacts.
12. Severity mapping + 0.85 confidence escalation unvalidated.
13. Reported `processing_time_ms` understates real latency (only `predict()`).
14. Static dashboard risk on mobile (`mock_dashboard_datasource.dart`).
15. Mobile recommendation hardcodes dummy `tree_id` and client-side fallback content.
16. Hardcoded default JWT secret; coarse `allow_all` on AI endpoints.

---

## 26. Recommendations & Action Items

**Immediate (correctness)**
1. Fix M3 label mapping in `risk_prediction_service.py` + `weather_service.py`: Cao→HIGH, Trung bình→MEDIUM, Thấp→LOW (align with trained `label_encoder` classes).
2. Add `opencv-python` (and explicit `numpy`) to `backend/requirements.txt`.
3. Wire trained M2 (`training_quality/exports/model.onnx`) into `/ai/image-quality` (or formally deprecate the trained model and document the heuristic gate as the standard).
4. Offload inference + preload model at startup (lifespan) per profiling report; enforce upload size/dimension caps.
5. Add an endpoint serving the trained M4 recommendation engine (classifier + 3 regressors) using real features from M3 + DB.

**Short term**
6. Remove the stale M2 config contradiction (`training/configs/model2.yaml` vs `training_quality/`).
7. Regenerate/commit M2 & M4 eval reports (resolve the all-zero targets anomaly).
8. Resolve the `disease` vs `disease_name`/`prediction` field contract between `/ai/detect`, detection-results CRUD, and clients.
9. Version/pin model artifacts (checksum + `model_info.json` fingerprint) and decide ONNX serving path.

**Medium term**
10. Replace chat mock with real RAG (`rag_pipeline.py` + knowledge base) or keep rule engine but expose it explicitly as rule-based (not "AI").
11. Add model monitoring (drift, latency, error rate) and structured metrics.
12. Containerize backend + model serving; document `model1_deployment/`.
13. Reconcile `risk_score` semantics across M1 (severity map) vs M3 (model) vs M4 (priority) — currently three different "risk" notions feed different UIs.

---

## 27. Roadmap

1. **Phase 1 — Correction sprint:** M3 mapping fix, requirements fix, startup preload, upload caps. *(Small, high impact.)*
2. **Phase 2 — Wire trained assets:** M2 into image-quality endpoint; M4 recommendation endpoint; regenerate stale reports.
3. **Phase 3 — Agronomist real RAG:** integrate `rag_pipeline.py` with Ollama + ChromaDB (add deps), or clearly scope a rule-based assistant.
4. **Phase 4 — Production hardening:** Docker/CI, model registry + versioning, monitoring/alerting, calibrated confidence thresholds, reproducible datasets (checksummed manifest).

---

## 28. Final Rating Table & Verdict

| # | Component | Rating | Score | Evidence |
|---|---|---|---|---|
| 1 | **Model 1 — Disease Detection** | ✅ READY | 9/10 | Acc 0.9423; checkpoints/exports verified; integrated; gaps: no dataset in repo, severity heuristic |
| 2 | **Model 2 — Image Quality** | ❌ NOT DEPLOYED | 3/10 | Trained (acc 0.8711) but not wired; heuristic gate active; stale eval report |
| 3 | **Model 3 — Risk Prediction** | ⚠️ PARTIALLY READY | 6/10 | Acc 0.941/AUC 0.9901; integrated; **label-mapping bug** forces MEDIUM; fallback masks errors |
| 4 | **Model 4 — Recommendation** | ⚠️ PARTIALLY READY | 4/10 | Trained (acc 1.0 on rule labels) but **no backend integration**; dataset absent |
| 5 | **AI Backend** | ⚠️ PARTIALLY READY | 6/10 | Solid architecture, singletons, DB write-through; event-loop blocking, missing deps, mock chat |
| 6 | **AI Mobile** | ⚠️ PARTIALLY READY | 6/10 | Real M1 + weather; recommendation via mock chat; static dashboard risk; hardcoded tree_id |
| 7 | **AI Pipeline** | ⚠️ PARTIALLY READY | 5/10 | Clean training framework; datasets not reproducible; pipeline (quality→detect→persist→alert) works |
| 8 | **Recommendation** | ❌ NOT DEPLOYED | 3/10 | Engine trained & exported; zero endpoints; mobile uses client-side canned advice |
| 9 | **Weather Integration** | ✅ READY | 9/10 | Real async client, cache-aside, TTL, coords resolution, M3 risk; affected by M3 label bug |

### Final Verdict

> ## ⚠️ PARTIALLY READY
>
> **Durian Guardian AI is "partially ready" for production AI usage.** The two flagship AI capabilities — **disease detection (M1, 94.2% acc)** and **risk prediction (M3, 94.1% acc / 0.9901 AUC)** — are trained, exported, integrated end-to-end in the backend, and consumed by mobile and web clients, with real inference replacing mocks. Weather integration (real OpenWeather + cache-aside + M3 risk) is production-grade.
>
> **However**, the system is not fully ready because: (a) the trained **image-quality (M2)** and **recommendation (M4)** engines are completely disconnected from the API (heuristics/mock/client-side stand-ins are used instead); (b) the **AI Agronomist is a mock rule engine**, not the planned RAG/LLM; (c) a **label-mapping bug** makes the weather/risk `fungal_disease_risk` always report MEDIUM; (d) runtime architecture risks (synchronous inference on the event loop, unbounded uploads) degrade concurrency; and (e) training datasets are not in the repository, blocking reproducibility.
>
> With the §26 recommendations — especially fixing the M3 mapping, wiring M2/M4, and the startup/inference latency fixes — the system can reach **✅ READY** status for the core AI feature set.
