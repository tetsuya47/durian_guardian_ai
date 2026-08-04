# MongoDB Full Analysis — Durian Guardian AI

- **Date:** 2026-08-03
- **Role:** Chief Data Architect
- **Mode:** Read-only analysis. No source code modified, no MongoDB write/DDL executed, no data imported/exported, no commit, no push.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`
- **Live inspection:** verified against the running MongoDB instance (`localhost:27017`, `durian_guardian_ai`) using read-only queries (`listCollections`, `index_information`, `count_documents`, sample `find`).

---

## 1. Executive Summary

The Durian Guardian AI data layer is a **MongoDB-backed persistence stack** split into two code areas:

1. `database/` — a standalone **data engineering layer** (config, connection singleton, `db_schema.py` with 16 collection registrations + `$jsonSchema` validators, `indexes.py` with 16 index specs, a 2,300-line Excel→MongoDB **ETL pipeline**, idempotent seed scripts, a Vietnamese data-migration script).
2. `backend/app/` — the **FastAPI application layer** (motor `AsyncIOMotorClient` singleton, `BaseRepository` + 21 specialized repositories, services, 20 API router groups, Pydantic schemas).

The design is **structurally strong**: centralized schema/index registry, strict validators, 84 live indexes, a clean repository pattern, and sophisticated `$lookup`-based aggregation for the dashboard/heatmap/overview features. However, a live read-only inspection reveals **material divergence between the declared schema and the actual database**:

- `neighbor_contact_requests` (declared in `db_schema.py`) **does not exist** in the live DB.
- `iot_orders` and `iot_fault_reports` (referenced by the IoT API) **do not exist** in the live DB.
- `farm_owners` **exists but is not declared** in `db_schema.py` and is **not referenced by any backend code** (orphan).
- The `farms` index `idx_farms_owner_id` was built on **`owner_id`** while `indexes.py` declares **`owner_user_id`**; live farm documents use `owner_id`, so several services/dashboards that query `owner_user_id` return empty results for the seeded farm.
- The IoT summary repository method raises a **`NameError` at runtime** (undefined variables), so `GET /api/v1/iot/summary` is broken.
- The backend **startup auto-seeder** (`seed_1200_trees`) is **destructive**: it deletes `trees`, `zones`, `farms`, `disease_history`, `diseases`, and `detection_results` whenever the tree count is below 1,200 — this wiped the ETL dataset and replaced it with a demo farm.

**Verdict: ⚠️ DATABASE PARTIALLY READY.** The schema/index foundation and the weather-cache + AI write-through paths are production-viable, but the live database is not aligned with the declared schema, several collections are missing or unvalidated, the IoT layer is under-specified and buggy, and there is no transaction support for multi-collection writes.

---

## 2. Objective & Scope

**Objective:** Produce a full, evidence-based analysis of the complete MongoDB system — connection/configuration, collections, `$jsonSchema` schemas, indexes, repository layer, aggregation usage, weather cache, AI and IoT databases, ETL/seed/migration pipelines, API↔collection mapping, authentication, and security — and issue a final readiness verdict.

**Scope (included):**
- `database/` — `config.py`, `mongodb.py`, `db_schema.py`, `indexes.py`, `etl_pipeline.py`, `setup_database.py`, `seed_admin.py`, `seed_farm_owners.py`, `seed/`, `migrate_vietnamese.py`, `dataset_builder/mongodb_reader.py`, `README.md`.
- `backend/app/` — `database/mongodb.py`, `core/config.py`, `models/enums.py`, `repositories/*` (21 files), `services/*`, `api/v1/*` (20 router groups), `schemas/*` (18 files), `dashboard/service.py`, `ai/service.py`, `main.py`, `seed_1200_trees.py`.
- Live MongoDB `durian_guardian_ai` (read-only).

**Scope (excluded):** no changes to code or data; training/pipelines outside the data layer are covered by `AI_SYSTEM_FULL_ANALYSIS.md`.

---

## 3. System Architecture Overview (Database Layer)

```
                 ┌────────────────────────────────────────────────┐
                 │               Clients (mobile/web)             │
                 └───────────────────────┬────────────────────────┘
                                         │ HTTP /api/v1
                 ┌───────────────────────▼────────────────────────┐
                 │          FastAPI Backend (backend/app)         │
                 │   api/v1 (20 routers) → services → repositories│
                 │   dashboard/service.py  ai/service.py          │
                 │   database/mongodb.py (motor singleton)        │
                 └───────────────────────┬────────────────────────┘
                                         │ motor AsyncIOMotorClient
                 ┌───────────────────────▼────────────────────────┐
                 │          MongoDB  (localhost:27017)            │
                 │          durian_guardian_ai  (17 collections)  │
                 │  core: companies farms zones trees users ...   │
                 │  ai:   inspections detection_results ...       │
                 │  cache: weather_cache (TTL)  iot_devices       │
                 └───────────────────────┬────────────────────────┘
                                         │ pymongo
                 ┌───────────────────────▼────────────────────────┐
                 │  database/ (data engineering layer)            │
                 │  config.py  mongodb.py  db_schema.py           │
                 │  indexes.py  etl_pipeline.py  seed_*           │
                 │  migrate_vietnamese.py  dataset_builder        │
                 └────────────────────────────────────────────────┘
```

**Key architectural facts**
- Backend reads/writes MongoDB via **motor** (`AsyncIOMotorClient`); the `database/` engineering layer uses **pymongo** (sync) for ETL/seed/migration.
- Collection/schema/index definitions are centralized in `database/db_schema.py` + `database/indexes.py` — the declared "single source of truth".
- The repository layer follows a uniform `BaseRepository` (CRUD + pagination + `_serialize`/`_deserialize`).
- Documents use Vietnamese string values for status/disease/alert fields (localized at ETL time or via `migrate_vietnamese.py`), while several aggregations still assume English enums — a known drift class.
- No multi-document transactions anywhere; the AI pipeline writes to 4–5 collections sequentially.

---

## 4. Deployment & Environment

| Item | Value | Evidence |
|---|---|---|
| MongoDB version | **8.3.4** (Community) | `server_info()` |
| Connection | `mongodb://localhost:27017` (no auth) | `database/config.py`, `backend/app/core/config.py`, live client |
| Database name | `durian_guardian_ai` | both config files |
| Replica set / sharding | **None** (standalone) | `dbStats`, no `start_session`/transactions possible |
| Live collections | **17** | `listCollectionNames()` |
| Live documents | **1,298** | `count_documents` per collection |
| Storage | ~0.39 MB data / 0.45 MB storage | `dbStats` |
| Total indexes | **84** (incl. `_id`) = 67 explicit | `index_information()` across 17 collections |

The README requires **MongoDB 6.0+ / PyMongo 4.6+**; the live instance is well above that.

---

## 5. Configuration & Settings

**`database/config.py`** (root engineering layer):

| Variable | Default | Notes |
|---|---|---|
| `MONGODB_URI` | `mongodb://localhost:27017` | |
| `MONGODB_USERNAME` / `MONGODB_PASSWORD` | empty | optional |
| `MONGODB_AUTH_SOURCE` | `admin` | |
| `MONGODB_AUTH_MECHANISM` | `SCRAM-SHA-256` | |
| `DATABASE_NAME` | `durian_guardian_ai` | |
| Pool min/max | 5 / 50 | `minPoolSize`/`maxPoolSize` |
| `CONNECT_TIMEOUT_MS` / `SERVER_SELECTION_TIMEOUT_MS` | 5,000 / 5,000 | |
| `SOCKET_TIMEOUT_MS` | 30,000 | |
| `MAX_IDLE_TIME_MS` | 600,000 | |
| `RETRY_WRITES` | true | |

**`backend/app/core/config.py`** (FastAPI layer, pydantic-settings from `.env`):

| Variable | Default |
|---|---|
| `MONGODB_URL` | `mongodb://localhost:27017` |
| `MONGODB_DB_NAME` | `durian_guardian_ai` |
| `WEATHER_CACHE_TTL_MINUTES` | 15 |
| `OPENWEATHER_API_KEY` / `OPENWEATHER_BASE_URL` | "" / `https://api.openweathermap.org/data/2.5` |

No `.env` file is committed; backend runs on defaults. The two config layers are **independent** (different classes, same defaults) — a duplication that can drift.

---

## 6. Connection Management — `database/mongodb.py`

`MongoDBConnection` (pymongo, sync):
- Singleton `_client` / `_db`.
- Exposes `get_client()`, `get_database()`, health check (`ping` via `client.admin.command("ping")`), and graceful `close()`.
- Uses `settings.mongodb_uri_with_credentials` + `connection_kwargs` (pool 5–50, timeouts, auth, retryWrites).
- Handles `ConnectionFailure`, `ServerSelectionTimeoutError`, `OperationFailure` in ETL/seed entry points.

**Assessment:** robust, production-oriented (pooling, timeouts, auth plumbing, retryWrites).

---

## 7. Backend Database Layer — `backend/app/database/mongodb.py`

`MongoDBManager` (motor, async):
- Class-level singleton `_client: AsyncIOMotorClient | None`, `_db: AsyncIOMotorDatabase | None`.
- `get_client()` → `AsyncIOMotorClient(settings.MONGODB_URL)` — **defaults only, no pool/timeout/auth config**.
- `get_db()` → `client[settings.MONGODB_DB_NAME]`.
- `close()` exists but is **never wired** to a FastAPI shutdown/lifespan event in `main.py`.

`get_database()` — async generator dependency (`yield db`) used by every router.

**Gaps:** no connection parameters, no startup/shutdown lifecycle hook, no explicit error mapping. Functional for local development but weaker than the `database/` layer.

---

## 8. Collections Registry & Actual State

`database/db_schema.py` declares **16 collections** (`Collections.all()`) and marks **10** as Excel-seeded (`seed_collections()`). The **live DB has 17 collections** and diverges:

| # | Collection | Declared | Live docs | Live idx | Validator live | Used by backend | Notes |
|---|---|---|---|---|---|---|---|
| 1 | companies | ✅ | 0 | 3 | ✅ | ✅ | empty |
| 2 | farms | ✅ | 1 | 6 | ✅ | ✅ | demo farm (`FARM_1200`) |
| 3 | zones | ✅ | 5 | 2 | ✅ | ✅ | 5 zones of demo farm |
| 4 | trees | ✅ | 1,200 | 6 | ✅ | ✅ | demo trees |
| 5 | users | ✅ | 3 | 4 | ✅ | ✅ | admin + 2 |
| 6 | diseases | ✅ | 0 | 2 | ✅ | ✅ | empty |
| 7 | inspections | ✅ | 6 | 7 | ✅ | ✅ | AI-written |
| 8 | detection_results | ✅ | 2 | 7 | ✅ | ✅ | AI-written |
| 9 | disease_history | ✅ | 2 | 7 | ✅ | ✅ | AI-written |
| 10 | alerts | ✅ | 5 | 10 | ✅ | ✅ | AI-written |
| 11 | seasons | ✅ | 0 | 5 | ✅ | ✅ | empty |
| 12 | harvests | ✅ | 0 | 5 | ✅ | ✅ | empty |
| 13 | farm_targets | ✅ | 0 | 4 | ✅ | ✅ | empty |
| 14 | farm_performance | ✅ | 0 | 6 | ✅ | ✅ | empty |
| 15 | neighbor_contact_requests | ✅ | **absent** | — | — | ⚠️ repo only | **missing in live DB** |
| 16 | weather_cache | ✅ | 1 | 4 | ❌ | ✅ | no validator |
| 17 | **farm_owners** | ❌ | 0 | 5 | ✅ | ❌ | **orphan** (not in code) |
| — | **iot_devices** | ❌ | 73 | 1 | ❌ | ✅ | populated, unvalidated |
| — | **iot_orders** | ❌ | **absent** | — | — | ✅ | **missing** (lazy-create on insert) |
| — | **iot_fault_reports** | ❌ | **absent** | — | — | ✅ | **missing** |

> **Finding:** of the 16 declared collections only 15 exist; of the 4 code-referenced-but-undeclared collections only `iot_devices` exists. The live schema is thus **not reproducible from `db_schema.py` alone**.

---

## 9. Companies Collection

- **Schema:** validator requires `company_code`, `company_name`, `district`, `province`; optional `owner`, `phone`, `email`, `created_at`.
- **Indexes (live):** `idx_companies_name` (unique), `idx_companies_code` (unique). Matches `indexes.py`.
- **Live state:** 0 documents.
- **Consumed by:** `CompanyRepository` (`get_all`, `get_company_stats` counting farms→zones→trees via 3 collections), `api/v1/companies.py`.
- **Notes:** unique `company_name` and `company_code` — ETL produces `COMP001–COMP010`.

---

## 10. Farms Collection

- **Schema:** validator requires `farm_code`, `farm_name`, `company_id`, `district`; optional `owner_user_id`, `manager_user_id`, `phone`, `commune`, `latitude/longitude`, `area_hectare`, `tree_count`.
- **Indexes (live):** `idx_farms_company_id`, `idx_farms_name`, `idx_farms_code` (unique), `idx_farms_owner_id`, `idx_farms_district`.
- **Live state:** 1 document — the demo farm from `seed_1200_trees`: `_id 6a6d50f6...`, `farm_code "FARM_1200"`, `owner_id`/`company_id` pointing at the admin user, `district "Định Quán"`, `location "Đồng Nai, Việt Nam"`, `total_area_ha 15.5`.
- **Critical drift:** the live farm document and live index use **`owner_id`**, while `db_schema.py`/`indexes.py` declare **`owner_user_id`**.
  - `backend/app/repositories/farm_repository.py:list_by_owner` filters `$or: [{user_id}, {owner_id}, {created_by}]` — partially covers it.
  - `backend/app/services/farmer_overview_service.py:56` and `chat_service.py:47` query `owner_user_id` → **return nothing for the demo farm**.
  - `dashboard.service._get_user_farms` covers both keys → dashboard works.

---

## 11. Zones & Trees Collections

### Zones
- **Schema:** requires `farm_id`, `zone_name`, `tree_count`; optional `zone_code`, `soil_type`, `irrigation`.
- **Index:** `idx_zones_farm_zone` unique compound `(farm_id, zone_name)` — matches.
- **Live state:** 5 zones (`Khu A–E`) of the demo farm with `variety`, `manager_name`, `tree_count` (450/350/200/120/80 = 1,200).
- **Repo:** `ZoneRepository` (`exists_by_id`, `get_farm_id`, `list_by_farm`).

### Trees
- **Schema:** requires `tree_code`, `farm_id`, `zone_id`, `variety`, `planting_date`, `tree_age`, `status`; `status` enum = Vietnamese health values.
- **Indexes:** `idx_trees_code_unique` (unique tree_code), `farm_id`, `zone_id`, `status`, `variety` — matches.
- **Live state:** 1,200 docs (`SR-A001…SR-E080`), tree codes unique; carries **extra fields** not in the validator: `health_status` (often a **disease name** like "Thán thư"), `risk_score`, `planted_year`, `location_row/column`.
- **Repo:** `TreeRepository` — aggregation-heavy (`_build_enrichment_stages` `$lookup` zones+farms, sub-pipeline `$lookup` to latest `disease_history`, health-status filtering, heatmap projection, KPI counts, `count_by_farms`).

---

## 12. Users Collection

- **Schema:** requires `user_code`, `full_name`, `role`; role enum `["Admin","Company Manager","Farm Manager","Farm Owner","Inspector","Technician"]`; optional `email`, `password_hash`, `refresh_token`, `phone`, `status`, `address{province,district,ward,detail}`.
- **Indexes:** `idx_users_code_unique` (unique user_code), `idx_users_role`, `idx_users_email` (unique, sparse).
- **Live state:** 3 users (admin `bao@gmail.com` + 2 demo). `password_hash` bcrypt (`$2b$12$...`).
- **Auth wiring:** `UserRole` enum (`farmer`/`field_technician`/`farm_manager`/`enterprise_admin`) + `db_role_to_api`/`api_role_to_db` mapping in `models/enums.py`. JWT HS256, access 30 min, refresh 7 days.
- **Seeding:** `database/seed_admin.py` (admin `bao@gmail.com` / `123456`, role `Admin`) and `backend/app/main.py` startup seed (same email, same default password). Farm-owner seed in `seed_farm_owners.py` / ETL `generate_farm_owner_users`.

---

## 13. Diseases & Inspections Collections

### Diseases
- **Schema:** requires `code`, `name`; optional `affected_part`, `severity`, `description`, `recommendation`.
- **Index:** `idx_diseases_code_unique` (unique).
- **Live state:** 0 docs. `database/seed/diseases.json` is **empty `[]`**, so disease master data only arrives via the Excel `diseases` sheet in ETL (`transform_diseases_combined`).

### Inspections
- **Schema:** requires `inspection_code`, `tree_id`, `farm_id`, `inspection_date`, `health_status`, `predicted_disease`, `confidence`; `health_status` enum = Vietnamese; `confidence` 0–100 double.
- **Indexes:** `tree_id`, `inspection_date` (desc), `predicted_disease`, `health_status`, `farm_id`, `confidence` (desc) — matches.
- **Live state:** 6 docs from AI runs; extra field **`status: "COMPLETED"`** (not in validator).
- **Repo:** `InspectionRepository` — `get_all` with keyword search resolving tree codes via a `trees` query then `$lookup` enrichment (trees + users), KPI stats.

---

## 14. Detection Results Collection

- **Schema:** requires `inspection_id`, `model`, `prediction`, `confidence`; optional `detection_code`, `tree_id`, `farm_id`, `company_id`, `image_path`, `image_quality`, `model_version`, `processing_time_ms`, `recommendation`, `lat/lon`, `captured_at`.
- **Indexes:** `inspection_id`, `tree_id`, `farm_id`, `company_id`, `prediction`, `created_at` (desc).
- **Live state:** 2 docs — model `EfficientNet-B0`, `prediction "Khỏe mạnh"`, `confidence 59.91`, `severity "none"`, `image_path "/uploads/..."`.
- **Unit inconsistency:** `disease_history.confidence` is stored **0.5991** while `detection_results.confidence` is **59.91** for the same prediction — the same metric in two units.
- **Repo:** `DetectionResultRepository` (`$lookup` inspections + trees enrichment).

---

## 15. Disease History & Alerts Collections

### Disease History
- **Schema:** requires `tree_id`, `disease`, `date`, `action`; optional `farm_id`, `company_id`, `severity`, `symptoms`, `diagnosis_method`, `detected_by_user_id`, `detection_result_id`, `resolved_at`, `resolution_notes`.
- **Indexes:** `tree_id`, `farm_id`, `company_id`, `disease`, `date` (desc), `action`.
- **Live state:** 2 docs; carries **extra fields** not in the validator: `disease_name`, `confidence`, `image_url`; `action "Chẩn đoán bệnh AI"`.
- **Repos:** `DiseaseHistoryRepository` (enrichment + KPI) and `DiseaseRepository` (also targets `disease_history` — confusing duplicate).

### Alerts
- **Schema:** requires `farm_id`, `tree_id`, `alert_type`, `priority`, `date`; many optional refs (`inspection_id`, `detection_result_id`, `disease_history_id`, `disease_id`, `alert_level`, `title`, `message`, `recommendation`, `is_read`, `acknowledged_*`).
- **Indexes (10):** `created_at`, `priority`, `farm_id`, `tree_id`, `company_id`, `alert_type`, `status`, compound `(is_read, created_at)`, `date` (desc).
- **Live state:** 5 docs — `alert_type "Bệnh nghiêm trọng"`, **`priority "Cao"`** (Vietnamese), `status "unread"` (English — schema example uses Vietnamese "chưa đọc").
- **Drift:** the dashboard risk aggregations map English `"High"/"Medium"/"Low"` priorities, so with Vietnamese values `risk_trend` and `alert_counts` resolve to **0**.
- **Repos:** `AlertRepository`, `NotificationRepository` (operates on the **`alerts`** collection).

---

## 16. Seasons, Harvests, Farm Targets & Farm Performance

Added for the Farm Performance Dashboard (see `DATABASE_EXTENSION_REPORT.md`):

| Collection | Validator required | Indexes | Live docs | Repo |
|---|---|---|---|---|
| seasons | farm_id, season_name, season_year, start_date, status | farm_id; (farm_id, season_year); season_year; status | **0** | `SeasonRepository.get_latest_by_farm` (active → latest year → newest) |
| harvests | farm_id, season_id, harvest_date, yield_kg | farm_id; season_id; (farm_id, season_id); harvest_date desc | **0** | `HarvestRepository` |
| farm_targets | farm_id, season_id, target_yield, target_revenue | farm_id; season_id; (farm_id, season_id) | **0** | `FarmTargetRepository` |
| farm_performance | farm_id, season_id, farm_score, overall_status, last_calculated | farm_id; season_id; (farm_id, season_id); overall_status; farm_score desc | **0** | `FarmPerformanceRepository` |

**Assessment:** fully specified (validators + indexes + repos) but **empty** in the live DB — the farm-performance dashboard and `get_farm_performance` therefore return "no data" states. ETL auto-generates 2 seasons/farm, 1 harvest & 1 target & 1 performance per season.

---

## 17. Neighbor Contact Requests Collection

- **Declared in `db_schema.py`** with a strict validator (6 required refs + consent flags + status enum: pending/waiting_target_consent/waiting_source_consent/contact_shared/rejected/cancelled) and **9 indexes** in `indexes.py` (unique `request_code`, source/target farm & user, inspection, status, created_at, expires_at).
- **Repository:** `NeighborContactRequestRepository` (`count_by_status`/`count_by_direction` aggregation, `list_latest` with `$lookup` farm names).
- **Live state:** collection **does not exist**. No API router exposes it (rollback documented in `NEIGHBOR_CONTACT_FULL_ROLLBACK_REPORT.md`).
- **Assessment:** schema/infra defined but neither instantiated nor exposed — dormant.

---

## 18. Weather Cache Collection

- **Purpose:** cache-aside store for OpenWeather (via `WeatherService` + `OpenWeatherClient`), feeding the M3 risk endpoint.
- **Document shape (flattened, never raw payload):** string `_id` = `weather_{lat}_{lon}`, `farm_id`, `latitude`, `longitude`, `location_name`, `temperature`, `feels_like`, `humidity`, `pressure`, `wind_speed`, `rainfall`, `clouds`, `visibility`, `weather`, `description`, `icon`, `updated_at`, `cache_expired_at`, optional `forecast`.
- **Indexes:** `farm_id`, `updated_at` (desc), and **TTL** `cache_expired_at` `expireAfterSeconds: 86400`.
- **Repo:** `WeatherRepository` — `build_cache_key`, `compute_cache_expired_at` (TTL 15 min), `get_by_coords`, `get_by_farm_id`, `create_weather`, `update_weather`, `upsert_weather`, `delete_expired`, `find_latest`.
- **Live state:** 1 doc (Buôn Ma Thuột coords, `farm_id null`).
- **TTL mismatch:** code computes `cache_expired_at = updated_at + 15 min` but the TTL index expires **86,400 s (1 day)** after that timestamp. Actual 15-min cleanup relies on `WeatherService` calling `delete_expired()` — if that call is missed, stale rows live up to a day.

---

## 19. IoT Collections (iot_devices / iot_orders / iot_fault_reports) + farm_owners

### iot_devices
- **Not declared** in `db_schema.py`; **no validator**, **only `_id` index**.
- **Live state:** 73 docs (soil sensors, weather stations, gateway hubs, smart valves) with `device_code`, `device_type`, `unit_price`, `farm_id`, `farm_name`, `status`, `battery_level`, `last_signal`.
- **Status vocabulary inconsistent:** `Active`, `In_Stock`, `InStock`, `Inactive`, `Maintenance`.
- **Repo bug (critical):** `IoTDeviceRepository.get_summary()` builds a dict referencing undefined locals `soil_sensors_online`, `weather_stations_online`, `gateway_hubs_online`, `smart_valves_online`, `soil_sensors_offline`, etc. (`iot_device_repository.py:40-51`) → **`NameError` → HTTP 500** on `GET /api/v1/iot/summary`.
- Populated by `backend/seed_iot_devices.py` (which **drops** the collection first).

### iot_orders / iot_fault_reports
- **Referenced** by `api/v1/iot.py` (`IoTOrderRepository`; `db["iot_fault_reports"]`) but **absent** from the live DB (MongoDB lazily creates them on first insert). No validator/index until then.
- `iot.py` performs manual **relational synchronization** between fault-report status and `iot_devices.status` (Maintenance/Active) — non-transactional.

### farm_owners (orphan)
- Exists with its own validator (`owner_id`, `company_id`, `full_name`, `phone`, `email`, `district`, `province`, `status` enum) and 5 indexes (`owner_id` unique, `company_id`, `phone`, `email` unique sparse).
- **Not declared in `db_schema.py`, not referenced by any backend module** — likely a leftover from an earlier model; safe to drop or adopt.

---

## 20. Schema Validators ($jsonSchema)

| Declared collection | Validator in code | Present in live DB |
|---|---|---|
| companies, farms, zones, trees, users, diseases, inspections, detection_results, disease_history, alerts, seasons, harvests, farm_targets, farm_performance, neighbor_contact_requests, weather_cache | ✅ (16) | 15 present (all but neighbor_contact_requests); weather_cache present **without** validator |
| iot_devices / iot_orders / iot_fault_reports / farm_owners | ❌ (not in code) | farm_owners has one (orphan); IoT none |

- Validators are applied at `validationLevel: "strict"`, `validationAction: "error"` by `create_collections_and_indexes()`.
- Validators **allow additional properties** (no `additionalProperties: false`), so drifted fields (`owner_id`, `health_status`, `disease_name`, `confidence`, `image_url`, `status: COMPLETED`) all pass validation.
- Enum constraints use **Vietnamese** values; several write paths produce **English/mixed** values (alerts `status "unread"`, trees `health_status "Thán thư"`), so enums are effectively unenforced for those fields.

---

## 21. Indexes

- **84 total live indexes** (67 explicit + 17 `_id`) across 17 collections; every collection in `indexes.py` (16 specs) is present except `neighbor_contact_requests`.
- Unique constraints verified live: companies name+code, farms farm_code, zones (farm_id, zone_name), trees tree_code, users user_code + email(sparse), diseases code, NCR request_code (collection absent).
- **TTL index:** only `weather_cache.cache_expired_at` (86,400 s) — see §18 mismatch.
- **Key drift:** `farms.idx_farms_owner_id` is built on `owner_id` (live) vs `owner_user_id` (declared).
- **Under-indexed:** `iot_devices` (73 docs, no query index); regex `$or` keyword searches in `UserRepository.get_all`, `AlertRepository.get_all`, `CompanyRepository.get_all`, `InspectionRepository.get_all` cannot use indexes.
- `indexes.py` docstring says "all 15 collections" but defines **16** — documentation nit.

---

## 22. Repository Layer

**`BaseRepository`** (`base.py`) — uniform `create/get/list/update/delete` with `created_at`/`updated_at` (UTC), ObjectId validation, `skip/limit` pagination, `_serialize`/`_deserialize` (id ↔ `_id`).

**21 specialized repositories:**

| Repository | Collection | Notable operations |
|---|---|---|
| UserRepository | users | get_by_email, refresh_token, keyword `$or`, KPI counts, exists_by_user_code |
| FarmRepository | farms | exists_by_id, list_by_owner (role-aware, multi-key `$or`) |
| ZoneRepository | zones | get_farm_id, list_by_farm |
| TreeRepository | trees | enrichment `$lookup`, health-status sub-pipeline, heatmap, KPI, count_by_farms, keyword |
| InspectionRepository | inspections | enrichment (trees+users), keyword w/ tree-code resolution, KPI |
| DetectionResultRepository | detection_results | enrichment (inspections+trees) |
| DiseaseHistoryRepository | disease_history | enrichment, KPI (distinct diseases) |
| DiseaseRepository | disease_history | list_by_tree, latest, count_diseased (aggregation) — **same collection as above** |
| DiseasesRepository | diseases | CRUD + exists_by_code |
| AlertRepository | alerts | keyword search incl. farm/tree resolution |
| NotificationRepository | alerts | get_latest — **naming mismatch (alerts)** |
| CompanyRepository | companies | get_company_stats (farms→zones→trees counts) |
| SeasonRepository | seasons | get_latest_by_farm (active→year→created) |
| HarvestRepository | harvests | latest, by farm+season, list_by_farm |
| FarmTargetRepository | farm_targets | by farm+season, list_by_farm |
| FarmPerformanceRepository | farm_performance | by farm+season, list_by_farm |
| NeighborContactRequestRepository | neighbor_contact_requests | status/direction counts, list_latest (collection absent) |
| WeatherRepository | weather_cache | cache CRUD/upsert/TTL/delete_expired |
| IoTDeviceRepository | iot_devices | get_summary (**NameError**), list_devices |
| IoTOrderRepository | iot_orders | create, by user, all, update_status |

**Assessment:** consistent pattern, good separation, but two name collisions (`Disease` vs `Diseases`; `Notification`→alerts) and one broken method.

---

## 23. Aggregations & Transactions

### Aggregations (used heavily, no `$facet`/`$graphLookup`)
- **Enrichment `$lookup`** (+`$unwind` preserveNull): trees→zones→farms (`tree_repository`), inspections→trees→users (`inspection_repository`), detection_results→inspections→trees (`detection_result_repository`), disease_history→trees, NCR→farms×2.
- **Correlated sub-pipelines:** latest `disease_history` per tree (`let`+`$expr`+`$sort`+`$limit 1`); latest detection per inspection (dashboard widgets).
- **Grouping:** `$group` by status/direction (`count_by_status`), by tree (`$first`+`$$ROOT`+`$replaceRoot` for priority trees), by date (`$dateToString` + `$avg` for risk trend), by `$toLower(priority)` for alert counts.
- **Filtering/aggregation:** `$filter` on embedded arrays (zone health counts), `$size`, `$switch` risk mapping.
- **Distinct/join logic** is often emulated in Python (`farmer_overview_service`, `dashboard.service._get_growth_trend` iterate all docs — fine at current scale, not at scale).

### Transactions
- **None.** No `start_transaction`, `with_transaction`, or `ClientSession` anywhere in `backend/` or `database/` (grep-verified).
- Consequence: the AI detect path (`ai/service.py`) writes **inspection → detection_result → disease_history → alert → tree update** in separate awaits; a failure mid-sequence leaves partial state. The standalone server (no replica set) cannot use multi-document transactions, so this requires either a replica set, outbox pattern, or compensating writes.

---

## 24. ETL, Seed & Migration Pipelines

### ETL (`database/etl_pipeline.py`, ~2,360 lines)
- Excel (`DGA_Enterprise_Dataset.xlsx`, sheets companies/farms/zones/trees/inspections/users/diseases/detection_results/disease_history/alerts) → normalized ObjectId graph → insert with duplicate fallback → **creates 16 collections + validators + indexes** → runs **orphan-reference validation** across 11 relationship paths.
- Auto-generates: Farm Owner users, seasons (2/farm), harvests, farm targets, farm performance, 25 neighbor-contact requests; enriches users with Vietnamese phone/address.
- `setup_database.py` orchestrates ETL + `seed_admin`; flags `--drop-existing`, `--dry-run`, `--verbose`.
- **Blockers:** hardcoded paths `D:/Code/Ai_For_Life/durian_guardian_ai/...` and `D:\Code\Ai_For_Life\...` do **not** match the current project root → ETL cannot run on this machine without edits. `seed/diseases.json` is empty (`[]`), so diseases require the Excel sheet.

### Seeds
- `seed_admin.py` — idempotent admin (`bao@gmail.com`/`123456`, bcrypt).
- `seed_farm_owners.py` — idempotent 10 Farm Owner users + links farms via `owner_user_id`.
- `backend/seed_1200_trees.py` — demo farm (1) + 5 zones + 1,200 trees; **destructive** (deletes trees/zones/farms/disease_history/diseases/detection_results) and triggered **on every backend startup when `trees < 1200`** (`main.py` `_seed_trees_if_empty`).
- `backend/seed_iot_devices.py` — 73 IoT devices; **drops** `iot_devices` first.

### Migration
- `migrate_vietnamese.py` — one-off English→Vietnamese `update_many` (regex `$replaceAll` for titles/messages) across diseases/trees/inspections/detection_results/disease_history/alerts, with verification of remaining English.

### Dataset builder
- `dataset_builder/mongodb_reader.py` — builds risk/history training DataFrames from inspections/trees/zones/farms/disease_history (used by Model 3).

---

## 25. API ↔ Collection Mapping

| API router | Collections accessed |
|---|---|
| auth, users, admin | users (JWT, roles) |
| companies | companies, farms, zones, trees |
| farms, zones, trees | farms, zones, trees, disease_history (status filtering) |
| inspections | inspections, trees, users |
| detection_results | detection_results, inspections, trees |
| disease_history | disease_history, trees |
| diseases | diseases |
| alerts | alerts, farms, trees |
| notifications | alerts |
| dashboard | users, farms, zones, trees, inspections, detection_results, disease_history, alerts, harvests, farm_targets, farm_performance, seasons, **iot_devices** |
| ai | trees, farms, zones, inspections, detection_results, disease_history, alerts |
| weather | weather_cache (via WeatherService/OpenWeather) |
| chat | users, farms, **iot_devices**, trees |
| iot (+ admin) | **iot_devices, iot_orders, iot_fault_reports** |
| farm_performance | farms, seasons, farm_performance, farm_targets, harvests |
| history | inspections, disease_history |
| farmer_overview (service) | users, farms (`owner_user_id`), zones, trees, inspections, detection_results, alerts, companies |

Every router depends on `get_database()` from `backend/app/database/mongodb.py`.

---

## 26. Findings, Gaps & Recommendations

### Critical
1. **`iot_devices` summary 500s** — fix undefined variables in `IoTDeviceRepository.get_summary()` (or replace with the aggregation pattern used in `chat_service`).
2. **Destructive startup auto-seed** — `_seed_trees_if_empty` deletes 6 core collections whenever `trees < 1200`; guard it (flag/env-gate, non-destructive upsert, count threshold check on all touched collections).
3. **Declared-but-missing collections** — `neighbor_contact_requests` (and, in the IoT area, `iot_orders`/`iot_fault_reports`) absent from the live DB; either provision them with validator+indexes or remove their declarations.

### High
4. **`owner_id` vs `owner_user_id` drift** — unify the field (validator, index, farm documents, and queries in `farmer_overview_service`/`chat_service`/`FarmRepository`).
5. **Alert priority language drift** — dashboard risk-trend/alert-count aggregations match English enums but live data is Vietnamese ("Cao"); normalize at write or map both.
6. **weather_cache TTL mismatch** — TTL index (86,400 s) vs code TTL (15 min); align to `WEATHER_CACHE_TTL_MINUTES` or rely solely on `delete_expired`.
7. **No transactions / non-atomic AI writes** — introduce replica set + `with_transaction` for inspection→detection→history→alert, or an outbox/compensation flow.
8. **ETL blocked on this machine** — fix hardcoded `D:/Code/Ai_For_Life/...` paths; populate empty `seed/diseases.json` (or document Excel requirement).
9. **Unit inconsistency** — `confidence` 59.91 in `detection_results` vs 0.5991 in `disease_history`; define one unit.

### Medium
10. **Orphan `farm_owners`** — adopt (add to `db_schema.py` + repo/router) or drop.
11. **IoT unvalidated/unindexed** — add validators + indexes for `iot_devices`, `iot_orders`, `iot_fault_reports`; normalize status vocabulary (`In_Stock` vs `InStock`).
12. **Repository naming** — `DiseaseRepository` (→`disease_history`) vs `DiseasesRepository` (→`diseases`); `NotificationRepository` (→`alerts`).
13. **Backend motor client** — add pool/timeout settings, wire `MongoDBManager.close()` to app shutdown.
14. **Default/weak credentials** — admin `123456` seeded twice; enforce password policy / env-driven seed in non-dev.
15. **No MongoDB access control** — localhost unauthenticated; enable auth (root config already supports SCRAM).
16. **Dashboard aggregation vs live enums** — `_get_alert_counts`/`_get_risk_trend` silently return 0 for Vietnamese priorities; `_get_recent_detections` pipeline runs against `disease_history` first and relies on fields (`disease_name`, `severity`, `image_url`) absent from `detection_results`.

### Low
17. `indexes.py` docstring "15 collections" vs 16 defined.
18. `db_schema.py` seeds-collections list (10) vs README (10) vs actual 16-collection registry — keep documentation in sync.
19. Regex keyword searches unindexed (`users`, `alerts`, `companies`, `inspections`, `disease_history`) — acceptable at current scale.

---

## 27. Final Rating Table & Verdict

| # | Component | Rating | Score | Evidence |
|---|---|---|---|---|
| 1 | **MongoDB Connection** | ⚠️ PARTIALLY READY | 7/10 | Root pymongo layer: pool 5–50, timeouts, auth, retryWrites, health check — excellent. Backend motor layer: bare defaults, no shutdown close |
| 2 | **Collections** | ⚠️ PARTIALLY READY | 6/10 | 16 declared vs 17 live; `neighbor_contact_requests`/`iot_orders`/`iot_fault_reports` missing; orphan `farm_owners` |
| 3 | **Schemas** | ⚠️ PARTIALLY READY | 7/10 | 16 `$jsonSchema` validators, strict mode; drift fields pass (no `additionalProperties:false`); weather_cache & IoT unvalidated |
| 4 | **Repository Layer** | ⚠️ PARTIALLY READY | 6/10 | Clean BaseRepository + 21 repos; `IoTDeviceRepository.get_summary()` NameError; naming collisions |
| 5 | **Indexes** | ⚠️ PARTIALLY READY | 7/10 | 84 live indexes, unique constraints verified; `owner_id` key drift; TTL 86,400s mismatch; iot_devices unindexed |
| 6 | **Aggregation** | ✅ READY | 8/10 | Rich `$lookup`/sub-pipeline/`$group`/`$dateToString`/`$replaceRoot` usage across repos + dashboard; minor unindexed sorts |
| 7 | **Weather Cache** | ✅ READY | 8/10 | Flattened schema, coords key, 15-min TTL, upsert/delete_expired, TTL index; TTL-index mismatch |
| 8 | **AI Database** | ⚠️ PARTIALLY READY | 7/10 | Full write-through (inspection→detection→history→alert) verified live; field/unit drift; non-atomic writes |
| 9 | **IoT Database** | ❌ NOT READY | 3/10 | 73 docs but no validator/index; broken summary endpoint; 2 referenced collections absent; status vocabulary inconsistent |
| 10 | **Authentication** | ⚠️ PARTIALLY READY | 7/10 | bcrypt + JWT + role mapping + unique user_code/email; weak default creds; no DB-level auth |

### Final Verdict

> ## ⚠️ DATABASE PARTIALLY READY
>
> **Durian Guardian AI's MongoDB layer is "partially ready" for production use.** The foundational engineering is strong and verified live: centralized schema/index registry, strict validators on 15 collections, 84 indexes with correct unique constraints, a clean repository layer, sophisticated aggregation for dashboard/heatmap/overview features, a well-designed weather cache (15-min TTL with cache-aside + M3 risk integration), and an AI write-through pipeline that persists real detection runs to `inspections`, `detection_results`, `disease_history`, and `alerts`.
>
> **It is not fully ready because:** (a) the **live database diverges from the declared schema** — `neighbor_contact_requests` is declared but absent, `iot_orders`/`iot_fault_reports` are referenced but absent, and `farm_owners` exists unused; (b) the **IoT layer is under-specified and buggy** — no validators/indexes, inconsistent status vocabulary, and a `NameError` that breaks `GET /iot/summary`; (c) **destructive startup auto-seeding** (`seed_1200_trees`) can wipe the core dataset on any boot when `trees < 1200`; (d) **field/unit drift** (`owner_id` vs `owner_user_id`, `confidence` 59.91 vs 0.5991, Vietnamese vs English enums) breaks several dashboard and overview queries; and (e) there are **no transactions**, so the multi-collection AI write is non-atomic.
>
> Executing the §26 recommendations — provisioning the missing collections, fixing the IoT summary bug and the destructive seeder, unifying `owner_*` fields and confidence units, aligning the weather TTL, and normalizing Vietnamese/English enums — will move the database to **✅ READY**.
