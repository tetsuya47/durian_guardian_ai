# AI_INTEGRATION_AUDIT

# Project Information

| Field | Value |
|---|---|
| Project | Durian Guardian AI (DGA) |
| Release | 2.0 (Preparation) |
| Audit | STEP AI-1 — AI Integration Audit |
| Mode | STRICT AUDIT / READ ONLY |
| Agent | OpenCode |
| Date | 2026-08-02 |

# LOCK STATUS

| Component | Status |
|---|---|
| Database | 🔒 LOCKED |
| Backend | 🔒 LOCKED |
| Frontend | 🔒 LOCKED |
| Training | 🔒 LOCKED |
| Model | 🔒 LOCKED |
| Deployment | 🔒 LOCKED |

> No file was created, deleted, moved, renamed, refactored, trained, or downloaded.
> Only the audit report `AI_INTEGRATION_AUDIT.md` was generated.

=====================================================

# AI Projects Found

| # | Project / Directory | Description | Role |
|---|---|---|---|
| 1 | `training/` | Model 1 (Disease Detection), Model 3 infra (Risk Prediction), Model 4 RAG/LLM stub | Training framework + trained weights |
| 2 | `training_quality/` | Model 2 (Image Quality) | Training framework + trained weights |
| 3 | `training_recommendation/` | Model 4 (AI Recommendation Engine) | Training framework + trained weights + rule engine |
| 4 | `model1_deployment/` | Deployment folder for Model 1 | EMPTY — README only (references missing artifacts) |
| 5 | `backend/` | FastAPI backend with AI endpoints | AI API scaffolding — MOCK only |
| 6 | `frontend/` | React web app | AI UI: NOT PRESENT (CRUD pages + mock data only) |
| 7 | `dga_mobile/` | Flutter mobile app | AI UI: PRESENT (disease detection flow) |
| 8 | `database/` | MongoDB schema/ETL | Data store |
| 9 | `scripts/` | Utility scripts | Data / audit utilities |

**Total AI projects (with code):** 4 training projects + 1 deployment folder + 1 backend AI module.

=====================================================

# Models Found

| Model | Status | Path (weights) | Weight |
|---|---|---|---|
| Model 1 — disease_detection (EfficientNet-B0, 11 classes) | **FOUND** | `training/checkpoints/disease_detection/` + `training/exports/disease_detection/` | best_model.pt / last_model.pt / model.pt / model.onnx / model.torchscript |
| Model 2 — image_quality (MobileNet V3 Small, 2 classes) | **FOUND** | `training_quality/checkpoints/` + `training_quality/exports/` | best_model.pt / last_model.pt / model.pt / model.onnx / model.torchscript |
| Model 3 — risk_prediction (RandomForest, 3 classes) | **FOUND** | `training/model3/exports/` | model.pkl + preprocessor.pkl + label_encoder.pkl |
| Model 4 — recommendation (Multi-task Random Forest: 1 classifier + 3 regressors) | **FOUND** | `training_recommendation/exports/` + `checkpoints/` | classifier.pkl + 3× regressor_*.pkl + preprocessor.pkl |
| Model 4 (LLM) — AI Agronomist RAG + Ollama llama3.2 | **NOT FOUND** | `training/configs/model4.yaml`, `training/models/llm/` | No weights. RAG stub only. Backend uses MOCK |

Notes:

- Model 1 config: `training/configs/model1.yaml` (efficientnet_b0, 11 classes, 224×224).
- Model 2 config: `training_quality/configs/model2.yaml` (mobilenet_v3_small, 2 classes). A duplicate stub also exists at `training/models/image_quality/quality_model.py` (marked "stub", unused).
- Model 3 config: `training/configs/model3.yaml` (random_forest / xgboost, 3 classes: Low/Medium/High).
- Model 4 config: `training_recommendation/configs/model4.yaml` (multi_task_rf, 4 priorities + 3 regressions).
- Model 4 LLM config: `training/configs/model4.yaml` (Ollama llama3.2 + nomic-embed-text + ChromaDB). No vector store exists (`training/models/llm/vector_store` NOT FOUND); only 4 markdown knowledge files.

=====================================================

# Weight Files

| Name | Path | Size (bytes) |
|---|---|---|
| best_model.pt | `training/checkpoints/disease_detection/best_model.pt` | 48,732,792 |
| last_model.pt | `training/checkpoints/disease_detection/last_model.pt` | 48,732,792 |
| model.onnx | `training/exports/disease_detection/model.onnx` | 657,523 |
| model.onnx.data | `training/exports/disease_detection/model.onnx.data` | 16,056,320 |
| model.pt | `training/exports/disease_detection/model.pt` | 16,365,203 |
| model.torchscript | `training/exports/disease_detection/model.torchscript` | 16,796,811 |
| best_model.pt | `training_quality/checkpoints/best_model.pt` | 13,156,591 |
| last_model.pt | `training_quality/checkpoints/last_model.pt` | 13,156,591 |
| model.onnx | `training_quality/exports/model.onnx` | 367,554 |
| model.onnx.data | `training_quality/exports/model.onnx.data` | 4,274,464 |
| model.pt | `training_quality/exports/model.pt` | 4,424,931 |
| model.torchscript | `training_quality/exports/model.torchscript` | 4,696,505 |
| model.pkl | `training/model3/exports/model.pkl` | 44,390,369 |
| preprocessor.pkl | `training/model3/exports/preprocessor.pkl` | 4,339 |
| label_encoder.pkl | `training/model3/exports/label_encoder.pkl` | 502 |
| classifier.pkl | `training_recommendation/exports/classifier.pkl` | 4,455,321 |
| regressor_urgency_score.pkl | `training_recommendation/exports/regressor_urgency_score.pkl` | 12,731,601 |
| regressor_estimated_loss_pct.pkl | `training_recommendation/exports/regressor_estimated_loss_pct.pkl` | 10,585,425 |
| regressor_next_check_days.pkl | `training_recommendation/exports/regressor_next_check_days.pkl` | 346,737 |
| preprocessor.pkl | `training_recommendation/exports/preprocessor.pkl` | 4,792 |
| label_encoder.pkl | `training_recommendation/exports/label_encoder.pkl` | 331 |
| best_classifier.pkl | `training_recommendation/checkpoints/best_classifier.pkl` | 4,455,321 |
| best_regressor_urgency_score.pkl | `training_recommendation/checkpoints/best_regressor_urgency_score.pkl` | 12,731,601 |
| best_regressor_estimated_loss_pct.pkl | `training_recommendation/checkpoints/best_regressor_estimated_loss_pct.pkl` | 10,585,425 |
| best_regressor_next_check_days.pkl | `training_recommendation/checkpoints/best_regressor_next_check_days.pkl` | 346,737 |
| best_preprocessor.pkl | `training_recommendation/checkpoints/best_preprocessor.pkl` | 4,792 |

**Total weight files:** 24 (excluding `.pt` duplicates and checkpoint copies).

**Model sizes (per metadata):**

| Model | Size |
|---|---|
| Model 1 (EfficientNet-B0) | ~15.5 MB (4,021,639 params) |
| Model 2 (MobileNet V3 Small) | ~4.15 MB (1,075,234 params) |
| Model 3 (Random Forest) | ~39.9 MB |
| Model 4 (RF ensemble) | ~29.3 MB |

=====================================================

# Inference Scripts

| Script | Path | Model | Status |
|---|---|---|---|
| predict.py | `training/predict.py` | Model 1 (disease detection, single image) | FOUND |
| predict_folder.py | `training/predict_folder.py` | Model 1 (batch folder) | FOUND |
| predict_model3.py | `training/predict_model3.py` | Model 3 (risk prediction) | FOUND |
| engine/inference.py | `training/engine/inference.py` | Model 1 (InferenceEngine class) | FOUND |
| predict.py | `training_quality/predict.py` | Model 2 (image quality) | FOUND |
| predict_folder.py | `training_quality/predict_folder.py` | Model 2 (batch folder) | FOUND |
| predict.py | `training_recommendation/predict.py` | Model 4 (recommendation) | FOUND |
| export.py / export_onnx.py | `training/export.py`, `training/scripts/export_onnx.py` | Model 1 (export) | FOUND |
| export.py | `training_quality/export.py` | Model 2 (export) | FOUND |
| evaluate.py / gradcam.py | `training/evaluate.py`, `training/gradcam.py` | Model 1 | FOUND |

**NOT FOUND:**
- No `serve.py`, `detect.py`, `api.py`, `run.py` inference server in the training projects.
- Backend `backend/run.py` runs the FastAPI app (mock AI), NOT a real model server.

=====================================================

# Deployment Audit

| Check | Status | Details |
|---|---|---|
| FastAPI (real AI) | **PARTIAL** | FastAPI exists (`backend/app/main.py`) but AI is MOCK |
| Flask AI | NOT FOUND | — |
| API Server | **PARTIAL** | `backend/run.py` → uvicorn on :8000 |
| Docker AI | NOT FOUND | No `Dockerfile`, no `docker-compose` anywhere in repo |
| Separate requirements | **PARTIAL** | `backend/requirements.txt` exists but contains NO ML/AI libs (no torch, no onnxruntime, no sklearn, no joblib) |
| Root requirements | FOUND | `requirements.txt` has tensorflow/sklearn/opencv but NO torch, NO onnxruntime, NO joblib |
| Endpoint /predict | NOT FOUND | — |
| Endpoint /inference | NOT FOUND | — |
| Endpoint /detect | **PARTIAL** | `/api/v1/ai/detect` exists but MOCK |
| Endpoint /classify | NOT FOUND | — |
| Endpoint /ai/image-quality | **PARTIAL** | exists but MOCK (hardcoded response) |
| Endpoint /ai/chat | **PARTIAL** | `/api/v1/chat` exists but MOCK Ollama |

**model1_deployment/ folder audit:**
- Contains ONLY `README.md`.
- README references `model.pt`, `model.torchscript`, `model.onnx`, `config.yaml`, `class_names.txt`, `api_schema.json`, and a `/predict` FastAPI example — **NONE of these files exist** in the folder.
- The real model artifacts are in `training/exports/disease_detection/` (not copied to the deployment folder).

=====================================================

# Backend Connection Audit

Searched for: `requests.post`, `http://`, `predict`, `inference`, `ai_service`, `model`, `YOLO`, `EfficientNet`, `onnxruntime`, `torch`.

| Check | Status | Evidence |
|---|---|---|
| Real model loaded by backend | **NOT CONNECTED** | `backend/app/ai/service.py:35` calls `self._mock_detection()` (uses `random.choice`) |
| Image quality real model | **NOT CONNECTED** | `service.py:57` returns hardcoded `{blur:False, brightness:"good", ...}` |
| LLM / Ollama real call | **NOT CONNECTED** | `service.py:91` `OllamaService.chat` returns `_mock_chat()` hardcoded text |
| Torch / onnxruntime in backend | NOT FOUND | no imports in `backend/app` |
| sklearn / joblib in backend | NOT FOUND | no imports in `backend/app` |
| Outbound HTTP to AI server | NOT FOUND | no `requests.post`/`httpx` calls to a model server |

**Verdict: NOT CONNECTED.** Backend exposes AI endpoints and persistence (writes to MongoDB), but performs no real inference.

=====================================================

# Frontend AI Audit

| Check | Web (`frontend/`) | Mobile (`dga_mobile/`) |
|---|---|---|
| Upload Image UI | NOT FOUND | FOUND (`image_selector_buttons.dart`, `image_editor_wizard.dart`) |
| Prediction / Result display | NOT FOUND (mock tables only) | FOUND (`ai_result_card.dart`, `disease_details_card.dart`) |
| Confidence display | PARTIAL (mock data only: `pages/detection-results/mockData.ts`) | FOUND (`ai_result_card.dart`) |
| Disease / diagnosis | PARTIAL (CRUD + mock) | FOUND |
| Recommendation | NOT FOUND | FOUND (`recommendation_page.dart`, `quick_recommendations_card.dart`) |
| Heatmap / overlay | NOT FOUND | PARTIAL (fields `heatmapUrl`/`overlayUrl` parsed in DTO; backend mock returns none) |
| Live API wired to /ai/detect | NOT FOUND | FOUND (`disease_detection_remote_datasource.dart` → `ApiEndpoints.aiDetect`) |

- Web frontend has **no AI upload/prediction screen**. Detection-Results page uses live CRUD service (`detectionResult.service.ts`) with mock-style seed data.
- Mobile app has a **complete AI diagnosis UI** and calls the real backend endpoints `/ai/detect` and `/ai/image-quality`, but the backend returns mock results. Mobile also falls back to local mock disease info (`mock_detection_datasource.dart`).

=====================================================

# Current Data Flow

## Web flow (as built today)

```
Frontend (React)
    │  REST /api/v1/*  (CRUD)
    ▼
Backend FastAPI (FastAPI + Motor)
    │  pymongo/motor
    ▼
MongoDB  ←──────────────────────────┐
    ▲                                │
    └────────────────────────────────┘
```

## AI flow (as built today — MOCK)

```
Mobile (dga_mobile) / (no web upload UI)
    │  POST /api/v1/ai/detect (multipart: tree_id + file)
    ▼
Backend AIService.detect_disease
    ├─ save upload to ./uploads          (uploads/ currently EMPTY)
    ├─ _mock_detection()  → random disease/confidence/severity   ⚠ MOCK
    ├─ write disease record → MongoDB
    └─ return DetectionResponse
```

## Real trained-model path (exists ONLY as training scripts, not wired)

```
Training CLI predict.py/predict_model3.py/predict_*.py
    │  loads weights (checkpoints/exports)
    ▼
Inference result (JSON)
    ▼
Manual / test scripts only — NOT called by Backend
```

**Missing link:** Backend does NOT load any of the 24 trained weight files.

=====================================================

# Missing Components

| Component | Status | Note |
|---|---|---|
| AI Service | **PARTIAL** | `AIService` exists but is MOCK (`_mock_detection`) |
| Inference API | **PARTIAL** | `/api/v1/ai/*` exists but returns mock output |
| Prediction Endpoint | **PARTIAL** | `/api/v1/ai/detect` (mock); `/predict`, `/inference`, `/classify` NOT FOUND |
| Model Loader | **NOT FOUND** | Backend has no torch/onnxruntime/joblib loader. Loader exists only in training CLI (`training/predict.py:load_model`) |
| Model Cache | **NOT FOUND** | Model not held in memory; no singleton/cache |
| Image Preprocessing | **NOT FOUND** | In backend. (Resize/normalize exists in `training/datasets/preprocess/` only) |
| Post Processing | **NOT FOUND** | No softmax → top-5 / label mapping / severity mapping in backend |
| Model Versioning | **PARTIAL** | Configs + `reports/model_info.json` + checkpoints naming; no deployment registry/versioning |
| Health Check | **PARTIAL** | `GET /health` exists (app-level); no model-load / AI health check |
| Docker | **NOT FOUND** | No Dockerfile / docker-compose / container deployment |

=====================================================

# Files Scanned

## Backend (AI scope)
- `backend/app/ai/service.py` — AIService (mock detection), OllamaService (mock chat)
- `backend/app/api/v1/ai.py` — POST /ai/detect, POST /ai/image-quality
- `backend/app/api/v1/chat.py` — POST /chat
- `backend/app/api/v1/__init__.py` — router registry
- `backend/app/services/chat_service.py` — ChatService (uses mock Ollama)
- `backend/app/main.py` — FastAPI app, /health, /uploads
- `backend/app/core/config.py` — settings
- `backend/run.py` — uvicorn entry
- `backend/requirements.txt` — no ML libs
- `backend/app/api/v1/*` (15 routers) — CRUD routers scanned
- `backend/tests/*` — test files scanned
- `backend/uploads/` — EMPTY

## Training (Model 1 + 3 + 4-LLM)
- `training/configs/model1.yaml`, `model2.yaml`, `model3.yaml`, `model4.yaml`
- `training/predict.py`, `predict_folder.py`, `predict_model3.py`
- `training/train.py`, `train_model3.py`, `evaluate.py`, `export.py`, `gradcam.py`
- `training/engine/inference.py`, `trainer.py`, `tester.py`, `validator.py`, `export_manager.py`, `base_engine.py`
- `training/models/registry.py`, `disease_detection/efficientnet.py`, `image_quality/quality_model.py`, `risk_prediction/tabular_model.py`, `llm/rag_pipeline.py`
- `training/models/llm/knowledge/*.md` (4 knowledge files)
- `training/checkpoints/disease_detection/*`, `training/exports/disease_detection/*`
- `training/model3/exports/*`, `training/reports/*`, `training/tensorboard/model1/*`
- `training/callbacks/*`, `datasets/**`, `losses/*`, `metrics/*`, `optimizers/*`, `schedulers/*`, `utils/*`
- `training/scripts/*` (dataset_audit, retrain, evaluate, validate, export_onnx, etc.)

## Training Quality (Model 2)
- `training_quality/configs/model2.yaml`
- `training_quality/predict.py`, `predict_folder.py`, `train.py`, `export.py`
- `training_quality/models/quality_model.py`
- `training_quality/checkpoints/*`, `training_quality/exports/*`, `training_quality/reports/*`
- `training_quality/engine/*`, `training_quality/dataset/*`, `training_quality/utils/*`

## Training Recommendation (Model 4)
- `training_recommendation/configs/model4.yaml`, `configs/feature_list.json`
- `training_recommendation/predict.py`, `train.py`
- `training_recommendation/exports/*` (classifier + 3 regressors + artifacts)
- `training_recommendation/checkpoints/*`
- `training_recommendation/rules/rule_engine.py`
- `training_recommendation/datasets/build_dataset.py`
- `training_recommendation/tests/*` (7 test files, incl. `test_predict_mongodb.py`, `test_model1_batch.py`)
- `training_recommendation/reports/*`

## Deployment
- `model1_deployment/README.md` (only file; referenced artifacts missing)

## Frontend
- `frontend/src/api/axios.ts`, `index.ts`, `interceptors.ts`
- `frontend/src/services/detectionResult.service.ts` (+ 12 other services)
- `frontend/src/pages/detection-results/DetectionResults.tsx`, `mockData.ts`
- `frontend/src/pages/*` (alerts, diseases, disease-history, inspections, etc. scanned)
- `frontend/src/types/*`, `frontend/src/components/**`, `frontend/src/routes/*`
- `frontend/package.json`, `vite.config.ts`

## Mobile
- `dga_mobile/lib/services/api_service.dart`
- `dga_mobile/lib/core/network/api_endpoints.dart`
- `dga_mobile/lib/features/disease_detection/**` (datasources, repository_impl, pages, widgets)
- `dga_mobile/lib/features/recommendation/**`
- `dga_mobile/lib/shared/widgets/ai_prediction_card.dart`
- `dga_mobile/docs/AI_ARCHITECTURE.md`, `AI_PIPELINE.md`

## Data / Utilities / Reports
- `database/**` (schema, ETL, seed, config, mongodb)
- `scripts/**` (audit_model4, check_database, import_excel, preprocess, reset, split)
- `reports/model4/*`
- Root: `README.md`, `requirements.txt`, `PROJECT_AI_SNAPSHOT.md`
- Weight-file inventory scan across full repo (24 weight files)

# Files Modified

| File | Action |
|---|---|
| `AI_INTEGRATION_AUDIT.md` | **CREATED** (this report) |
| All other files | NONE |

# Bugs / Issues Found (recorded, NOT fixed)

1. **Backend AI is mock** — `backend/app/ai/service.py` uses `random.choice` and hardcoded responses; not connected to any trained model.
2. **model1_deployment/ incomplete** — README references `model.pt`, `model.torchscript`, `model.onnx`, `config.yaml`, `class_names.txt`, `api_schema.json`; only `README.md` present.
3. **Duplicate/inconsistent Model 2 definition** — `training/models/image_quality/quality_model.py` is a stub (EfficientNet, "framework ready"), while the trained Model 2 lives in `training_quality/` (MobileNet V3 Small). Risk of confusion.
4. **Root `requirements.txt` lacks torch/torchvision/onnxruntime/joblib** — required to run `training/predict.py` etc.; backend `requirements.txt` has no AI libs at all.
5. **LLM Model 4 has no weights / vector store** — `training/configs/model4.yaml` defines Ollama RAG, but vector store was never built; backend `OllamaService` is a mock.
6. **Frontend (web) has no AI upload/prediction UI** — detection-results page relies on CRUD + mock data.
7. **Model versioning / registry absent in backend** — no model-loader, cache, or version check on any endpoint.
8. **No Docker / container deployment** for AI or backend.
9. **`backend/uploads/` exists but empty** — no persisted inference images.
10. **Name mismatch risk** — config file `training/configs/model4.yaml` (LLM/RAG) vs `training_recommendation/configs/model4.yaml` (recommendation engine) both use "Model 4".

# Final Status

**AUDIT COMPLETE**

- All scoped directories audited (read-only).
- 4 trained model sets found (Models 1–4) + 1 untrained LLM/RAG stub.
- 24 weight files inventoried.
- 7 inference scripts found (training CLI only).
- Backend AI endpoints exist but are **MOCK / NOT CONNECTED**.
- Web frontend: no AI UI. Mobile frontend: full AI UI wired to mock backend.
- Missing: real AI Service wiring, Model Loader, Model Cache, Image Preprocessing, Post Processing, Model Versioning, Docker.
- **No code was modified.**
