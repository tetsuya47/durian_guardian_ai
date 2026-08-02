# AI Model Deployment Audit — Durian Guardian AI

- **Date:** 2026-07-31
- **Audit mode:** Read-only inspection + runtime verification (no source code modified)
- **Target system:** `backend/app/ai` (FastAPI), `training/` (training pipeline), `frontend/` (consumers)
- **Scope:** Disease-detection model pipeline. Supporting (quality / recommendation / chat) components are noted where relevant.

---

## 1. Executive Summary

**Verdict: The trained disease-detection model is production-viable and the working tree already executes real inference instead of the mock.**

- The working tree of `backend/app/ai/service.py` calls `self._run_detection(file_bytes)` (real model) via the new `predictor.py`; it is **not committed** (`git status`: `M backend/app/ai/service.py`, `?? backend/app/ai/predictor.py`).
- The loaded checkpoint `training/checkpoints/disease_detection/best_model.pt` is valid, loads strictly, and matches the ONNX/TorchScript exports to ~1e-6 logits.
- Live inference on real upload images produced sensible results (Healthy and canker_disease).
- Evaluation report: test accuracy **94.23 %**, macro F1 **0.94** (537 test samples).
- **Remaining mocks:** `check_image_quality()` is still hardcoded (a real `training_quality` model exists but is not wired); `chat()` is still `_mock_chat()`.
- **Main risks:** uncommitted integration, no input validation (invalid bytes → 500), dataset images not available for reproduction, heuristic severity mapping, a label typo (`stem_cracking_ gummosis`) baked into every artifact, and a frontend/backend field-name contract mismatch.

---

## 2. Scope and Method

Inspected (read-only): model configs, checkpoints, exports, training/eval reports, training source, backend AI service/API/schemas/repositories, frontend types/services. Runtime-verified: checkpoint loadability (strict), parameter count, architecture reproduction, ONNX/TorchScript parity, preprocessing parity, and live inference on sample images. No code was changed and nothing was committed.

---

## 3. Environment and Artifact Inventory

### 3.1 Runtime environment (audit machine)
- Python 3.13.12, torch 2.11.0+cpu, torchvision 0.26.0+cpu, CUDA unavailable.
- `onnx`, `onnxruntime`, `sklearn`, `pillow`, `fastapi`, `motor`, `uvicorn`, `pydantic` all installed.
- Matches `backend/requirements.txt` and `training/reports/model_info.json` framework versions.

### 3.2 Disease-detection artifacts
| Artifact | Size | Notes |
|---|---|---|
| `training/checkpoints/disease_detection/best_model.pt` | 48.7 MB | Contains `model_state_dict` + config; `best_epoch=49`, `best_metric=0.8871` |
| `training/checkpoints/disease_detection/last_model.pt` | 48.7 MB | **Tensors identical** to `best_model.pt` (verified, max diff 0.0) |
| `training/exports/disease_detection/model.pt` | 16.4 MB | State dict export; **tensors identical** to `best_model.pt` (verified) |
| `training/exports/disease_detection/model.onnx` (+ `.data`) | 0.66 + 16.1 MB | ONNX opset 17, dynamic batch; logits match torch to 1.1e-6 |
| `training/exports/disease_detection/model.torchscript` | 16.8 MB | Loads and runs, output `(1, 11)` |

### 3.3 Other trained components (not the audit focus)
- `training_quality/` — image-quality model (MobileNet-V3, 2 classes Good/Bad, acc 0.8711; checkpoints + ONNX + reports exist).
- `training_recommendation/` + `training/model3/` — sklearn recommendation models (classifier + 3 regressors, `feature_columns.json` present).
- `training_quality` / `training_recommendation` dataset sources are not inside the repository.

---

## 4. Model Architecture Verification

- Configured in `training/configs/model1.yaml`: architecture `efficientnet-b0`, `num_classes: 11`, `dropout: 0.2`, input `224×224`.
- Reproduction for verification: `torchvision.models.efficientnet_b0(weights=None)` + replaced classifier head `Linear(1280, 11)`.
- `training/models/registry.py` and `training/models/efficientnet.py` provide the same adapter (`EfficientNetClassifier`).
- **`load_state_dict(strict=True)` succeeds** — checkpoint architecture and class count match.
- `best_model.pt == last_model.pt == exports/model.pt` at tensor level (max elementwise diff 0.0), so exports are **not stale**.

---

## 5. Preprocessing Verification

Training and inference preprocessing are **identical**:

1. `Resize((224, 224))` (bilinear)
2. `ToTensor()`
3. `Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])`

Source of truth: `training/datasets/preprocess/image_preprocessor.py`, `training/configs/model1.yaml`, and `predictor.py` `_build_transform()` all match. No augmentation is applied at inference time (correct).

---

## 6. Class Mapping Verification

The 11-class label set is **identical across all artifacts** (verified programmatically):

- `predictor.py` `CLASS_NAMES` == `training/reports/model_info.json` `class_names` == checkpoint embedded config == training eval scripts.

Classes: `Healthy, anthracnose_disease, canker_disease, leaf_spot, thrips_disease, downy_mildew, powdery_mildew, pink_disease, sooty_mold, root_rot, stem_cracking_ gummosis`.

> **Note:** the label `stem_cracking_ gummosis` contains a space after the underscore — a typo, but it is **consistent** across every artifact (training, checkpoint, backend), so inference is not broken by it. Fixing requires a full retrain.

`DISEASE_NAME_VI` in `predictor.py` provides Vietnamese display names (e.g., `canker_disease → Sẹo thân`). The backend returns the Vietnamese name to clients (see §9).

---

## 7. Checkpoint Integrity and Loadability

- `best_model.pt` loads via `torch.load(weights_only=False)`; contains `model_state_dict` and training config.
- Strict state-dict load against the reproduced EfficientNet-B0 head succeeds (no missing/unexpected keys).
- Live test results below (§8) confirm numerical validity end-to-end.

---

## 8. Exported Artifacts Parity

| Check | Result |
|---|---|
| `model.pt` vs `best_model.pt` tensors | identical (max diff 0.0) |
| `model.onnx` vs torch logits (same input) | max abs diff **1.13e-6**, same argmax |
| `model.torchscript` forward | works, output `(1, 11)` |

The ONNX model is a faithful, dynamically-batched (batch axis dynamic) export of the current best checkpoint — safe for CPU serving via onnxruntime.

---

## 9. Inference Correctness (Live Tests)

Ran `DiseasePredictor.predict()` on 6 real upload images:

| Image | Top-1 | Confidence | Severity |
|---|---|---|---|
| 4 upload images | `Healthy` | ~0.60–0.75 | low |
| 2 upload images | `canker_disease` | 0.4766 | high |

- Results are sensible and consistent for the small non-exhaustive sample.
- `canker_disease` base severity is `high` in the `_SEVERITY_MAP`; non-Healthy predictions with confidence ≥ 0.85 escalate low/medium → high (heuristic in `predictor.py`).
- Confidence semantics: top-1 softmax probability. **No calibration validation was performed** — on a confirmed canker sample the model was only 47.7 % confident, so thresholds (e.g., a 0.85 escalation cutoff) are not empirically validated.

---

## 10. Backend Integration State

### 10.1 Detection (REAL model — uncommitted)
- `backend/app/api/v1/ai.py` — `POST /ai/detect` (`tree_id` form field + `UploadFile`).
- `AIService.detect_disease()` → `_run_detection()` → `DiseasePredictor.predict()`.
- Result persisted to the `disease_history` collection (`DiseaseRepository`), then returned as `DetectionResponse{tree_id, image_url, detection{disease, confidence, severity}, created_at}` where `disease` is the **Vietnamese** name.
- Graceful fallback on any inference exception → `disease="Không xác định", confidence=0.0, severity="low"` (no crash, but hides real errors).

### 10.2 Image quality (STILL MOCK)
- `POST /ai/image-quality` → `AIService.check_image_quality()` returns a hardcoded `{blur: False, brightness: "good", leaf_detected: True, passed: True}`.
- A trained `training_quality` model (acc 0.8711) exists but is **not wired** to the backend.

### 10.3 Chat (STILL MOCK)
- `OllamaService.chat()` → `_mock_chat()` returns canned advice text. No LLM/Ollama integration present.

### 10.4 Git state
- `M backend/app/ai/service.py`, `?? backend/app/ai/predictor.py` — **uncommitted**. Git HEAD (`b678f35`) still contains `_mock_detection()`; the working tree is what actually runs the model. This switch must be committed deliberately.

---

## 11. Mock vs Real Comparison

| Capability | Old (committed) | Current (working tree) | Status |
|---|---|---|---|
| Disease detection | `_mock_detection()` canned result | Real EfficientNet-B0 via `predictor.py` | ✅ Real |
| Image quality | n/a | Hardcoded dict | ⚠️ Mock |
| Chat advice | `_mock_chat()` | `_mock_chat()` | ⚠️ Mock |

The core deliverable (disease detection) is running on the real model.

---

## 12. Gaps, Risks, and Observations

1. **Uncommitted integration** — real-model switch lives only in the working tree. Rollback/loss risk.
2. **No input validation** — any bytes are passed to PIL; invalid/corrupt images raise `UnidentifiedImageError` → HTTP 500 (no domain/format check, no max-size enforcement at the endpoint despite `MAX_UPLOAD_SIZE_MB=10` in config).
3. **No duplicate/quality filtering** — any accepted image is classified directly; the quality model is not used as a pre-filter.
4. **Dataset not reproducible** — repo contains only `dataset/DGA_Enterprise_Dataset.xlsx` + `DGA_seed_dataset_10000.csv`; actual training images are absent (source folder `D:\Ten_Classes_of_Durian_Leaf_Diseases` holds only a CSV). The 537-sample test report cannot be re-run locally.
5. **Label typo** — `stem_cracking_ gummosis` (extra space) is baked into all artifacts; display-layer workaround needed until retrain.
6. **Severity is heuristic** — `_SEVERITY_MAP` + confidence escalation, not learned from data; unvalidated.
7. **Confidence calibration untested** — 0.4766 on a positive canker sample; escalation/acceptance thresholds are not empirically grounded.
8. **Contract mismatch** — `/ai/detect` returns `detection.disease` (Vietnamese string), while the frontend `DetectionResult` type and detection-results page use `disease_name`; the separate `detection-results` CRUD schema uses `prediction`/`model`. Two parallel result models; the detection-results page may be fed by mocks/mismatched fields.
9. **Singleton lifetime** — `DiseasePredictor` uses a module-level singleton (`__new__`) with model loaded at first use; safe on thread use in FastAPI, but model path is resolved relative to the project root (fragile if deployed to another cwd).
10. **Image-quality + chat remain mock** despite trained assets for quality.

---

## 13. Recommendations

1. Commit the working-tree switch (`service.py` + `predictor.py`) as an explicit "real model" PR, and run the backend test suite.
2. Add endpoint-level validation: file extension/MIME check, byte-size cap, and catch `UnidentifiedImageError`/`PIL.UnidentifiedImageError` → 400 (keep the graceful fallback only for genuine model failures).
3. Wire the trained `training_quality` model into `/ai/image-quality` (replaces hardcoded dict).
4. Resolve the `disease` vs `disease_name` contract between backend and frontend before frontend consumes `/ai/detect`.
5. Decide on the `stem_cracking_ gummosis` typo: keep consistent + map in display layer, or retrain with corrected labels.
6. Version and package model artifacts (with `model_info.json` fingerprint) so backend always loads the same checkpoint; consider onnxruntime for CPU serving.
7. Document dataset provenance and commit/link the training images (or a checksummed manifest) so reports are reproducible.
8. Validate severity mapping and confidence thresholds against a labeled holdout set before relying on them.

---

## 14. Questions Requiring Product Decision

- Should the model return English keys, Vietnamese display names, or both? (Affects persistence + frontend display + the chat context.)
- Is a 47 %-confidence top-1 acceptable to surface to users, or should a confidence floor ("Không xác định" / retry) be enforced?
- Should image-quality checking gate classification (reject blurry/unclear leaves) or run in parallel?

---

## 15. Conclusion

The disease-detection model is **valid, consistent, and already running in the backend working tree**, with exports that faithfully match the checkpoint and a documented 94.23 % test accuracy. The remaining blockers are **process** (commit the integration), **robustness** (input validation), and **secondary features** (quality check and chat are still mock). With the §13 recommendations applied, the model is fit to replace the mock permanently.
