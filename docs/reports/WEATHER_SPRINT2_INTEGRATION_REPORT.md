# Weather Sprint 2 Integration Report — Durian Guardian AI (DGA)

- **Date:** 2026-08-02
- **Role:** Lead Backend Engineer
- **Mode:** Real integration + safe refactor. API contract unchanged, Flutter untouched, no AI/Model 3 changes, no commit, no push.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`
- **Preceded by:** `WEATHER_BACKEND_ARCHITECTURE_AUDIT.md` + `WEATHER_BACKEND_FOUNDATION_REPORT.md`
- **Key enabler:** `OPENWEATHER_API_KEY` restored into the git-ignored `backend/.env` (verified live: returns real data for Buôn Ma Thuột 12.6667,108.05 → 23.85°C, 93%, "mây cụm").

---

## 1. Files Modified

| File | Change | Task |
|---|---|---|
| `backend/app/utils/openweather_client.py` | Retry-once logic (HTTP 5xx + 429 + transport errors), 401 = immediate error, small backoff (0.3s). | 1 |
| `backend/app/repositories/weather_repository.py` | Flattened cache schema; added `cache_expired_at`; `delete_expired()` now purges by `cache_expired_at < now`; `upsert_weather()`/`update_weather()` recompute `cache_expired_at` from TTL; `_id` fallback derived from stored lat/lon. | 3, 4, 9 |
| `backend/app/services/weather_service.py` | `get_current_weather()` now resolves farm coords itself; full cache-aside workflow; OpenWeather→DGA mapping; optional normalized forecast; keeps existing `_analyze_durian_risk` logic byte-for-byte. | 2, 5, 6, 7 |
| `backend/app/api/v1/weather.py` | Deleted duplicate `_resolve_coords`/farm lookup (moved into service); endpoint signature, response model, wrapper **unchanged**. | 8 |
| `database/indexes.py` | TTL index key changed from `updated_at` → `cache_expired_at` (`idx_weather_cache_cache_expired_at_ttl`, `expireAfterSeconds: 86400`). | 9 |
| `database/etl_pipeline.py` | Fixed `spec.pop("keys")` mutation bug (now copies the spec before applying) so index specs survive repeated runs. | 9 |
| `scripts/import_excel_to_mongodb.py` | Same `spec.pop("keys")` fix. | 9 |
| `backend/.env` (git-ignored, created) | `OPENWEATHER_API_KEY=...` — never committed. | — |

## 2. Files Created

| File | Purpose |
|---|---|
| `backend/.env` | Local secret provisioning (git-ignored via `backend/.gitignore:9`). |
| Validation scripts under `%TEMP%\opencode\` | `s2_integration_test.py`, `s2_retry_test.py`, `s2_endpoint_test.py`, `s2_mongo_verify.py`, `s2_provision_indexes.py` (throwaway, not part of the repo). |

## 3. OpenWeather Connectivity

Verified against the **live** OpenWeather API (real key):

- `GET /data/2.5/weather` → 200, `main.temp`, `main.humidity`, `weather[0].description` (Vietnamese `lang=vi`), correct UTF-8 ("mây cụm", "Buôn Ma Thuột").
- `GET /data/2.5/forecast` → 200, `list` with 3-hourly entries.
- Params sent: `lat`, `lon`, `appid`, `units=metric`, `lang=vi`.
- Async `httpx.AsyncClient`, `timeout=8.0` — never blocks the event loop.
- **Retry once (mock server):** HTTP 500 then 200 → 2 requests, success. Transport error (connection drop) then 200 → 2 requests, success. Persistent 5xx → `OpenWeatherClientError` after 2 attempts. HTTP 401 (invalid key) → immediate error, **no retry**.
- Missing key → `OpenWeatherClientError("OPENWEATHER_API_KEY is not configured…")`.

## 4. MongoDB Cache Verification

Real document persisted at `_id = weather_12.67_108.05`:

```
farm_id: None   latitude: 12.6667   longitude: 108.05   location_name: 'Buôn Ma Thuột'
temperature: 23.9   feels_like: 24.7   humidity: 93   pressure: 1008
wind_speed: 0.7   rainfall: 0.0   clouds: 76   visibility: 10000
weather: 'Clouds'   description: 'mây cụm'   icon: '04n'
updated_at: 2026-08-02 12:25:18   cache_expired_at: 2026-08-02 12:40:18
```

- **ONLY required fields stored** — raw OpenWeather payload (`coord`, `sys`, `dt`, nested `main`, `weather` arrays) is **not** persisted (verified: no `coord`/`dt`/`main` in the doc).
- Collection registered: `Collections.WEATHER_CACHE` (16th collection in `db_schema.py`).
- TTL index created and verified: `idx_weather_cache_cache_expired_at_ttl` → `[("cache_expired_at", 1)]`, `expireAfterSeconds: 86400`.

## 5. Repository Verification

`WeatherRepository(BaseRepository)` on `weather_cache` — pure data access:

- `get_by_coords` / `get_by_farm_id` / `find_latest` return flattened docs.
- `upsert_weather` atomically replaces by `_id` (create + update verified).
- `delete_expired` purged an artificially-expired doc (verified: doc gone after `cache_expired_at` set to past).
- `_is_cache_fresh` (service) honors `cache_expired_at`; falls back to `updated_at + TTL` for legacy docs.

## 6. API Verification

`GET /api/v1/weather/current` (ASGI, real OpenWeather) — **11/11 checks passed**:

- HTTP **200**, wrapper `{"success": True, "message": "Current weather retrieved successfully", "data": {...}}`.
- `data` has **exactly** the 9 contract fields, in order: `location_name`, `temp_celsius`, `feels_like_celsius`, `humidity_percent`, `wind_speed_m_s`, `description`, `icon_url`, `fungal_disease_risk`, `agricultural_advice`.
- Data is **real** (not the fallback sentinel).
- `farm_id` with `gps_lat/gps_lng` → HTTP 200; log confirms OpenWeather called with the farm's coords (12.0011, 107.9911).
- `farm_id` with `latitude/longitude` → HTTP 200, same 9-field shape.
- Explicit `lat`/`lon` honored. Invalid `farm_id` → falls back to defaults (Buôn Ma Thuột), HTTP 200.
- No token → 401 (auth unchanged).

## 7. Cache Verification (Cache-Aside)

- **Cold fetch:** cache miss → real OpenWeather → mapped → written to Mongo. Measured **591 ms**.
- **Cache hit:** `cache_expired_at` in future → served from Mongo, **OpenWeather NOT called again** (verified via client spy — 0 calls on hit). Measured **1.5 ms**.
- Expired cache → re-fetched from OpenWeather and re-written.
- `delete_expired()` runs before each write to purge stale entries.

## 8. Performance

| Path | Measured |
|---|---|
| Cold fetch (OpenWeather + Mongo write) | 591 ms |
| Cache hit (Mongo read + response build) | 1.5 ms |
| Cache → OpenWeather call ratio (steady state) | 0 API calls per request while TTL (15 min) is fresh |

Async-only I/O (httpx + motor) — no event-loop blocking.

## 9. Compatibility with Flutter

- Endpoint path unchanged: `dga_mobile/lib/core/network/api_endpoints.dart:79` → `/weather/current` → served as `/api/v1/weather/current`.
- `WeatherCurrentDto.fromJson` (`dga_mobile/lib/features/weather/data/models/weather_dtos.dart`) reads exactly the same 9 keys the API returns — field names/types confirmed identical.
- Wrapper (`success`/`message`/`data`) unchanged. **No mobile source files modified.**

## 10. Known Issues

1. **Pre-existing test/DB mismatch:** `backend/tests/conftest.py:53` inserts a test user without `user_code`, but the live `users` collection validator requires it → `tests/test_farm.py` errors in fixture setup. Unrelated to weather; affects the whole pytest suite against the live DB. (Also: `conftest.setup_db` wipes all collections — destructive against a real DB.)
2. **TTL index + app TTL interplay:** Mongo's TTL index deletes docs 86400s after `cache_expired_at`; app-level `delete_expired()` handles freshness within that window. Old cache docs written pre-Sprint-2 (nested `data` shape) are stale and not migrated — collection was re-seeded during verification.
3. **`forecast` is optional:** stored only when `include_forecast=True` (normalized 8 × 3-hourly entries); the default endpoint path makes a single API call (current weather only) to limit quota.
4. **Per-coordinate cache key:** two farms sharing the same rounded coordinates share one cache entry (cache-aside by design); `farm_id` on the doc is the last writer.

## 11. Remaining Sprint 3 Work

1. **Unit tests in repo:** add `backend/tests/test_weather.py` (mocked OpenWeather client, `httpx.AsyncClient` + `ASGITransport`) following `conftest.py` conventions; fix the conftest `user_code` fixture mismatch so the suite runs.
2. **`.env.example`:** commit a template (`OPENWEATHER_API_KEY=`, `MONGODB_URL=`, `JWT_SECRET_KEY=`) so the key provisioning is documented; consider a production guard for an empty key.
3. **Scheduler (optional):** background cache refresher (APScheduler or an asyncio task in the existing startup hook) to prefetch weather for all farms beyond the 15-min lazy cache.
4. **AI wiring:** populate `ChatService`'s `"Weather Data (last 3 days)"` placeholder (`chat_service.py:42-50`) from `weather_cache` via `WeatherRepository`; join `weather_cache` into Model 3's dataset builder for `temperature`/`humidity`/`rainfall` features.
5. **Forecast endpoint exposure (optional):** expose forecast to mobile once the DTO is extended; wire `include_forecast=True` via query param.

---

## Verification Summary

| Check | Result |
|---|---|
| Real OpenWeather current + forecast (live key) | Pass |
| Invalid key (401) → immediate error, no retry | Pass |
| Retry-once on 5xx / transport / 429 | Pass |
| Flattened cache doc with all required fields, no raw payload | Pass |
| `cache_expired_at` set = `updated_at + TTL` | Pass |
| Cache-Aside: hit skips OpenWeather (spy-verified); expiry refreshes | Pass |
| TTL index present (86400s on `cache_expired_at`); `delete_expired` works | Pass |
| Endpoint: HTTP 200, 9 exact fields, same wrapper | Pass |
| Farm coords: `gps_lat/gps_lng` and `latitude/longitude` both resolved | Pass |
| Flutter DTO keys match response | Pass |
| No commit / no push / no mobile / no AI changes | Pass |
