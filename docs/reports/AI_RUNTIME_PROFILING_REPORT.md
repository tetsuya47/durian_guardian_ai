# AI Runtime Profiling Report — Durian Guardian

- **Date:** 2026-08-01
- **Analyst role:** Lead AI Runtime Performance Engineer / Backend Debugging Specialist
- **Mode:** Read-only. No business logic modified, no functions replaced, no refactoring, no optimization, no commit, no push.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`
- **Backend entry point:** `backend/run.py` (`uvicorn app.main:app`)

---

## 1. Executive Summary

The complete AI inference pipeline was traced and instrumented with **per-stage runtime timers and a 10-second watchdog**. Every stage was measured separately: image decode, preprocessing, model loading, inference, postprocessing, JSON serialization, full predict, full `/api/v1/ai/detect` endpoint, and concurrent request behavior.

**Primary finding — no single pipeline stage exceeds 10 s on this machine, and the pure compute pipeline is fast (40 ms–0.8 s). The perceived "hang" is an architectural latency amplifier, not a slow model.**

Three evidence-backed mechanisms convert these fast stages into a *perceived hang*:

1. **Cold model load runs synchronously inside an async request handler.** `AIService.__init__` → `DiseasePredictor()` → `torch.load()` executes on uvicorn's single event-loop thread. During the first request the *entire* API freezes. Measured here: a concurrent `/health` request was blocked **193 ms**; on weaker hardware / cold disk / antivirus scanning a 48 MB checkpoint, this becomes seconds for *every* endpoint.
2. **Synchronous CPU-bound inference + preprocessing inside the async handler.** Every `predict()` blocks the event loop for its full duration. Measured: a `/health` request was blocked **397 ms** while one large-image detect ran, and a small detect was fully serialized behind a huge one (both completed together at ~1.36 s).
3. **Oversized images amplify decode/preprocess super-linearly with resolution.** 4000×3000 ≈ 0.25 s CPU, 8000×6000 ≈ 0.6–0.8 s CPU and **+183 MB transient RSS**. There is no size/dimension guard on the upload endpoint.

Secondary findings: torch uses 8 threads and pins **~7.5 cores (751 % CPU)** per inference (concurrency oversubscription), and the model **is** cached globally (loaded once, not per request) — but only after the first, blocking request.

**Verdict:** The bottleneck is *where* the work runs (synchronously on the event loop, cold-loaded on first request, unbounded input size), not the model itself.

---

## 2. Runtime Timeline (measured on this machine)

```
POST /api/v1/ai/detect            (cold, first request ever)
 ├─ file.read()                    ~ 1–5 ms        (multipart body)
 ├─ _validate_image() img.verify() ~ 0.1–28 ms     (header check, not full decode)
 ├─ AIService(db)                  ← BLOCKS EVENT LOOP
 │    └─ DiseasePredictor() cold     ~ 180 ms       (torch.load 96 ms + load_state_dict)
 ├─ tree_repo.get(tree_id)         ~ 2 ms           (MongoDB)
 ├─ save upload                    ~ 1–5 ms
 ├─ _run_detection() → predict()   ← BLOCKS EVENT LOOP
 │    ├─ decode (Image.open+convert) ~ 3–360 ms     (grows with resolution)
 │    ├─ preprocess (Resize224+ToTensor+Norm) ~ 12–480 ms
 │    ├─ inference (forward, CPU)      ~ 50–90 ms   (fixed 224×224)
 │    └─ postprocess (softmax/argmax/topk) ~ 2–3 ms
 ├─ disease_repo.create()          ~ 1–17 ms
 ├─ disease_repo.get()             ~ 2 ms
 └─ success_response() JSON        ~ 1 ms
```

On warm (model cached): the same flow minus model load ⇒ **41 ms wall / 27 ms processing** for a 512×512 image; **~1.2 s wall / ~0.78 s processing** for an 8000×6000 image.

---

## 3. Pipeline Diagram

```
 Client
   │  multipart (tree_id + file)
   ▼
 FastAPI endpoint  app/api/v1/ai.py:46 detect_disease (async)
   │  file.read()
   │  _validate_image()  app/api/v1/ai.py:29  (PIL Image.open + img.verify())
   │  AIService(db)      app/ai/service.py:35  → DiseasePredictor()  [COLD LOAD]
   │       └─ DiseasePredictor.__init__  predictor.py:135
   │            └─ _load_model()         predictor.py:151
   │                 └─ torch.load(...)  predictor.py:158   ← SYNCHRONOUS, BLOCKS LOOP
   ▼
 AIService.detect_disease()  service.py:45 (async)
   │  tree_repo.get(tree_id)                       (await → loop free)
   │  save file to uploads/
   │  _run_detection(file_bytes)  service.py:86 (SYNC — blocks loop)
   │       └─ DiseasePredictor.predict()  predictor.py:178 (SYNC)
   │            ├─ Image.open(io.BytesIO(...)).convert("RGB")   predictor.py:190  decode
   │            ├─ _transform(img)                                preprocess
   │            ├─ with torch.no_grad(): logits = model(tensor)   forward
   │            ├─ softmax / argmax / topk                        postprocess
   │            └─ build result dict
   │  disease_repo.create() / get()                 (await → loop free)
   ▼
 success_response() → JSONResponse (serialize JSON) → HTTP 200
```

---

## 4. Stage Timing Table

Measurements on: Python 3.13.12, torch **2.11.0+cpu** (no CUDA), torchvision 0.26.0+cpu, Pillow 12.1.1, `torch.get_num_threads()=8`. Checkpoint `best_model.pt` = **48.73 MB**. 10 s watchdog **never triggered**.

### 4.1 Model loading (STEP 4)

| Stage | Elapsed (ms) |
|---|---|
| `_build_model()` (EfficientNet-B0 + 11-class head) | 126 |
| `torch.load(checkpoint, map_location=cpu, weights_only=False)` | 96 |
| build + torch.load + `load_state_dict(strict=True)` | 214 |
| **Cold `DiseasePredictor()` full init** | **158–210** (CPU ~156 ms) |
| **Warm `DiseasePredictor()` re-init** | **0.00** → cached |

### 4.2 Per-image-size stages (STEP 5, STEP 8)

| Stage | 512×512 | 1024×1024 | 4000×3000 | 8000×6000 |
|---|---|---|---|---|
| File size (JPEG, test) | 0.05 MB | 0.21 MB | 1.8–2.0 MB | 2.7–3.5 MB |
| Image decode (`Image.open().convert("RGB")`) | 3 ms | 11 ms | 93 ms | **263–357 ms** |
| Preprocess (Resize 224 + ToTensor + Normalize) | 12 ms | 13 ms | 164 ms | **157–481 ms** |
| Inference (model forward, CPU, fixed 224×224 tensor) | ~60 ms | ~52 ms | ~47 ms | ~52 ms |
| Postprocess (softmax + argmax + topk) | 3 ms | 2 ms | 3 ms | 3 ms |
| **Full `predict()` (3-run avg)** | **38.9 ms** | **41.2 ms** | **146.3 ms** | **464.0 ms** |

### 4.3 API (STEP 6) — live server, keep-alive HTTP

| Request | Wall (client) | `processing_time_ms` (reported) | Server overhead* |
|---|---|---|---|
| GET `/health` keep-alive | ~2 ms | — | — |
| `/ai/detect` warm 512×512 | 41 ms | 27 ms | ~14 ms |
| `/ai/detect` warm 4000×3000 | 517–665 ms | 165–309 ms | — |
| `/ai/detect` warm 8000×6000 | 1183–1246 ms | 759–778 ms | — |
| `/ai/detect` **cold (first ever)** | 643–673 ms | 70 ms | ~180 ms model load |

\* multipart parse + validation + DB ops + JSON encode. DB ops measured locally: tree get 2.4 ms, disease insert 0.9–17 ms, disease get 1.9 ms. JSON `json.dumps(prediction)` = 0.7 ms (570 bytes).

**Note:** the reported `processing_time_ms` only covers `predict()` (service.py:92–99), *not* the full pipeline, so clients are told ~27 ms while the real end-to-end cost (incl. model load on first call) is much larger.

---

## 5. Slowest Stage

**Image decode + preprocessing for large uploads** is the slowest *compute* stage: 0.5–0.8 s of pure CPU at 8000×6000. It scales with input resolution and is **unbounded** — there is no size check. On the first request, **model loading (~180 ms, synchronous)** is the single most disruptive stage because it blocks the event loop while everything else waits.

---

## 6. Blocking Function

Runtime evidence (stack samples at timeout/concurrency windows + wall-clock per stage) identifies the exact synchronous call sites that block the uvicorn event loop:

| # | Function | File:Line | When |
|---|---|---|---|
| 1 | `DiseasePredictor._load_model` → `torch.load(...)` | `app/ai/predictor.py:151` → `:158` | Cold (first request) |
| 2 | `DiseasePredictor.predict` → `Image.open(...).convert("RGB")` | `app/ai/predictor.py:178` → `:190` | Every request |
| 3 | `AIService._run_detection` → `self._predictor.predict(...)` | `app/ai/service.py:86` → `:94` | Every request (sync call inside async method) |
| 4 | `AIService.detect_disease` → `_run_detection(...)` | `app/ai/service.py:45` → `:62` | Every request |
| 5 | endpoint `detect_disease` → `AIService(db)` | `app/api/v1/ai.py:46` → `:58` | Cold model load trigger |

All of 1–4 execute on uvicorn's **single event-loop thread**. Concurrency test evidence: `/health` blocked **193 ms** during cold load and **397 ms** during a warm huge-image detect (baseline 2–7 ms).

---

## 7. CPU Usage (STEP 7)

- `torch.get_num_threads()` = **8** (default), inter-op threads = 8.
- **20× `predict()` on 1024×1024: wall 729 ms, CPU time 5,469 ms ⇒ 751 % utilization (~7.5 cores pinned per inference).**
- Cold model load: ~100 % single-core (kernel 94 ms + user 62 ms).
- Consequence: each inference saturates all cores. Under concurrent requests, threads oversubscribe → wall time inflates super-linearly; the event loop additionally serializes all requests.

---

## 8. Memory Usage (STEP 7)

| Point | RSS |
|---|---|
| After `import torch`/`torchvision` | ~270 MB (baseline) |
| After cold model load | +73 MB (→ ~342 MB) |
| Transient 8000×6000 PIL decode | **+183 MB** per image |
| Final (post GC, various allocs) | ~538 MB |

No memory *leak* observed (RSS returned to baseline after decode). Pressure driver: oversized uploads each temporarily claim ~180 MB+; several concurrent large uploads risk swap/slowdown.

---

## 9. Model Loading Analysis (STEP 4)

- **Loaded ONCE, not per request.** `DiseasePredictor` is a module-level thread-safe singleton (`predictor.py:123–133`); warm re-init measured **0.00 ms**; `cold is warm` instance verified.
- Cost of the one load: `torch.load` 96 ms + `load_state_dict` ≈ 158–210 ms total on this machine.
- **But the load is deferred to the first request and runs synchronously inside the async handler** (`service.py:40`), blocking the whole API during that window. A deployment with slower disk/CPU/antivirus turns 180 ms into multiple seconds — every endpoint hangs.

---

## 10. Inference Analysis (STEP 5)

- `predict()` = decode + preprocess + forward + postprocess. Forward (`torchvision efficientnet.forward`) is ~50–90 ms on CPU and is **independent of input size** (tensor fixed 224×224).
- cProfile (3× 1024×1024) confirms forward dominates predict time: `torch.conv2d` ~50 ms / 3 calls; PIL decode ~28 ms; resize ~16 ms.
- Real inference latency is **not** the bottleneck; `softmax`/`argmax`/`topk` total < 3 ms.

---

## 11. API Response Analysis (STEP 6)

- Keep-alive warm small detect: 41 ms wall vs 27 ms reported processing ⇒ ~14 ms server overhead (multipart + validate + 4 DB awaits + JSON). Healthy.
- Fresh-connection overhead on this host: ~20 ms (stdlib urllib); an `httpx` per-call client artifact added ~320 ms per request — not a server issue. **Clients should reuse connections (keep-alive).**
- Cold first detect: ~320 ms server work (~180 ms model load + ~70 ms predict + overhead); observed wall 643–673 ms with connection overhead included.
- No stage anywhere in the endpoint exceeded 10 s; the 10 s watchdog never fired.

---

## 12. Root Cause

**The model and inference are fast; the bottleneck is architectural:**

1. **Cold synchronous model load in an async handler** (`service.py:40` → `predictor.py:158`) freezes the single event loop on the first AI call.
2. **Synchronous CPU-bound inference/preprocessing in async handlers** (`service.py:62/94`, `predictor.py:178/190`) blocks the event loop for every request's full compute time; all concurrent traffic (health, dashboard, other users) queues behind it — the exact signature of "diagnosis appears to hang."
3. **Unbounded input resolution** turns decode+preprocess into the slowest stage (0.5–0.8 s CPU + 183 MB per 8000×6000 image) and multiplies the event-loop freeze.
4. **8-thread oversubscription (751 % CPU/inference)** amplifies wall time when requests overlap.

No single stage exceeds 10 s on this hardware; the "long hang" reproduces when (a) the first request loads the 48 MB checkpoint on slower I/O, and/or (b) large images are submitted under concurrent load.

---

## 13. Recommended Fix Order (analysis only — NOT implemented, per scope)

1. **Preload the model at app startup** (FastAPI lifespan/startup calls `DiseasePredictor()` once) so no request ever pays the load cost and the event loop is never blocked by it. *(Startup wiring only — no business-logic change.)*
2. **Offload the sync inference off the event loop** — call `predict()` via `asyncio.to_thread()`/`run_in_executor` in `_run_detection`. This alone removes the whole-API freeze under load.
3. **Bound input size at upload** (enforce `MAX_UPLOAD_SIZE_BYTES`, cap pixel dimensions before decode) since the model consumes a fixed 224×224 tensor. Removes the 0.8 s / 183 MB amplification.
4. **Set `torch.set_num_threads()` to physical core count** to stop 8-thread oversubscription during concurrent requests.
5. **Report true end-to-end `processing_time_ms`** (currently only `predict()` is measured, service.py:92–99), so latency is visible instead of masked.
6. **Client-side: reuse HTTP connections** (keep-alive) — fresh connections add ~20 ms locally and more on real networks.
7. *(Optional hardening)* Run inference in a separate worker/process to isolate CPU from the API event loop.

---

## Appendix A — Instrumentation method (temporary, removed after capture)

- A read-only harness (`profile_ai_runtime.py`) timed each stage with `time.perf_counter()` under a **10 s watchdog thread**; on timeout it captured the blocking stack via `sys._current_frames()`.
- A live API harness started the real backend on ports 8011–8015, logged in (`bao@gmail.com`), inserted a temporary tree, and measured `/api/v1/ai/detect` end-to-end plus concurrency.
- Windows-native RSS/CPU sampling via `GetProcessMemoryInfo` / `GetProcessTimes`.
- All test images (512→8000 px), temporary DB records, and uploads created for profiling were removed afterwards. **No source file was modified.**
