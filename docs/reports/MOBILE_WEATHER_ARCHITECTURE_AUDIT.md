# Mobile Weather Architecture Audit

**Report:** `MOBILE_WEATHER_ARCHITECTURE_AUDIT.md`
**Date:** 2026-08-02
**Role:** Lead Flutter Mobile Architect
**Scope:** READ-ONLY architectural audit of `dga_mobile` against the completed Weather Backend (Sprint 2).
**Objective:** Determine whether the Flutter app is ready to consume `GET /api/v1/weather/current` and, if not, what is required for Sprint 3.
**Method:** Static source inspection only. No source files were modified; no commits were made.

---

## 1. Current Flutter Architecture

The app follows a **feature-first, layered architecture** (clean-ish). Root layout under `dga_mobile/lib/`:

```
lib/
  main.dart
  config/          routes/, theme/
  core/            network/, errors/, constants/, theme/
  data/            (shared data helpers)
  features/
    authentication/
    dashboard/
    disease_detection/
    history/
    profile/
    recommendation/
    settings/
    splash/
    weather/
  models/          (legacy shared models)
  services/        api_service (legacy), connectivity_service, storage_service, logger_service
  shared/          widgets/, styles/
```

Each feature is internally layered:

```
features/<feature>/
  data/
    datasources/       Remote + (optional) Local datasources
    models/            DTOs + mappers
    repository_impl/   Repository implementation
  domain/
    entities/          Domain entities
    repositories/      Abstract repository interfaces
    usecases/          (sparsely used)
  presentation/
    pages/             Screens
    providers/         Riverpod providers
    widgets/           Feature widgets
```

Notable deviations from this convention: the `weather` feature is **partially layered** (data + presentation only — see §3), and several legacy artifacts exist (`services/api_service.dart`, `models/`, `shared/widgets/weather_card.dart`) that predate the current `core/network/` layer.

**Stack:** `flutter_riverpod` (state + DI), `go_router` (navigation), `dio` (HTTP), `flutter_secure_storage` + `shared_preferences` (persistence), `internet_connection_checker` (connectivity), `logger`.

---

## 2. Networking Architecture

Two networking tracks exist; the **new canonical track is what the weather feature uses**.

### Canonical track — `core/network/`
- `dio_api_client.dart` — `DioApiClient` implements the abstract `ApiClient.request<T>()` contract. Configured with `BaseOptions` from `EnvironmentConfig.baseUrl`, 30 s connect/receive/send timeouts, and three interceptors.
- `interceptors.dart` — `AuthInterceptor` (injects `Bearer` token; on 401 triggers a single refresh attempt then retries the original request once; clears session on refresh failure), `LoggingInterceptor`, `ErrorInterceptor` (maps `DioException` → typed `AppException`).
- `network_foundation.dart` — `ApiClient<T>` abstraction, `NetworkConfig`, `TimeoutConfig`, `RequestOptions`, and `ResponseWrapper<T>` (`data` / `message` / `status_code` / `success`) — the exact wrapper shape the backend emits.
- `result.dart` — sealed `Result<T>` (`Success` / `Failure` / `Loading` / `Empty`) with a `.when(...)` dispatcher.
- `api_endpoints.dart` — canonical endpoint table. `ApiEndpoints.weatherCurrent == '/weather/current'` (line 79).
- `environment_config.dart` — `baseUrl` switch for `_Env.emulator | device | production`. Dev = `http://$deviceHost:8000/api/v1` (device host `192.168.1.45`), prod = `https://api.durian-guardian.ai/v1`.

### Legacy track — `services/api_service.dart`
Older `ApiService`/Dio wrapper bound to `ApiConstants.baseUrl` with only a logging interceptor. **Not used by the weather feature.** Should be retired opportunistically to avoid dual-path confusion.

**Verdict:** The networking layer is production-viable: typed request/response handling, Bearer auth with refresh-and-retry, timeout handling, and error normalization already exist and are the exact path the weather datasource relies on.

---

## 3. Weather Module Status

The weather feature already exists, but is **incompletely layered**:

```
features/weather/
  data/
    datasources/weather_remote_datasource.dart   # GET weather/current via ApiClient
    models/weather_dtos.dart                     # WeatherCurrentDto (9 fields)
  presentation/
    providers/weather_providers.dart             # weatherRemoteDataSourceProvider, currentWeatherProvider
    widgets/weather_card.dart                    # Risk-graded WeatherCard (already on dashboard)
```

**Missing** relative to the app's own convention:
- `domain/entities/` — no `WeatherEntity` in the weather feature (dashboard/recommendation each define their own).
- `domain/repositories/` — no `WeatherRepository` interface.
- `data/repository_impl/` — no repository implementation.
- No offline caching (the feature always hits the network).

These are structural gaps, not functional blockers — the feature currently works via datasource → provider → widget.

---

## 4. API Consumption Flow

Current (working) flow for the weather card:

```
WeatherCard (ConsumerWidget, features/weather/presentation/widgets/weather_card.dart)
  └─ watches currentWeatherProvider (FutureProvider<WeatherCurrentDto>)
       └─ WeatherRemoteDataSourceImpl.getCurrentWeather()
            └─ ApiClient.request<WeatherCurrentDto>(path: /weather/current, GET)
                 └─ DioApiClient → AuthInterceptor (Bearer) → ErrorInterceptor
                 └─ decoder: WeatherCurrentDto.fromJson
                 └─ fallback: const WeatherCurrentDto(...) if data == null
```

Request shape observed in datasource: `GET {baseUrl}/weather/current` with no query parameters (backend accepts optional `farm_id`, defaulting to the authenticated user's primary farm).

Error/empty/loading surfaces are handled in the card via `AsyncValue.when(data / error / loading)`. No offline-fallback wiring today (connectivity primitives exist — see §11).

---

## 5. Repository Architecture

The app's convention is datasource → repository interface → repository impl → provider. Examples:

- **Dashboard:** `DashboardRemoteDataSource` → `DashboardRepository` (abstract, returns `Result<DashboardFullData>`) → `DashboardRepositoryImpl` → `dashboardDataProvider`.
- **Weather:** datasource only. No repository layer exists.

**Assessment:** Adding a `WeatherRepository` layer is a small, low-risk change that aligns the weather feature with the dashboard pattern and gives a natural home for offline caching (local datasource) and `farm_id` selection. It is a *consistency* improvement, not a prerequisite for integration.

---

## 6. DTO Compatibility

Backend Sprint 2 response (single `data` object under the standard wrapper):

```
success, message, status_code, data:
  location_name, temp_celsius, feels_like_celsius,
  humidity_percent, wind_speed_m_s,
  description, icon_url,
  fungal_disease_risk, agricultural_advice
```

`WeatherCurrentDto.fromJson` (`features/weather/data/models/weather_dtos.dart`) reads exactly:

```
location_name, temp_celsius, feels_like_celsius,
humidity_percent, wind_speed_m_s,
description, icon_url,
fungal_disease_risk, agricultural_advice
```

**Field-by-field match: complete, 9/9 keys, naming identical.** No renaming or transformation needed at the DTO boundary.

### Other weather DTOs in the codebase (do NOT touch / not required for Sprint 3)
- `features/dashboard/data/models/dashboard_dtos.dart::WeatherDto` — 7-field legacy shape (`location`, `temperature`, `humidity`, `rainfall`, `wind_speed`, `condition`, `disease_risk`). Feed of `DashboardWeatherCard` + `WeatherEntity`. **Dead code:** `DashboardWeatherCard` is never imported by any page; the dashboard remote datasource does not return weather.
- `features/recommendation/data/models/recommendation_dtos.dart::WeatherDto` — recommendation-specific 4-field shape (`temperature`, `humidity`, `rainfall`, `wind_speed`); consumed by `WeatherConditionsCard` on the recommendation page. Separate concern, unrelated to the weather endpoint.
- `features/history/...` — `HistoryWeatherDto`/`HistoryWeatherEntity`, inspection-history payload. Unrelated.

**Assessment:** The correct, backend-compatible DTO already exists and is in use. The dashboard's legacy weather DTO/entity/card are safe to remove in a future cleanup (out of scope for Sprint 3).

---

## 7. State Management

Riverpod everywhere (no GetIt, no Bloc).

- `currentWeatherProvider` — `FutureProvider<WeatherCurrentDto>`; simplest viable shape; auto-revalidates via provider invalidation and supports pull-to-refresh.
- `weatherRemoteDataSourceProvider` — plain `Provider` wrapping `dioApiClientProvider`.
- UI consumes `AsyncValue` directly in `WeatherCard` with `.when(data/error/loading)`.

**Assessment:** Sufficient for the weather feature. If Sprint 3 adds offline-first behavior or farm switching, upgrade to a `StateNotifier`/`NotifierProvider` (or a `FutureProvider.autoDispose` with cache layer) — but this is optional.

---

## 8. Dashboard Integration Analysis

**Weather is already on the dashboard.** `features/dashboard/presentation/pages/dashboard_page.dart`:
- imports `../../../weather/presentation/widgets/weather_card.dart` (line 16);
- renders `const WeatherCard()` (line 47) inside the `SingleChildScrollView` column;
- the page's `RefreshIndicator` invalidates `dashboardDataProvider`, and `WeatherCard` self-manages via its own provider.

Current dashboard data flow: `dashboardRemoteDataSourceProvider` → `dashboardRepositoryProvider` → `dashboardDataProvider` (`FutureProvider<DashboardFullData>`). The remote datasource calls `/dashboard` and `/auth/me` **only** — weather is intentionally fetched independently by the weather card.

**Assessment:** Dashboard integration is effectively *done*. Remaining UX niceties: coordinate pull-to-refresh so the weather card revalidates on the same gesture, and unify the error/empty state visuals with `shared/widgets/error_state.dart` / `empty_state.dart`.

---

## 9. Dependency Injection

- Riverpod providers are the only DI mechanism.
- `main.dart` wraps the app in `ProviderScope` and overrides `storageServiceProvider` with a concrete `StorageService(sharedPreferences, secureStorage)`.
- `dioApiClientProvider` is constructed with tokenReader/tokenWriter/refresh callbacks and a `sessionClearer`, all backed by `StorageService` / secure storage.

The weather provider chain is fully resolvable with zero wiring changes. No constructor injection refactors required.

---

## 10. Required Files For Sprint 3

Scope depends on ambition. Minimum viable integration (already ~95% present) versus recommended cleanup:

**Already present (no work required):**
- `core/network/api_endpoints.dart` — `/weather/current` route.
- `features/weather/data/models/weather_dtos.dart` — backend-compatible DTO.
- `features/weather/data/datasources/weather_remote_datasource.dart` — live fetch.
- `features/weather/presentation/providers/weather_providers.dart` — provider chain.
- `features/weather/presentation/widgets/weather_card.dart` — UI, on dashboard.
- `dashboard_page.dart` — card mounted.

**Recommended additions (small, aligns with conventions):**
- `features/weather/domain/repositories/weather_repository.dart` — abstract repository (`Future<Result<WeatherCurrentDto>> getCurrentWeather({String? farmId})`).
- `features/weather/data/repository_impl/weather_repository_impl.dart` — delegates to remote datasource (+ optional local cache).
- `features/weather/domain/entities/weather_entity.dart` — (optional) if you want the domain entity distinct from the DTO; the current app mixes these per-feature, so this is a judgment call.
- `features/weather/data/datasources/weather_local_datasource.dart` — offline cache (SharedPreferences/JSON), if offline-first is desired.
- Optional `farm_id` query parameter plumbing (backend supports it; `WeatherCurrentDto` unchanged).

**Future cleanup (not Sprint 3):**
- Remove dead dashboard weather code: `dashboard_weather_card.dart`, `dashboard_dtos.dart::WeatherDto`, `dashboard_entities.dart::WeatherEntity`, `dashboard_local_datasource.dart` (never wired), `dashboard_mappers.dart::WeatherDtoMapper`.
- Retire legacy `services/api_service.dart` + `models/` if unused elsewhere.
- Consolidate the three weather-card variants (feature `WeatherCard`, legacy dashboard card, `shared/widgets/weather_card.dart`).

---

## 11. Potential Risks

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| 1 | **Runtime verification gap** — DTO compatibility is verified statically; no Flutter tests/device run performed in this audit. Backend tests (21/21) prove server shape, but the widget path is unproven on-device. | Medium | Sprint 3 kickoff: unit-test `WeatherCurrentDto.fromJson` against a real captured payload + manual emulator run. |
| 2 | **Backend reachability from device** — dev base URL is `http://192.168.1.45:8000/api/v1`; the phone must reach that LAN host + HTTP is cleartext (Android 9+ blocks cleartext by default unless configured). | High | Verify Android `usesCleartextTraffic`/network security config and that device ↔ backend are on the same network before the first device test. |
| 3 | **No offline fallback** — weather card error state today shows an error; no stale-cache read when offline. | Low | Optional local datasource in Sprint 3. |
| 4 | **Farm context** — backend resolves the farm via the auth token; multi-farm users may want explicit `farm_id`. Currently the app sends none (uses default). | Low | Acceptable now; plumb `farm_id` when multi-farm support lands. |
| 5 | **Legacy dead code confusion** — three weather DTO/card variants could cause a future developer to wire the wrong one. | Low | Remove dead dashboard weather code in cleanup; comment/delete legacy `shared` card. |
| 6 | **Pull-to-refresh not coordinated** — weather card and dashboard refresh are decoupled; a pull may refresh dashboard data but not weather. | Low | Have the dashboard's `RefreshIndicator` also invalidate `currentWeatherProvider`. |
| 7 | **Auth expiry race** — 401 → refresh → retry handled by interceptor; the fallback `const WeatherCurrentDto()` masks failures (empty/zero values render). | Medium | Keep fallback (crash-proofing) but log and surface a subtle stale indicator. |

---

## 12. Estimated Sprint 3 Complexity

| Item | Effort |
|------|--------|
| Wire dashboard pull-to-refresh to `currentWeatherProvider` | ~30 min |
| Add repository layer + optional local cache | ~2–4 h |
| `farm_id` plumbing | ~1–2 h |
| DTO unit tests + device smoke test | ~2–3 h |
| Dead-code cleanup (dashboard weather, legacy api_service, shared card) | ~1–2 h |
| **Total** | **~1 day (recommended scope)** |

No backend changes are required; the Sprint 2 API is already compatible.

---

## 13. Recommended Sprint 3 Implementation Order

1. **Verify on device first** (risk #1/#2): run backend, run app against `192.168.1.45:8000`, confirm the weather card renders live data. Fix cleartext/LAN issues if they surface.
2. Add `WeatherRepository` interface + impl (+ optional `WeatherLocalDataSource` for offline), mirroring the dashboard pattern.
3. Plumb `farm_id` (optional) as a query parameter through repository → datasource.
4. Coordinate refresh: invalidate `currentWeatherProvider` from the dashboard's `RefreshIndicator`.
5. Add `WeatherCurrentDto.fromJson` unit tests against a captured backend payload.
6. (Cleanup, separate ticket) Remove dead dashboard weather code, legacy `api_service.dart`, and consolidate weather card variants.

---

## 14. Final Verdict

# READY WITH MINOR CHANGES

The Flutter app is **architecturally ready to consume the Weather Backend Sprint 2 API today**:

- The correct endpoint (`/weather/current`) is declared in `ApiEndpoints`.
- A backend-compatible 9-field DTO (`WeatherCurrentDto`) already exists and parses the exact Sprint 2 response keys.
- The datasource already calls the canonical `ApiClient` with Bearer auth, refresh-retry, timeout, and error normalization.
- The weather card is **already rendered on the dashboard** and self-manages its load/error/data states.

The only required Sprint 3 work is **verification and polish**: prove it end-to-end on a device, then add the conventional repository layer (with optional offline cache and `farm_id` support) for consistency. No backend changes and no major refactor are required.

**Suggested label for the ticket:** *Sprint 3 — Mobile Weather: device verification + repository layer + refresh coordination.*
