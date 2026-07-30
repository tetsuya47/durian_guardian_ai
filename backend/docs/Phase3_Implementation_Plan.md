# Phase 3: Backend Implementation Plan

**Date:** 2026-07-28
**Status:** PLANNING COMPLETE (waiting manual review)

---

## 1. IMPLEMENTATION SCOPE

Based on Phase 2.5 root cause analysis, the following are included in this plan:

| Include | Count | Details |
|---------|-------|---------|
| ✅ Root Causes | 3 | RC-A (P0), RC-C (P1), RC-E (P2) |
| ✅ Broken Issues | 3 | #13 (farm service), #23/#24 (dashboard joins) |
| ❌ Warnings | 0 | Not required to resolve any root cause |
| ❌ False Positives | 0 | None identified |
| ❌ Architecture Decisions | 0 | Not touched |

### Excluded Root Causes

| RC ID | Reason for Exclusion |
|-------|---------------------|
| RC-B (`inspector_id` in inspections) | Code already writes `inspector_id` on create. Repo `$lookup` works correctly for new data. Seed data gap only — Warning, not broken |
| RC-D (Notifications = alerts phantom) | Architecture decision. Functions at runtime |
| RC-F (`zone_id` in inspections) | Code writes field. MongoDB accepts. Seed data gap — Warning |
| RC-G (Disease extra fields) | MongoDB accepts. Seed data gap — Warning |
| RC-H (`refresh_token` in users) | MongoDB accepts. Auth flow works — Warning |
| RC-I (`severity`/`confidence` in disease_history) | `.get()` defaults gracefully. Degraded AI context — Warning |

---

## 2. PRIORITY MATRIX

| RC ID | Priority | Description | Estimated Complexity | Affected Layers |
|-------|----------|-------------|---------------------|-----------------|
| **RC-A** | **P0** | `company_id` not in DB `users` → farm authorization broken (returns ALL farms) | Medium | Repository → Service → API → Dashboard |
| **RC-C** | **P1** | `tree_id` not in DB `detection_results` → tree enrichment joins broken | Low | Repository → Dashboard |
| **RC-E** | **P2** | `zone_code` not in DB `zones` → sort silently no-op, enrichment adds null field | Low | Repository |

---

## 3. AFFECTED FILE LIST

### P0 — RC-A: Farm Authorization Fix

| # | File | Reason | Depends On | Impact |
|---|------|--------|------------|--------|
| 1 | `backend/app/repositories/farm_repository.py` | `list_by_owner` relies on `user.get("company_id")` which is always None. Fallback returns unfiltered results. Must change the filter logic | None | Medium — changes core query logic for farm listing by user |
| 2 | `backend/app/services/farm_service.py` | `list_farms` delegates to repo `list_by_owner`. May need adapter or role-based fallback logic | #1 | Low — thin wrapper, follows repo change |
| 3 | `backend/app/api/v1/farms.py` | `GET /farms` endpoint may need updated response handling | #2 | Low — docs-only `response_model` |
| 4 | `backend/app/dashboard/service.py` | `get_dashboard` calls `farm_repo.list_by_owner(user_id, ...)` → relies on correct filtering | #1 | Low — consumer only |

### P1 — RC-C: Detection Tree Enrichment Fix

| # | File | Reason | Depends On | Impact |
|---|------|--------|------------|--------|
| 5 | `backend/app/repositories/detection_result_repository.py` | `_build_enrichment_stages` uses `"localField": "tree_id"` but `detection_results` has no `tree_id`. Must use `"inspection_info.tree_id"` after the inspections $lookup | None | Low — single field path change |
| 6 | `backend/app/dashboard/service.py` | Two methods broken: `_get_widget_detections` (line 427) and `_get_widget_priority_trees` (line 494) both use `"localField": "tree_id"` directly on `detection_results`. Must join through inspections first | None | Medium — both methods need pipeline restructure to join inspections → trees |

### P2 — RC-E: Zone Code Sort Fix

| # | File | Reason | Depends On | Impact |
|---|------|--------|------------|--------|
| 7 | `backend/app/repositories/zone_repository.py` | `list_by_farm` sorts by `"zone_code"` which doesn't exist in DB zones. Change to `"zone_name"` | None | Low — single field name change |
| 8 | `backend/app/repositories/tree_repository.py` | `_build_enrichment_stages` adds `"zone_code": "$zone_info.zone_code"` (always null). Change to `"zone_name": "$zone_info.zone_name"` or remove | None | Low — single field path change |

---

## 4. IMPLEMENTATION ORDER

```
Phase 3.1 — Schemas
  (No schema changes required — all schema warnings are excluded per scope rules)

Phase 3.2 — Repositories
  ├── #7  zone_repository.py        (P2 — RC-E: zone_code → zone_name sort)
  ├── #8  tree_repository.py         (P2 — RC-E: zone_code → zone_name enrichment)
  ├── #5  detection_result_repository.py  (P1 — RC-C: fix tree_id join path)
  └── #1  farm_repository.py         (P0 — RC-A: fix company_id filter)

Phase 3.3 — Services
  └── #2  farm_service.py            (P0 — RC-A: align with repo changes)

Phase 3.4 — APIs
  └── #3  farms.py                   (P0 — RC-A: align response if needed)

Phase 3.5 — Dashboard
  ├── #6  dashboard/service.py       (P1 — RC-C: fix widget detection joins)
  └── #4  dashboard/service.py       (P0 — RC-A: consumer of farm filtering)
```

---

## 5. DEPENDENCY ANALYSIS

| Task | Must Finish Before | Blocked By | Potential Side Effects |
|------|--------------------|------------|----------------------|
| #7 zone_repo sort | #8 | None | Sorting order changes from unsorted/no-op to sorted by `zone_name`. No breaking change |
| #8 tree_repo enrichment | — | None | `zone_code` field no longer added to tree docs. Any code reading `zone_code` from enriched tree output will get `None` instead of `null`. Check consumers: `WidgetZoneOption`, `FarmZone`, dashboard tree data |
| #5 detection_result_repo | #6 | None | `tree_code` now populated correctly via inspections join. Previously always null. Non-breaking — values go from null to populated |
| #6 dashboard widget joins | — | #5 | `_get_widget_detections` and `_get_widget_priority_trees` now return correct tree data. Previously tree_code/farm_name/zone_name were always "—" or empty. Non-breaking — values go from defaults to actual data |
| #1 farm_repo filter | #2, #3, #4 | None | Farm listing filter changes. **Breaking potential** — role-based access semantics may change |
| #2 farm_service | — | #1 | Thinner layer; follows repo changes |
| #3 farms API | — | #2 | Docs-only `response_model`; functional change if `list_farms` return shape changes |
| #4 dashboard service | — | #1 | Consumer of `list_by_owner`. Dashboard KPI (total_farms) may change if filter behavior changes |

### Critical Dependency Path

The dependency chain is linear within each root cause:
- **RC-A**: farm_repo → farm_service → farms API → dashboard
- **RC-C**: detection_result_repo → dashboard widgets
- **RC-E**: zone_repo and tree_repo (independent)

No cross-RC dependencies exist.

---

## 6. RISK ASSESSMENT

| Risk | RC-A | RC-C | RC-E |
|------|------|------|------|
| **Data corruption risk** | None | None | None |
| **Breaking API contract** | Medium — farm listing results may change | Low — previously null fields now populated | None |
| **Downstream breakage** | Medium — frontend may rely on current (broken) farm filtering | Low — frontend will now receive correct tree data | Low — sort order changes |
| **Regression potential** | Low — only one code path changes | Low — existing correct implementation (`_get_recent_detections`) proves the approach | Low |
| **Testing difficulty** | Medium — authorization correctness requires role-aware test setup | Low — aggregation pipeline output is deterministic | Low — sort order is observable |

### Overall Risk by Priority

| Priority | Overall Risk | Rationale |
|----------|-------------|-----------|
| P0 (RC-A) | **Medium** | Farm filtering semantics may change. Requires careful rollback planning |
| P1 (RC-C) | **Low** | Following already-proven pattern (`_get_recent_detections`). Fields go from null to populated |
| P2 (RC-E) | **Low** | Trivial field name change in sort/enrichment |

---

## 7. ROLLBACK STRATEGY

### Group 1: RC-A (Farm Authorization)

| Layer | Files | Rollback Method | Risk | Recovery Complexity |
|-------|-------|----------------|------|-------------------|
| Repository | `farm_repository.py` | Revert to previous `user.get("company_id")` logic | Low | Low — single file revert |
| Service | `farm_service.py` | Revert to previous delegation | Low | Low |
| API | `farms.py` | Revert `response_model` or response shape | Low | Low |
| Dashboard | `service.py` | Revert to previous `list_by_owner` call | Low | Low |

**Overall RC-A Rollback:** `git revert <commit>` on affected files. Estimated recovery: 5 minutes.

### Group 2: RC-C (Detection Tree Enrichment)

| Layer | Files | Rollback Method | Risk | Recovery Complexity |
|-------|-------|----------------|------|-------------------|
| Repository | `detection_result_repository.py` | Revert `_build_enrichment_stages` to direct `tree_id` | Low | Low |
| Dashboard | `service.py` | Revert widget methods to direct `tree_id` join | Low | Low |

**Overall RC-C Rollback:** `git revert <commit>` on affected files. Recovery: 5 minutes.

### Group 3: RC-E (Zone Code)

| Layer | Files | Rollback Method | Risk | Recovery Complexity |
|-------|-------|----------------|------|-------------------|
| Repository | `zone_repository.py` | Revert sort field | Low | Low |
| Repository | `tree_repository.py` | Revert enrichment field | Low | Low |

**Overall RC-E Rollback:** `git revert <commit>`. Recovery: 2 minutes.

---

## 8. FINAL IMPLEMENTATION PLAN

### Summary

| Metric | Value |
|--------|-------|
| Root Causes to Fix | 3 (RC-A, RC-C, RC-E) |
| Files to Modify | 6 (`farm_repo`, `farm_service`, `detection_result_repo`, `zone_repo`, `tree_repo`, `dashboard/service`) |
| Files to Review (no change needed) | 2 (`farms.py` API, `dashboard/service.py` RC-A portion) |
| Total Effort Estimate | **Small** (all fixes are localized, low-complexity changes) |

### Execution Order

```
Step 1: zone_repository.py       — sort by "zone_name" (2 min)
Step 2: tree_repository.py       — enrichment zone_name instead of zone_code (2 min)
Step 3: detection_result_repo.py — fix tree_id join path via inspections (5 min)
Step 4: dashboard/service.py     — fix widget detection joins (10 min)
Step 5: farm_repository.py       — fix company_id filter logic (15 min)
Step 6: farm_service.py          — align with repo changes (5 min)
Step 7: farms.py API             — review response alignment (5 min)
Step 8: dashboard/service.py     — review RC-A impact on get_dashboard (5 min)
```

Total estimated implementation time: **~49 minutes**

### Verification Strategy

After each group, verify with:
1. **Lint/typecheck**: `ruff`, `mypy`, or equivalent
2. **Existing tests**: `pytest` to confirm no regression
3. **API smoke test**: Hit affected endpoints and verify response shape

### What NOT to Do

- Do NOT modify any schema files (all schema warnings excluded per scope)
- Do NOT modify database (locked per Phase 1)
- Do NOT touch notification/auth/disease/chat code (warnings, functional at runtime)
- Do NOT create new collections or tables

---

**WAITING FOR MANUAL REVIEW. DO NOT START PHASE 4.**
