# Phase 2.5: Root Cause Classification Report

**Date:** 2026-07-28
**Status:** COMPLETE

---

## 1. BROKEN ITEM CLASSIFICATION

Each of the 26 Phase 2 Broken items is classified below.

### Items 1–4: Schema Layer

| # | Item | Classification | Reason | Evidence | Depends On |
|---|------|---------------|--------|----------|------------|
| 1 | `DiseaseCreate/Update/Out` — extra fields `affected_part`, `severity`, `description`, `recommendation` not in DB | ⚠️ Warning | MongoDB is schemaless. Writing extra fields does NOT cause errors. Seed data lacks them → they are null in responses. This is a **seed-data difference** and **optional field** design choice. Not broken at runtime. | DB `diseases` has `code`, `name`, `created_at`. Service writes `affected_part` → MongoDB accepts. `DiseaseOut` uses `Optional` types → null is valid. | — |
| 2 | `InspectionCreate/Update/Out` — `zone_id` not in DB `inspections` | ⚠️ Warning | Same principle. MongoDB stores the extra field. For seed inspections (no zone_id), `InspectionOut` returns `zone_id` as null. The schema uses `str` not `Optional[str]` — this can cause Pydantic validation failure if response_model were enforced. But API returns raw dict via `JSONResponse`, so no runtime failure. | `InspectionOut.zone_id: str` not Optional. But `success_response` returns `JSONResponse` directly → `response_model` is docs-only. Seed data returned as-is. | — |
| 3 | `InspectionCreate` — `inspector_id` used by service but not in DB schema | ⚠️ Warning | `inspector_id` is added by the service layer (from authenticated user), not by the schema. It's written to DB at runtime — MongoDB accepts it. Seed data lacks it → null for old records. | `InspectionService.create_inspection` adds `inspector_id: ObjectId(inspector_id)`. DB seed inspections don't have it. | — |
| 4 | `InspectionUpdate` — Same as #3 | ⚠️ Warning | Same reasoning as #3. | Same as #3. | — |

### Items 5–10: Repository Layer

| # | Item | Classification | Reason | Evidence | Depends On |
|---|------|---------------|--------|----------|------------|
| 5 | `DetectionResultRepository` — `$lookup` on `trees` using `tree_id` not in `detection_results` | ❌ Root Cause | `detection_results` has only `inspection_id`. No `tree_id` field exists. `$lookup` with non-existent localField uses `null` → yields zero matches → `tree_code` always null. This is a **real deficiency** — enrichments silently fail. | DetectionResultRepository `_build_enrichment_stages()` line: `"localField": "tree_id"`. Dashboard `_get_recent_detections` correctly uses `"inspection.tree_id"` after lookup — proving the correct path. | — |
| 6 | `DiseasesRepository` — Queries `affected_part` not in DB | ⚠️ Warning | Querying a non-existent field returns zero results for seed data. No crash. Degraded search for keyword=affected_part. | `get_all` includes `"affected_part"` in `$or` regex filter. Won't match seed data. | Cascade of #1 |
| 7 | `FarmRepository` — `user.get("company_id")` not in DB `users` | ❌ Root Cause | `users` collection has no `company_id` field. `user.get("company_id")` always returns `None`. Fallback sets empty filter → `list_by_owner` returns **ALL farms** regardless of user. Farm-level authorization **completely broken**. | `farm_repository.py:list_by_owner`: `user = await db["users"].find_one(...)`, `user_company = user.get("company_id")`. DB users: `created_at`, `email`, `full_name`, `password_hash`, `role`, `user_code`. **No company_id.** | — |
| 8 | `InspectionRepository` — `$lookup` on `users` via `inspector_id` not in `inspections` | ❌ Root Cause | `inspections` collection has no `inspector_id`. `$lookup` uses `null` localField → `inspector_name` always null. Inspector metadata enrichment **completely non-functional**. | `inspection_repository.py:_build_enrichment_stages`: `"localField": "inspector_id"`. DB inspections: `confidence`, `created_at`, `disease_id`, `farm_id`, `health_status`, `humidity`, `inspection_code`, `inspection_date`, `predicted_disease`, `rainfall`, `temperature`, `tree_id`. **No inspector_id.** | — |
| 9 | `UserRepository` — Writes `refresh_token` not in DB `users` | ⚠️ Warning | MongoDB stores the field. Not in audit schema but works at runtime. Auth refresh flow functions correctly. | `user_repository.py:update_refresh_token`: `"$set": {"refresh_token": refresh_token}`. MongoDB accepts. AuthService login/refresh/register all call this — authentication works. | — |
| 10 | `ZoneRepository` / `TreeRepository` — Sort/query by `zone_code` not in DB `zones` | ⚠️ Warning | MongoDB sort on non-existent field is a **silent no-op** — no error, no sort applied. Degraded UX (zones listed unsorted) but no crash. | `zone_repository.py:list_by_farm`: `sort=[("zone_code", 1)]`. `tree_repository.py:_build_enrichment_stages`: adds `"zone_code": "$zone_info.zone_code"`. DB zones: `created_at`, `farm_id`, `tree_count`, `zone_name`. **No zone_code.** | — |

### Items 11–19: Service Layer

| # | Item | Classification | Reason | Evidence | Depends On |
|---|------|---------------|--------|----------|------------|
| 11 | `ChatService` — References `disease.get('severity')` and `.get('confidence')` on `disease_history` | ⚠️ Warning | Fields don't exist so `.get()` returns `None` → f-string renders `'None'`. AI context has less data but doesn't crash. Degraded AI response quality. | `chat_service.py:ask`: `d.get('severity', 'N/A')`, `d.get('confidence', 'N/A')`. DB `disease_history`: `action`, `created_at`, `date`, `disease`, `tree_id`. **No severity or confidence.** | — |
| 12 | `DiseaseService` — Writes extra fields to `diseases` | ⚠️ Warning | MongoDB accepts extra fields. New records have them, seed records don't. Schema drift but not a crash. | `disease_service.py:create_disease`: writes `affected_part`, `severity`, `description`, `recommendation`. MongoDB stores them. Existing seed data lacks them. | Cascade of #1 |
| 13 | `FarmService.list_by_owner` — broken because `user.get("company_id")` always None | ❌ Cascade Issue | Authorized farm listing returns ALL farms. Direct consequence of Root Cause #7. | `farm_service.py:list_farms` → `self.repo.list_by_owner(user_id, ...)`. Repo returns unfiltered list. | RC #7 |
| 14 | `InspectionService` — Writes `zone_id` and `inspector_id` not in DB | ❌ Cascade Issue / ⚠️ Warning | `zone_id`: MongoDB accepts → extra field. `inspector_id`: MongoDB accepts → extra field. Two distinct downstream issues: `zone_id` is a Warning (graceful), `inspector_id` root cause is #8. | `inspection_service.py:create_inspection`: adds both `zone_id` and `inspector_id` to doc. | RC #8 (inspector_id) + #2 (zone_id) |
| 15 | `NotificationService.create_notification` — Writes `title`, `content`, `status` to `alerts` | ❌ Root Cause | Backend uses notifications mapped to `alerts` collection with phantom fields. Creates records with `status`, `title`, `content` not in DB `alerts` schema. Functions at runtime but schema is invented. | `notification_service.py:create_notification`: `alert_doc = {"title": data.title, "content": data.content, "status": data.status.value, ...}`. DB `alerts`: `alert_type`, `created_at`, `date`, `farm_id`, `priority`, `tree_id`. | — |
| 16 | `NotificationService.list_unread` — Filters by `{"status": "unread"}` | ⚠️ Warning | Seed alerts have no `status` field → not matched. Only notification-created alerts (with `status`) appear. Degraded but not crashing. | `notification_service.py:list_unread`: `filter_query={"status": "unread"}`. Existing alerts lack `status`. Only new notifications returned. | Cascade of #15 |
| 17 | `AuthService.register` — Writes `refresh_token` | ⚠️ Warning | MongoDB accepts the extra field. No runtime issue. | `auth_service.py:register` → `user_repo.create(...)` then later `update_refresh_token(...)`. | Cascade of #9 |
| 18 | `AuthService.login` — Same | ⚠️ Warning | Same as #17. | `auth_service.py:login`: calls `update_refresh_token`. | Cascade of #9 |
| 19 | `AuthService.refresh` — Same | ⚠️ Warning | Same as #17. | `auth_service.py:refresh`: calls `update_refresh_token`. | Cascade of #9 |

### Items 20–22: API Layer

| # | Item | Classification | Reason | Evidence | Depends On |
|---|------|---------------|--------|----------|------------|
| 20 | `diseases` CRUD API — Docs show phantom fields | ⚠️ Warning | API docs (OpenAPI/Swagger) reflect schema. Recorded fields exist in API output (null for seed). Correct but misleading to API consumers. | `response_model=SuccessResponse[DiseaseOut]` — used for docs only. Actual response is raw `JSONResponse`. | Cascade of #1 |
| 21 | `inspections` CRUD API — Docs show phantom `zone_id` | ⚠️ Warning | Same as #20 — docs-only issue. | Same mechanism. | Cascade of #2 |
| 22 | `notifications` endpoints — Phantom schema | ❌ Cascade Issue | Notifications API exposes CRUD on a phantom entity. The underlying `alerts` collection stores the data with extra fields. Works at runtime but the conceptual model is disconnected from DB reality. | Notifications router maps to `NotificationService` → `NotificationRepository` (points to `alerts`). Writing to alerts with phantom fields. | RC #15 |

### Items 23–25: Dashboard Layer

| # | Item | Classification | Reason | Evidence | Depends On |
|---|------|---------------|--------|----------|------------|
| 23 | `_get_widget_detections` — `$lookup` on `trees` via `tree_id` not in `detection_results` | ❌ Cascade Issue | Same broken pattern as item #5. Dashboard aggregates detection_results and tries direct `tree_id` join — fails silently. Widget detections always show empty tree info. | `dashboard/service.py:420-463`: `"localField": "tree_id"`. Same Root Cause as #5. Compare with correct implementation at line 155: `"localField": "inspection.tree_id"`. | RC #5 |
| 24 | `_get_widget_priority_trees` — Same as #23 | ❌ Cascade Issue | Same broken `tree_id` join. Priority trees widget has no tree data. | `dashboard/service.py:488-560`: aggregates detection_results, `"localField": "tree_id"`. | RC #5 |
| 25 | Dashboard does NOT use a Read Model collection | ⚠️ Warning | No `seasons`, `harvests`, `farm_targets`, `farm_performance` collections exist in DB. The dashboard uses direct aggregation — this is an **architecture design decision**, not a bug. The DB was never seeded with read-model collections. | Planned collections never created. Dashboard `get_dashboard` uses live aggregation queries which work (except for the broken joins in #23-#24). | — |

### Item 26: Phase 1 Warning

| # | Item | Classification | Reason | Evidence | Depends On |
|---|------|---------------|--------|----------|------------|
| 26 | Farm owner role mapping — `user.get("company_id")` broken | ❌ Cascade Issue | Same root cause as #7 and #13. Farm listing authorization is broken because `company_id` not in DB `users`. | Already analyzed in #7. | RC #7 |

---

## 2. ROOT CAUSE MATRIX

```
Root Cause          ↓ Schemas  ↓ Repos    ↓ Services  ↓ APIs     ↓ Dashboard
───────────────────────────────────────────────────────────────────────────────
RC-A #7             —          FarmRepo   FarmSvc    farms API  Dashboard
 company_id not                 (#7)       (#13)      (#26)     (farm filter)
 in DB users                                             	
                                                                 
RC-B #8             —          InspRepo   InspSvc    —          —
 inspector_id                   (#8)       (#14)
 not in DB inspir.

RC-C #5             —          DetResRepo —          —          WidgetDets (#23)
 tree_id not in                             (correct              WidgetPri (#24)
 detection_results                          path exists
                                            via inspection)

RC-D #15            Notification           NotifSvc   notifs API —
 notifications       schemas     —         (#15,#16)  (#22)
 mapped to alerts    (#2*)

* Note: RC-D includes the Notification schema definition as a root cause act.
```

**Correction — let me rebuild this cleanly:**

---

### Root Cause Matrix (clean)

| # | Root Cause | Origin Layer | Schemas | Repositories | Services | APIs | Dashboard |
|---|-----------|-------------|---------|-------------|----------|------|-----------|
| **RC-A** | `company_id` missing from DB `users` | **DB Model** | — | `FarmRepository` (#7) | `FarmService.list_by_owner` (#13) | `GET /farms` (#26) | `Dashboard.get_dashboard` |
| **RC-B** | `inspector_id` missing from DB `inspections` | **DB Model** | — | `InspectionRepository` (#8) | `InspectionService.create` (#14) | — | — |
| **RC-C** | `tree_id` missing from DB `detection_results` | **DB Model** | — | `DetectionResultRepository` (#5) | — | — | `_get_widget_detections` (#23), `_get_widget_priority_trees` (#24) |
| **RC-D** | Notifications mapped to `alerts` with invented schema | **Architecture** | `NotificationCreate` (+ `title`, `content`, `status`) | `NotificationRepository` (collection = `alerts`) | `NotificationService.create` (#15), `list_unread` (#16) | `notifications` endpoints (#22) | `_get_alerts` (reads `title`/`content`) |
| **RC-E** | `zone_code` missing from DB `zones` | **DB Model** | — | `ZoneRepository.sort` (#10), `TreeRepository.enrich` (#10) | — | — | — |
| **RC-F** | `zone_id` missing from DB `inspections` | **DB Model** | `InspectionCreate` (has `zone_id`) (#2) | — | `InspectionService.create` (#14) | `inspections` API docs (#21) | — |
| **RC-G** | Disease schema has extra fields not in DB | **Schema Design** | `DiseaseCreate/Out` has `affected_part`, `severity`, etc. (#1) | `DiseasesRepository` queries them (#6) | `DiseaseService` writes them (#12) | `diseases` API docs (#20) | — |
| **RC-H** | `refresh_token` not in DB `users` | **DB Model** | — | `UserRepository.update_refresh_token` (#9) | `AuthService` (#17,#18,#19) | — | — |
| **RC-I** | `severity`/`confidence` not in DB `disease_history` | **DB Model** | — | — | `ChatService.ask` (#11) | — | — |

---

## 3. MERGED ROOT CAUSE LIST

After merging, the **original 26 broken items** reduce to **9 independent root causes**:

| RC ID | Root Cause | Affected Components | Severity |
|-------|-----------|-------------------|----------|
| **RC-A** | `company_id` missing from DB `users` collection | FarmRepository (owner filter), FarmService (farm listing by user), Dashboard (farm-scoped data), API (authorized farm access) | **Critical** — farm authorization completely broken |
| **RC-B** | `inspector_id` missing from DB `inspections` collection | InspectionRepository (user lookup for inspector name), InspectionService (writes phantom field) | **High** — inspector enrichment non-functional |
| **RC-C** | `tree_id` missing from DB `detection_results` collection | DetectionResultRepository (enrichment), Dashboard widget (2 separate aggregation paths) | **High** — tree enrichment for detections broken |
| **RC-D** | Notifications mapped to `alerts` collection with invented schema | Notification schema, NotificationRepository, NotificationService, notifications API | **Medium** — functions at runtime but schema is fabricated |
| **RC-E** | `zone_code` missing from DB `zones` collection | ZoneRepository (sort), TreeRepository (enrichment adds null field) | **Low** — sort silently no-op; null field gracefully handled |
| **RC-F** | `zone_id` missing from DB `inspections` collection | Inspection schema (has field), InspectionService (writes it), API docs (shows it) | **Low** — MongoDB accepts extra field; null for seed data |
| **RC-G** | Disease schema has extra fields not in DB | Disease schema, DiseasesRepository, DiseaseService, API docs | **Low** — MongoDB accepts; null for seed data |
| **RC-H** | `refresh_token` not in DB `users` collection | UserRepository, AuthService (login/register/refresh) | **Low** — MongoDB accepts; auth flow works |
| **RC-I** | `severity`/`confidence` not in DB `disease_history` | ChatService (reduces AI context quality) | **Low** — degraded AI responses but no crash |

---

## 4. CASCADE ISSUE LIST

These are NOT root causes — they are downstream consequences:

| # | Cascade Issue | Root Cause | Layer |
|---|--------------|------------|-------|
| 13 | `FarmService.list_by_owner` returns ALL farms | RC-A (#7) | Service |
| 14 (part) | `InspectionService` writes `inspector_id` | RC-B (#8) | Service |
| 16 | `NotificationService.list_unread` misses seed alerts (no `status`) | RC-D (#15) | Service |
| 17 | `AuthService.register` calls `update_refresh_token` | RC-H (#9) | Service |
| 18 | `AuthService.login` calls `update_refresh_token` | RC-H (#9) | Service |
| 19 | `AuthService.refresh` calls `update_refresh_token` | RC-H (#9) | Service |
| 20 | `diseases` API docs show phantom fields | RC-G (#1) | API |
| 21 | `inspections` API docs show phantom `zone_id` | RC-F (#2) | API |
| 22 | `notifications` API exposes phantom entity | RC-D (#15) | API |
| 23 | Dashboard `_get_widget_detections` broken join | RC-C (#5) | Dashboard |
| 24 | Dashboard `_get_widget_priority_trees` broken join | RC-C (#5) | Dashboard |
| 26 | Farm owner role mapping returns all farms | RC-A (#7) | Service/API |

---

## 5. WARNING LIST

These items are NOT broken at runtime — they are seed-data differences, design decisions, or graceful degradation:

| # | Warning | Reason |
|---|---------|--------|
| 1 | Disease schema extra fields | MongoDB accepts them; null for seed data |
| 2 | Inspection schema `zone_id` | MongoDB accepts; `response_model` is docs-only |
| 3 | Inspection `inspector_id` added by service | MongoDB accepts; null for seed data |
| 4 | InspectionUpdate same as #3 | Same reasoning |
| 6 | DiseasesRepository queries `affected_part` | Degraded search (no match on seed data) but no crash |
| 9 | UserRepository writes `refresh_token` | MongoDB accepts; auth flow works |
| 10 | Sort by `zone_code` in zones | MongoDB no-op; unsorted output |
| 11 | ChatService references missing `severity`/`confidence` | `.get()` defaults to 'N/A'; degraded AI context |
| 12 | DiseaseService writes extra fields | MongoDB accepts |
| 14 (part) | InspectionService writes `zone_id` | MongoDB accepts; null for seed data |
| 25 | Dashboard lacks Read Model collection | Architecture decision; planned collections never created |
| 20 | API docs show phantom fields | Docs-only via `response_model`; actual response is raw JSON |
| 21 | API docs show phantom `zone_id` | Same as #20 |

---

## 6. FALSE POSITIVE LIST

None of the 26 broken items are false positives. Every item reflects a genuine discrepancy between the backend and the locked database. However, many are not "broken" in the runtime-crash sense — they are classified as Warnings.

---

## 7. ROOT CAUSE SUMMARY

| Metric | Count |
|--------|-------|
| **Original Phase 2 Broken Items** | 26 |
| **Independent Root Causes** | **9** |
| **Cascade Issues** | 12 |
| **Warnings** | 13 |
| **False Positives** | 0 |

| Root Cause | Severity | Functional Impact |
|-----------|----------|-------------------|
| RC-A: `company_id` not in `users` | Critical | Farm authorization broken |
| RC-B: `inspector_id` not in `inspections` | High | Inspector info always null |
| RC-C: `tree_id` not in `detection_results` | High | Tree enrichment in detections fails |
| RC-D: Notifications = alerts phantom | Medium | Works at runtime; schema mismatch |
| RC-E: `zone_code` not in `zones` | Low | Sort silently fails |
| RC-F: `zone_id` not in `inspections` | Low | Extra field, gracefully handled |
| RC-G: Disease extra fields | Low | Extra fields, gracefully handled |
| RC-H: `refresh_token` not in `users` | Low | Works at runtime |
| RC-I: `severity`/`confidence` missing | Low | Degraded AI context |

---

## 8. FINAL DECISION

| Category | Count |
|----------|-------|
| **True Root Causes** | 9 |
| **Truly Broken (Critical/High)** | **3** (RC-A, RC-B, RC-C) |
| **Low/Medium Issues** | 6 (RC-D through RC-I) |
| **Warnings (not broken)** | 13 |
| **False Positives** | 0 |

The original 26 broken items collapse to **3 critical root causes** that produce real functional damage:

1. **RC-A** — `company_id` missing from `users` → farm-level authorization void
2. **RC-B** — `inspector_id` missing from `inspections` → inspector enrichment non-functional
3. **RC-C** — `tree_id` missing from `detection_results` → detection tree joins broken

The remaining 6 root causes are low/medium severity (schema drift, phantom fields, degraded features, design gaps).

The 13 warnings are seed-data differences, graceful degradations, or architecture decisions that function correctly at runtime.

**WAITING FOR MANUAL REVIEW. DO NOT START PHASE 3.**
