# AUTHORIZATION AUDIT EXTENSION
## Durian Guardian AI (DGA) — Release 1.3.x

**Audit type:** READ-ONLY Authorization Preparation Audit — EXTENSION
**Agent:** OpenCode
**Scope:** NEW INFORMATION ONLY. Supplements `AUTHORIZATION_AUDIT_REPORT.md`.
**Mode:** READ / ANALYZE / SCAN / DOCUMENT — NO WRITE (except this report)
**Generated:** 2026-08-02

> This extension **does NOT repeat** the content of `AUTHORIZATION_AUDIT_REPORT.md` (route audit, database audit, collections, authentication, user model, dependency map, risks, readiness, recommendations). It only adds the information that report did not contain, grouped into the 6 sections required by the extension brief.
>
> **NO** authorization / RBAC / role / permission design is made here. Everything below is a factual description of what exists today. Where the project provides no data, the entry is marked **NOT FOUND** / **NOT IMPLEMENTED**.
>
> Read the old report first; this file assumes it as context and never restates it.

---

## 1. Business Use Cases

Purpose: per module — the business served, current CRUD, current UI, current flow, current upstream data. Facts only; **no** "who may do X" statements.

| Module | Business served today | Current CRUD | Current UI | Current flow (as coded) | Current upstream data |
|---|---|---|---|---|---|
| Auth (Login / Register / Session) | Identity entry and session management | register / login / refresh / logout / me / profile / change-password | `/login`, `/register` (public pages) | Register → login → access+refresh tokens stored in `localStorage` → `AuthProvider` bootstraps `/auth/me` → protected shell renders | `users` collection, `AuthService`, `UserRepository` |
| Dashboard (Tổng quan) | Whole-enterprise durian-farm health monitoring (KPI, heatmap, AI agronomist, real-time inspection log, farm performance) | Read-only aggregations | `/dashboard` + `components/dashboard/*` (KPISection, HeatmapCard, AgronomistPanel, RealtimeInspectionCard, FarmPerformanceCard, TreeDistributionCard, SystemOverviewCard) | Loads `/dashboard`, `/dashboard/heatmap`, `/dashboard/widgets` in parallel; farm/zone filters applied client-side on the returned data; FarmPerformanceCard loads `/dashboard/farm-performance` | farms, zones, trees, inspections, detection_results, alerts, seasons, harvests, farm_targets, farm_performance |
| Companies (Công ty) | Legal company (top of hierarchy) master data + per-company stats | Full CRUD | `/companies` — list + detail drawer; list rows hydrate farms/zones/trees counts | List/detail call `CompanyService` which appends `get_company_stats` (farms/zones/trees counts) to each company | `companies` collection, `CompanyRepository` |
| Farms (Trang trại) | Orchard/farm master data; carries owner/manager linkage fields (seed-only) | Full CRUD | `/farms` — list + detail drawer; farm dashboard reachable from Dashboard | `FarmService.list_farms(user_id,…)` → `FarmRepository.list_by_owner(user_id,…)` (owner filter built as empty dict → all farms) | `farms`, `companies` (via `company_id`) |
| Zones (Khu vực) | Zone (sub-area of farm) master data; `tree_count` counter | Full CRUD | `/zones` — list (farm_id filter) + detail drawer | `ZoneService.list_zones` branches to `list_by_farm` when `farm_id` given, else global list | `zones`, `farms` (via `farm_id`) |
| Trees (Cây) | Individual durian tree registry with health status; digital-id dossier | Full CRUD + `/trees/{id}/digital-id` | `/trees` — list (zone/farm/status filters) + detail drawer; digital-id view | `TreeService` derives `farm_id` from the chosen zone at create/update (`zone_repo.get_farm_id`); KPI stats endpoint; digital-id = tree + per-tree disease history + images | `trees`, `zones`, `diseases` (per-tree rows) |
| Users (Người dùng) | Account administration (the web UI's user directory) | Full CRUD | `/users` — list + filters (role / company / status) + detail drawer + "Thêm người dùng" drawer (role options: Admin, Company Manager, Farm Manager, Inspector, Technician; company selector; status Active/Inactive) | UI sends `company_id` and `status`, backend persists only `full_name/email/password/role`; "Tổng quan hoạt động" button rendered only for rows whose role/db_role is `Farm Owner` → navigates to `/users/:user_id` | `users`, `UserService` (+ `companyService` for the UI-only company dropdown) |
| Farmer Overview (Tổng quan nông dân) | Per-Farm-Owner operational dossier (farms, zones, trees, area, inspections, AI detections, alerts, neighbor contact, activity feed) | Read-only aggregate | `/users/:user_id` — profile card + farm/zone/tree/area cards + inspection/detection + alerts + neighbor counts + activity timeline | `FarmerOverviewService.get_overview(user_id)` requires `role == "Farm Owner"`, finds farms by `owner_user_id`, then aggregates zones/trees/inspections/detections/alerts/companies/neighbor counts scoped to those farms | users, farms, zones, trees, inspections, detection_results, alerts, companies, neighbor_contact_requests |
| Inspections (Kiểm tra) | Field inspection records per tree (health, weather, predicted disease, confidence) | Full CRUD + KPI | `/inspections` — list + detail drawer | `InspectionService.create_inspection` validates tree + inspector exists and sets `inspector_id = current user id`; update also re-binds `inspector_id` to caller | `inspections`, `trees`, `users` |
| Detection Results (Kết quả nhận diện) | AI detection outputs keyed to inspections | Full CRUD | `/detection-results` (route exists; hidden from sidebar) — list + detail drawer | Create/update validates `inspection_id` exists; service writes only `inspection_id/model/prediction/confidence` | `detection_results`, `inspections` |
| Disease History (Lịch sử phát sinh bệnh) | Longitudinal per-tree disease/action log | Full CRUD + KPI | `/disease-history` — list + detail drawer | Create/update validates `tree_id` exists; service writes only `tree_id/disease/date/action` | `disease_history`, `trees` |
| Diseases (Bệnh) | Disease catalog / master data with unique code | Full CRUD | `/diseases` (route exists; hidden from sidebar) — list + detail drawer | Standard CRUD; consumed by AI detect (writes per-tree disease rows into this collection), history, chat, digital-id | `diseases` |
| Alerts (Cảnh báo) | Warning records per farm/tree with priority; doubles as the notification store | Full CRUD | `/alerts` — list + detail drawer; Header notification bell calls `/alerts?per_page=50` | Create/update validate farm + tree exist; service writes only `farm_id/tree_id/alert_type/priority/date` | `alerts`, `farms`, `trees` |
| Notifications | Backend-only wrapper over the `alerts` collection (list/unread/read/delete/create) | CRUD (no update) | No dedicated web page found; Header bell uses `alertService` (`/alerts`); `/notifications*` endpoints exist server-side only | `NotificationService.list_unread` filters only `status == "unread"` (no user); `create_notification` writes an `alerts` doc picking the first zone/tree of the farm | `alerts`, `zones`, `trees` |
| History | Per-tree disease-history aggregation (feeds dashboard / tree / digital-id / chat) | Read-only | No dedicated page; consumed by tree/dashboard/digital-id surfaces | `HistoryService.get_tree_history(tree_id)` reads per-tree rows from `diseases` | `diseases` |
| Chat / AI Agronomist | AI advisory on a specific tree (mock answer) | Read-only | `components/dashboard/AgronomistPanel.tsx` on Dashboard | `ChatService.ask(question, tree_id)` builds a prompt from tree + per-tree disease history (+ weather placeholder "No weather data") → `OllamaService` mock reply | `trees`, `diseases`, `zones` (instantiated, unused) |
| AI Detection | Image upload + mock disease classification; saves the image file | Create (mock) | No web page (mobile has camera wizard); dashboard widgets consume `detection_results` | `AIService.detect_disease(tree_id, file, filename)` validates tree, saves file under `UPLOAD_DIR`, writes a per-tree row into `diseases` with `image_url` | `trees`, `diseases`, upload filesystem |
| Settings (Cài đặt) | Profile + preferences (frontend-only) | Read/Update (frontend) | `/settings` | Client-side form; no dedicated backend module beyond `/auth/profile` | auth profile endpoints |
| Mobile app (dga_mobile) | Farmer-facing mobile experience (onboarding, login/register, dashboard, disease detection camera wizard, history, profile, settings, recommendation) | Mostly mock repositories/datasources | Splash → onboarding → login/register → dashboard → feature screens | Uses same backend endpoints via `ApiEndpoints`; most features fall back to mock data | Same FastAPI backend (partially), mock datasources |

---

## 2. Resource Mapping

Purpose: full chain per resource — Collection → Repository → Service → DTO → API → Frontend service → Frontend page → Owner/Company/Farm/User fields → Current scope. Field names are taken from schema/validator where they exist; **NOT IMPLEMENTED** = field or behavior absent from the project. (Gate semantics per route are already in `AUTHORIZATION_AUDIT_REPORT.md` §6 — not repeated here.)

| Resource | Collection | Repository | Service | DTO (schemas) | API | Frontend service | Frontend page | Current Owner field | Current Company field | Current Farm field | Current User field | Current Scope |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| User / Account | `users` | `UserRepository` | `AuthService`, `UserService` | `user.py` (UserRegister/Login/Out/ProfileUpdate/TokenOut/TokenRefresh/ChangePassword), `user_crud.py` (UserCreate/Update/Out) | `/auth/*`, `/users` CRUD | `auth.service.ts`, `user.service.ts` | `pages/auth/*`, `pages/users/Users.tsx`, `pages/users/FarmerOverview.tsx` | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** (backend; frontend type/UI declares `company_id`) | **NOT IMPLEMENTED** | `users.role`, `users.status`, `users.refresh_token` | None; self-register open; user CRUD global |
| Company | `companies` | `CompanyRepository` | `CompanyService` | `company.py` (Create/Update/Out) | `/companies` CRUD | `company.service.ts` | `pages/companies/Companies.tsx` | `companies.owner` (free-text string, **not** a user ref) | self | **NOT IMPLEMENTED** (stats only) | **NOT IMPLEMENTED** | None (global) |
| Farm | `farms` | `FarmRepository` (`list_by_owner` builds empty filter) | `FarmService` | `farm.py` (Create/Update/Out) | `/farms` CRUD | `farm.service.ts` | `pages/farms/Farms.tsx`, `pages/dashboard/FarmDashboard.tsx` | `farms.owner_user_id` (seed-only; not enforced) | `farms.company_id` | self | `farms.manager_user_id` (seed-only; not enforced) | None — `list_by_owner` returns all farms |
| Zone | `zones` | `ZoneRepository` | `ZoneService` | `zone.py` (Create/Update/Out) | `/zones` CRUD | `zone.service.ts` | `pages/zones/Zones.tsx` | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** (inherited via farm only in aggregations) | `zones.farm_id` | **NOT IMPLEMENTED** | None — optional `farm_id` is an input filter, not a scope |
| Tree | `trees` | `TreeRepository` | `TreeService` | `tree.py` (Create/Update/Out) | `/trees` CRUD + `/trees/{id}/digital-id` | `tree.service.ts` | `pages/trees/Trees.tsx` | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** (derived via farm, not stored) | `trees.farm_id` (derived from zone at create/update) | **NOT IMPLEMENTED** | None — `zone_id/farm_id/status` are optional filters |
| Inspection | `inspections` | `InspectionRepository` | `InspectionService` | `inspection.py` (Create/Update/Out) | `/inspections` CRUD | `inspection.service.ts` | `pages/inspections/Inspections.tsx` | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** (via farm/tree, not stored) | `inspections.farm_id` | `inspections.inspector_id` (set to caller; **absent from collection validator**; no enforcement) | None — `inspector_id` is write-only |
| Detection Result | `detection_results` | `DetectionResultRepository` | `DetectionResultService` | `detection_result.py` (Create/Update/Out) | `/detection-results` CRUD | `detectionResult.service.ts` | `pages/detection-results/DetectionResults.tsx` | **NOT IMPLEMENTED** | `company_id` (in schema, optional; **not written** by service) | `farm_id` (in schema, optional; **not written** by service) | **NOT IMPLEMENTED** | None |
| Disease History | `disease_history` | `DiseaseHistoryRepository` | `DiseaseHistoryService` | `disease_history.py` (Create/Update/Out) | `/disease-history` CRUD | `diseaseHistory.service.ts` | `pages/disease-history/DiseaseHistory.tsx` | **NOT IMPLEMENTED** | `company_id` (in schema, optional; **not written** by service) | `farm_id` (in schema, optional; **not written** by service) | `detected_by_user_id` (in schema; **not written** by service) | None |
| Disease (master) | `diseases` | `DiseaseRepository` + `DiseasesRepository` (dual) | `DiseaseService` | `disease.py` (Create/Update/Out, DetectionResponse/Result, DiseaseHistoryOut) | `/diseases` CRUD; also written by `/ai/detect`, read by `/history/{tree_id}`, `/chat`, `/trees/{id}/digital-id` | `disease.service.ts` | `pages/diseases/Diseases.tsx` | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** (per-tree rows keyed by `tree_id` only) | **NOT IMPLEMENTED** | None — shared master data |
| Alert / Notification | `alerts` | `AlertRepository`, `NotificationRepository` | `AlertService`, `NotificationService` | `alert.py` (Create/Update/Out), `notification.py` (Create/Update/Out) | `/alerts` CRUD; `/notifications` (list/unread/detail/create/read/delete) | `alert.service.ts` (Header bell) | `pages/alerts/Alerts.tsx`; Header bell | **NOT IMPLEMENTED** | `company_id` (alerts schema, optional; **not written** by services) | `alerts.farm_id` | `alerts.acknowledged_by` (schema; **not written**); notifications carry **no user field** | None — `list_unread` has no user filter |
| Neighbor Contact Request | `neighbor_contact_requests` | `NeighborContactRequestRepository` | none dedicated (used by `FarmerOverviewService`) | `farmer_overview.py` `NeighborOverviewDTO` (read aggregates) | **NOT FOUND** (no API) | **NOT FOUND** (no frontend service/page) | shown only inside `FarmerOverview.tsx` | `source_user_id`, `target_user_id` | **NOT IMPLEMENTED** | `source_farm_id`, `target_farm_id` | `source_user_id`, `target_user_id` | Read-only counts by user/direction in Farmer Overview |
| Dashboard (aggregate) | multiple (farms, zones, trees, inspections, detection_results, alerts, seasons, harvests, farm_targets, farm_performance) | `FarmRepository`, `TreeRepository`, `NotificationRepository`, `SeasonRepository`, `FarmPerformanceRepository`, `FarmTargetRepository`, `HarvestRepository` | `DashboardService` | `dashboard.py` (DashboardOut, KpiData, SystemOverview, WidgetsOut, FarmDashboardOut, …), `dashboard/dto.py` (FarmPerformanceDTO) | `/dashboard`, `/dashboard/heatmap`, `/dashboard/widgets`, `/dashboard/farm-performance`, `/dashboard/farm/{farm_id}` | `dashboardDataManager.service.ts` | `pages/dashboard/Dashboard.tsx`, `pages/dashboard/FarmDashboard.tsx`, `components/dashboard/*` | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | `farm_id` only as endpoint argument (farm dashboard / farm-performance) | `user_id` accepted by `get_dashboard`/`get_farm_performance` but routed through the empty-filter `list_by_owner`; heatmap/widgets take no user at all | None (global aggregations) |
| History (tree dossier) | `diseases` (per-tree rows) | `DiseaseRepository` | `HistoryService` | reuse `disease.py` `DiseaseHistoryOut` | `GET /history/{tree_id}` | no dedicated service (used via tree/dashboard pages) | no dedicated page | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | `tree_id` path argument only |
| Chat / AI Agronomist | `trees`, `diseases` (read), `zones` (instantiated, unused) | `TreeRepository`, `DiseaseRepository`, `ZoneRepository` (+ `OllamaService` mock) | `ChatService` | `chat.py` (ChatRequest/Response) | `POST /chat` | no dedicated service | `components/dashboard/AgronomistPanel.tsx` | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | `tree_id` request body argument only |
| AI Detection | `trees`, `diseases` (write), upload filesystem | `DiseaseRepository`, `TreeRepository` | `AIService` | `disease.py` (DetectionResponse/Result) | `POST /ai/detect`, `POST /ai/image-quality` | no dedicated web service | no web page (mobile camera wizard) | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | **NOT IMPLEMENTED** | `tree_id` request argument only |

---

## 3. Module Relation

Purpose: which module depends on which module (business data flow), as coded today. Database relationships are already described in the old report — this section is about **module-to-module** dependencies only.

```
Auth ──► users
   │
   └──(token)──► every protected module

Header ──► alerts (bell)
   ├──► /trees?search=… (search + alert click-through)
   └──► /alerts (view all)

Dashboard ──► Trees (heatmap/KPI via zones)
   ├──► Zones (heatmap, zone options)
   ├──► Farms (KPIs, farm options, farm-performance)
   ├──► Inspections (real-time inspection log, pending_review)
   ├──► Detection Results (recent detections, widget detections)
   ├──► Alerts (alert counts, widget alerts, system overview)
   ├──► Seasons ──► Harvests / Farm Targets / Farm Performance (farm dashboard + performance)
   └──► Chat (AgronomistPanel)

Companies ──► Farms (stats: total_farms)
   ├──► Zones (stats)
   └──► Trees (stats)

Farms ──► Companies (company_id)
   ├──► Zones (zone list per farm)
   └──► Trees (tree counts, farm filter)

Zones ──► Farms (farm_id)

Trees ──► Zones (farm_id derivation) ──► Farms

Inspections ──► Trees (tree validation)
   ├──► Users (inspector validation, inspector_id = caller)
   ├──► Zones (zone_id format validation)
   └──► Diseases (disease_id validation)

Detection Results ──► Inspections (inspection validation)

Disease History ──► Trees (tree validation)

Alerts ──► Farms + Trees (reference validation)

Notifications ──► Zones (picks first zone of farm)
   ├──► Trees (picks first tree of zone)
   └──► alerts collection (write)

History ──► Diseases (per-tree rows)

Tree Digital-ID ──► Diseases (per-tree history + images)

Chat ──► Trees (tree info)
   ├──► Diseases (per-tree disease history)
   └──► Zones (instantiated; unused)

AI Detection ──► Trees (tree validation)
   ├──► Diseases (writes per-tree detection row + image_url)
   └──► filesystem (image upload)

Farmer Overview ──► Users (role check)
   ├──► Farms (owner_user_id)
   ├──► Zones / Trees / Inspections / Detection Results / Alerts (scoped aggregations)
   ├──► Companies (name resolution via farms.company_id)
   └──► Neighbor Contact Requests (counts by source/target user)

Admin (farmer overview endpoint) ──► Farmer Overview

Users (CRUD) ──► users only (no cross-module dependency)
```

---

## 4. Entry Point Audit

Purpose: every place a user can enter the system (or a surface) today. No design.

### 4.1 Web portal (React SPA)

| # | Entry point | How reached | Target | Current behavior |
|---|---|---|---|---|
| 1 | Login page | `/login` (public) | → post-login route | After login, navigates to `location.state.from?.pathname` or `/`; if already authenticated, redirects to `from` |
| 2 | Register page | `/register` (public, link on login) | → `/login` | Self-registration (`POST /auth/register`, no role field in UI → backend default `field_technician`); success → auto-redirect to login after 2s |
| 3 | Root redirect | `/` | → `/dashboard` | `Navigate replace` |
| 4 | Protected shell | `/` (child routes) via `ProtectedRoute` | AppLayout | Auth-only guard (`isAuthenticated`); shows spinner while `AuthProvider` bootstraps via `/auth/me`; on failure clears tokens |
| 5 | Sidebar menu | links inside AppLayout | each module page | All menu items rendered for every authenticated user; `HIDDEN_MENU_PATHS` statically removes `/detection-results` and `/diseases` from the menu (routes still reachable) |
| 6 | Header search | magnifier icon, Enter | `/trees?search=<q>` | Client-side navigate; search box placeholder "Tree ID, trang trại, khu vực..." |
| 7 | Header notification bell | bell icon | `/alerts` or `/trees?search=<tree_id>` | Fetches `/alerts?per_page=50`; badge = high-priority count; clicking an alert with `tree_id` → tree search page; "Xem tất cả" → `/alerts` |
| 8 | Header profile dropdown | avatar icon | logout → `/login` | Displays `user.full_name` + `user.role`; "Đăng xuất" calls logout, clears tokens, navigates to `/login` |
| 9 | Users page action | "Tổng quan hoạt động" button (Farm Owner rows only) | `/users/:user_id` | `navigate('/users/' + user._id)`; route renders `FarmerOverview` |
| 10 | Dashboard farm card | FarmPerformanceCard / farm options | `/dashboard/farm/:farmId` | Client-side navigation to farm dashboard |
| 11 | Direct URL entry (deep links) | typing any route in the address bar | each module page | Any protected path is served as long as a token exists — **no role gate**; hidden-sidebar routes (`/detection-results`, `/diseases`) and nested paths (`/users/:user_id`, `/dashboard/farm/:farmId`) are directly reachable |
| 12 | Global 401 redirect | any API 401 | `window.location.href = "/login"` | Response interceptor clears tokens and hard-redirects |
| 13 | Unknown path | any unmatched path | `/login` | Fallback route `*` → `Navigate to /login` |
| 14 | "Quên mật khẩu?" | login page link | — | Button exists, **no handler wired** (no-op) |

### 4.2 Mobile app (dga_mobile, Flutter)

| # | Entry point | Current behavior |
|---|---|---|
| 1 | Splash page | Startup entry; then onboarding/login flow |
| 2 | Onboarding slides | Pre-login intro |
| 3 | Login / Register pages | Same backend auth endpoints (`/auth/login`, `/auth/register`) via `ApiEndpoints` |
| 4 | Forgot password page | Screen exists |
| 5 | Dashboard (after login) | Quick stats, quick actions, weather card, alerts card, recent inspections, AI farm status |
| 6 | Disease detection wizard | Camera simulator + image editor wizard → `/ai/detect`, `/ai/image-quality` |
| 7 | History page | Per-tree history (mostly mock) |
| 8 | Profile page | Profile view/edit |
| 9 | Settings page | Theme + settings tiles |
| 10 | Recommendation feature | Present as feature folder (mock) |

---

## 5. Authorization Touchpoints

Purpose: points where a future Authorization layer would need to check something. Only **Touchpoint** + **Current State** are recorded — no proposal, no design.

| # | Touchpoint | Current State |
|---|---|---|
| 1 | Login (`POST /auth/login`) | Public; `users.status` not checked |
| 2 | Register (`POST /auth/register`) | Public; open self-registration; backend default role `field_technician`; no approval, no company/farm link |
| 3 | Token issuance / claims | `sub`, `role` (DB role string), `type`, `exp`, `iat` only; no scope/tenant/permission claims |
| 4 | `AuthProvider` bootstrap (`GET /auth/me`) | Accepts any valid token; no role/scope decision |
| 5 | Route guard (`ProtectedRoute`) | Auth-only; all protected routes identical |
| 6 | Sidebar menu | All items rendered for every authenticated user; only a static `HIDDEN_MENU_PATHS` set |
| 7 | Header notification bell | Calls `/alerts?per_page=50` — global alert stream for every user |
| 8 | Header search | Navigates to `/trees?search=<q>` — global tree search |
| 9 | Route table (`routes/index.tsx`) | No per-route guard/role metadata |
| 10 | Page-level CRUD action buttons (Users, Farms, Zones, Trees, Inspections, Detection Results, Disease History, Diseases, Alerts, Companies) | Rendered for every authenticated user; no role-based show/hide |
| 11 | Users page "Tổng quan hoạt động" button | Client-side check: shown only when row role/db_role is `Farm Owner`; navigation is not otherwise guarded (deep link `/users/:id` is open) |
| 12 | API router dependencies (`Depends(RoleChecker(...))`) | `allow_all` on all resource routers (auth-only in practice); `admin_only` only on `GET /admin/users/{user_id}/overview` |
| 13 | Repository list methods (`BaseRepository.list`) | No user/tenant filter anywhere; `FarmRepository.list_by_owner` builds an empty filter |
| 14 | Service methods binding the caller | `InspectionService.create/update` write `inspector_id = current user id`; `FarmerOverviewService.get_overview` scopes by `farms.owner_user_id` and rejects non-Farm-Owner users — the only two caller-aware spots in the codebase |
| 15 | Dashboard aggregations (`get_dashboard`, `get_heatmap`, `get_widgets`, `get_farm_dashboard`, `get_farm_performance`) | Global; `user_id` either unused or routed through the empty-filter `list_by_owner` |
| 16 | Farmer overview endpoint (`GET /admin/users/{user_id}/overview`) | `RoleChecker([enterprise_admin])` — only role-restricted route; the overview itself is scoped to the target Farm Owner's farms |
| 17 | Notifications (`/notifications`, `/notifications/unread`, `/{id}/read`, delete) | No user targeting; unread list global |
| 18 | Neighbor contact data | No user-facing API/UI; counts only inside Farmer Overview; `neighbor_contact_requests` carries source/target user+farm consent fields |
| 19 | Chat (`POST /chat`) | Any authenticated user may ask about any `tree_id` |
| 20 | AI detection (`POST /ai/detect`, `/ai/image-quality`) | Any authenticated user may run detection on any `tree_id`; files written to shared uploads dir |
| 21 | Mobile app | Shares the same JWT + endpoints; most features mock-backed; no role handling in mobile UI observed |
| 22 | `users.status` (Active/Inactive) | Field exists in UI + seed, but never enforced at any touchpoint |

---

## 6. Information Still Missing

Purpose: gaps discovered during this extension pass that the old report's §14 did not list. **NOT FOUND** = no data in the project. (Role semantics, role hierarchy, permission catalog, tenant requirements, ownership/assignment requirements, consent-endpoint behavior, notification targeting rules, mobile auth policy, production data, export/import, authorization spec — already covered in `AUTHORIZATION_AUDIT_REPORT.md` §14; not repeated here.)

| # | Item | Status |
|---|---|---|
| 1 | Intended primary audience of the web portal (enterprise staff vs farmers) — login page markets "enterprise farm management"; no per-role landing page exists | **NOT FOUND** |
| 2 | Expected Farm Owner self-service in the web portal — no "my farms" page for a logged-in Farm Owner; Farmer Overview is admin-facing under `/users/:user_id` | **NOT FOUND** |
| 3 | Intended user→company organization model — the Users UI (company field, company filter, "Thuộc tổ chức" detail section) implies users belong to companies, but no backend support exists | **NOT FOUND** (UI intent only) |
| 4 | Operational approval / sign-off workflows (e.g., who finalizes an inspection, who owns/acknowledges an alert) | **NOT FOUND** (no workflow code or doc) |
| 5 | Weather intelligence — chat prompt hardcodes "No weather data"; dashboard weather card exists in mobile but no weather data source/integration found | **NOT FOUND** |
| 6 | Relationship between `detection_results` (per-inspection CRUD) and the per-tree `diseases` rows written by `/ai/detect` — whether they are the same logical entity is not documented | **NOT FOUND** |
| 7 | Lifecycle of seasons / harvests / farm targets / farm performance — who creates seasons, sets targets, reviews performance; no UI/API exists (schema + dashboard reads only) | **NOT FOUND** |
| 8 | Bulk data ownership intent — companies/farms/zones/trees are bulk-seeded via ETL; whether runtime CRUD is meant for operational users or only data admins | **NOT FOUND** |
| 9 | Mobile ↔ web feature parity intent (mobile has onboarding + camera detection; web has neither) | **NOT FOUND** |
| 10 | `users.status` semantics (Active/Inactive) — how a disabled user is expected to behave (login, token refresh, existing sessions) | **NOT FOUND** (field exists, never enforced) |
| 11 | "Quên mật khẩu?" (forgot password) — UI button exists with no handler and no backend endpoint | **NOT FOUND** (dead UI) |
| 12 | `farms.manager_user_id` — the Company Manager linkage is seeded/fielded but no UI or flow ever sets or uses it | **NOT FOUND** (field only) |
| 13 | Audit/logging requirements per business action (who did what) — activity feed exists only inside Farmer Overview | **NOT FOUND** |
| 14 | Language/role labels — UI mixes API-role and DB-role labels (Vietnamese); no stated target-user language or terminology standard | **NOT FOUND** |

---

*End of AUTHORIZATION_AUDIT_EXTENSION.md. Extension complete — READ ONLY. No code, files, or git changes were made beyond the creation of this report.*
