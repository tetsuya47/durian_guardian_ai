# Weather Backend Foundation Report — Durian Guardian AI (DGA)

- **Date:** 2026-08-02
- **Role:** Lead Backend Software Architect
- **Mode:** Safe refactor (no contract changes). No new dependencies, no git commit, no push.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`
- **Preceded by:** `docs/reports/WEATHER_BACKEND_ARCHITECTURE_AUDIT.md` (read-only audit, 2026-08-02)
- **Scope:** Close the gaps identified in §5/§6 of the audit — repository layer, async HTTP client, secret hygiene, collection/index registration, farm coordinate resolution — while keeping `GET /api/v1/weather/current` byte-compatible with the Flutter client.

---

## 1. Files Modified

| File | Change | Why |
|---|---|---|
| `backend/app/core/config.py` | `OPENWEATHER_API_KEY` default changed from a hardcoded key to `""`. `OPENWEATHER_BASE_URL` + `WEATHER_CACHE_TTL_MINUTES` kept unchanged. | Secret hygiene: the key may now live only in `.env` / environment. Empty default means an unconfigured server fails fast with a graceful fallback instead of sending a committed key. |
| `backend/app/api/v1/weather.py` | Added optional `farm_id` query param + `_resolve_coords()` helper supporting both `gps_lat/gps_lng` and `latitude/longitude`; source coordinates from the Farm document with fallback to the Buôn Ma Thuột defaults. Endpoint path, method, and response contract unchanged. | Auto-locate a farm's weather instead of always using hardcoded defaults; reconcile the two coordinate naming schemes found in the codebase. |
| `backend/app/api/v1/__init__.py` | `weather_router` import + `include_router(weather_router)`. | Registers `GET /api/v1/weather/current` (pre-existing wiring, retained). |
| `backend/app/schemas/__init__.py` | Barrel-exported `WeatherCurrentResponse`. | Matches the schema barrel convention used by every other feature. |
| `database/db_schema.py` | Added `Collections.WEATHER_CACHE = "weather_cache"` + appended to `Collections.all()` (now 16 collections). | Central collection registry — `weather_cache` is now a first-class collection. |
| `database/indexes.py` | Added 3 `weather_cache` index specs: `idx_weather_cache_farm_id`, `idx_weather_cache_updated_at_desc`, and TTL index `idx_weather_cache_updated_at_ttl` (`expireAfterSeconds: 86400`). | Indexes for farm lookups, recency sorts, and automatic expiry of stale cache entries. |

## 2. Files Created

| File | Purpose |
|---|---|
| `backend/app/repositories/weather_repository.py` | `WeatherRepository(BaseRepository)` for `weather_cache`. Pure data access — cache-key builder, `get_by_coords`, `get_by_farm_id`, `create_weather`, `update_weather`, `delete_expired(ttl_minutes)`, `upsert_weather` (atomic `replace_one` upsert keyed by `_id`), `find_latest`. No business logic. |
| `backend/app/utils/openweather_client.py` | `OpenWeatherClient` + `OpenWeatherClientError`. Minimal async `httpx.AsyncClient` wrapper (`timeout=8.0`) with `get_current_weather()` → `/weather` and `get_forecast()` → `/forecast`; params `lat`, `lon`, `appid`, `units=metric`, `lang=vi`. Raises `OpenWeatherClientError` when the API key is unset or HTTP fails. No business logic, no Mongo access. |

## 3. Architecture Before

```
GET /api/v1/weather/current
   │
   ▼
app/api/v1/weather.py  (router, hardcoded default lat/lon; no farm lookup)
   │
   ▼
app/services/weather_service.py
   │   · reads/writes db["weather_cache"] DIRECTLY (bypasses repository layer)
   │   · calls OpenWeather via blocking synchronous urllib.request (freezes event loop)
   │   · uses a real-looking API key hardcoded in config.py
   ▼
MongoDB (weather_cache)          OpenWeatherMap (urllib, sync)
```

Gaps closed by this foundation: repository bypass, blocking HTTP, secret-in-source, unregistered collection, missing indexes, farm coordinate mismatch.

## 4. Architecture After

```
GET /api/v1/weather/current?farm_id=&lat=&lon=
   │  Depends(get_current_user_id) · Depends(get_database) · RoleChecker
   ▼
app/api/v1/weather.py
   │   _resolve_coords(farm, lat, lon): gps_lat/gps_lng → latitude/longitude → fallback
   ▼
app/services/weather_service.py
   │   1. WeatherRepository.get_by_coords()      ← cache lookup (TTL via settings.WEATHER_CACHE_TTL_MINUTES)
   │   2. OpenWeatherClient.get_current_weather() ← async httpx (cache miss)
   │   3. _process_current_weather() + _analyze_durian_risk()   ← business logic
   │   4. WeatherRepository.delete_expired() + upsert_weather() ← cache write
   ▼
app/repositories/weather_repository.py   (BaseRepository, collection "weather_cache")
   ▼
MongoDB                                   OpenWeatherMap (httpx.AsyncClient, async)

app/utils/openweather_client.py          (pure HTTP; settings.OPENWEATHER_API_KEY)
```

The module now follows the project-wide `API → Service → Repository → MongoDB` layering exactly, with all external HTTP I/O isolated behind `OpenWeatherClient` and all Mongo I/O behind `WeatherRepository`.

## 5. Repository Verification

Verified against the live MongoDB (`127.0.0.1:27017`, db `durian_guardian_ai`) via a throwaway script under `%TEMP%\opencode\test_weather_service_flow.py`:

- Cache miss → OpenWeatherClient called → processed result returned; second call hits cache (client invoked only once).
- TTL expiry: `delete_expired(0)` removes entries older than the (zero) cutoff; fresh entries survive.
- `upsert_weather` creates and later updates the same `_id`; `create_weather`/`update_weather`/`get_by_farm_id`/`find_latest` all return/round-trip correctly.
- `build_cache_key` → `weather_{lat:.2f}_{lon:.2f}` (e.g. `weather_12.67_108.05`).
- Business rule verified: humidity 88 / temp 31.2 → `fungal_disease_risk == "HIGH"`.
- Test data cleaned afterward; `weather_cache` count back to 0.

## 6. HTTP Client Verification

Verified against a local `http.server` mock (`%TEMP%\opencode\test_openweather_client.py`):

- `GET {base_url}/weather` and `GET {base_url}/forecast` hit the expected paths.
- Query params `lat`, `lon`, `appid`, `units=metric`, `lang=vi` are sent exactly once.
- Missing/unset `OPENWEATHER_API_KEY` → `OpenWeatherClientError("OPENWEATHER_API_KEY is not configured…")`.
- No `urllib`, `requests`, or `aiohttp` remains in `backend/app`; only `httpx==0.27.2` (already pinned in `requirements.txt`) is used — **no new dependency**.

## 7. MongoDB Verification

- `weather_cache` added to `database/db_schema.py::Collections`; `Collections.all()` returns 16 collections including it.
- Index specs added in `database/indexes.py`; names and TTL confirmed by importing the module (`idx_weather_cache_farm_id`, `idx_weather_cache_updated_at_desc`, `idx_weather_cache_updated_at_ttl` with `expireAfterSeconds=86400`).
- Collection + indexes are created when the DB provisioning scripts run (`scripts/import_excel_to_mongodb.py` / `database/etl_pipeline.py`); see §10 for the follow-up needed to guarantee creation in every environment.
- Known pre-existing bug surfaced during verification: `scripts/import_excel_to_mongodb.py:153` and `database/etl_pipeline.py:1595-1601` mutate the shared index specs dict (`spec.pop("keys")`), so a second run has empty `keys` and skips index creation. Tracked in §10.

## 8. API Compatibility Verification

- Endpoint: `GET /api/v1/weather/current` — path, method, auth (`get_current_user_id` + `RoleChecker` for all roles), and response model `SuccessResponse[WeatherCurrentResponse]` unchanged.
- Response schema (9 fields, unchanged): `location_name`, `temp_celsius`, `feels_like_celsius`, `humidity_percent`, `wind_speed_m_s`, `description`, `icon_url`, `fungal_disease_risk`, `agricultural_advice`.
- End-to-end (no API key): HTTP 200, `{'success': True, 'message': 'Current weather retrieved successfully', 'data': {...9 fields, fallback values...}}`.
- Farm coordinate resolution (all HTTP 200): `farm_id` → `latitude/longitude` (10.5, 106.7); `farm_id` → `gps_lat/gps_lng` (21.0, 105.8); explicit `lat`/`lon` (15, 109) respected; no params → defaults (12.6667, 108.05); invalid `farm_id` → defaults.

## 9. Flutter Compatibility Verification

- Mobile client consumes `GET /weather/current` (`dga_mobile/lib/core/network/api_endpoints.dart:79`), which maps to the registered `/api/v1/weather/current`.
- `dga_mobile/lib/features/weather/weather_dtos.dart` expects the same 9-field JSON produced by `WeatherCurrentResponse`; field names/types are unchanged, so the DTO parse path is unaffected.
- The response wrapper shape (`success`/`message`/`data`) is unchanged, so existing deserialization still works.
- No mobile source files were modified by this foundation.

## 10. Remaining Work for Sprint 2

1. **`backend/tests/test_weather.py`** — follow `backend/tests/conftest.py` conventions (`httpx.AsyncClient` + `ASGITransport`, auto-cleaning fixtures) with a **mocked** OpenWeather client (monkeypatched `OpenWeatherClient`); cover cache hit/miss, TTL expiry, farm coordinate resolution, fallback path, and risk levels.
   - Note: existing `tests/test_farm.py` currently errors in setup because `conftest.py:53` inserts a user without `user_code` while the live `users` collection enforces a JSON-schema validator requiring it — a pre-existing environment mismatch unrelated to weather. Worth fixing conftest fixtures alongside.
2. **`.env.example` + key provisioning** — create `.env.example` with `OPENWEATHER_API_KEY=`, `MONGODB_URL=`, `JWT_SECRET_KEY=` placeholders; add a production guard for the empty `OPENWEATHER_API_KEY` (mirroring the existing `JWT_SECRET_KEY` guard in `config.py`). Rotate the previously committed key if it is live.
3. **DB provisioning** — run the index-creation flow so `weather_cache` (with its 3 indexes incl. TTL) is actually created in MongoDB.
4. **Pre-existing bug** — `scripts/import_excel_to_mongodb.py:153` and `database/etl_pipeline.py:1595-1601` mutate the shared specs dict via `spec.pop("keys")` (and `keys = spec.pop("keys")`), destroying `get_index_specs()` output after the first run. Fix to copy specs per collection before applying.
5. **Optional scheduler** — the backend has no scheduler (§3.6 of the audit); add background cache refresh (APScheduler or an `asyncio` task from the existing startup hook) if freshness beyond the 15-min lazy cache-aside is required.
6. **AI wiring** — populate `ChatService`'s `"Weather Data (last 3 days)"` placeholder (`backend/app/services/chat_service.py:42-50`) from `weather_cache` via `WeatherRepository`; extend Model 3's dataset builder to join `weather_cache` for `temperature` / `humidity` / `rainfall` features.
7. **Optional model enum** — add `WeatherRisk` enum (`LOW`/`MEDIUM`/`HIGH`) in `app/models/` following the enum-only model convention, replacing the hardcoded risk strings in `weather_service.py`.

---

## Verification Summary

| Check | Result |
|---|---|
| `py_compile` of all 8 modified/created Python files | Pass |
| Imports + `settings.OPENWEATHER_API_KEY == ''` | Pass |
| `Collections.WEATHER_CACHE in Collections.all()` | Pass |
| Index spec names + TTL `86400` | Pass |
| App boots; `/api/v1/weather/current` mounted | Pass |
| Endpoint contract (9-field response, HTTP 200, no API key → fallback) | Pass |
| Repository/cache flow + HIGH-risk rule | Pass |
| Farm coordinate resolution (all naming schemes) | Pass |
| OpenWeatherClient paths/params + missing-key error | Pass |
| No `urllib`/`requests`/`aiohttp`/hardcoded key in `backend/app` | Pass |
| Pre-existing suite (`tests/test_farm.py`) | Blocked by unrelated conftest/`user_code` validator mismatch (pre-existing, not caused by this change) |

> Files under `%TEMP%\opencode\` used for validation: `test_weather_endpoint.py`, `test_weather_service_flow.py`, `test_weather_farm_coords.py`, `test_openweather_client.py`, `cleanup_test_data.py`.
