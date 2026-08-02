# AUTHORIZATION DISCOVERY REPORT
## Durian Guardian AI (DGA) — Release 1.3.x

**Report type:** READ-ONLY Business Decision Discovery
**Agent:** OpenCode
**Inputs (evidence only):** `AUTHORIZATION_AUDIT_REPORT.md` (REPORT) and `AUTHORIZATION_AUDIT_EXTENSION.md` (EXTENSION)
**Generated:** 2026-08-02

> Purpose: enumerate **every Business Decision** that the Antigravity IDE will need to decide in order to design Enterprise Authorization. This report does **NOT** design roles, permissions, RBAC, ABAC, policies, or middleware. It does **NOT** re-audit the project and does **NOT** restate the two prior reports — every entry below is a *decision to be made*, with the decision anchored only to evidence already recorded in the two reports.
>
> **Evidence Rule:** every `Current Evidence` references the REPORT and/or EXTENSION only. No source-code re-reading, no outside knowledge.
>
> `Current Implementation` = what the evidence says exists today. `Unknown` = what the evidence does not say. `Conflict` = contradictions *already present inside the two reports* (or "None found"). `Decision Required` = **YES** (this report only flags; it does not answer).

---

## Legend for evidence citations

- `REPORT §n` → section in `AUTHORIZATION_AUDIT_REPORT.md`
- `EXT §n` → section in `AUTHORIZATION_AUDIT_EXTENSION.md`

---

## 1. ROLE DISCOVERY

### Decision 001

**Question:** Are the 6 DB roles (Admin, Company Manager, Farm Manager, Inspector, Technician, Farm Owner) 6 distinct business jobs, or are some of them redundant synonyms?

**Current Evidence:** The DB stores 6 role strings; the API collapses them to 4 (`REPORT §5.2`): Company Manager & Farm Manager → `farm_manager`; Inspector → `field_technician`; Technician & Farm Owner → `farmer`. The Users-create UI offers only 5 role options (Admin, Company Manager, Farm Manager, Inspector, Technician) — Farm Owner is not offered in the create drawer (`EXT §1, Users`).

**Evidence Source:** REPORT §5.2; EXT §1 (Users module)

**Current Implementation:** 6 distinct strings exist in `users.role`; UI and API mapping treat them as 4; one role (Farm Owner) is not selectable in the web create UI.

**Unknown:** Whether "Company Manager" vs "Farm Manager" and "Technician" vs "Farm Owner" are intentionally different jobs that authorization must keep distinct.

**Conflict:** Mapping collapses distinct DB roles into one API role (`REPORT §5.2`), while `REPORT §15.1` says authorization ground truth should be the 6 DB roles.

**Impact:** If Antigravity bases authorization on collapsed roles, distinct jobs lose differentiation; if on DB roles, the decision of which distinctions matter is business, not technical.

**Priority:** High

**Decision Required:** YES

---

### Decision 002

**Question:** What is the business meaning / responsibility of each role?

**Current Evidence:** Roles exist as names only; role semantics / responsibilities per role are **NOT FOUND** (`REPORT §14`). No code or doc maps role → duties.

**Evidence Source:** REPORT §14 ("Role semantics / responsibilities per role — NOT FOUND")

**Current Implementation:** Roles are stored, mapped, displayed in Vietnamese labels (`REPORT §5.2`, `REPORT §7.3`), and used in one endpoint gate (`REPORT §6` admin-only overview). No behavioral definition.

**Unknown:** What each role is actually expected to do in the business.

**Conflict:** None found.

**Impact:** Without role semantics, any RBAC design has no business foundation.

**Priority:** High

**Decision Required:** YES

---

### Decision 003

**Question:** Which identity is the business identity for authorization — the API role (4 values) or the DB role (6 values)?

**Current Evidence:** JWT carries the **DB role string** (`REPORT §4.1`); `RoleChecker` compares against API-role values (`REPORT §4.2`); users serialization exposes both `role` (API) and `db_role` (`REPORT §5.3`); the Users page filters/color-codes by `db_role` (`REPORT §7.3`).

**Evidence Source:** REPORT §4.1, §4.2, §5.3, §7.3; EXT §1 (Users)

**Current Implementation:** Token claims use DB role; guards use API role; UI mixes both.

**Unknown:** Which single identity Antigravity should treat as authoritative for decisions.

**Conflict:** `REPORT §15.1` (use 6 DB roles) vs existing guard machinery built on 4 API roles.

**Impact:** Determines token claims, guard logic, and UI role model.

**Priority:** High

**Decision Required:** YES

---

### Decision 004

**Question:** Should open self-registration with default role `field_technician` remain as-is?

**Current Evidence:** Register is public, `role` optional defaulting to `field_technician`; no approval or email verification; register UI sends no role (`REPORT §4.3`, `§4.5`; `EXT §4` entry 2).

**Evidence Source:** REPORT §4.3, §4.5; EXT §4.1 (entry 2)

**Current Implementation:** Anyone can register and instantly obtain an authenticated session with a default role.

**Unknown:** Whether self-registration is an intended business entry (vs staff-created accounts only).

**Conflict:** None found.

**Impact:** Defines the boundary of the "public" trust surface.

**Priority:** High

**Decision Required:** YES

---

### Decision 005

**Question:** Can a user's role be changed after creation, and if so who may change it?

**Current Evidence:** User CRUD includes update (`REPORT §6`), `UserUpdate` includes `role` (`REPORT §5.3`); the Users edit drawer allows changing the role (`EXT §1, Users`). The update route is `AnyRole` (`REPORT §6`).

**Evidence Source:** REPORT §5.3, §6; EXT §1 (Users)

**Current Implementation:** Any authenticated user can change any user's role via the API/UI today.

**Unknown:** Whether role change is a business operation (and its approval rule).

**Conflict:** None found.

**Impact:** Role change is a privilege-escalation-sensitive operation.

**Priority:** High

**Decision Required:** YES

---

### Decision 006

**Question:** Should `users.status` (Active/Inactive) control login, tokens, and existing sessions?

**Current Evidence:** `status` field exists and is seeded `"ACTIVE"` (`REPORT §5.1`); login does not check it (`REPORT §4.5`); status check readiness = Not Implemented (`REPORT §11`); UI offers Active/Inactive but nothing enforces it (`EXT §5` touchpoint 22; `EXT §6` item 10).

**Evidence Source:** REPORT §4.5, §5.1, §11; EXT §5 (touchpoint 22), EXT §6 (item 10)

**Current Implementation:** Status is stored and displayed; never enforced.

**Unknown:** Semantics of Active/Inactive (block login? block refresh? block existing sessions?).

**Conflict:** None found.

**Impact:** Account lifecycle control is a core authorization input.

**Priority:** High

**Decision Required:** YES

---

## 2. RESOURCE OWNERSHIP

### Decision 007 (Company)

**Question:** Does a Company have an owner, and who is it?

**Current Evidence:** `companies.owner` is a free-text string, **not** a user reference (`REPORT §3.1`, `REPORT §10`); company ownership = Not Implemented (`REPORT §10`); no API assigns a company to a user (`REPORT §10`).

**Evidence Source:** REPORT §3.1, §10; EXT §2 (Company)

**Current Implementation:** Company ownership is unrepresented in a usable form.

**Unknown:** Whether companies belong to users/orgs and how.

**Conflict:** None found.

**Impact:** Foundation for company-level authorization.

**Priority:** High

**Decision Required:** YES

---

### Decision 008 (Farm)

**Question:** Is `farms.owner_user_id` the intended ownership relation, and is `manager_user_id` a second owner?

**Current Evidence:** `farms` carries `owner_user_id` (Farm Owner) and `manager_user_id` (Company Manager) (`REPORT §3.1`); only seed sets them (`REPORT §10`); Farmer Overview scopes by `owner_user_id` (`REPORT §9.3`); `FarmRepository.list_by_owner` ignores the owner filter (`REPORT §13` risk 3); manager linkage has no UI/flow (`EXT §6` item 12).

**Evidence Source:** REPORT §3.1, §9.3, §10, §13; EXT §6 (item 12)

**Current Implementation:** Owner/manager fields exist and are seeded; one service (Farmer Overview) reads owner; nothing enforces ownership.

**Unknown:** The authoritative farm-ownership model (single owner? owner+manager?).

**Conflict:** Field says owner matters (`REPORT §9.3`) but repository ignores it (`REPORT §13` risk 3).

**Impact:** Farm-level scoping and Farm Owner access depend on this.

**Priority:** High

**Decision Required:** YES

---

### Decision 009 (Zone)

**Question:** Does a Zone need its own ownership beyond the parent Farm?

**Current Evidence:** `zones` has only `farm_id` (`REPORT §3.1`); zone owner = NOT IMPLEMENTED (`EXT §2, Zone`).

**Evidence Source:** REPORT §3.1; EXT §2 (Zone)

**Current Implementation:** Zone ownership is not represented.

**Unknown:** Whether zone-level ownership is needed.

**Conflict:** None found.

**Impact:** Granularity of scoping decisions.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 010 (Tree)

**Question:** Does a Tree have an owner distinct from its Farm/Zone?

**Current Evidence:** `trees` has `farm_id`, `zone_id` only (`REPORT §3.1`); tree owner = NOT IMPLEMENTED (`EXT §2, Tree`).

**Evidence Source:** REPORT §3.1; EXT §2 (Tree)

**Current Implementation:** Tree ownership is not represented.

**Unknown:** Whether per-tree ownership is needed.

**Conflict:** None found.

**Impact:** Tree-level access decisions (e.g., Farmer Over... view of own trees).

**Priority:** High

**Decision Required:** YES

---

### Decision 011 (Inspection)

**Question:** Does an Inspection "belong" to its `inspector_id`, and is that the owner?

**Current Evidence:** `inspections.inspector_id` is written by the service as the caller (`REPORT §6`; `EXT §2, Inspection`); `inspector_id` is **absent from the collection validator** (`REPORT §3.3`, `REPORT §13` risk 11); no enforcement of who may edit a record (`REPORT §13` risk 1).

**Evidence Source:** REPORT §3.3, §6, §13; EXT §2 (Inspection), EXT §5 (touchpoint 14)

**Current Implementation:** Caller is recorded as inspector at create/update; the field is not in the validator and is not used for access.

**Unknown:** Whether the inspector owns the record for edit/delete purposes.

**Conflict:** Field written but schema-absent (`REPORT §13` risk 11).

**Impact:** Edit/delete ownership rules for operational records.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 012 (Detection Result)

**Question:** Who owns a Detection Result?

**Current Evidence:** `detection_results` schema has optional `company_id`/`farm_id` but the service writes only `inspection_id/model/prediction/confidence` (`EXT §2, Detection Result`); no user field (`EXT §2`).

**Evidence Source:** EXT §2 (Detection Result)

**Current Implementation:** No ownership field is actually persisted.

**Unknown:** Owner model for detection results.

**Conflict:** Schema declares `company_id`/`farm_id` but service never writes them (`EXT §2`).

**Impact:** Access to AI outputs.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 013 (Disease History)

**Question:** Who owns a Disease History record?

**Current Evidence:** `disease_history` schema has `detected_by_user_id`, optional `company_id`/`farm_id`, but the service writes only `tree_id/disease/date/action` (`EXT §2, Disease History`).

**Evidence Source:** EXT §2 (Disease History)

**Current Implementation:** No ownership field is actually persisted.

**Unknown:** Owner model for disease history records.

**Conflict:** Schema declares owner fields; service never writes them (`EXT §2`).

**Impact:** Who may view/correct a disease record.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 014 (Alert)

**Question:** Who owns an Alert, and who may acknowledge/resolve it?

**Current Evidence:** `alerts` has `acknowledged_by` in schema, not written by services (`EXT §2, Alert`); notifications carry **no user field** (`EXT §2`); alert/notification lists are global (`REPORT §13` risk 10; `EXT §5` touchpoint 17).

**Evidence Source:** REPORT §13; EXT §2 (Alert/Notification), EXT §5 (touchpoint 17)

**Current Implementation:** Alerts exist per farm/tree; no owner or acknowledgement persistence.

**Unknown:** Alert ownership / responsibility model.

**Conflict:** Schema field vs service behavior (`EXT §2`).

**Impact:** Alert visibility and acknowledge workflows.

**Priority:** High

**Decision Required:** YES

---

### Decision 015 (Neighbor Contact Request)

**Question:** What is the ownership/consent model for Neighbor Contact Requests?

**Current Evidence:** Records carry `source_farm_id/target_farm_id/source_user_id/target_user_id` and consent statuses; used only for overview counts; **no API exposes them** (`REPORT §3.1`, `REPORT §10`; `EXT §2, Neighbor`). Consent statuses enumerated in Farmer Overview counts (pending, waiting_source_consent, waiting_target_consent, contact_shared, rejected, cancelled) (`EXT §1, Farmer Overview`).

**Evidence Source:** REPORT §3.1, §10; EXT §1 (Farmer Overview), EXT §2 (Neighbor)

**Current Implementation:** Two-party (source/target) consent data exists; no user-facing create/respond flow.

**Unknown:** The full consent workflow the business intends.

**Conflict:** None found (feature is data-only today).

**Impact:** Cross-farm data sharing authorization.

**Priority:** High

**Decision Required:** YES

---

## 3. SCOPE DISCOVERY

### Decision 016 (Tenant model)

**Question:** Is the system single-tenant or multi-tenant (per company)?

**Current Evidence:** Tenant/company scoping requirements are **NOT FOUND** in code (`REPORT §14`); no company scoping logic anywhere (`REPORT §11`); README describes multi-farm agribusiness targets only (`REPORT §14`).

**Evidence Source:** REPORT §11, §14

**Current Implementation:** All data effectively global; no tenant boundary.

**Unknown:** Whether companies are independent tenants.

**Conflict:** None found.

**Impact:** The most fundamental scoping decision.

**Priority:** High

**Decision Required:** YES

---

### Decision 017 (Company scope)

**Question:** Should any module be scoped by company?

**Current Evidence:** Company Scope = Not Implemented (`REPORT §11`); `companies` is global CRUD (`EXT §2, Company`); no user has a company field (`REPORT §5.1`).

**Evidence Source:** REPORT §5.1, §11; EXT §2 (Company)

**Current Implementation:** No company scoping exists.

**Unknown:** Which modules need company scope.

**Conflict:** None found.

**Impact:** Data isolation at company level.

**Priority:** High

**Decision Required:** YES

---

### Decision 018 (Farm scope)

**Question:** Should farm-scoped reads exist for anyone (e.g., a Farm Owner's own farms)?

**Current Evidence:** Farm Scope is Not Implemented except Farmer Overview reads (`REPORT §11`); dashboard is effectively global because `list_by_owner` returns all farms (`REPORT §9.3`, `REPORT §13` risk 3); no "my farms" page exists (`EXT §6` item 2).

**Evidence Source:** REPORT §9.3, §11, §13; EXT §6 (item 2)

**Current Implementation:** No farm scoping in lists/dashboards.

**Unknown:** Whether and where farm scope should apply.

**Conflict:** None found.

**Impact:** Core row-level isolation.

**Priority:** High

**Decision Required:** YES

---

### Decision 019 (Zone / Tree scope)

**Question:** Should zone/tree reads be scoped to a farm or company?

**Current Evidence:** Zones and Trees have farm/zone filter *inputs* but no scoping (`EXT §2, Zone/Tree`); trees CRUD is global (`REPORT §6`).

**Evidence Source:** REPORT §6; EXT §2 (Zone, Tree)

**Current Implementation:** Filters are caller-provided, not derived from identity.

**Unknown:** Desired scope granularity.

**Conflict:** None found.

**Impact:** Granularity of the scope model.

**Priority:** High

**Decision Required:** YES

---

### Decision 020 (User scope / "my data")

**Question:** Should users see only their own data, and which data is "theirs"?

**Current Evidence:** The only user-scoped code is Farmer Overview via `farms.owner_user_id` (`REPORT §9.3`); no other service filters by current user (`REPORT §9.3`); user → company/farm assignment is Not Implemented (`REPORT §10`).

**Evidence Source:** REPORT §9.3, §10

**Current Implementation:** Only the Farm Owner overview is user-scoped.

**Unknown:** Whether the concept of "my data" applies beyond Farm Owners.

**Conflict:** None found.

**Impact:** Row-level per-user visibility.

**Priority:** High

**Decision Required:** YES

---

## 4. CRUD DECISION

### Decision 021 (Tree CRUD)

**Question:** Who should Create/Read/Update/Delete trees?

**Current Evidence:** Trees CRUD is `AnyRole` (`REPORT §6`); full CRUD page (`REPORT §8`); tree create derives farm from zone (`EXT §1, Trees`).

**Evidence Source:** REPORT §6, §8; EXT §1 (Trees)

**Current Implementation:** Any authenticated user can do all tree operations.

**Unknown:** The business rule for each tree CRUD operation.

**Conflict:** None found.

**Impact:** Standard object-level authorization for the central resource.

**Priority:** High

**Decision Required:** YES

---

### Decision 022 (Company CRUD)

**Question:** Who may create/update/delete Companies?

**Current Evidence:** Companies CRUD is `AnyRole` (`REPORT §6`); which users can create/delete companies is **NOT FOUND** (`REPORT §14`); companies are the top of the hierarchy (`EXT §1, Companies`).

**Evidence Source:** REPORT §6, §14; EXT §1 (Companies)

**Current Implementation:** Anyone authenticated.

**Unknown:** The business rule for company lifecycle.

**Conflict:** None found.

**Impact:** Root-entity administration.

**Priority:** High

**Decision Required:** YES

---

### Decision 023 (User CRUD)

**Question:** Who may create/update/delete Users (the account directory)?

**Current Evidence:** Users CRUD is `AnyRole` (`REPORT §6`); the page is an admin-style directory with role/status editing (`EXT §1, Users`); no rule says who may manage users (`REPORT §14`).

**Evidence Source:** REPORT §6, §14; EXT §1 (Users)

**Current Implementation:** Anyone authenticated can manage any account.

**Unknown:** User-administration authority.

**Conflict:** None found.

**Impact:** Highest-privilege operation; identity lifecycle.

**Priority:** High

**Decision Required:** YES

---

### Decision 024 (Operational records CRUD: Inspection / Detection / Disease History / Alerts)

**Question:** Who may Create/Read/Update/Delete inspections, detection results, disease history, alerts?

**Current Evidence:** All four are full CRUD at `AnyRole` (`REPORT §6`, `REPORT §8`); inspections bind the caller as inspector (`EXT §5` touchpoint 14).

**Evidence Source:** REPORT §6, §8; EXT §5 (touchpoint 14)

**Current Implementation:** Open CRUD for every authenticated user.

**Unknown:** Per-record business rules (who records, who edits, who deletes).

**Conflict:** None found.

**Impact:** Operational trust and record integrity.

**Priority:** High

**Decision Required:** YES

---

### Decision 025 (Delete vs Archive)

**Question:** Should destructive Delete be allowed, or should there be Archive/Restore?

**Current Evidence:** Delete exists on every resource CRUD (`REPORT §8`); no export/import (`REPORT §8`); no archive/restore anywhere (`EXT §6` item 13 mentions no audit/archive); DB relationships are not enforced (no cascade) (`REPORT §3.1`).

**Evidence Source:** REPORT §3.1, §8; EXT §6 (item 13)

**Current Implementation:** Hard delete everywhere; dependent rows are not cascade-protected.

**Unknown:** Retention / archive / restore requirements.

**Conflict:** None found.

**Impact:** Data-loss policy and authorization around destructive actions.

**Priority:** Medium

**Decision Required:** YES

---

## 5. VIEW DECISION

### Decision 026 (Dashboard visibility)

**Question:** Who may see the global Dashboard (and its KPIs, heatmap, widgets, farm performance)?

**Current Evidence:** `/dashboard` is `Auth` (`REPORT §6`); dashboard is effectively global (`REPORT §9.3`); heatmap/widgets take no user (`EXT §2, Dashboard`); dashboard is the main landing page (`EXT §4` entry 3).

**Evidence Source:** REPORT §6, §9.3; EXT §2 (Dashboard), EXT §4 (entry 3)

**Current Implementation:** Any authenticated user sees the full enterprise overview.

**Unknown:** Which roles should see enterprise-wide vs personal data.

**Conflict:** None found.

**Impact:** Primary information-exposure surface.

**Priority:** High

**Decision Required:** YES

---

### Decision 027 (Farmer Overview visibility)

**Question:** Who may view a Farm Owner's overview, and for which owners?

**Current Evidence:** The endpoint is the only `AdminOnly` route (`REPORT §6`); the UI shows the button only for Farm Owner rows (`EXT §4` entry 9) but the URL `/users/:user_id` is directly reachable by any authenticated user (`EXT §4` entry 11, `EXT §5` touchpoint 11).

**Evidence Source:** REPORT §6; EXT §4 (entries 9, 11), EXT §5 (touchpoint 11)

**Current Implementation:** Backend restricts the overview to admin; frontend deep link is not restricted.

**Unknown:** Intended viewer set (only admins? managers of the owner's company? the owner himself?).

**Conflict:** Backend admin-only vs open deep-link navigation (`EXT §4` entry 11).

**Impact:** Sensitive per-farmer dossier access.

**Priority:** High

**Decision Required:** YES

---

### Decision 028 (Users directory visibility)

**Question:** Who may view the Users directory (all accounts, roles, statuses)?

**Current Evidence:** Users list is `AnyRole` (`REPORT §6`); UI is an admin-style directory with role chips and organization sections (`EXT §1, Users`).

**Evidence Source:** REPORT §6; EXT §1 (Users)

**Current Implementation:** Any authenticated user can browse all accounts.

**Unknown:** Whether the directory is admin-only or role-restricted.

**Conflict:** None found.

**Impact:** Identity/org data exposure.

**Priority:** High

**Decision Required:** YES

---

### Decision 029 (Operational lists visibility)

**Question:** Who may see Trees, Inspections, Detection Results, Disease History, Alerts lists?

**Current Evidence:** All are `AnyRole` (`REPORT §6`); lists are global with no scoping (`EXT §2`); notifications/alert stream is global in the header bell (`EXT §5` touchpoint 7).

**Evidence Source:** REPORT §6; EXT §2, EXT §5 (touchpoint 7)

**Current Implementation:** Global lists for every authenticated user.

**Unknown:** Per-module viewer rules.

**Conflict:** None found.

**Impact:** Bread-and-butter list access control.

**Priority:** High

**Decision Required:** YES

---

## 6. ACTION DECISION

### Decision 030 (Approve / Reject / Resolve)

**Question:** Which business actions require an Approve/Reject/Resolve step, and who performs them?

**Current Evidence:** No approval workflow exists (`EXT §6` item 4); neighbor request consent statuses (pending, waiting_source_consent, waiting_target_consent, contact_shared, rejected, cancelled) imply a consent action that has no endpoint (`REPORT §14`; `EXT §1, Farmer Overview`); alerts have no acknowledge/resolve action persisted (`EXT §2, Alert`).

**Evidence Source:** REPORT §14; EXT §1 (Farmer Overview), EXT §2 (Alert), EXT §6 (item 4)

**Current Implementation:** No approve/reject/resolve actions in the system.

**Unknown:** Which approvals the business requires.

**Conflict:** Consent statuses exist but no action produces them (`REPORT §14`).

**Impact:** Workflow authorization.

**Priority:** High

**Decision Required:** YES

---

### Decision 031 (Assign)

**Question:** Who assigns users to companies/farms, and how?

**Current Evidence:** User↔company/farm/zone assignment is Not Implemented; no assignment endpoint (`REPORT §10`); the Users UI presents a company selector but backend drops it (`EXT §6` item 3); `farms.manager_user_id` is never set by any flow (`EXT §6` item 12).

**Evidence Source:** REPORT §10; EXT §6 (items 3, 12)

**Current Implementation:** No assignment capability.

**Unknown:** The assignment model and its authority.

**Conflict:** None found.

**Impact:** Enables all scope/ownership decisions.

**Priority:** High

**Decision Required:** YES

---

### Decision 032 (Export / Import)

**Question:** Should Export and Import exist as authorized actions?

**Current Evidence:** Export = **NOT FOUND**; Import exists only offline via ETL (`REPORT §8`, `REPORT §14`).

**Evidence Source:** REPORT §8, §14

**Current Implementation:** No export API; bulk import is offline only.

**Unknown:** Whether export/import are required and who may do them.

**Conflict:** None found.

**Impact:** Data-movement authorization.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 033 (Mark-read / Acknowledge)

**Question:** Who may mark alerts/notifications read, and should read-state be per user?

**Current Evidence:** Notification read endpoints exist but lists are global with no user filter (`REPORT §13` risk 10; `EXT §2, Notification`); alerts `acknowledged_by` is never written (`EXT §2, Alert`).

**Evidence Source:** REPORT §13; EXT §2 (Alert, Notification)

**Current Implementation:** Read/unread is global, not per-user.

**Unknown:** Per-user read/ack semantics.

**Conflict:** None found.

**Impact:** Personal vs shared notification state.

**Priority:** Medium

**Decision Required:** YES

---

## 7. NAVIGATION DECISION

### Decision 034 (Sidebar menu visibility)

**Question:** Should menu items be shown/hidden by role?

**Current Evidence:** Sidebar hardcodes all items; only a static `HIDDEN_MENU_PATHS` removes two paths (`REPORT §7.1`); no role gating anywhere (`REPORT §7.3`); `ProtectedRoute` is auth-only (`REPORT §7.1`; `EXT §5` touchpoint 6).

**Evidence Source:** REPORT §7.1, §7.3; EXT §5 (touchpoint 6)

**Current Implementation:** Same menu for every authenticated user.

**Unknown:** Desired per-role navigation.

**Conflict:** None found.

**Impact:** UX-level authorization surface.

**Priority:** High

**Decision Required:** YES

---

### Decision 035 (Hidden-but-routable routes)

**Question:** Should routes hidden from the menu (`/detection-results`, `/diseases`) be protected differently from visible ones?

**Current Evidence:** Hidden from sidebar but directly routable (`REPORT §7.1`; `EXT §4` entry 5); still full CRUD `AnyRole` (`REPORT §6`).

**Evidence Source:** REPORT §6, §7.1; EXT §4 (entry 5)

**Current Implementation:** Hiding is cosmetic only.

**Unknown:** Whether hidden routes imply restricted access.

**Conflict:** None found.

**Impact:** Consistency of UI vs enforced access.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 036 (Deep-link protection)

**Question:** Should URLs entered directly (e.g., `/users/:user_id`, `/dashboard/farm/:farmId`) be guarded the same as menu navigation?

**Current Evidence:** Deep links are reachable because the only guard is auth (`EXT §4` entry 11; `EXT §5` touchpoint 11); `/dashboard/farm/:farmId` and `/users/:user_id` are nested routes (`EXT §4` entry 10, 11).

**Evidence Source:** EXT §4 (entries 10, 11), EXT §5 (touchpoint 11)

**Current Implementation:** No distinction between menu navigation and direct URL access.

**Unknown:** Whether direct-URL access should be further restricted.

**Conflict:** None found.

**Impact:** Backend must remain the real authority regardless of frontend.

**Priority:** High

**Decision Required:** YES

---

### Decision 037 (Page-level feature visibility)

**Question:** Should CRUD buttons / actions within pages be shown per role?

**Current Evidence:** All page CRUD buttons render for everyone (`EXT §5` touchpoint 10); the one exception is the "Tổng quan hoạt động" button gated client-side on Farm Owner rows (`EXT §5` touchpoint 11).

**Evidence Source:** EXT §5 (touchpoints 10, 11)

**Current Implementation:** Uniform UI actions.

**Unknown:** Desired per-role action visibility.

**Conflict:** None found.

**Impact:** Frontend consistency with backend rules.

**Priority:** Medium

**Decision Required:** YES

---

## 8. API ACCESS DECISION

### Decision 038 (Per-endpoint protection model)

**Question:** Should every endpoint carry explicit protection instead of the current `allow_all` pattern?

**Current Evidence:** Most routers use `allow_all = RoleChecker([all roles])` = effectively any authenticated user; only the admin overview is restricted (`REPORT §4.3`, `§6`); `history.py` and `chat.py` use only `get_current_user_id` (`REPORT §4.3`).

**Evidence Source:** REPORT §4.3, §6

**Current Implementation:** Per-route guard is auth-only in practice.

**Unknown:** The intended per-endpoint policy.

**Conflict:** None found.

**Impact:** The enforcement point for all API access.

**Priority:** High

**Decision Required:** YES

---

### Decision 039 (Public endpoint set)

**Question:** Which endpoints should remain public?

**Current Evidence:** Public set today: `/health`, `/docs`, `/redoc`, `/openapi.json`, `/auth/register`, `/auth/login`, `/auth/refresh` (`REPORT §4.3`); `/docs`/`/openapi.json` expose the full API surface with no auth (`REPORT §13` risk 12).

**Evidence Source:** REPORT §4.3, §13

**Current Implementation:** As listed.

**Unknown:** Whether the current public set is the intended business set.

**Conflict:** None found.

**Impact:** Attack-surface boundary.

**Priority:** High

**Decision Required:** YES

---

### Decision 040 (Notification endpoint access)

**Question:** Who may create/read/delete notifications, and for whom are they targeted?

**Current Evidence:** Notifications are global; unread list has no user filter (`REPORT §13` risk 10; `EXT §5` touchpoint 17); create writes into `alerts` picking arbitrary zone/tree of the farm (`EXT §1, Notifications`).

**Evidence Source:** REPORT §13; EXT §1 (Notifications), EXT §5 (touchpoint 17)

**Current Implementation:** Anyone authenticated can create/read/delete global notifications.

**Unknown:** Notification ownership and targeting rules.

**Conflict:** None found.

**Impact:** Communication-channel access control.

**Priority:** High

**Decision Required:** YES

---

## 9. DATA VISIBILITY

### Decision 041 (Company / Farm data visibility)

**Question:** Which users may see which companies' and farms' data?

**Current Evidence:** Companies and farms are global CRUD (`EXT §2, Company/Farm`); no scoping (`REPORT §11`); dashboard aggregates across all farms (`REPORT §9.3`, `§13` risk 3).

**Evidence Source:** REPORT §9.3, §11, §13; EXT §2 (Company, Farm)

**Current Implementation:** Everyone sees all companies and farms.

**Unknown:** The visibility rule per role/scope.

**Conflict:** None found.

**Impact:** Enterprise data confidentiality.

**Priority:** High

**Decision Required:** YES

---

### Decision 042 (Zone / Tree / Inspection / Detection / Alert visibility)

**Question:** Who may see zone/tree/inspection/detection/alert rows?

**Current Evidence:** All are global lists (`REPORT §6`; `EXT §2`); alerts stream is global in the header (`EXT §5` touchpoint 7).

**Evidence Source:** REPORT §6; EXT §2, EXT §5 (touchpoint 7)

**Current Implementation:** Global visibility.

**Unknown:** Row-level visibility rules.

**Conflict:** None found.

**Impact:** Operational data exposure.

**Priority:** High

**Decision Required:** YES

---

### Decision 043 (Neighbor contact visibility)

**Question:** Who may see neighbor-contact information, and to whom is it shared?

**Current Evidence:** Neighbor data is read-only counts inside Farmer Overview (`EXT §2, Neighbor`); consent statuses exist but no sharing flow (`REPORT §14`); two-party consent fields exist (`REPORT §3.1`).

**Evidence Source:** REPORT §3.1, §14; EXT §2 (Neighbor)

**Current Implementation:** Minimal exposure (counts only).

**Unknown:** The intended sharing/visibility model.

**Conflict:** None found.

**Impact:** Cross-farm privacy.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 044 (Field-level visibility)

**Question:** Should certain fields (e.g., contact info, status, internal codes) be visible to all roles?

**Current Evidence:** Password hashes are stripped from user responses (`REPORT §5.3`); frontend `User` type declares `company_id` that backend never returns (`REPORT §5.5`); Users detail shows role and organization sections (`EXT §1, Users`).

**Evidence Source:** REPORT §5.3, §5.5; EXT §1 (Users)

**Current Implementation:** One field redaction (password) exists; otherwise flat visibility.

**Unknown:** Desired field-level redaction rules.

**Conflict:** Frontend expects `company_id`, backend never provides it (`REPORT §5.5`).

**Impact:** Field-level privacy.

**Priority:** Medium

**Decision Required:** YES

---

## 10. SPECIAL CASE

### Decision 045 (Cross-company / cross-farm access)

**Question:** Should users ever access data of another company or farm?

**Current Evidence:** No scoping exists at all (`REPORT §13` risk 1); tenant requirements NOT FOUND (`REPORT §14`); everything is effectively global today.

**Evidence Source:** REPORT §13, §14

**Current Implementation:** Cross-company/cross-farm access is possible (unrestricted) but is neither sanctioned nor denied.

**Unknown:** Whether cross-entity access is a business feature.

**Conflict:** None found.

**Impact:** Boundary rules for any enterprise deployment.

**Priority:** High

**Decision Required:** YES

---

### Decision 046 (Neighbor contact sharing workflow)

**Question:** What is the intended end-to-end neighbor-contact sharing flow and its consent rules?

**Current Evidence:** Data model + statuses exist; no API or UI (`REPORT §10`, `§14`; `EXT §2, Neighbor`); consent statuses are only counted (`EXT §1, Farmer Overview`).

**Evidence Source:** REPORT §10, §14; EXT §1 (Farmer Overview), EXT §2 (Neighbor)

**Current Implementation:** Feature is inert beyond counts.

**Unknown:** The complete workflow (request, consent, share, revoke).

**Conflict:** None found.

**Impact:** A bespoke two-party authorization case.

**Priority:** High

**Decision Required:** YES

---

### Decision 047 (Shared data / multiple companies)

**Question:** Can one entity (farm, tree, or detection record) be shared across companies?

**Current Evidence:** `detection_results`/`disease_history`/`alerts` carry optional `company_id` that services never write (`EXT §2`); the relationship between per-inspection `detection_results` and per-tree `diseases` rows is undocumented (`EXT §6` item 6); users have no multi-company field (`REPORT §5.1`).

**Evidence Source:** REPORT §5.1; EXT §2, EXT §6 (item 6)

**Current Implementation:** No sharing mechanism.

**Unknown:** Whether data sharing across companies is intended.

**Conflict:** None found.

**Impact:** Multi-tenancy corner cases.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 048 (Delegation / temporary assignment)

**Question:** Are delegation or temporary assignments (e.g., a manager standing in for a Farm Owner) required?

**Current Evidence:** No assignment/delegation exists (`REPORT §10`); `farms.manager_user_id` suggests a second party but is never used (`EXT §6` item 12).

**Evidence Source:** REPORT §10; EXT §6 (item 12)

**Current Implementation:** No delegation capability.

**Unknown:** Whether delegation is a business requirement.

**Conflict:** None found.

**Impact:** Advanced authorization scenarios.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 049 (Audit log)

**Question:** What must be audited (who did what, when), and who can view the audit trail?

**Current Evidence:** Activity feed exists only inside Farmer Overview (`EXT §1, Farmer Overview`); no system-wide audit/activity log (`EXT §6` item 13); no token revocation list, only refresh-token clearing (`REPORT §4.5`).

**Evidence Source:** REPORT §4.5; EXT §1 (Farmer Overview), EXT §6 (item 13)

**Current Implementation:** Per-farmer activity timeline only.

**Unknown:** Audit requirements and audit access.

**Conflict:** None found.

**Impact:** Accountability and compliance.

**Priority:** Medium

**Decision Required:** YES

---

### Decision 050 (Mobile vs web parity)

**Question:** Should the mobile app follow the same authorization model and role set as the web portal?

**Current Evidence:** Mobile shares the same backend endpoints (`EXT §4.2`) but most features are mock-backed (`REPORT §13` risk 14); mobile auth policy NOT FOUND (`REPORT §14`); web has no mobile-equivalent camera/onboarding flows (`EXT §6` item 9).

**Evidence Source:** REPORT §13, §14; EXT §4.2, EXT §5 (touchpoint 21), EXT §6 (item 9)

**Current Implementation:** Same token/endpoints; mock-heavy client.

**Unknown:** Whether mobile users have different roles/screens than web.

**Conflict:** None found.

**Impact:** Consistent enforcement across clients.

**Priority:** Medium

**Decision Required:** YES

---

## FINAL SECTION — AUTHORIZATION READINESS SCORE

Evidence-based readiness of the current project to support Antigravity's Authorization **design**. Each factor is rated from evidence in the two reports (0–100%); the overall score is the average of the rated factors, **not** a judgment of code quality.

| # | Design input | Evidence | Score |
|---|---|---|---|
| 1 | Authentication mechanism (JWT HS256, bcrypt, refresh rotation) documented | Implemented; fully described (`REPORT §4.1`, `§4.2`) | 100% |
| 2 | Role identity documented (6 DB roles ↔ 4 API roles, mapping, fallbacks) | Fully described (`REPORT §5.2`) | 100% |
| 3 | Enforcement seams documented (dependencies, `RoleChecker`, repositories, services, frontend routes/sidebar) | Fully described (`REPORT §4.2`, `§12`; `EXT §5`) | 80% |
| 4 | Data hooks for scoping/ownership documented (`owner_user_id`, `manager_user_id`, `company_id`, `inspector_id`, source/target fields) | Documented but mostly seed/schema-only (`REPORT §3.1`, `§15.2`; `EXT §2`) | 60% |
| 5 | Frontend gating seams documented (ProtectedRoute, sidebar, routes) | Auth-only; gaps described (`REPORT §7.1`, `§7.3`; `EXT §4`) | 50% |
| 6 | Permission model / permission catalog | **NOT FOUND** (`REPORT §11`, `§14`) | 0% |
| 7 | Ownership model (who owns what) | Not Implemented / mostly UNKNOWN (`REPORT §10`; `EXT §2`) | 15% |
| 8 | Scope / tenant model | Not Implemented (`REPORT §11`); tenant requirements NOT FOUND (`REPORT §14`) | 10% |
| 9 | Business rules "who may do what" (CRUD/view/action) | NOT FOUND (`REPORT §14`; `EXT §6`) | 0% |
| 10 | Special-case requirements (cross-entity, neighbor consent, delegation, audit) | NOT FOUND / inert data only (`REPORT §14`; `EXT §6`) | 10% |

**Overall readiness for Authorization design:** ≈ **42%**

**Basis for the score:** ~4 of the 10 design inputs (auth mechanism, role identity, enforcement seams, partial data hooks) are substantially ready (100/100/80/60). The other six (permission catalog, ownership, scope/tenant, business rules, special cases) are 0–15% because they are recorded as **NOT FOUND / NOT IMPLEMENTED / UNKNOWN** in the evidence. The dominant gap is therefore not code but the **business decisions** catalogued in this report (Decisions 001–050) — all of which remain **Decision Required: YES** and are left open for Antigravity and the product owner to answer.

---

*End of AUTHORIZATION_DISCOVERY_REPORT.md. Discovery complete — READ ONLY. No code, files, or git changes were made beyond the creation of this report.*
