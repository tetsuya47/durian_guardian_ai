# Backend Implementation Report — Release 1.3
## Admin Farmer Activity Overview

---

## Project Information

| Field | Value |
|---|---|
| **Project** | Durian Guardian AI |
| **Release** | 1.3 — Admin Farmer Activity Overview (Phase 4) |
| **Date** | 2026-08-01 |
| **Author** | opencode |
| **Stack** | FastAPI + Motor (async MongoDB), Python 3.12 |
| **Status** | Implemented theo Solution Design đã APPROVED (STEP 3) |

---

## Executive Summary

Triển khai hoàn chỉnh feature **Farmer Activity Overview** phía Backend: endpoint
`GET /api/v1/admin/users/{user_id}/overview` cho phép Admin xem tổng quan hoạt động của
một Farm Owner (profile, farm, inspection + AI detection, alerts, neighbor contact, recent activities).

Endpoint là **read-only**, chỉ truy vấn MongoDB thông qua aggregation. **Không thay đổi
Database, ETL, Collection, Validation, Authentication, Authorization.** Không ảnh hưởng
Dashboard / Users / Farms / Inspections / Alerts.

Kiến trúc tuân thủ phân lớp: **Repository → Service → DTO → API**, Dependency Injection
qua `Depends(get_database)` và `RoleChecker` hiện có.

---

## Danh sách file

### File tạo mới

| # | File | Chức năng |
|---|---|---|
| 1 | `backend/app/api/v1/admin.py` | Router admin mới. Định nghĩa endpoint `GET /admin/users/{user_id}/overview`, phân quyền Admin-only, trả về `SuccessResponse[FarmerOverviewDTO]`. |
| 2 | `backend/app/services/farmer_overview_service.py` | `FarmerOverviewService` — Business Logic duy nhất của feature. Aggregate dữ liệu từ `users`, `farms`, `zones`, `trees`, `inspections`, `detection_results`, `alerts`, `neighbor_contact_requests`; xây dựng timeline Recent Activities. |
| 3 | `backend/app/schemas/farmer_overview.py` | Bộ DTO response: `AddressDTO`, `FarmerProfileDTO`, `FarmOverviewDTO`, `InspectionStatsDTO`, `DetectionStatsDTO`, `InspectionOverviewDTO`, `AlertOverviewDTO`, `NeighborOverviewDTO`, `ActivityDTO`, `FarmerOverviewDTO` (cấu trúc phẳng). |
| 4 | `backend/app/repositories/neighbor_contact_request_repository.py` | `NeighborContactRequestRepository` — truy vấn thuần dữ liệu `neighbor_contact_requests`: `count_by_status`, `count_by_direction`, `list_latest` (kèm enrichment tên trang trại nguồn/đích). Không chứa Business Logic. |

### File sửa đổi

| # | File | Chức năng thay đổi |
|---|---|---|
| 5 | `backend/app/api/v1/__init__.py` | Đăng ký `admin_router` vào `api_router` (`/api/v1/admin`). Không sửa router hiện có. |
| 6 | `backend/app/models/enums.py` | Thêm mapping `"Farm Owner": UserRole.farmer.value` vào `_DB_TO_API_ROLE` để toàn bộ stack nhận diện Farm Owner là farmer. |
| 7 | `backend/app/schemas/user_crud.py` | Thêm field `db_role: str | None` vào `UserOut` để giữ nguyên giá trị role gốc trong DB. |
| 8 | `backend/app/services/user_service.py` | `serialize_user` bổ sung `db_role` (giá trị role DB) bên cạnh `role` (giá trị API). |

> Ghi chú: các thay đổi trong `database/db_schema.py`, `database/etl_pipeline.py`,
> `database/indexes.py`, `database/seed_farm_owners.py` thuộc Phase 4 Database
> (Farm Owner support, commit `88429e4`) — **không thuộc** phạm vi Release 1.3, không bị
> sửa bởi feature này.

---

## Giải thích chức năng từng file

### 1. `backend/app/api/v1/admin.py`

- `admin_only = RoleChecker([UserRole.enterprise_admin.value])` — chỉ Admin được truy cập (tái sử dụng `RoleChecker` hiện có, không đổi Authorization).
- `get_farmer_overview` nhận `user_id` từ path, lấy `db` qua `Depends(get_database)` (DI), gọi `FarmerOverviewService(db).get_overview(user_id)`.
- HTTP Status: `200` (thành công), `401` (thiếu token), `403` (không phải Admin), `404` (user không tồn tại hoặc không phải Farm Owner).

### 2. `backend/app/services/farmer_overview_service.py`

- `get_overview(user_id)`:
  1. Validate + tải user từ `users`; nếu `role != "Farm Owner"` → `404 User is not a Farm Owner`.
  2. Lấy danh sách farm theo `owner_user_id` (sort theo `farm_code`).
  3. Aggregate song song (`asyncio.gather`): zones/trees count, inspection stats, detection stats, alert counts, NCR status/direction.
  4. Lấy tên công ty của farm; lấy 4 nhóm event (inspection / detection / alert / neighbor), mỗi nhóm tối đa 10.
  5. Merge timeline bằng `_merge_activities` — sort giảm dần theo thời gian, tie-break inspection → detection → alert → neighbor, cắt tối đa **20**.
  6. Mapping response phẳng theo Solution Design: `profile`, `farm`, `inspection`, `alerts`, `neighbor`, `activities`.
- `_get_inspection_stats`: total + `last` = `MAX(inspection_date)` (không dùng ETL `created_at`).
- `_get_detection_stats`: lookup `detection_results → inspections`, lọc theo farm, đếm `healthy` (`prediction == "Khỏe mạnh"`), `diseased = total - healthy`; `detection_rate = diseased / trees * 100`.
- `_get_alert_counts`: group theo `priority`, map `Cao → critical`, `Trung bình → warning`, `Thấp → normal`, giữ cả `raw_priority`.
- `_get_inspection_events` / `_get_detection_events` / `_get_alert_events`: lookup tree_code + thuộc tính mô tả, dùng mốc thời gian nghiệp vụ.
- `_get_ncr_events`: dùng `NeighborContactRequestRepository.list_latest`; `_build_ncr_activity` chọn event type theo hướng (source/target) + trạng thái; timestamp ưu tiên `shared_at → updated_at → created_at`.
- Toàn bộ Business Logic nằm trong Service. Không query MongoDB ngoài Repository (ngoại trừ aggregation cross-collection đặc thù của feature, theo đúng Solution Design đã duyệt).

### 3. `backend/app/schemas/farmer_overview.py`

- Các DTO dùng Pydantic `BaseModel`, đúng cấu trúc response:

```json
{
  "profile": {},
  "farm": {},
  "inspection": {},
  "alerts": {},
  "neighbor": {},
  "activities": []
}
```

### 4. `backend/app/repositories/neighbor_contact_request_repository.py`

- Kế thừa `BaseRepository` (collection `neighbor_contact_requests`).
- `count_by_status(user_id)` — group theo `status` cho mọi request liên quan user.
- `count_by_direction(user_id)` — `(sent = source_user_id, received = target_user_id)`.
- `list_latest(user_id, limit)` — sort `updated_at` giảm dần, enrichment `source_farm_name`/`target_farm_name` qua lookup `farms`.
- Repository **chỉ truy vấn dữ liệu**, không Business Logic.

---

## Xác nhận tuân thủ yêu cầu chung

| Yêu cầu | Xác nhận |
|---|---|
| Không Mock Data | ✅ Toàn bộ dữ liệu lấy trực tiếp từ MongoDB qua API. Không có bất kỳ dữ liệu giả trong code. |
| Không Hardcode | ✅ Không hardcode dữ liệu hiển thị. Chỉ có hằng số domain mapping theo Solution Design (`Farm Owner`, `Khỏe mạnh`, `Cao/Trung bình/Thấp`, mốc thời gian nghiệp vụ). |
| Không thay đổi Database / ETL / Collection / Validation | ✅ Không sửa schema, không thêm collection, không sửa ETL. |
| Không thay đổi Authentication / Authorization | ✅ Tái sử dụng token + `RoleChecker` hiện có. |
| Không ảnh hưởng Dashboard / Users / Farms / Inspections / Alerts | ✅ Endpoint mới tách riêng ở `/admin`; không sửa endpoint hiện có (chỉ thêm field `db_role` thông tin thuần phản chiếu). |
| Read-only | ✅ Đã kiểm chứng snapshot DB trước/sau khi gọi endpoint — không thay đổi. |
| Repository không chứa Business Logic | ✅ Chỉ truy vấn. |
| Business Logic trong Service | ✅ Toàn bộ aggregation/timeline trong `FarmerOverviewService`. |
| DI | ✅ `Depends(get_database)`, `Depends(RoleChecker)`, service khởi tạo qua DI. |

---

## Kết quả kiểm tra (đã thực hiện)

- Import app + route đăng ký: OK.
- HTTP matrix: 401 (no token) / 200 (admin → farmer) / 404 (bad id, non-Farm Owner) / 403 (non-admin): PASS.
- Cross-check toàn bộ 10 Farm Owner so với query trực tiếp trên DB (profile, farm, inspection, detection, alerts, neighbor, activities ≤ 20, sắp xếp giảm dần): **0 mismatch**.
- Read-only: snapshot 9 collection trước/sau giống hệt.

---

# Release 1.3.1 — KPI Aggregation Fix (Backend)

## Tóm tắt

Sửa 4 module KPI (Users, Trees, Inspections, Disease History) để số liệu khớp với MongoDB.
Root cause: KPI trước đây được tính phía frontend chỉ trên **trang hiện tại** của list data,
so sánh status tiếng Anh với giá trị **tiếng Việt** trong DB, và Users đếm theo `role` chuẩn
hóa (không bao giờ bằng `Admin`/`Inspector`/`Company Manager`/`Farm Manager`).

Giải pháp: backend tính aggregation trên toàn bộ dữ liệu và gắn khóa `stats` vào **object
`data` sẵn có** của list endpoint. Nhờ `success_response()` trả `JSONResponse` (không qua
`response_model`), khóa phụ đi qua nguyên vẹn — **không đổi DTO, cấu trúc response, route,
DB, collection, validator**. Các field `items`, `total`, `page`, `total_pages` giữ nguyên.

## Root cause chi tiết

1. **Tính trên current page**: frontend đếm KPI từ các item đang tải (~20 dòng/trang) thay vì toàn bộ dữ liệu.
2. **Status là tiếng Việt trong DB**: ETL lưu `Khỏe mạnh` / `Bị bệnh` / `Đang theo dõi`
   (map `HEALTH_STATUS_EN_TO_VI`, `TREE_STATUS_EN_TO_VI`, `ACTION_EN_TO_VI` trong
   `database/etl_pipeline.py`). Frontend so với `Healthy`/`Monitoring`/`Diseased`/`Treatment Applied` → không khớp.
3. **Users đếm sai field**: `role` API là `enterprise_admin`/`field_technician`/`farm_manager`/`farmer`;
   `Admin`/`Inspector`/`Company Manager`/`Farm Manager` chỉ tồn tại ở `db_role` (giá trị gốc DB).

## Danh sách file sửa đổi

### Repository (thêm `get_kpi_stats()`)

| File | Nội dung |
|---|---|
| `backend/app/repositories/user_repository.py` | `total_users`, `total_admins` (`role == "Admin"`), `total_inspectors` (`role == "Inspector"`), `total_managers` (`role in ["Company Manager", "Farm Manager"]`). |
| `backend/app/repositories/tree_repository.py` | `total_trees`, `healthy_trees` (`Khỏe mạnh`/`Healthy`), `monitoring_trees` (`Đang theo dõi`/`Monitoring`), `diseased_trees` (`Bị bệnh`/`Diseased`). |
| `backend/app/repositories/inspection_repository.py` | `total_inspections`, `healthy_inspections` (`Khỏe mạnh`/`Healthy`), `today_inspections` (khoảng UTC ngày hiện tại qua `datetime.combine`). |
| `backend/app/repositories/disease_history_repository.py` | `total_records`, `processed_records` (`Đã điều trị`/`Treatment Applied`), `unprocessed_records = total - processed`, `unique_diseases` (`distinct("disease_name")`). |

### Service (delegate `get_kpi_stats()`)

| File | Nội dung |
|---|---|
| `backend/app/services/user_service.py` | Delegate repo; `serialize_user` đã có `db_role` (giữ nguyên). |
| `backend/app/services/tree_service.py` | Delegate repo. |
| `backend/app/services/inspection_service.py` | Delegate repo + tính `pass_rate = round(healthy / total * 100)`. |
| `backend/app/services/disease_history_service.py` | Delegate repo. |

### API router (gắn `stats` vào `data` của list endpoint)

| File | Thay đổi |
|---|---|
| `backend/app/api/v1/users.py` | `data["stats"] = await user_service.get_kpi_stats()`. |
| `backend/app/api/v1/trees.py` | `data["stats"] = await tree_service.get_kpi_stats()`. |
| `backend/app/api/v1/inspections.py` | `data["stats"] = await inspection_service.get_kpi_stats()`. |
| `backend/app/api/v1/disease_history.py` | `data["stats"] = await disease_history_service.get_kpi_stats()`. |

> Không sửa DTO / schema response. `stats` là khóa cộng thêm trong `data`, không nằm trong Pydantic model.

## KPI → nguồn aggregation (MongoDB)

| KPI | Nguồn | Giá trị xác thực |
|---|---|---|
| Users total / admins / inspectors / managers | `users.role` (raw) | 61 / 13 / 7 / 18 |
| Trees total / healthy / monitoring / diseased | `trees.status` (VI + EN) | 6000 / 2006 / 2058 / 1936 |
| Inspections total / healthy / today / pass_rate | `inspections.health_status`, `inspection_date` | 10000 / 5657 / 0 / 57 |
| Disease history total / processed / unprocessed / unique | `disease_history.action`, `disease_name` | 2136 / 2136 / 0 / 14 |

## Kết quả kiểm tra (đã thực hiện)

- `python -m py_compile` toàn bộ file sửa đổi: OK. Server uvicorn `--reload` tự nhận thay đổi.
- Gọi 4 list endpoint qua API, đối chiếu `data.stats` với query trực tiếp MongoDB: **khớp chính xác** (bảng trên).
- `today_inspections = 0` là đúng: dữ liệu `inspection_date` là nửa đêm (midnight) trong quá khứ, không thuộc ngày hiện tại.
- Regression: chạy `pytest` với thay đổi và trên baseline (`git stash`) cho cùng tập failure — **0 lỗi mới**.
  Các `WriteError` còn lại là do fixture test chèn `status: "Healthy"` vào collection có `$jsonSchema`
  validator yêu cầu enum tiếng Việt — sẵn có từ trước, ngoài phạm vi Release 1.3.1.
- `test_users_crud.py`: 5/5 PASS (create/list/get/update/delete).
- Không đổi API structure / DTO / route / DB → không ảnh hưởng Dashboard, CRUD, pagination, search/filter, detail, Farmer Activity Overview.

---

# Release 1.3.2 — Responsive UI Optimization (Phase A: Layout Foundation)

## Backend Implementation Report — No Changes

| Phạm vi | Thay đổi |
|---|---|
| Backend | ✅ **Không thay đổi** |
| Database | ✅ Không thay đổi |
| MongoDB | ✅ Không thay đổi |
| API | ✅ Không thay đổi |
| DTO | ✅ Không thay đổi |
| Repository / Service | ✅ Không thay đổi |
| Aggregation / Business Logic | ✅ Không thay đổi |
| Authentication / Authorization | ✅ Không thay đổi |
| Routes | ✅ Không thay đổi |

Phase A (Layout Foundation) của Release 1.3.2 hoàn toàn là **Frontend-only**:
toàn bộ thay đổi nằm trong `frontend/src/**` (JSX/Tailwind) + `tailwind.config.js`.
Không có bất kỳ file backend/database nào bị sửa trong Phase A.

---

# Release 1.3.2 — Responsive UI Optimization (Phase B: Shared Components)

## Backend Implementation Report — No Changes

| Phạm vi | Thay đổi |
|---|---|
| Backend | ✅ **Không thay đổi** |
| Database | ✅ Không thay đổi |
| MongoDB | ✅ Không thay đổi |
| API | ✅ Không thay đổi |
| DTO | ✅ Không thay đổi |
| Repository / Service | ✅ Không thay đổi |
| Aggregation / Business Logic | ✅ Không thay đổi |
| Authentication / Authorization | ✅ Không thay đổi |
| Routes | ✅ Không thay đổi |

Phase B (Shared Components) của Release 1.3.2 hoàn toàn là **Frontend-only**:
toàn bộ thay đổi nằm trong `frontend/src/components/common/**` (JSX/Tailwind).
Không có bất kỳ file backend/database nào bị sửa trong Phase B.

---

# Release 1.3.2 — Responsive UI Optimization (Phase C: CRUD Pages)

## Backend Implementation Report — No Changes

| Phạm vi | Thay đổi |
|---|---|
| Backend | ✅ **Không thay đổi** |
| Database | ✅ Không thay đổi |
| MongoDB | ✅ Không thay đổi |
| API | ✅ Không thay đổi |
| DTO | ✅ Không thay đổi |
| Repository / Service | ✅ Không thay đổi |
| Aggregation / Business Logic | ✅ Không thay đổi |
| Authentication / Authorization | ✅ Không thay đổi |
| Routes | ✅ Không thay đổi |

Phase C (CRUD Pages) của Release 1.3.2 hoàn toàn là **Frontend-only**:
thay đổi duy nhất nằm trong `frontend/src/pages/users/FarmerOverview.tsx` (class JSX/Tailwind).
Không có bất kỳ file backend/database nào bị sửa trong Phase C.

---

# Release 1.3.2 — Responsive UI Optimization (Phase D: Dashboard)

## Backend Implementation Report — No Changes

| Phạm vi | Thay đổi |
|---|---|
| Backend | ✅ **Không thay đổi** |
| Database | ✅ Không thay đổi |
| MongoDB | ✅ Không thay đổi |
| API | ✅ Không thay đổi |
| DTO | ✅ Không thay đổi |
| Repository / Service | ✅ Không thay đổi |
| Aggregation / Business Logic | ✅ Không thay đổi |
| Authentication / Authorization | ✅ Không thay đổi |
| Routes | ✅ Không thay đổi |

Phase D (Dashboard) của Release 1.3.2 hoàn toàn là **Frontend-only**:
toàn bộ thay đổi nằm trong `frontend/src/components/dashboard/**` và
`frontend/src/pages/dashboard/**` (class JSX/Tailwind — grid/flex/height/overflow + typography scale
của DashboardHeader). Không có bất kỳ file backend/database nào bị sửa trong Phase D.

---

# Release 1.3.2 — Responsive UI Optimization (Phase E: Authentication + Final Polish)

## Backend Implementation Report — No Changes

| Phạm vi | Thay đổi |
|---|---|
| Backend | ✅ **Không thay đổi** |
| Database | ✅ Không thay đổi |
| MongoDB | ✅ Không thay đổi |
| Collection / Validation / ETL | ✅ Không thay đổi |
| API | ✅ Không thay đổi |
| DTO | ✅ Không thay đổi |
| Repository / Service / Dependency Injection | ✅ Không thay đổi |
| Authentication Logic / Authorization Logic | ✅ Không thay đổi |
| Existing APIs | ✅ Không thay đổi |
| Routes | ✅ Không thay đổi |

Phase E (Authentication + Final Polish) của Release 1.3.2 hoàn toàn là **Frontend-only**:
thay đổi duy nhất nằm trong `frontend/src/pages/auth/Login.tsx` (class JSX/Tailwind —
padding mobile + `flex-wrap`). Không có bất kỳ file backend/database nào bị sửa trong Phase E.

---

# Release 1.3.2 — Heatmap Bug Fix (STEP 4D.1)

## Backend Implementation Report — No Changes

| Phạm vi | Thay đổi |
|---|---|
| Backend | ✅ **Không thay đổi** |
| Database | ✅ Không thay đổi |
| MongoDB | ✅ Không thay đổi |
| Collection / Validation / ETL | ✅ Không thay đổi |
| API | ✅ Không thay đổi |
| DTO | ✅ Không thay đổi |
| Repository / Service / Dependency Injection | ✅ Không thay đổi |
| Authentication Logic / Authorization Logic | ✅ Không thay đổi |
| Existing APIs | ✅ Không thay đổi |
| Routes | ✅ Không thay đổi |

STEP 4D.1 (Heatmap Bug Fix) hoàn toàn là **Frontend-only**: thay đổi duy nhất nằm trong
`frontend/src/components/dashboard/HeatmapCard.tsx` (className của title/header row —
`flex-wrap` + `xl:flex-nowrap`). Không có bất kỳ file backend/database nào bị sửa trong bug fix này.





