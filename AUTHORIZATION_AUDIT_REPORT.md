# AUTHORIZATION AUDIT REPORT
## Durian Guardian AI (DGA) — Release 1.3.x

**Audit type:** READ-ONLY Authorization Preparation Audit
**Agent:** OpenCode
**Scope:** Whole project (backend, frontend, database, mobile, ML)
**Mode:** READ / ANALYZE / SCAN / DOCUMENT — NO WRITE (except this report)
**Generated:** 2026-08-02

> Purpose: collect ALL information needed so a separate AI (Antigravity IDE) can later design Authorization. This report does NOT design authorization, RBAC, permission matrices, roles, policies, or code. It only states what exists in the project. Where the project has no information, the entry is marked **NOT FOUND** / **Not Implemented**.

---

## 1. System Architecture

### 1.1 Top-level view

```
D:\durian_guardian_ai  (git monorepo)
│
├── backend/        FastAPI (Python 3.12) REST API — the only server
├── frontend/       React 19 + Vite + TypeScript SPA (DGA Portal / admin web)
├── dga_mobile/     Flutter mobile app (DGA Mobile)
├── database/       MongoDB schema/validator/index/ETL/seed definitions
├── training/       ML Model 1 (disease classification) artifacts
├── training_quality/     ML Model 2 (image quality) artifacts
├── training/model3/      ML Model 3 (risk assessment) artifacts
├── training_recommendation/  ML Model 4 (recommendation engine) artifacts
├── model1_deployment/     Model 1 deployment notes
├── scripts/        Utilities (db check, reset, import, split, audit)
├── manual_review/  Screenshots + step6_results.json
├── docs/reports/   (empty)
├── reports/model4/ ML Model 4 reports
└── *.md            Release/audit/design reports at repo root
```

### 1.2 Runtime architecture

```
[Flutter dga_mobile]      [React frontend]
        │                         │
        │  HTTP (Dio/Axios)       │  HTTP (Axios)
        ▼                         ▼
   ┌─────────────────────────────────────────┐
   │   backend  —  FastAPI (app.main:create_app)│
   │   /api/v1/* routers (app.api.v1)          │
   │   Service layer (app.services, app.dashboard) │
   │   Repository layer (app.repositories)     │
   │   Auth (app.auth.service) / Security      │
   │   AI (app.ai.service) — mock inference    │
   └─────────────────────────────────────────┘
        │  Motor (async) MongoClient
        ▼
   MongoDB  →  database name: durian_guardian_ai_1 (default)
               durian_guardian_ai (README text)
               15 collections (db_schema.py), 10 seeded
```

- Web portal and mobile client share the same FastAPI backend.
- ML inference in the backend is currently a **mock** (`app/ai/service.py` — `_mock_detection()`); real trained models are offline artifacts only.
- No message broker, no external identity provider, no microservices.

### 1.3 Backend stack

| Concern | Technology | Evidence |
|---|---|---|
| Framework | FastAPI | `backend/app/main.py` |
| DB driver | Motor (async) / PyMongo (sync, in `database/`) | `app/database/mongodb.py`, `database/mongodb.py` |
| Config | pydantic-settings | `app/core/config.py` |
| Validation | Pydantic v2 | `app/schemas/*.py` |
| Auth | python-jose JWT (HS256) + passlib bcrypt | `app/core/security.py` |
| Auth deps | HTTPBearer, `get_current_user_id`, `get_current_user_role`, `RoleChecker` | `app/core/dependencies.py` |
| AI | Mock inference service + Ollama mock chat | `app/ai/service.py` |
| Uploads | StaticFiles mounted at `/uploads` | `app/main.py` |

### 1.4 Frontend stack

| Concern | Technology | Evidence |
|---|---|---|
| Framework | React 19 | `frontend/package.json` |
| Build | Vite 6 + TypeScript | `vite.config.ts`, `tsconfig*.json` |
| Router | react-router-dom v7 (createBrowserRouter) | `src/routes/index.tsx` |
| Data fetching | @tanstack/react-query + Axios | `src/App.tsx`, `src/api/*` |
| Styling | Tailwind CSS 3 + shadcn/ui config | `tailwind.config.js`, `components.json` |
| Charts | Recharts | `package.json` |

### 1.5 Database layer stack

| Concern | Technology | Evidence |
|---|---|---|
| Schema validators | `$jsonSchema` for 15 collections | `database/db_schema.py` |
| Indexes | Explicit index specs for 15 collections | `database/indexes.py` |
| ETL | CSV → MongoDB (10,000-row seed) | `database/etl_pipeline.py` |
| Seed | `seed_admin.py`, `seed_farm_owners.py`, `seed/__init__.py` + `seed/diseases.json` | `database/seed/` |
| Migrations | `migrate_vietnamese.py` | `database/` |

---

## 2. Folder Structure

### 2.1 `backend/app`

```
app/
├── main.py                  # FastAPI app factory, CORS, admin auto-seed (bao@gmail.com)
├── ai/service.py            # AIService (mock detect + image quality), OllamaService (mock)
├── api/v1/                  # All REST routers
│   ├── admin.py             # GET /admin/users/{id}/overview  (admin-only)
│   ├── ai.py                # POST /ai/detect, /ai/image-quality
│   ├── alerts.py            # alerts CRUD
│   ├── auth.py              # register/login/refresh/me/profile/logout/change-password
│   ├── chat.py              # POST /chat
│   ├── companies.py         # companies CRUD
│   ├── dashboard.py         # dashboard, heatmap, widgets, farm-performance, farm/{id}
│   ├── detection_results.py # detection-results CRUD
│   ├── disease_history.py   # disease-history CRUD
│   ├── diseases.py          # diseases CRUD
│   ├── farms.py             # farms CRUD
│   ├── history.py           # GET /history/{tree_id}
│   ├── inspections.py       # inspections CRUD
│   ├── notifications.py     # notifications (backed by alerts collection)
│   ├── trees.py             # trees CRUD + digital-id
│   ├── users.py             # users CRUD
│   ├── zones.py             # zones CRUD
│   └── __init__.py          # api_router assembly (/api/v1)
├── auth/service.py          # AuthService (register/login/refresh/logout/me/update/change-password)
├── core/
│   ├── config.py            # Settings (JWT, Mongo, CORS, uploads)
│   ├── dependencies.py      # get_current_user_id/role, RoleChecker, PaginationDep
│   ├── exceptions.py        # AppException + 400/401/403/404/409/500
│   ├── exception_handlers.py
│   ├── logging.py
│   ├── response.py          # success_response / error_response envelope
│   └── security.py          # bcrypt + JWT create/decode
├── dashboard/
│   ├── dto.py               # FarmPerformanceDTO
│   └── service.py           # DashboardService (1055 lines)
├── database/mongodb.py      # async MongoDBManager + get_database
├── models/enums.py          # UserRole (4 API roles), role mapping, NotificationStatus, SeverityLevel
├── repositories/            # base + per-collection repositories
├── schemas/                 # Pydantic DTOs (CRUD + response)
├── services/                # per-module business logic
└── utils/
```

### 2.2 `frontend/src`

```
src/
├── api/         axios client + interceptors (token attach, 401 → login)
├── auth/        authContext, tokenStorage (localStorage), constants, context
├── components/  common (DataTable, DrawerForm, Pagination, …) / dashboard / layout (Header, Sidebar, Footer)
├── hooks/       useAuth
├── layouts/     AppLayout
├── lib/         utils
├── pages/       alerts, auth (Login/Register), companies, dashboard, detection-results,
│                disease-history, diseases, farms, inspections, settings, trees, users (incl. FarmerOverview), zones
├── routes/      index.tsx (all routes), ProtectedRoute.tsx (auth-only guard)
├── services/    per-module API service wrappers
├── types/       TS interfaces (incl. user.company_id, db_role)
└── utils/       translate.ts (ROLE_VI, USER_STATUS_VI, NCR_STATUS_VI), dateFormatter, loadAllPages
```

### 2.3 `dga_mobile` (Flutter)

Clean-architecture feature folders: `authentication`, `dashboard`, `disease_detection`, `history`, `profile`, `recommendation`, `settings`, `splash`. Most features include `mock_*` datasources/repositories. Network layer in `core/network` (Dio client, `api_endpoints.dart`).

### 2.4 `database`

```
database/
├── config.py         # MONGODB_URI/USERNAME/PASSWORD, DATABASE_NAME (durian_guardian_ai_1)
├── db_schema.py      # 15 collection names + $jsonSchema validators
├── indexes.py        # index specs
├── mongodb.py        # sync singleton client
├── etl_pipeline.py   # CSV → Mongo (companies,farms,zones,trees,users,diseases,inspections,
│                     #  detection_results,disease_history,alerts)
├── migrate_vietnamese.py
├── seed_admin.py     # bao@gmail.com / 123456 / role "Admin"
├── seed_farm_owners.py  # 10 Farm Owner users linked to farms.owner_user_id
├── seed/__init__.py  # load_diseases from diseases.json
├── setup_database.py # CLI orchestrator (ETL → validators → indexes → admin seed)
└── README.md
```

---

## 3. Database Audit

- Driver/connection: **MongoDB**. Default DB name in `backend/app/core/config.py` = `durian_guardian_ai_1`; default in `database/config.py` = `durian_guardian_ai_1`; `database/README.md` text says `durian_guardian_ai` (documentation discrepancy).
- **15 collections** defined in `database/db_schema.py`.
- **10 collections** seeded by ETL (`seed_collections()`): companies, farms, zones, trees, users, diseases, inspections, detection_results, disease_history, alerts.
- **5 collections** are schema/index-only (no ETL, no REST CRUD): seasons, harvests, farm_targets, farm_performance, neighbor_contact_requests (read indirectly by dashboard/overview aggregations).
- JSON Schema validators exist for all 15 collections (see `get_collection_validators()`).
- Indexes defined for all 15 collections (see `get_index_specs()`).
- No `$lookup`/`dbRef` standard enforced by schema; relationships are plain `ObjectId` fields (no foreign-key enforcement at DB level).

### 3.1 Collections table

| # | Collection | Purpose | Primary Key | Owner/Company/Farm/User fields | Indexes (key fields) |
|---|---|---|---|---|---|
| 1 | `companies` | Legal farm-owning companies | `_id` (ObjectId), `company_code` unique | `owner` (text, nullable — **not** a user ref) | `company_name` unique, `company_code` unique |
| 2 | `farms` | Orchards/farms | `_id`, `farm_code` unique | `company_id`→companies, `owner_user_id`→users (Farm Owner), `manager_user_id`→users (Company Manager) | `company_id`, `farm_name`, `farm_code` unique, `owner_user_id`, `district` |
| 3 | `zones` | Zones within farms | `_id`, compound unique `(farm_id, zone_name)` | `farm_id`→farms | `(farm_id, zone_name)` unique |
| 4 | `trees` | Individual durian trees | `_id`, `tree_code` unique | `farm_id`→farms, `zone_id`→zones | `tree_code` unique, `farm_id`, `zone_id`, `status`, `variety` |
| 5 | `users` | System accounts | `_id`, `user_code` unique | **none** (no company_id/farm_id/zone_id) | `user_code` unique, `role`, `email` unique sparse |
| 6 | `diseases` | Disease master data | `_id`, `code` unique | none | `code` unique |
| 7 | `inspections` | Inspection records (tree health) | `_id`, `inspection_code` | `tree_id`→trees, `farm_id`→farms, `zone_id`→zones, `disease_id`→diseases, `inspector_id`→users (used in service; not in validator) | `tree_id`, `inspection_date` desc, `predicted_disease`, `health_status`, `farm_id`, `confidence` desc |
| 8 | `detection_results` | AI detection output | `_id` | `inspection_id`→inspections, `tree_id`→trees, `farm_id`→farms, `company_id`→companies | `inspection_id`, `tree_id`, `farm_id`, `company_id`, `prediction`, `created_at` desc |
| 9 | `disease_history` | Longitudinal disease records | `_id` | `tree_id`→trees, `farm_id`→farms, `company_id`→companies, `detected_by_user_id`→users | `tree_id`, `farm_id`, `company_id`, `disease`, `date` desc, `action` |
| 10 | `alerts` | System-generated alerts (also serves "notifications") | `_id` | `farm_id`→farms, `tree_id`→trees, `company_id`→companies, `acknowledged_by`→users | `created_at` desc, `priority`, `farm_id`, `tree_id`, `company_id`, `alert_type`, `status`, `(is_read, created_at)`, `date` desc |
| 11 | `seasons` | Season cycles per farm | `_id`, `season_id` | `farm_id`→farms | `farm_id`, `(farm_id, season_year)`, `season_year`, `status` |
| 12 | `harvests` | Yield/revenue per farm+season | `_id`, `harvest_id` | `farm_id`→farms, `season_id`→seasons | `farm_id`, `season_id`, `(farm_id, season_id)`, `harvest_date` desc |
| 13 | `farm_targets` | Targets per farm+season | `_id`, `target_id` | `farm_id`→farms, `season_id`→seasons | `farm_id`, `season_id`, `(farm_id, season_id)` |
| 14 | `farm_performance` | Computed farm score per farm+season | `_id`, `performance_id` | `farm_id`→farms, `season_id`→seasons | `farm_id`, `season_id`, `(farm_id, season_id)`, `overall_status`, `farm_score` desc |
| 15 | `neighbor_contact_requests` | Cross-farm contact sharing (two-party consent) | `_id`, `request_code` unique | `source_farm_id`→farms, `target_farm_id`→farms, `source_user_id`→users, `target_user_id`→users | `request_code` unique, `source_farm_id`, `target_farm_id`, `source_user_id`, `target_user_id`, `inspection_id`, `status`, `created_at` desc, `expires_at` |

### 3.2 Relationships (as defined by schema fields, NOT enforced by DB)

```
companies (owner: text — no user FK)
   │ company_id
   ▼
farms ──owner_user_id──► users (Farm Owner)
   │ farm_id            └──manager_user_id──► users (Company Manager)
   ▼
zones ──farm_id──► farms
   │ zone_id
   ▼
trees ──farm_id──► farms / ──zone_id──► zones
   │
   ├── inspections ──tree_id/farm_id/zone_id──► trees/farms/zones; inspector_id──► users
   │        └── detection_results ──inspection_id/tree_id/farm_id/company_id──► …
   ├── disease_history ──tree_id/farm_id/company_id/detected_by_user_id──► …
   └── alerts ──farm_id/tree_id/company_id/acknowledged_by──► …
seasons / harvests / farm_targets / farm_performance ──farm_id──► farms, ──season_id──► seasons
neighbor_contact_requests ──source_farm_id / target_farm_id──► farms,
                         ──source_user_id / target_user_id──► users
```

### 3.3 Key observations (facts, not proposals)

- The `users` collection has **no** `company_id`, `farm_id`, `zone_id`, `permissions`, or ownership array.
- Ownership-style fields exist on resource collections: `farms.owner_user_id`, `farms.manager_user_id`, and optional `company_id` on `detection_results`/`disease_history`/`alerts` (nullable).
- `companies.owner` is a free-text string, not a user reference.
- `inspections.inspector_id` is written by the service (`inspection_service.py:84`) but is **absent** from the collection validator (`db_schema.py` inspections schema).

---

## 4. Authentication Audit

### 4.1 Mechanism
- **JWT (HS256)** via `python-jose`; passwords hashed with **bcrypt** via passlib.
- Tokens contain claims: `sub` (user ObjectId as str), `role` (**DB role string**, e.g. `"Admin"`), `type` (`access`|`refresh`), `exp`, `iat`.
- Access token TTL: 30 min (`JWT_ACCESS_TOKEN_EXPIRE_MINUTES`). Refresh TTL: 7 days.
- Refresh token stored in `users.refresh_token`; rotation on refresh; revocation by clearing on logout.
- `decode_token` returns `{}` on `JWTError` (no exception raised).

### 4.2 Dependency chain (the only auth gate)
- `HTTPBearer(auto_error=False)` → `get_current_user_id` (decodes token, returns `sub`).
- `get_current_user_role` (decodes token, maps `db_role_to_api`).
- `RoleChecker(allowed_roles)` → calls `get_current_user_role`, raises `ForbiddenException` (403) if the role is not allowed.
- A **separate `ForbiddenException` (403)** exists in `core/exceptions.py`.

### 4.3 How roles are actually enforced
- Most routers define `allow_all = RoleChecker([r.value for r in UserRole])` = all 4 API roles allowed → effectively **any authenticated user**.
- Only `GET /admin/users/{user_id}/overview` uses `admin_only = RoleChecker([enterprise_admin])`.
- `history.py` and `chat.py` apply only `get_current_user_id` (no `RoleChecker`) → any authenticated user.
- Public (no auth): `/health`, `/docs`, `/redoc`, `/openapi.json`, `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`.

### 4.4 Endpoints summary (auth)

| Method | Route | Protected | Notes |
|---|---|---|---|
| POST | `/api/v1/auth/register` | Public | `role` optional, defaults to `field_technician`; no approval/email verification |
| POST | `/api/v1/auth/login` | Public | returns access+refresh |
| POST | `/api/v1/auth/refresh` | Public | refresh-token rotation |
| GET | `/api/v1/auth/me` | Auth | current user profile |
| PUT | `/api/v1/auth/profile` | Auth | self profile update (name/email) |
| POST | `/api/v1/auth/logout` | Auth | clears refresh token |
| PUT | `/api/v1/auth/change-password` | Auth | requires old password |

### 4.5 Auth gaps (observed facts)
- `login` does **not** check `users.status` (field exists in schema, seeded as `"ACTIVE"`).
- `register` is fully open and lets anyone self-register; there is no association to company/farm at registration.
- No token revocation list (only refresh-token clear).
- JWT secret default is a placeholder; only enforced as error when `ENVIRONMENT=production`.

---

## 5. User Model Audit

### 5.1 DB document shape (`users`, from `db_schema.py` + ETL)
```
{
  _id: ObjectId,
  user_code: "USR0001",        # unique
  full_name: str,
  role: enum[ "Admin", "Company Manager", "Farm Manager",
              "Farm Owner", "Inspector", "Technician" ],
  email: str|null,             # unique sparse
  password_hash: str|null,
  refresh_token: str|null,
  phone: str|null,
  status: str|null,            # "ACTIVE" in seed
  address: { province, district, ward, detail } | null,
  created_at, updated_at
}
```
- **No** `company_id`, **No** `farm_id`, **No** `zone_id`, **No** `permissions`, **No** ownership/assignment array.

### 5.2 Role model (two layers)

API role enum (`app/models/enums.py` `UserRole`): `farmer`, `field_technician`, `farm_manager`, `enterprise_admin`.

DB role strings ↔ API role mapping (`_DB_TO_API_ROLE`):

| DB role (stored in users.role) | API role |
|---|---|
| `Admin` | `enterprise_admin` |
| `Company Manager` | `farm_manager` |
| `Farm Manager` | `farm_manager` |
| `Inspector` | `field_technician` |
| `Technician` | `farmer` |
| `Farm Owner` | `farmer` |

- `db_role_to_api()` default fallback (unknown DB role) → `field_technician`.
- `api_role_to_db()` default fallback → `"Inspector"`.
- Note: `Farm Owner` and `Technician` both map to `farmer` at the API level, so role-based differentiation between them is **lost** after the mapping.

### 5.3 DTOs
- `UserOut` (auth, `schemas/user.py`): `id, full_name, email, role, created_at` — role is API role string; **no db_role**.
- `UserOut` (CRUD, `schemas/user_crud.py`): `id, user_code, full_name, email, role (UserRole), db_role, created_at` — includes `db_role`.
- `UserCreate`/`UserUpdate` (CRUD): `full_name, email, password, role` only — **no company/farm fields**.
- `UserProfileUpdate`: `full_name, email` only.

### 5.4 JWT claims
`sub` (user id), `role` (**DB role string**, e.g. `"Admin"`), `type`, `exp`, `iat`. No company_id/farm_id/permissions/scope claims.

### 5.5 Frontend user type (`types/user.ts`)
```
{ _id, user_code?, company_id?, full_name, email, phone?, role, db_role?,
  status?, created_at }
```
- **Discrepancy:** the frontend type declares `company_id` and the Users page UI includes a `company_id` form field and company filter, but the **backend does not persist or return** `company_id` on users (neither schema, nor DTO, nor repository). `CreateUserRequest.company_id` is dropped by the backend.

---

## 6. Route Audit (all under `/api/v1`)

Legend: **Public** = no token; **Auth** = any authenticated user (only `get_current_user_id`); **AnyRole** = Auth + `RoleChecker([all roles])` (equivalent to Auth); **AdminOnly** = `RoleChecker([enterprise_admin])`.

| # | Method | Route | Purpose | Module | Gate |
|---|---|---|---|---|---|
| 1 | POST | `/auth/register` | Create account | Auth | Public |
| 2 | POST | `/auth/login` | Login | Auth | Public |
| 3 | POST | `/auth/refresh` | Refresh token | Auth | Public |
| 4 | GET | `/auth/me` | Current profile | Auth | Auth |
| 5 | PUT | `/auth/profile` | Update profile | Auth | Auth |
| 6 | POST | `/auth/logout` | Logout | Auth | Auth |
| 7 | PUT | `/auth/change-password` | Change password | Auth | Auth |
| 8 | GET | `/companies` | List companies | Companies | AnyRole |
| 9 | GET | `/companies/{id}` | Company detail + stats | Companies | AnyRole |
| 10 | POST | `/companies` | Create company | Companies | AnyRole |
| 11 | PUT | `/companies/{id}` | Update company | Companies | AnyRole |
| 12 | DELETE | `/companies/{id}` | Delete company | Companies | AnyRole |
| 13 | GET | `/farms` | List farms | Farms | AnyRole |
| 14 | GET | `/farms/{id}` | Farm detail | Farms | AnyRole |
| 15 | POST | `/farms` | Create farm | Farms | AnyRole |
| 16 | PUT | `/farms/{id}` | Update farm | Farms | AnyRole |
| 17 | DELETE | `/farms/{id}` | Delete farm | Farms | AnyRole |
| 18 | GET | `/zones` | List zones (filter farm_id) | Zones | AnyRole |
| 19 | GET | `/zones/{id}` | Zone detail | Zones | AnyRole |
| 20 | POST | `/zones` | Create zone | Zones | AnyRole |
| 21 | PUT | `/zones/{id}` | Update zone | Zones | AnyRole |
| 22 | DELETE | `/zones/{id}` | Delete zone | Zones | AnyRole |
| 23 | GET | `/trees` | List trees (zone_id/farm_id/status filters) + KPI stats | Trees | AnyRole |
| 24 | GET | `/trees/{id}` | Tree detail | Trees | AnyRole |
| 25 | POST | `/trees` | Create tree | Trees | AnyRole |
| 26 | PUT | `/trees/{id}` | Update tree | Trees | AnyRole |
| 27 | GET | `/trees/{id}/digital-id` | Tree digital ID | Trees | AnyRole |
| 28 | DELETE | `/trees/{id}` | Delete tree | Trees | AnyRole |
| 29 | GET | `/users` | List users + KPI stats | Users | AnyRole |
| 30 | GET | `/users/{id}` | User detail | Users | AnyRole |
| 31 | POST | `/users` | Create user | Users | AnyRole |
| 32 | PUT | `/users/{id}` | Update user | Users | AnyRole |
| 33 | DELETE | `/users/{id}` | Delete user | Users | AnyRole |
| 34 | GET | `/inspections` | List inspections + KPI | Inspections | AnyRole |
| 35 | GET | `/inspections/{id}` | Inspection detail | Inspections | AnyRole |
| 36 | POST | `/inspections` | Create inspection (sets inspector_id = caller) | Inspections | AnyRole |
| 37 | PUT | `/inspections/{id}` | Update inspection | Inspections | AnyRole |
| 38 | DELETE | `/inspections/{id}` | Delete inspection | Inspections | AnyRole |
| 39 | GET | `/detection-results` | List detection results | Detection Results | AnyRole |
| 40 | GET | `/detection-results/{id}` | Detail | Detection Results | AnyRole |
| 41 | POST | `/detection-results` | Create | Detection Results | AnyRole |
| 42 | PUT | `/detection-results/{id}` | Update | Detection Results | AnyRole |
| 43 | DELETE | `/detection-results/{id}` | Delete | Detection Results | AnyRole |
| 44 | GET | `/disease-history` | List disease history + KPI | Disease History | AnyRole |
| 45 | GET | `/disease-history/{id}` | Detail | Disease History | AnyRole |
| 46 | POST | `/disease-history` | Create | Disease History | AnyRole |
| 47 | PUT | `/disease-history/{id}` | Update | Disease History | AnyRole |
| 48 | DELETE | `/disease-history/{id}` | Delete | Disease History | AnyRole |
| 49 | GET | `/diseases` | List diseases | Diseases | AnyRole |
| 50 | GET | `/diseases/{id}` | Disease detail | Diseases | AnyRole |
| 51 | POST | `/diseases` | Create disease | Diseases | AnyRole |
| 52 | PUT | `/diseases/{id}` | Update disease | Diseases | AnyRole |
| 53 | DELETE | `/diseases/{id}` | Delete disease | Diseases | AnyRole |
| 54 | GET | `/alerts` | List alerts | Alerts | AnyRole |
| 55 | GET | `/alerts/{id}` | Alert detail | Alerts | AnyRole |
| 56 | POST | `/alerts` | Create alert | Alerts | AnyRole |
| 57 | PUT | `/alerts/{id}` | Update alert | Alerts | AnyRole |
| 58 | DELETE | `/alerts/{id}` | Delete alert | Alerts | AnyRole |
| 59 | GET | `/notifications/unread` | List unread notifications | Notifications | AnyRole |
| 60 | GET | `/notifications` | List notifications (filter farm_id) | Notifications | AnyRole |
| 61 | GET | `/notifications/{id}` | Notification detail | Notifications | AnyRole |
| 62 | POST | `/notifications` | Create notification (writes alerts doc) | Notifications | AnyRole |
| 63 | PUT | `/notifications/{id}/read` | Mark read | Notifications | AnyRole |
| 64 | DELETE | `/notifications/{id}` | Delete notification | Notifications | AnyRole |
| 65 | GET | `/dashboard` | Main dashboard | Dashboard | Auth |
| 66 | GET | `/dashboard/heatmap` | Heatmap data | Dashboard | AnyRole |
| 67 | GET | `/dashboard/widgets` | Widget data | Dashboard | AnyRole |
| 68 | GET | `/dashboard/farm-performance` | Farm performance (optional farm_id) | Dashboard | AnyRole |
| 69 | GET | `/dashboard/farm/{farm_id}` | Farm-level dashboard | Dashboard | AnyRole |
| 70 | GET | `/history/{tree_id}` | Tree history | History | Auth |
| 71 | POST | `/chat` | AI agronomist chat | Chat | Auth |
| 72 | POST | `/ai/detect` | AI disease detection (mock) | AI | AnyRole |
| 73 | POST | `/ai/image-quality` | Image quality check (mock) | AI | AnyRole |
| 74 | GET | `/admin/users/{user_id}/overview` | Farmer overview (admin) | Admin | **AdminOnly** |
| — | GET | `/health` | Health check | System | Public |
| — | GET | `/docs` `/redoc` `/openapi.json` | Swagger | System | Public |

> Facts: 73 REST endpoints under `/api/v1` (auth/register+login+refresh are the only public API endpoints). All resource CRUD is available to **any authenticated user**; only the farmer-overview endpoint is role-restricted. There is **no** per-object, per-company, or per-farm scope check on any route.

---

## 7. Frontend Module Audit

### 7.1 Routes (`frontend/src/routes/index.tsx`)

| Module | URL | Component | Sidebar menu (Vietnamese) | Protected |
|---|---|---|---|---|
| Login | `/login` | `pages/auth/Login` | — | Public |
| Register | `/register` | `pages/auth/Register` | — | Public |
| Root redirect | `/` → `/dashboard` | `Navigate` | — | Auth |
| Dashboard | `/dashboard` | `pages/dashboard/Dashboard` | Bảng điều khiển | Auth |
| Farm Dashboard | `/dashboard/farm/:farmId` | `pages/dashboard/FarmDashboard` | (child) | Auth |
| Companies | `/companies` | `pages/companies/Companies` | Công ty | Auth |
| Farms | `/farms` | `pages/farms/Farms` | Trang trại | Auth |
| Zones | `/zones` | `pages/zones/Zones` | Khu vực | Auth |
| Trees | `/trees` | `pages/trees/Trees` | Cây | Auth |
| Users | `/users` | `pages/users/Users` | Người dùng | Auth |
| Farmer Overview | `/users/:user_id` | `pages/users/FarmerOverview` | (child of Users) | Auth |
| Inspections | `/inspections` | `pages/inspections/Inspections` | Kiểm tra | Auth |
| Detection Results | `/detection-results` | `pages/detection-results/DetectionResults` | (hidden from sidebar) | Auth |
| Disease History | `/disease-history` | `pages/disease-history/DiseaseHistory` | Lịch sử phát sinh bệnh | Auth |
| Alerts | `/alerts` | `pages/alerts/Alerts` | Cảnh báo | Auth |
| Diseases | `/diseases` | `pages/diseases/Diseases` | (hidden from sidebar) | Auth |
| Settings | `/settings` | `pages/settings/Settings` | (via header) | Auth |
| Fallback | `*` → `/login` | `Navigate` | — | — |

- Sidebar (`components/layout/Sidebar.tsx`) hardcodes all menu items; **no role/menu filtering**. It hides only `/detection-results` and `/diseases` via a constant `HIDDEN_MENU_PATHS`.
- `ProtectedRoute.tsx` guards only on **authentication** (`isAuthenticated`), **not** on role or scope.
- Header (`components/layout/Header.tsx`) displays `user.role` label (no role-specific actions found).

### 7.2 Pages and features (frontend)

| Page | CRUD | Search | Filter | Detail | Notes |
|---|---|---|---|---|---|
| Dashboard | Read | — | farm | — | KPI cards, heatmap, weather, agronomist panel, tables |
| FarmDashboard | Read | — | — | — | farm-level KPIs, heatmap, performance, yield |
| Companies | CRUD | keyword | — | detail drawer | stats: farms/zones/trees |
| Farms | CRUD | keyword | — | detail drawer | maps, areas |
| Zones | CRUD | keyword | farm_id | detail drawer | tree_count |
| Trees | CRUD | keyword | zone/farm/status | detail drawer | digital-id, mock data file present |
| Users | CRUD | keyword | role/company/status | detail drawer | role+company form fields; farmer overview link |
| FarmerOverview | Read | — | — | — | profile+farm+inspection+alert+neighbor+activity |
| Inspections | CRUD | keyword | — | detail drawer | KPI stats |
| DetectionResults | CRUD | keyword | — | detail drawer | mock data file present |
| DiseaseHistory | CRUD | keyword | — | detail drawer | KPI stats |
| Diseases | CRUD | keyword | — | detail drawer | |
| Alerts | CRUD | keyword | — | detail drawer | mock data file present |
| Settings | Read/Update | — | — | — | profile + preferences |

- Several pages ship local `mockData.ts` fallbacks (alerts, detection-results, disease-history, diseases, farms, inspections, trees, zones) used when the API fails.

### 7.3 Frontend role usage (facts)
- `translate.ts` maps API role values (`enterprise_admin`, `farm_manager`, `field_technician`, `farmer`) and DB role strings (`Admin`, …) to Vietnamese labels.
- Users page filters/color-codes by `db_role` (`Farm Owner`, `Admin`, `Inspector`, `Company Manager`, `Farm Manager`).
- No route-level or component-level role gating found anywhere in `frontend/src`.

---

## 8. CRUD Audit

| Module | Create | Read (list/detail) | Update | Delete | Export | Import | Search | Filter | Detail |
|---|---|---|---|---|---|---|---|---|---|
| Companies | ✅ `POST /companies` | ✅ `GET /companies`, `/companies/{id}` | ✅ `PUT` | ✅ `DELETE` | ❌ | ❌ (ETL only) | ✅ keyword | ❌ | ✅ |
| Farms | ✅ `POST /farms` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ❌ | ✅ |
| Zones | ✅ `POST /zones` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ✅ farm_id | ✅ |
| Trees | ✅ `POST /trees` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ✅ zone_id, farm_id, status | ✅ + digital-id |
| Users | ✅ `POST /users` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ❌ (frontend-only role/company/status) | ✅ |
| Inspections | ✅ `POST /inspections` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ❌ | ✅ |
| DetectionResults | ✅ `POST /detection-results` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ❌ | ✅ |
| DiseaseHistory | ✅ `POST /disease-history` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ❌ | ✅ |
| Diseases | ✅ `POST /diseases` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ❌ | ✅ |
| Alerts | ✅ `POST /alerts` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ keyword | ❌ | ✅ |
| Notifications | ✅ `POST /notifications` | ✅ (list/unread/detail) | ✅ read | ✅ | ❌ | ❌ | ❌ | ✅ farm_id | ✅ |
| Dashboard | — | ✅ (dashboard/heatmap/widgets/farm-performance/farm) | — | — | ❌ | ❌ | ❌ | ✅ farm_id (performance) | ✅ |
| History | ❌ | ✅ `/history/{tree_id}` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Chat / AI | ✅ `/ai/detect`, `/ai/image-quality`, `/chat` | — | — | — | ❌ | ❌ | ❌ | ❌ | — |
| Admin Overview | — | ✅ `/admin/users/{id}/overview` | — | — | ❌ | ❌ | ❌ | ❌ | ✅ |

> Import = bulk CSV/Excel ingestion exists only via offline `database/etl_pipeline.py` (not an API). Export = **NOT FOUND** anywhere in the project.

---

## 9. Business Flow (current implementation only)

### 9.1 Hierarchical entity flow
```
Company ──companies──► Farm ──farms──► Zone ──zones──► Tree ──trees──►
  │                                                                   │
  ├─ companies.company_id (farms)                                     ├─ inspections (per tree)
  ├─ farms.owner_user_id (Farm Owner)                                 ├─ detection_results
  ├─ farms.manager_user_id (Company Manager)                          ├─ disease_history
  └─ zones.farm_id (zones)                                            └─ alerts
                                                                        (all carry farm_id/tree_id,
                                                                         some carry company_id)
Season/period flow (farm level):
  seasons ──► harvests ──► farm_targets ──► farm_performance   (schema-only; read by DashboardService)
Cross-farm flow:
  neighbor_contact_requests (source/target farm + user, consent statuses)
```

### 9.2 Inspection → Detection → History → Alert flow (as coded)
1. `TreeService`/`ZoneService` maintain tree↔zone↔farm linkage (`trees.farm_id` derived from zone at create/update — `tree_service.py:60-72`).
2. `POST /inspections` validates tree + inspector exists, writes `inspections` with `inspector_id = current user id`, weather fields, predicted disease, confidence, health status (`inspection_service.py`).
3. `POST /ai/detect` (mock) saves the uploaded image and records a `detection` record; `detection_results` CRUD can store results per `inspection_id`.
4. `disease_history` CRUD logs longitudinal per-tree disease/action records.
5. `alerts` CRUD + `notifications` (writes into `alerts`) create warnings per farm/tree with `priority` and `is_read`/`status`.
6. Dashboards aggregate: `DashboardService.get_dashboard(user_id)` and `get_farm_dashboard(farm_id)`; `FarmerOverviewService.get_overview(user_id)` for a Farm Owner user scoped by `farms.owner_user_id`.
7. `POST /chat` builds a prompt from tree + disease history and returns a (mock) agronomist answer.

### 9.3 Where the current "user-scoping" actually happens (facts)
- Only **`FarmerOverviewService`** scopes data by user: it looks up farms where `owner_user_id == user` and counts zones/trees/inspections/alerts within those farms (`farmer_overview_service.py:56-77`).
- `DashboardService.get_dashboard(user_id)` passes `user_id` to `FarmRepository.list_by_owner(user_id, …)`, but that repository method builds an **empty** filter (owner param unused) — so the dashboard is effectively global. (`farm_repository.py:18-31`).
- `FarmService.list_farms` also calls `list_by_owner` (unfiltered).
- No other service filters by current user.

---

## 10. Ownership Audit

| Aspect | Status | Evidence / Notes |
|---|---|---|
| Company Ownership | **Not Implemented** | `companies` has no user ref (only free-text `owner` string in schema). No API assigns a company to a user. |
| Farm Ownership | **Partial / seed-only** | `farms.owner_user_id` and `farms.manager_user_id` exist in schema + indexes; seeded by `seed_farm_owners.py` / ETL. `FarmerOverviewService` uses `owner_user_id` to scope a Farm Owner's overview. **No API or middleware enforces it** for farm CRUD; `FarmRepository.list_by_owner` ignores the owner filter. |
| User Ownership (user→company/farm/zone) | **Not Implemented** | `users` has no `company_id`/`farm_id`/`zone_id`; register/user-create accept none. |
| Assignment | **Not Implemented** | No endpoint assigns users to companies/farms/zones. |
| Scope (row-level restriction by tenant) | **Not Implemented** | No query filter in any list/get by current user's company/farm. |
| Hierarchy | **Exists in data model only** | company → farm → zone → tree links exist via ObjectId fields; no authorization traversal uses them. |
| Permission/ownership table | **NOT FOUND** | No collection for permissions, user-role assignments, or resource owners beyond the fields above. |
| `neighbor_contact_requests` ownership | **Partial** | Records carry `source_user_id`/`target_user_id` and consent booleans; used only for overview counts, **no API exposes them**, no enforcement. |

---

## 11. Authorization Readiness

Assessment scale used: **Implemented** = present and wired into code; **Partial** = present in some form but not fully enforced; **Not Implemented** = absent.

| Component | Status | Evidence |
|---|---|---|
| Authentication (JWT login/refresh) | **Implemented** | `auth/service.py`, `core/security.py` |
| Role definitions (enum + DB strings) | **Implemented** | `models/enums.py` (4 API roles, 6 DB roles) |
| Role claim in JWT | **Implemented** | `create_access_token` embeds `role` (DB role string) |
| Role guard dependency (RoleChecker) | **Implemented** (only used for admin overview; other routers use allow-all) | `core/dependencies.py:53-64`, `api/v1/admin.py` |
| Role-based route protection (broad) | **Partial** | `allow_all = RoleChecker([all roles])` on most routers = any authenticated user |
| Company Scope | **Not Implemented** | No company scoping logic anywhere |
| Farm Scope | **Not Implemented** (except Farm Owner overview reads) | `FarmerOverviewService` scopes by `owner_user_id`; all other modules global |
| Ownership (user↔entity) | **Not Implemented** | Users have no ownership fields; no ownership checks |
| Assignment | **Not Implemented** | No assignment API |
| Permission system / Permission Table | **Not Implemented / NOT FOUND** | No permissions collection, enum, or code |
| RBAC | **Partial** | Role exists + one role-checked endpoint; no permission matrix, no role hierarchy semantics defined |
| ABAC / Policies | **Not Implemented** | No policy engine |
| Claims (beyond sub/role/type) | **Not Implemented** | No tenant/company/farm/permission claims |
| Resource Guard / object-level check | **Not Implemented** | None |
| Middleware (authz) | **Not Implemented** | No global authz middleware; only per-route dependencies |
| Decorator-based auth | **Partial** | FastAPI `Depends(RoleChecker(...))` pattern (equivalent to decorator) |
| Dependency for auth | **Implemented** | `get_current_user_id`, `get_current_user_role`, `RoleChecker` |
| User status / enabled check | **Not Implemented** | `users.status` stored but never checked on login |
| Permission Matrix / Role Matrix | **NOT FOUND** | No file/table defining role→permission mappings |
| Frontend route guarding by role | **Not Implemented** | `ProtectedRoute` checks auth only |

---

## 12. Dependency Map (Module → Repository → Service → DTO → API → Frontend)

> Repository classes live in `backend/app/repositories` (BaseRepository: create/get/list/update/delete). Service classes in `backend/app/services` (plus `dashboard/service.py`, `ai/service.py`, `auth/service.py`). DTOs in `backend/app/schemas`. Routers in `backend/app/api/v1`. Frontend services in `frontend/src/services`, pages in `frontend/src/pages`.

| Module | Repository | Service | DTOs (schemas) | API router | Frontend service / page |
|---|---|---|---|---|---|
| Auth | `UserRepository` | `AuthService` (`auth/service.py`) | `user.py` (UserRegister/Login/Out/ProfileUpdate/ChangePassword), `response_models.py` | `auth.py` | `services/auth.service.ts`, `pages/auth/*`, `auth/authContext.tsx` |
| Companies | `CompanyRepository` | `CompanyService` | `company.py` | `companies.py` | `services/company.service.ts`, `pages/companies/Companies.tsx` |
| Farms | `FarmRepository` | `FarmService` | `farm.py` | `farms.py` | `services/farm.service.ts`, `pages/farms/Farms.tsx` |
| Zones | `ZoneRepository` | `ZoneService` | `zone.py` | `zones.py` | `services/zone.service.ts`, `pages/zones/Zones.tsx` |
| Trees | `TreeRepository` | `TreeService` | `tree.py` | `trees.py` | `services/tree.service.ts`, `pages/trees/Trees.tsx` |
| Users (CRUD) | `UserRepository` | `UserService` | `user_crud.py` | `users.py` | `services/user.service.ts`, `pages/users/Users.tsx` |
| Farmer Overview | `UserRepository`, `NeighborContactRequestRepository` | `FarmerOverviewService` | `farmer_overview.py` | `admin.py` | `services/farmerOverview.service.ts`, `pages/users/FarmerOverview.tsx` |
| Inspections | `InspectionRepository`, `TreeRepository`, `UserRepository` | `InspectionService` | `inspection.py` | `inspections.py` | `services/inspection.service.ts`, `pages/inspections/Inspections.tsx` |
| Detection Results | `DetectionResultRepository`, `InspectionRepository` | `DetectionResultService` | `detection_result.py` | `detection_results.py` | `services/detectionResult.service.ts`, `pages/detection-results/DetectionResults.tsx` |
| Disease History | `DiseaseHistoryRepository`, `TreeRepository` | `DiseaseHistoryService` | `disease_history.py` | `disease_history.py` | `services/diseaseHistory.service.ts`, `pages/disease-history/DiseaseHistory.tsx` |
| Diseases | `DiseaseRepository` / `DiseasesRepository` (dual) | `DiseaseService` | `disease.py` | `diseases.py` | `services/disease.service.ts`, `pages/diseases/Diseases.tsx` |
| Alerts | `AlertRepository` (via alerts.py imports) | `AlertService` | `alert.py` | `alerts.py` | `services/alert.service.ts`, `pages/alerts/Alerts.tsx` |
| Notifications | `NotificationRepository` (writes `alerts`), `ZoneRepository`, `TreeRepository` | `NotificationService` | `notification.py` | `notifications.py` | (no dedicated service file; used via pages) |
| History | `DiseaseRepository` | `HistoryService` | `disease.py` (reuse) | `history.py` | (used by dashboard/tree pages) |
| Chat | `DiseaseRepository`, `TreeRepository`, `ZoneRepository`, `OllamaService` | `ChatService` | `chat.py` | `chat.py` | `components/dashboard/AgronomistPanel.tsx` |
| AI Detection | `DiseaseRepository`, `TreeRepository` | `AIService` | `disease.py` (DetectionResponse/Result) | `ai.py` | (mobile + detection flow) |
| Dashboard | `FarmRepository`, `TreeRepository`, `NotificationRepository`, `SeasonRepository`, `FarmPerformanceRepository`, `FarmTargetRepository`, `HarvestRepository` | `DashboardService` (`dashboard/service.py`) | `dashboard.py`, `dashboard/dto.py` | `dashboard.py` | `pages/dashboard/Dashboard.tsx`, `FarmDashboard.tsx`, `components/dashboard/*` |
| Database layer (sync) | — | — | — | — | `database/db_schema.py`, `database/indexes.py`, `database/etl_pipeline.py`, `database/seed_*` |

---

## 13. Known Risks (observed in code — no fix suggested)

1. **No tenant/ownership scoping.** All CRUD list/get/create/update/delete endpoints accept any authenticated user; there is no company/farm/zone scope check (`api/v1/*`, `repositories/base.py`).
2. **`RoleChecker([all roles])` is effectively no authorization** — it passes for every role, so the 4-role model currently guards only the single admin overview endpoint.
3. **`FarmRepository.list_by_owner` ignores `owner_id`** — the filter dict is empty (`farm_repository.py:23-25`), so "my farms" returns all farms; dashboard KPI is global.
4. **Open self-registration** with default `field_technician` role and no approval, no company/farm association, no email verification.
5. **Role ambiguity:** `Farm Owner` and `Technician` both map to API role `farmer`; `Company Manager` and `Farm Manager` both map to `farm_manager`. Any future RBAC must be built on `db_role`, not API role.
6. **Token payload trusts DB role string** with silent fallback to `field_technician` for unknown roles (`enums.py:34`) — an unknown/legacy role silently downgrades (or, with custom mapping, could escalate if added).
7. **`users.status` never enforced** — disabled/archived users can still log in.
8. **Default credentials:** `bao@gmail.com / 123456` auto-seeded admin (`main.py`, `seed_admin.py`); default JWT secret in dev.
9. **Frontend/backend user model mismatch:** frontend `User.company_id` exists in types + UI but backend neither stores nor returns it.
10. **Notifications are global:** `list_unread` has no user filter — every authenticated user sees the same unread set.
11. **`inspections.inspector_id`** is written but missing from the collection validator (schema drift).
12. **Public `/docs`/`/openapi.json`** exposes the full API surface with no auth.
13. **DB name inconsistency** between docs (`durian_guardian_ai`) and code defaults (`durian_guardian_ai_1`).
14. **Mobile app** uses mock repositories/datasources for most features (no server authz exercised).

---

## 14. Information Missing

Entries marked **NOT FOUND** where the project provides no data.

| Item | Status |
|---|---|
| Role semantics / responsibilities per role (what each role may do) | **NOT FOUND** (roles exist as names only) |
| Role hierarchy / inheritance definition | **NOT FOUND** |
| Permission definitions / permission catalog | **NOT FOUND** |
| Tenant/company scoping requirements | **NOT FOUND** in code (README describes multi-farm agribusiness targets only) |
| Farm ownership enforcement requirements | **NOT FOUND** (only seed data sets `owner_user_id`) |
| User↔farm/company assignment requirements | **NOT FOUND** |
| Required behavior of `neighbor_contact_requests` consent endpoints | **NOT FOUND** (no API; statuses only counted in overview) |
| Notification → user targeting rules | **NOT FOUND** (notifications not tied to users) |
| Auth policy for the Flutter app vs web | **NOT FOUND** (mobile is mock-heavy) |
| Production users data / real role distribution | **NOT FOUND** (seed-only dataset) |
| Any authorization spec/design doc | **NOT FOUND** (no doc in repo references authorization) |
| Export/Import API requirements | **NOT FOUND** |
| Which users can create/delete companies vs farms vs users | **NOT FOUND** |

---

## 15. Recommendations For Antigravity (preparation notes only — not a design)

These point to project facts that the Authorization design should account for. No design decisions are made here.

1. **Ground truth for roles:** use the **6 DB role strings** stored in `users.role` (see §5.2), because the 4 API roles collapse distinct DB roles. The authoritative mapping lives in `backend/app/models/enums.py`.
2. **Available scope hooks already in the data:** `farms.company_id`, `farms.owner_user_id`, `farms.manager_user_id`, `zones.farm_id`, `trees.farm_id/zone_id`, optional `company_id` on `detection_results`/`disease_history`/`alerts`, `inspections.inspector_id`, and `neighbor_contact_requests.source_/target_user_id`. `users` currently has **no** scope fields.
3. **Where to enforce:** the single gate is FastAPI dependencies in `backend/app/core/dependencies.py` (`get_current_user_id`, `get_current_user_role`, `RoleChecker`); resource access flows through `BaseRepository` (`repositories/base.py`) and per-module services — these are the natural seams.
4. **Schema constraints to respect:** JSON Schema validators in `database/db_schema.py` will reject writes to undeclared fields; adding user scope fields (e.g. company/farm on `users`) requires validator + index changes in `database/`.
5. **Discrepancies to resolve before designing:** `inspections.inspector_id` missing from validator; frontend `User.company_id` vs backend absence; DB name doc drift.
6. **Existing precedent:** `FarmerOverviewService` already demonstrates user-scoped aggregation via `farms.owner_user_id`; the admin overview endpoint is the only current role-restricted route — a reference for how guards are wired.
7. **Frontend:** route protection today is auth-only (`ProtectedRoute.tsx`); role/menu gating would be new. The sidebar and `routes/index.tsx` are the seams.
8. **Non-goals implied by project state:** no OAuth/SSO/IDP present; no permission tables; no policy engine — the design will be greenfield for RBAC/ownership on top of existing JWT auth.
9. **Mobile app** (`dga_mobile`) consumes the same backend but is largely mock-backed; the design should decide whether mobile receives the same token/role model.

---

*End of AUTHORIZATION_AUDIT_REPORT.md. Audit complete — READ ONLY. No code, files, or git changes were made beyond the creation of this report.*
