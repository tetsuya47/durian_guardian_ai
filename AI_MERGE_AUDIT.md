# AI MERGE AUDIT

**Project** — Durian Guardian AI (DGA)

**Release** — 2.0 (DGA Enterprise Development Protocol)

**Mode** — STRICT AUDIT (READ ONLY)

**Status** — AUDIT COMPLETE

---

## 1. REPORT — SCOPE SUMMARY

| Section | Path | Status |
|---|---|---|
| Project | `durian_guardian_ai` (branch `main`) | — |
| Commit audited | `46181fe` (feat(ai-mobile): non-durian filter, DB config, mobile UI) + recent pull | — |
| Files Scanned | ~45 (see Files Scanned list) | — |
| Files Modified | **NONE** (READ ONLY mode) | ✅ |

> Audit was performed on files changed/added after the GitHub pull. No file was edited.

---

## 2. FILES SCANNED

**backend/app/ai/** — `predictor.py`, `service.py`

**backend/app/api/v1/** — `ai.py`, `dashboard.py`, `inspections.py`, `detection_results.py`, `disease_history.py`, `alerts.py`, `chat.py`, `main.py` (router registration)

**backend/app/dashboard/** — `service.py`, `dto.py`

**backend/app/repositories/** — `disease_repository.py`, `disease_history_repository.py`, `detection_result_repository.py`, `inspection_repository.py`, `tree_repository.py`, `notification_repository.py`, `base.py`

**backend/app/schemas/** — `disease.py`, `dashboard.py`, `detection_result.py`

**backend/app/services/** — `history_service.py`, `detection_result_service.py`, `alert_service.py`, `inspection_service.py`

**backend/app/core/** — `config.py`

**backend/tests/** — `test_integration.py`, `test_durian_filter.py`, `conftest.py`

**backend scripts** — `seed_demo.py`, `seed_full_history.py`, `seed_1200_trees.py`, `clear_history.py`, `clear_mock_history.py`

**frontend/src (Web React)** — `pages/dashboard/Dashboard.tsx`, `components/dashboard/AgronomistPanel.tsx`, `services/dashboardDataManager.service.ts`, `pages/inspections/Inspections.tsx`, `pages/disease-history/DiseaseHistory.tsx`, `pages/detection-results/DetectionResults.tsx`

**dga_mobile (Flutter)** — `disease_detection_repository_impl.dart`, `disease_detection_remote_datasource.dart`, `dashboard_repository_impl.dart`, `dashboard_remote_datasource.dart`, `history_repository_impl.dart`, `history_remote_datasource.dart`, `disease_detection_providers.dart`

**Model artifacts (verify)** — `training/checkpoints/disease_detection/best_model.pt` (48,732,792 bytes) ✅ exists, `last_model.pt`, `training/exports/disease_detection/model.onnx`, `model.pt`

---

## 3. FINDINGS

### 3.1 AI PREDICTOR — `backend/app/ai/predictor.py`

| Item | Detail |
|---|---|
| **Model** | EfficientNet-B0 (`torchvision.models.efficientnet_b0`, `weights=None`), classifier head replaced `Linear(1280 → 11)`. Mirrors `ModelFactory._adapt_classifier`. |
| **Weight / Checkpoint** | `training/checkpoints/disease_detection/best_model.pt` (relative to project root). Loaded with `torch.load(..., weights_only=False)`; accepts raw state dict or wrapped under `model_state_dict`. Raises `RuntimeError` if missing/failed. |
| **Device** | `cuda` if available, else `cpu`. Singleton, thread-safe (`threading.Lock`). |
| **Input** | Raw image bytes → `PIL.Image.open(...).convert("RGB")` → Resize `(224,224)` → `ToTensor` → ImageNet normalize (mean 0.485/0.456/0.406, std 0.229/0.224/0.225). |
| **Output** | `{disease (EN), disease_vi, confidence (0–1, rounded 4dp), severity (none/low/medium/high), top5 [{class, class_vi, confidence}]}` |
| **Classes** | 11 classes in `CLASS_NAMES` (incl. `Healthy`). |
| **Severity logic** | Base severity per class in `_SEVERITY_MAP`; escalates `low/medium → +1 level` when confidence ≥ 0.85 (non-Healthy). |
| **Note** | Class key `"stem_cracking_ gummosis"` contains a space typo but is **internally consistent** across `CLASS_NAMES`, `DISEASE_NAME_VI`, `_SEVERITY_MAP`. |

### 3.2 AI SERVICE — `backend/app/ai/service.py`

**Workflow `detect_disease`:**

1. Resolve tree: `tree_id` valid → `TreeRepository.get()`; else first tree from `tree_repo.list(per_page=1)`; else hardcoded fallback `6a6cc2ba3432b70022fba65d`.
2. `_analyze_quality(file_bytes)` — OpenCV Laplacian blur (`var < 1.0`), brightness (`<5 dark`, `>252 too_bright`), HSV foliage/skin/blue/red/mono rejection rules, plus predictor confidence.
3. Reject with `BadRequestException` (400): "Ảnh quá tối", "Ảnh quá mờ", "Ảnh không phải lá/cây sầu riêng".
4. Predict via `DiseasePredictor.predict` (reuses `quality.prediction` if available).
5. Save image → `settings.UPLOAD_DIR` (uuid name).
6. **Write `disease_history`** via `DiseaseRepository.create(...)` with `{tree_id, disease (VI name), disease_name (VI), severity, confidence, image_url, date (UTC now), action: "Chẩn đoán bệnh AI"}`.
7. Return `DetectionResponse` — `recommendation` template, `processing_time_ms` **hardcoded 120.0**.

**Repositories used** — `DiseaseRepository` (collection `disease_history`, write), `TreeRepository` (collection `trees`, read-only).

**Collection written** — ONLY `disease_history`.

**OllamaService** — still a `_mock_chat` stub; not used by `/ai` endpoints.

**Unused helper** — `_run_detection()` performs real inference but is **not** called by `detect_disease`.

### 3.3 API — `backend/app/api/v1/ai.py`

**`POST /api/v1/ai/detect`**
- Request: `multipart/form-data` — `tree_id: str (Form)`, `file: UploadFile`. Auth required (`get_current_user_id`), role `allow_all`.
- Validation: empty file, extension whitelist `{.jpg,.jpeg,.png,.bmp,.webp,.heic,.heif}`, `PIL.verify()`, cv2 fallback.
- Response: success envelope → `data: {tree_id, image_url, detection:{disease, confidence, severity}, created_at, heatmap_url:null, overlay_url:null, risk_level:null, risk_probability:null, recommendation, processing_time_ms}`.
- Errors: 400 (`BadRequestException`) for empty/invalid/corrupted/dark/blur/not-leaf; 401/403 via auth.

**`POST /api/v1/ai/image-quality`** (spec named `/ai/check-quality` — **name mismatch**, see Missing)
- Request: `file: UploadFile`. Auth required.
- Response: `{blur, brightness, leaf_detected, passed}`.

**Note** — Spec declares `/api/v1/ai/check-quality`; implementation exposes `/api/v1/ai/image-quality`. Client (`ApiEndpoints.aiImageQuality`) matches the implementation, not the spec.

### 3.4 MONGO MAPPING (AI write paths)

| Collection | Status | Evidence |
|---|---|---|
| `inspections` | **NOT FOUND** | AI never inserts; only `/api/v1/inspections` (manual) or `seed_demo.py` / `seed_full_history.py` |
| `detection_results` | **NOT FOUND** | AI never inserts; only `/api/v1/detection-results` (manual, requires `inspection_id`) or seed scripts |
| `disease_history` | **FOUND** | `AIService.detect_disease` → `DiseaseRepository.create` (only collection AI writes) |
| `alerts` | **NOT FOUND** | AI never inserts; only `/api/v1/alerts` / `AlertService.create` (manual) or seed |
| `trees` | **PARTIAL** | AI reads `trees` for tree resolution only; never updates `status` / `health_status` |

**Consequence** — The AI flow is **detached** from the inspection → detection_result → alert pipeline. Dashboard `system_overview` (inspection_today / ai_detection_today / new_alerts_today / pending_review) and detection-based widgets are not fed by real AI detections.

### 3.5 DASHBOARD — collection usage

| Widget | Collection(s) |
|---|---|
| **Heatmap** | `trees` + `zones` + `farms` (status via `trees.status` / `health_status`) |
| **KPI** | `trees` (healthy/diseased/high-risk by status regex) |
| **System Overview** | `inspections`, `detection_results`, `alerts`, `detection_results.distinct("inspection_id")` |
| **Recent Detection (activity)** | `disease_history` (fallback `detection_results`) |
| **Alerts (DashboardOut)** | `alerts` (via `NotificationRepository`) |
| **Risk Trend** | `alerts` (priority → avg risk) |
| **Widget Inspections** | `inspections` + joins (`trees`, `zones`, `farms`, `users`, `detection_results`) |
| **Widget Detections / Priority Trees** | `detection_results` + joins (requires `inspection_id`) |
| **Farm Dashboard** | `trees`, `zones`, `alerts`, `seasons`, `farm_performance`, `farm_targets`, `harvests` |

### 3.6 FRONTEND — real AI data vs mock

**Web (React) — REAL backend API**
- Dashboard: `dashboardDataManager.service.ts` → `/dashboard`, `/dashboard/heatmap`, `/dashboard/widgets`, `/dashboard/farm/{id}`, `/dashboard/farm-performance`.
- Inspections / Disease History / Detection Results pages use real services (`inspectionService`, `diseaseHistoryService`, `detectionResultService`).
- `AgronomistPanel` = local rule engine over real KPI/alert data (no LLM).
- Stale mock files remain (`pages/*/mockData.ts`, `MockWidgets.tsx`, `KPICards.tsx` KPI_MOCK_DATA) but are **not wired** into the main Dashboard.

**Mobile (Flutter) — PARTIAL real / partial mock**
- Disease detection → real `/ai/detect` + `/ai/image-quality` via `DiseaseDetectionRepositoryImpl` (DI provider). ✅
- History → real `/history/{tree_id}` + `/trees` APIs. ✅
- Dashboard → real `/dashboard`. ✅
- **Mock remains in mobile**: disease description (symptoms/causes/recommendations) resolved from local `MockDetectionDatasource.getDiseaseInfo(...)`; risk score fallback recomputed locally; `MockDiseaseDetectionRepository` exists but is **not** wired to DI.

### 3.7 MISSING COMPONENTS (Release 2.0)

Listed only — no fix proposals.

1. AI detect does not create an `inspections` record for the detection.
2. AI detect does not create a `detection_results` record (and cannot — it requires `inspection_id` which the AI flow never creates).
3. AI detect does not create an `alerts` record for high-severity / high-confidence detections.
4. AI detect does not update `trees.status` / `trees.health_status` after detection (heatmap + KPI unaffected by AI).
5. `system_overview` (inspection_today / ai_detection_today / new_alerts_today / pending_review) is not fed by the AI flow.
6. Detection-based dashboard widgets (`_get_widget_detections`, `_get_widget_priority_trees`) are empty unless seeded manually — AI results never reach them.
7. `processing_time_ms` is **hardcoded 120.0** in `detect_disease` (real inference time not measured/returned).
8. EN/VI class mismatch: predictor returns `"Healthy"` (EN) but service stores `result.disease` = VI `"Khỏe mạnh"` in `disease_history`; tree list status filter (`_list_with_joins`) matches `latest_disease.disease == "Healthy"` → AI-healthy trees will NOT match "healthy" filter.
9. Spec endpoint `/api/v1/ai/check-quality` does not exist; implementation is `/api/v1/ai/image-quality`.
10. `OllamaService.chat` is still a mock (no real agronomist/AI-chat inference).
11. Mobile disease info payload (symptoms/causes/impact/spread/recommendations) still comes from local mock data, not the backend.
12. `risk_level` / `risk_probability` / `heatmap_url` / `overlay_url` in `DetectionResponse` are always null.
13. `_run_detection()` in `AIService` is dead code (not invoked).
14. Seeded demo data (`seed_demo.py`, `seed_full_history.py`, `seed_1200_trees.py`) injects synthetic inspections/detection_results/disease_history — not produced by the real AI pipeline.
15. Hardcoded fallback tree id `6a6cc2ba3432b70022fba65d` duplicated in backend service and mobile repo.
16. No backfill/migration to link existing `disease_history` AI records into `inspections` / `detection_results`.

---

## 4. REPORT — FINAL

| Field | Value |
|---|---|
| Project | Durian Guardian AI |
| Release | 2.0 |
| Files Scanned | ~45 |
| Files Modified | **NONE** |
| Findings | 16 (AI pipeline detached from inspection/detection/alert chain; endpoint name mismatch; mock remnants in mobile; hardcoded timing; EN/VI class mismatch) |
| Collection Mapping | `disease_history` = FOUND · `inspections` = NOT FOUND · `detection_results` = NOT FOUND · `alerts` = NOT FOUND · `trees` = PARTIAL (read-only) |
| API Mapping | `/ai/detect` = real model inference + `disease_history` write · `/ai/image-quality` (spec: `/ai/check-quality`) = rule-based quality gate |
| Dashboard Mapping | KPI/Heatmap = `trees` · System Overview/Widgets = `inspections`, `detection_results`, `alerts` · Recent Activity = `disease_history` · Risk Trend = `alerts` |
| Frontend Mapping | Web = real API (stale mock files unused) · Mobile = real `/ai/detect` + `/ai/image-quality`, mock disease descriptions |
| Missing Components | 16 items (see §3.7) |
| Final Status | **AUDIT COMPLETE** |
