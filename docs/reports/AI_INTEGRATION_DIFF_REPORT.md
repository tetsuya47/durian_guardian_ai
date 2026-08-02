# AI Integration Diff Report — Git HEAD vs Working Tree

- **Date:** 2026-07-31
- **Auditor role:** Lead AI Integration Engineer / Git Code Auditor
- **Mode:** Read-only. No code modified, nothing staged, committed, or pushed.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`

---

## 1. Executive Summary

The real disease-detection AI integration **exists in the Working Tree but not in Git HEAD**.

- **Working Tree:** `service.py` calls `self._run_detection()` → `DiseasePredictor.predict()` → trained `best_model.pt` (EfficientNet-B0, 11 classes). Verified live: images infer correctly (`Healthy`, `canker_disease`).
- **Git HEAD:** `service.py` still calls `_mock_detection()` (random canned result). `predictor.py` does not exist in any commit.
- **State:** `service.py` = unstaged modified (`M`). `predictor.py` = untracked (`??`). Nothing staged.
- **Model/label mapping verified consistent:** training class index (alphabetical `sorted()` in `ImageClassificationDataset`) == `model_info.json` `class_names` == `predictor.py` `CLASS_NAMES`.
- **Classification:** Integration is functionally complete in the working tree, but not committed and missing small robustness fixes (input validation).

**Verdict: Git is outdated, the integration is complete in code, deployment-blocking items are small.** Next action = **B (Small fixes required: input validation + commit).**

---

## 2. Git HEAD vs Working Tree

| Aspect | Git HEAD (b5746d4) | Working Tree |
|---|---|---|
| `backend/app/ai/service.py` | uses `_mock_detection()` | uses `_run_detection()` (real model) |
| `backend/app/ai/predictor.py` | **does not exist** (never committed) | exists, 224 lines, untracked |
| `AIService.__init__` | no predictor | `self._predictor = DiseasePredictor()` |
| Imports | no AI imports | `from app.ai.predictor import DiseasePredictor` |
| `_mock_detection()` | present | **removed** |
| `_run_detection()` | absent | **added** |
| `check_image_quality()` | mock (hardcoded dict) | mock (unchanged) |
| `OllamaService.chat()` | `_mock_chat()` | `_mock_chat()` (unchanged) |

Files changed in the working tree (unrelated to AI): `backend/app/dashboard/service.py`, `backend/seed_demo.py`, several `dga_mobile/*.dart`, plus untracked `docs/reports/AI_MODEL_DEPLOYMENT_AUDIT.md`. None staged.

---

## 3. service.py comparison

Git HEAD version (verbatim, key lines):

```
        result = self._mock_detection()          # call site
    def _mock_detection(self) -> DetectionResult:  # lines 64-93
        import random
        diseases = ["Healthy", "Root Rot", "Leaf Spot", "Fruit Borer",
                    "Powdery Mildew", "Phytophthora"]
        ...
        return DetectionResult(disease=disease, confidence=round(confidence,4),
                               severity=severity)
```

Working Tree version (verbatim, key lines):

```
        # Run real AI inference
        result = self._run_detection(file_bytes)   # call site (line 43)

    def _run_detection(self, file_bytes: bytes) -> DetectionResult:  # lines 65-88
        prediction = self._predictor.predict(file_bytes)
        logger.info("AI detection: disease=%s (vi: %s), confidence=%.4f, severity=%s", ...)
        return DetectionResult(
            disease=prediction["disease_vi"],   # Vietnamese name to app
            confidence=prediction["confidence"],
            severity=prediction["severity"],
        )
        # except Exception -> graceful fallback "Không xác định" / 0.0 / low
```

**Function-level diff:**
- ADDED: `_run_detection()`
- REMOVED: `_mock_detection()`
- CHANGED: `result = self._mock_detection()` → `result = self._run_detection(file_bytes)`
- ADDED: `import logging`, `from app.ai.predictor import DiseasePredictor`, `logger`, `self._predictor = DiseasePredictor()` (+ 2 comments)
- UNCHANGED: `detect_disease()` persistence logic (saves upload → creates `disease_history` doc → returns `DetectionResponse`), `check_image_quality()` (still mock), `OllamaService` (still mock).

Answer to "was `_mock_detection()` replaced by `_run_detection()`?": **Yes, exactly** — same call position, same signature `(file_bytes)`, same return type `DetectionResult`.

---

## 4. predictor.py comparison

`predictor.py` (224 lines) is **brand new — never existed in any commit** (`git log --all -- backend/app/ai/predictor.py` returns nothing).

Contents:
- `CLASS_NAMES` (11, alphabetical) + `DISEASE_NAME_VI` (11 Vietnamese labels) + `_SEVERITY_MAP`
- `_CHECKPOINT_PATH` → `training/checkpoints/disease_detection/best_model.pt` (resolved from project root)
- `_build_model()` — EfficientNet-B0 (`weights=None`) + head `Linear(1280, 11)` (mirrors `training/models/registry.py`)
- `_build_transform()` — `Resize(224,224)` → `ToTensor` → ImageNet `Normalize` (matches training)
- `DiseasePredictor` — thread-safe singleton; loads checkpoint once; falls back to random weights if checkpoint missing
- `predict(image_bytes)` — decode → transform → forward → softmax → top-1 + top-5, severity heuristic, returns dict with `disease` (EN), `disease_vi` (VI), `confidence`, `severity`, `top5`

**Design note:** class names are **hardcoded** — the checkpoint does **not** embed `class_names` (see §7). Correctness depends on the (verified) alphabetical alignment with training.

---

## 5. AI Pipeline

```
POST /ai/detect  (api/v1/ai.py:24)
   │  Form: tree_id,  File: image bytes
   ▼
AIService.detect_disease()                service.py:26
   │ 1. validate tree exists
   │ 2. save image to uploads/
   ▼
_run_detection(file_bytes)                service.py:65   ← REAL (working tree)
   ▼
DiseasePredictor.predict(bytes)           predictor.py:178
   │  Image.open(BytesIO) → RGB
   │  transform (224,224, Normalize)
   │  EfficientNet-B0 forward  (loaded from best_model.pt)
   │  softmax → argmax top-1 + top-5
   │  severity heuristic (_SEVERITY_MAP + 0.85 escalation)
   ▼
{ disease (EN), disease_vi (VI), confidence, severity, top5 }
   ▼
DetectionResult(disease=VI name, confidence, severity)     service.py:76
   ▼
disease_repo.create({tree_id, disease_name, severity, confidence, image_url})
   ▼
DetectionResponse {tree_id, image_url, detection, created_at}   → JSON response
```

---

## 6. Runtime Pipeline (what executes today)

**Working Tree (current):** REAL model → `AIService.detect_disease` → `_run_detection` → `DiseasePredictor.predict` → `best_model.pt`.

**Git HEAD (committed):** MOCK → `AIService.detect_disease` → `_mock_detection` → `random.choice` over 6 canned diseases.

- HEAD flow cannot import `predictor.py` (file absent).
- If the working tree is deployed/run as-is, **real inference executes today**.

Verified live (this audit, working tree, 6 real upload images):

| Image | Prediction | Confidence | Severity |
|---|---|---|---|
| 4 uploads | `Healthy` | 0.5991–0.7465 | none |
| 2 uploads | `canker_disease` | 0.4766 | high |

---

## 7. Model Loading Verification (predictor.py)

| Artifact the task listed | Loaded by predictor.py? | Details |
|---|---|---|
| `best_model.pt` | **YES** | `_load_model()` via `torch.load(weights_only=False)`; strict `load_state_dict`; verified loads (11-class head) |
| `metadata.json` | **NO** | Does not exist for disease model (only `training/model3/exports/metadata.json` for the tabular model). Class names hardcoded in `CLASS_NAMES` |
| `label_encoder.pkl` | **NO** | Does not exist for disease model (only `training/model3/exports/label_encoder.pkl`). No encoding step needed — labels are a fixed list |
| preprocessing | **YES (hardcoded)** | `_build_transform()`: `Resize(224,224)`, `ToTensor`, `Normalize(0.485,0.456,0.406 / 0.229,0.224,0.225)` — matches `model1.yaml` |
| postprocessing | **YES (hardcoded)** | softmax → argmax → top-5 → `_SEVERITY_MAP` + 0.85 escalation |

**Label-order consistency (verified this audit):**
- Training index order: `ImageClassificationDataset._build_class_index()` uses `sorted()` on class directories → alphabetical. `train.py` passes no `class_names` override; `final_report.py` also uses `sorted([...])`.
- `training/reports/model_info.json` `class_names` == `predictor.py` `CLASS_NAMES` (identical, 11 names, alphabetical, incl. the `stem_cracking_ gummosis` typo).

⇒ The index↔label mapping matches between training and inference. Predictions are not permuted.

---

## 8. Git Status

```
$ git status --short
 M backend/app/ai/service.py      ← modified, NOT staged, NOT committed
?? backend/app/ai/predictor.py    ← untracked, never in git history
 M backend/app/dashboard/service.py      (unrelated)
 M backend/seed_demo.py                  (unrelated)
 M dga_mobile/... (6 dart files)         (unrelated)
?? docs/reports/AI_MODEL_DEPLOYMENT_AUDIT.md  (untracked)
```

- `git diff --cached --stat` → empty ⇒ **nothing staged**.
- `git log --oneline --all -- backend/app/ai/predictor.py` → empty ⇒ **predictor.py has never been committed**.
- `git log --oneline -3 -- backend/app/ai/service.py` → last commit touching service.py: `b678f35 feat: add backend and frontend modules`.

**Answer:**
- `predictor.py`: working tree only (untracked).
- `service.py`: modified in working tree only; unstaged; uncommitted.
- Neither is staged; neither is committed.

---

## 9. Integration Percentage

Disease-detection feature, end-to-end:

| Layer | HEAD | Working Tree |
|---|---|---|
| Entry point `/ai/detect` | ✓ | ✓ |
| Real model loading | ✗ | ✓ |
| Real inference | ✗ | ✓ |
| Postprocessing (severity, top5) | ✗ | ✓ |
| Response building | ✓ | ✓ |
| Persistence to DB | ✓ | ✓ |
| Error handling | ✗ (none) | ✓ (graceful fallback) |
| Input validation | ✗ | ✗ |
| Committed to git | ✗ | ✗ |

**Overall: 75%.**
- The **code** for the detection integration is **100% done** in the working tree (verified running).
- It is **0% deployed** because it is **uncommitted** and **0% robust** because input validation is missing.
- Quality-check and chat remain mock (out of scope for disease detection, but part of "AI" completeness).

---

## 10. Runtime Readiness

**Answer: YES.**

The backend can already run the real AI **without writing additional code**:
- `predictor.py` imports cleanly; `DiseasePredictor()` singleton loads `best_model.pt` and infers on CPU (torch 2.11.0+cpu present).
- `service.py` working-tree code resolves (`from app.ai.predictor import DiseasePredictor`) and `detect_disease()` executes the real path (verified live).
- No `predictor` → falls back to `"Không xác định" / 0.0 / low` instead of crashing.

**Caveats (do not change the YES):** invalid/non-image bytes raise `PIL.UnidentifiedImageError` → HTTP 500 (no validation at endpoint); the path relies on the project-root relative `_CHECKPOINT_PATH`; torch CPU latency not benchmarked.

---

## 11. Remaining Missing Parts

1. **Commit** `service.py` + `predictor.py` (the integration is currently 100% local).
2. **Input validation** at `/ai/detect`: file extension/MIME check, byte-size cap, catch `UnidentifiedImageError` → 400. This is the one real code gap on the detection path.
3. **Backend test coverage** for the real path (there is no test exercising `_run_detection`).
4. **Package model artifact** (`best_model.pt` is referenced by relative path; no versioning/fingerprint check at load time).
5. **Out of scope for detection but missing:** wire `training_quality` model into `/ai/image-quality` (still mock); replace `OllamaService._mock_chat`.
6. **Frontend contract:** backend returns Vietnamese `disease` inside `detection.*`, frontend `DetectionResult` type uses `disease_name` — resolve before frontend consumes the endpoint.

---

## 12. Next Required Action

**Choice: B — Small fixes required.**

- The mock has been functionally replaced (code complete and verified).
- Only small fixes are needed before/at commit time: (a) add input validation so bad images return 400 not 500, (b) optionally add a smoke test, then (c) **commit** the two files.
- If validation is deferred, the minimum path is **A (just commit)** — but B is the accurate classification because at least the input-validation fix should land with the integration.

---

## Final Conclusion

The real disease-detection AI is **fully integrated in the Working Tree and executes real inference today**; only Git is outdated. The committed `_mock_detection()` remains on disk solely because the working-tree change is uncommitted. Model, labels, preprocessing, and exports were re-verified consistent (alphabetical 11-class mapping; checkpoint loads strictly; live predictions `Healthy` / `canker_disease`). Remaining work is small (validation + tests), followed by committing `service.py` and `predictor.py`. **Do NOT modify model files or mock code — the mock is already dead; it just needs a commit.**
