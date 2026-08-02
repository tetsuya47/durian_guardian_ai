# Weather Backend Architecture Audit — Durian Guardian AI (DGA)

- **Date:** 2026-08-02
- **Role:** Lead Backend Software Architect
- **Mode:** Read-only. No source code modified, no files created/deleted except this report, no packages installed, no commits, no database changes.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`
- **Backend entry point:** `backend/run.py` / `backend/run_server.py` (`uvicorn app.main:app`)

---

## 1. Executive Summary

The DGA FastAPI backend follows a clean **API → Service → Repository → MongoDB** layered architecture. **A weather module is already partially implemented and registered** — three new (untracked in git) files exist:

- `backend/app/api/v1/weather.py` (router, registered at `/api/v1/weather/current`)
- `backend/app/services/weather_service.py` (service with MongoDB cache-aside + risk rules)
- `backend/app/schemas/weather.py` (Pydantic response model)

Configuration for OpenWeather is already present in `app/core/config.py` (`OPENWEATHER_API_KEY`, `OPENWEATHER_BASE_URL`, `WEATHER_CACHE_TTL_MINUTES`), and the Flutter mobile app already has a weather feature consuming `GET /api/v1/weather/current`.

The backend is **architecturally ready** for full weather integration, but the current implementation has **three blockers / gaps** that must be resolved before it is production-consistent with the rest of the codebase:

1. **Repository-layer bypass** — `WeatherService` reads/writes `db["weather_cache"]` directly, instead of going through a `WeatherRepository(BaseRepository)` like every other collection.
2. **Blocking HTTP client** — `weather_service.py` uses synchronous `urllib.request`, which blocks the async event loop; the project already declares `httpx` (used for tests) and should reuse it.
3. **Secret committed in source** — a live-looking `OPENWEATHER_API_KEY` is hardcoded as the default in `config.py` instead of living only in `.env`.

Additional gaps: no `repositories/weather_repository.py`, no `models/weather.py` (risk levels are hardcoded strings), no `utils/openweather_client.py`, `weather_cache` is not registered in the central collection registry or index specs, and the Farm coordinate fields have a naming mismatch (`gps_lat`/`gps_lng` in the API layer vs `latitude`/`longitude` in the DB JSON-schema validator / ETL data).

**Verdict: YES — ready for integration**, with the specific gaps listed in §7 to be closed during implementation.

---

## 2. Architecture Diagram

```
                         ┌────────────────────────────────────────────┐
                         │              FastAPI (app.main)            │
                         │   CORS · exception handlers · startup hook │
                         └──────────────────┬─────────────────────────┘
                                            │  include_router(api_router)
                                            ▼
                        ┌──────────────────────────────────────────────┐
                        │        API layer   app/api/v1/              │
                        │   prefix="/api/v1"   · weather.py (exists)  │
                        │   auth, farms, zones, trees, ai, dashboard, │
                        │   history, chat, notifications, companies,  │
                        │   users, inspections, detection_results,    │
                        │   disease_history, diseases, alerts, admin  │
                        └──────────────────┬──────────────────────────┘
                                           │  DI: Depends(get_current_user_id)
                                           │      Depends(get_database)
                                           │      RoleChecker
                                           ▼
                        ┌──────────────────────────────────────────────┐
                        │      Service layer   app/services/           │
                        │   XxxService(db) · weather_service.py (exists)│
                        └──────────────────┬──────────────────────────┘
                                           │
                                           ▼
                        ┌──────────────────────────────────────────────┐
                        │   Repository layer  app/repositories/        │
                        │   BaseRepository · XxxRepository(db)          │
                        │   weather_repository.py  ← MISSING           │
                        └──────────────────┬──────────────────────────┘
                                           ▼
                        ┌──────────────────────────────────────────────┐
                        │      MongoDB  (Motor, async)                 │
                        │   MongoDBManager · get_database()            │
                        │   collections registry: database/db_schema.py│
                        │   index specs:     database/indexes.py       │
                        │   weather_cache  ← used, NOT registered      │
                        └──────────────────────────────────────────────┘
```

Supporting/cross-cutting layers:

```
app/core/        config.py · exceptions.py · exception_handlers.py · response.py
                 security.py · dependencies.py · logging.py
app/schemas/     Pydantic models (weather.py exists; NOT exported in __init__)
app/models/      enums only (UserRole, NotificationStatus, SeverityLevel)
app/database/    mongodb.py  →  MongoDBManager + get_database()
app/auth/        auth/service.py
app/ai/          service.py (AIService, OllamaService) · predictor.py
app/dashboard/   service.py · dto.py
app/utils/       EMPTY (no openweather_client.py)
```

---

## 3. Findings

### 3.1 Project architecture — confirmed pattern

The codebase implements exactly **API → Service → Repository → MongoDB**:

| Layer | Location | Convention |
|---|---|---|
| API | `backend/app/api/v1/*.py` | `router = APIRouter(prefix="/xxx", tags=["Xxx"])`; `success_response(...)` |
| Service | `backend/app/services/*.py` | `class XxxService` with `__init__(self, db)` |
| Repository | `backend/app/repositories/*.py` | `class XxxRepository(BaseRepository)`; collection name passed to super |
| Schema | `backend/app/schemas/*.py` | Pydantic `BaseModel`; re-exported via `schemas/__init__.py` barrel |
| Model | `backend/app/models/` | **enums only** (`enums.py`); no DB model classes — documents are plain `dict`s |
| Config | `backend/app/core/config.py` | `pydantic-settings` `Settings` + module-level `settings` singleton |
| DB | `backend/app/database/mongodb.py` | `MongoDBManager` singleton + `get_database()` FastAPI dependency |
| Utility | `backend/app/utils/__init__.py` | **empty** — no shared client utilities yet |

There is **no ORM/ODM model layer** (no MongoEngine/Beanie); Mongo documents are handled as raw dicts with a central JSON-schema validator in `database/db_schema.py`. A `weather.py` "model" would therefore follow the enum-only convention (e.g., a `WeatherRisk` enum), not a document model.

### 3.2 Environment configuration

- **`.env` support:** Yes. `Settings.model_config` sets `env_file=".env"`, `env_file_encoding="utf-8"`, `extra="ignore"` (`app/core/config.py:6-12`).
- **dotenv usage:** `python-dotenv==1.0.1` is pinned in `requirements.txt`; `pydantic-settings` (2.5.2) handles loading.
- **Settings class / loader:** `app/core/config.py::Settings`, instantiated once as `settings = Settings()`.
- **`.env` files:** `.env` and `.env.example` are gitignored; **no `.env` or `.env.example` exists in the repository.**
- **OpenWeather settings — already present:**
  - `OPENWEATHER_API_KEY` — **default value is a real-looking key hardcoded in source** (`config.py:35`). This is a security finding: the key is not stored only in `.env`.
  - `OPENWEATHER_BASE_URL`, `WEATHER_CACHE_TTL_MINUTES` (15 min) also present.
- **Recommendation:** store `OPENWEATHER_API_KEY` only in `.env` (with a `.env.example` placeholder), and change the source default to an empty string with an explicit check (mirroring the existing `JWT_SECRET_KEY` production guard at `config.py:58-65`).

### 3.3 HTTP client

- The project declares **`httpx==0.27.2`** in `backend/requirements.txt` (used for tests via `ASGITransport` in `conftest.py`).
- `requests` and `aiohttp` are **not** declared or used.
- The current `weather_service.py` uses **`urllib.request`** — synchronous and blocking. `urlopen(timeout=8)` runs on the async event loop, freezing concurrent requests for up to 8 s on a slow OpenWeather response. This is the same class of issue documented in `docs/reports/AI_RUNTIME_PROFILING_REPORT.md` (blocking work on the event loop).
- **Recommendation:** reuse `httpx.AsyncClient` (already a pinned dependency) with a shared client, so no new dependency is added and the async event loop is not blocked.

### 3.4 MongoDB

- **Manager:** `MongoDBManager` singleton with lazy `get_client()` / `get_db()` (`app/database/mongodb.py`); DI via `get_database()`.
- **Collections:** centrally registered in `database/db_schema.py::Collections` (15 collections). **`weather_cache` is NOT registered.**
- **Indexes:** centrally defined in `database/indexes.py::get_index_specs()`, applied by ETL/import scripts (`database/etl_pipeline.py:1590`, `scripts/import_excel_to_mongodb.py:148`). **No index spec exists for `weather_cache`** — there is no TTL index to expire stale cache entries.
- **Repositories:** `BaseRepository` (CRUD + serialization) and per-collection repositories. `weather_cache` is accessed directly via `self.db["weather_cache"]` in the service, bypassing the layer.
- **Fit:** A `weather_cache` collection fits the architecture naturally once it is (a) added to `Collections`, (b) given an index spec (recommend a TTL index on `updated_at`), and (c) accessed through a `WeatherRepository`.

### 3.5 Farm data (coordinates)

Coordinates **exist**, but under two different field names depending on the write path:

- API/Schema layer: `gps_lat` / `gps_lng` — `app/schemas/farm.py:11-12`, written by `app/services/farm_service.py:48-51`.
- DB validator / ETL seed data: `latitude` / `longitude` — `database/db_schema.py:145-146` (farm validator) and `database/db_schema.py:184-185` (tree validator).

**Missing / inconsistent:** there is no single canonical coordinate field; the DB JSON-schema validator expects `latitude`/`longitude` while the CRUD service writes `gps_lat`/`gps_lng`. The weather router currently does **not** read farm coordinates at all — it uses hardcoded defaults (Buôn Ma Thuột 12.6667, 108.0500) passed as query parameters (`app/api/v1/weather.py:23-24`). Before the weather service can auto-locate a farm, this field mismatch must be reconciled (pick one canonical name, or support both with a fallback).

### 3.6 Existing scheduler

**None.** The backend has:
- No APScheduler / cron / periodic worker.
- No `BackgroundTasks`, no `asyncio.create_task` worker loop.
- Only a startup hook `@app.on_event("startup")` that seeds the admin user (`app/main.py:61-84`).

Weather refresh is **cache-aside** (lazy fetch + TTL cache inside the request). There is **no reusable scheduler component**; a background refresh loop (APScheduler or a simple asyncio task started from the existing startup hook) would be a new addition.

### 3.7 API versioning

- All routers are mounted under `api/v1` via `api_router = APIRouter(prefix="/api/v1")` and registered in `backend/app/api/v1/__init__.py`.
- `weather.py` is **already registered** there (`__init__.py:20,41`), exposing `GET /api/v1/weather/current`.
- The mobile app expects `GET /weather/current` (`dga_mobile/lib/core/network/api_endpoints.dart:79`). Registration location is correct — no change needed.

### 3.8 Coding style conventions

| Aspect | Convention (observed) | Weather module compliance |
|---|---|---|
| Repository naming | `class XxxRepository(BaseRepository)` | ✗ Missing entirely |
| Service naming | `class XxxService` with `__init__(self, db)` | ✓ `WeatherService(db)` |
| Schema naming | `XxxResponse` / `XxxCreate`; exported in `schemas/__init__.py` | ⚠ `WeatherCurrentResponse` exists but is **not** exported in the barrel |
| Router naming | `router = APIRouter(prefix="/xxx", tags=["Xxx"])` | ✓ |
| Dependency injection | `Depends(get_current_user_id)`, `Depends(get_database)`, `RoleChecker` | ✓ |
| Response models | `success_response(data=..., message=...)` + `SuccessResponse[T]` | ✓ |
| Exception handling | Raise `AppException` subclasses (`app/core/exceptions.py`) | ⚠ Service swallows upstream errors and returns mock fallback instead of raising |
| Logging | `logger = logging.getLogger(__name__)` | ✓ |
| File header | `from __future__ import annotations` | ✓ |

### 3.9 Weather integration compatibility

Requested module structure vs. current state:

| Requested file | Status |
|---|---|
| `backend/app/api/v1/weather.py` | **Exists** (untracked, registered) |
| `backend/app/services/weather_service.py` | **Exists** (untracked; uses `urllib`; bypasses repository) |
| `backend/app/repositories/weather_repository.py` | **Missing** |
| `backend/app/schemas/weather.py` | **Exists** (untracked; not barrel-exported) |
| `backend/app/models/weather.py` | **Missing** (follows enum-only model convention) |
| `backend/app/utils/openweather_client.py` | **Missing** (utils package is empty) |

The module structure is **compatible in principle** — it matches the existing layer layout. Required changes for full consistency: add the repository, move HTTP I/O into a client util (or the service) using `httpx`, register the collection/index, export the schema, and add a risk-level enum.

### 3.10 AI compatibility (Model 3)

- **Model 3** (tabular disease-risk prediction) already trains/predicts on weather features: `temperature`, `humidity`, `rainfall` (`training/train_model3.py:76`, `training/predict_model3.py:108-110`, `training/datasets/build_model3_dataset.py`). Today it sources these from inspection records, **not** from `weather_cache`.
- **`ChatService`** (`backend/app/services/chat_service.py:42-50`) already builds a prompt with a `"Weather Data (last 3 days)"` section whose value is currently the placeholder `"No weather data"` — a clear integration point that has been left unwired.
- Because the weather module persists processed data to MongoDB (`weather_cache`), Model 3 / the AI services can consume it **through a repository, exactly like `DiseaseRepository`/`TreeRepository`**, without ever calling OpenWeather directly. The architecture supports this today; only the repository wiring is missing.

---

## 4. Compatibility Analysis

| Integration concern | Status | Detail |
|---|---|---|
| Layer structure matches `API→Service→Repository→MongoDB` | ✅ Compatible | Weather files live in the correct directories |
| Router registration / versioning | ✅ Compatible | `/api/v1/weather/current` already mounted; mobile already consumes it |
| Configuration / `.env` | ⚠ Compatible w/ fixes | Settings exist; hardcoded key must move to `.env` |
| HTTP client | ⚠ Needs change | Reuse declared `httpx`; drop blocking `urllib` |
| MongoDB cache collection | ⚠ Needs wiring | `weather_cache` used directly; register + index + repository |
| Farm coordinates | ⚠ Needs reconciliation | `gps_lat/gps_lng` (API) vs `latitude/longitude` (DB) mismatch; not yet auto-sourced from Farm |
| Scheduler / periodic refresh | ❌ Not present | No scheduler exists; must be added if background refresh is required |
| AI / Model 3 consumption | ✅ Compatible | Mongo-backed weather data readable via repository; ChatService slot already reserved |

---

## 5. Missing Components

1. **`backend/app/repositories/weather_repository.py`** — `WeatherRepository(BaseRepository)` for `weather_cache` (get by cache key, upsert, TTL-aware read), matching the existing repository pattern.
2. **`backend/app/models/weather.py`** — `WeatherRisk` enum (`LOW` / `MEDIUM` / `HIGH`) replacing hardcoded risk strings, following the enum-only model convention.
3. **`backend/app/utils/openweather_client.py`** (or equivalent in the service) — async `httpx.AsyncClient` wrapper with timeout + JSON decoding; no new dependency (httpx already pinned).
4. **Collection registration** — add `WEATHER_CACHE = "weather_cache"` to `database/db_schema.py::Collections`.
5. **Index spec** — add `weather_cache` to `database/indexes.py` (recommend TTL index on `updated_at`, e.g., `expireAfterSeconds` = a few days, keyed on `updated_at`).
6. **Schema barrel export** — add `WeatherCurrentResponse` to `app/schemas/__init__.py`.
7. **Farm coordinate wiring** — reconcile `gps_lat/gps_lng` vs `latitude/longitude` and make the weather endpoint source coordinates from the Farm document (with fallback to the Buôn Ma Thuột default).
8. **Secret management** — move `OPENWEATHER_API_KEY` to `.env`; add `.env.example`; empty default + production guard in `Settings`.
9. **Scheduler (optional)** — background refresh of `weather_cache` (e.g., APScheduler or an `asyncio` task started in the existing startup hook), if live data freshness beyond the 15-min lazy cache is required.
10. **Tests** — no `tests/test_weather.py` exists; the module currently has zero test coverage.

---

## 6. Recommendations

1. **Reuse `httpx.AsyncClient`** (already in `backend/requirements.txt`) instead of `urllib.request`; share one client (lifespan-scoped) to avoid per-request connection setup and to keep the event loop non-blocking.
2. **Route all `weather_cache` access through `WeatherRepository(BaseRepository)`** so the weather module honors the same layering as every other feature.
3. **Treat `weather_cache` as a first-class collection**: register it in `Collections`, add a TTL index on `updated_at`, and consider a unique index on the cache key (`_id`).
4. **Do not hardcode the API key.** Empty default + `.env` value + `.env.example`; mirror the existing `JWT_SECRET_KEY` production guard. Rotate the exposed key if it is live.
5. **Canonicalize farm coordinates.** Either adopt `latitude`/`longitude` (matching the DB validator and ETL data) or update the validator — then have the weather router resolve the Farm and pass its coordinates into `WeatherService` instead of hardcoded query defaults.
6. **Preserve the cache-aside design** (MongoDB TTL cache + lazy refresh); only add a scheduler if forecast/history or cross-farm prefetch is required.
7. **Wire the AI slot:** populate `ChatService`'s `"Weather Data (last 3 days)"` section from `weather_cache` via `WeatherRepository`, and extend Model 3's dataset builder to join `weather_cache` for the `temperature` / `humidity` / `rainfall` features.
8. **Add tests** following `backend/tests/*` conventions (`httpx.AsyncClient` + `ASGITransport`, `conftest.py` fixtures), mocking the OpenWeather HTTP call.

---

## 7. Final Verdict

**YES — the backend architecture is ready for Weather (OpenWeather) integration.**

The layered `API → Service → Repository → MongoDB` architecture, the `/api/v1` versioning, the Pydantic-settings config, the Motor MongoDB manager, and the AI consumption pattern (repositories reading Mongo) are all directly compatible. A functional weather module already exists and is registered; the remaining work is **consistency hardening, not re-architecture**.

**Remaining implementation steps (no blockers to the architecture itself):**

1. Add `WeatherRepository(BaseRepository)` and route all `weather_cache` reads/writes through it.
2. Move HTTP I/O to `httpx.AsyncClient` (reuse existing dependency) in `utils/openweather_client.py`.
3. Register `weather_cache` in `db_schema.py::Collections` and add a TTL index in `database/indexes.py`.
4. Add `WeatherRisk` enum in `models/weather.py`; export `WeatherCurrentResponse` in `schemas/__init__.py`.
5. Move `OPENWEATHER_API_KEY` to `.env` (+ `.env.example`), remove the hardcoded default, add a production guard.
6. Reconcile farm coordinate fields and source them from the Farm document in the weather router.
7. Optionally add a background cache-refresh scheduler.
8. Wire `weather_cache` into `ChatService` and Model 3 dataset features; add `tests/test_weather.py`.

> Note: three of the weather files (`api/v1/weather.py`, `schemas/weather.py`, `services/weather_service.py`) are currently **untracked** in git (`git status` shows them as `??`), while `api/v1/__init__.py` and `core/config.py` carry uncommitted modifications. Ensure these are reviewed and committed as part of the weather integration.
