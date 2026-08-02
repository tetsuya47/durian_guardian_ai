# AUDIT_REPORT

**Project:** Durian Guardian AI (DGA)
**Release:** 1.3.2 — STEP 1 Audit (trước khi thiết kế/triển khai tính năng mới)
**Date:** 2026-08-01
**Method:** 100% read-only — không Coding, không đổi Database/Backend/Frontend/API, không commit
**Note:** Module mới chưa được xác định cụ thể; báo cáo đánh giá khả năng tái sử dụng + mức độ sẵn sàng cho bất kỳ module mới nào trong kiến trúc hiện tại.

---

## 1. Executive Summary

Hệ thống Durian Guardian AI là một nền tảng quản lý vườn sầu riêng theo kiến trúc **monorepo
phân lớp chuẩn**: `MongoDB → Repository → Service → DTO → API (FastAPI) → Frontend Service →
React Component → UI`, gồm 3 nhánh chính: `backend/` (FastAPI + Motor, async), `frontend/`
(React 19 + Vite + TS + Tailwind), `database/` (ETL + schema + indexes + seed).

**Trạng thái dữ liệu hiện tại (quan trọng):** Database `durian_guardian_ai` đã được **khôi
phục đầy đủ** về Enterprise Dataset chuẩn (đo trực tiếp, read-only):

| Collection | Count | Collection | Count |
|---|---|---|---|
| companies | 10 | inspections | 10,000 |
| farms | 10 | detection_results | 10,000 |
| zones | 100 | disease_history | 2,136 |
| trees | 6,000 | alerts | 875 |
| users | 61 | seasons | 20 |
| diseases | 15 | harvests | 20 |
| neighbor_contact_requests | 26 | farm_targets | 20 |
| | | farm_performance | 20 |

Toàn bộ 15 collection có `$jsonSchema` validator (`strict/error`), toàn bộ index theo
`database/indexes.py` đã được tạo. **Dữ liệu đủ cho module mới phát triển** — không cần seed thêm.

**Kiến trúc đã sẵn sàng để mở rộng:** backend có bộ khung phân lớp đầy đủ (BaseRepository,
serialize helpers, `success_response`, `RoleChecker`, DI); frontend có 14 shared components
(DataTable, DrawerForm, RecordDetailDrawer, StatCard, Pagination…) và bộ service/type đồng bộ.
Một module mới điển hình chỉ cần: 1 repository + 1 service + 1 schema + 1 router (backend) và
1 page + 1 route + 1 service (frontend) — không phải sửa tầng lõi.

**Những lưu ý bắt buộc trước khi thiết kế:**
1. **Rủi ro cao nhất:** test suite (`backend/tests/conftest.py`) vẫn `delete_many({})` trên
   **database production** — **KHÔNG được chạy `pytest`** cho tới khi có cơ chế cô lập test DB.
2. AI runtime hiện là **mock** (detection/chat); nếu module mới liên quan AI, cần xác nhận phạm vi.
3. Có các lỗi tiềm ẩn sẵn có (authorization theo ownership chưa có, dữ liệu integrity trong ETL,
   frontend mockData ở một số trang) — cần định rõ module mới có chạm tới hay không.

**Kết luận:** Hệ thống **sẵn sàng cho STEP 2 (thiết kế)**. Kết quả audit: **PASS WITH RECOMMENDATIONS**.

---

## 2. Database Analysis

### 2.1 Collection Analysis

15 collection, tất cả đều **liên quan** đến domain (không có collection thừa). Nhóm chính:

| Nhóm | Collection |
|---|---|
| Tổ chức | `companies`, `farms`, `zones` |
| Cây trồng | `trees` |
| Nhân sự | `users` |
| Kiểm tra & AI | `inspections`, `detection_results`, `diseases`, `disease_history` |
| Vận hành | `alerts`, `seasons`, `harvests`, `farm_targets`, `farm_performance` |
| Xã hội hóa | `neighbor_contact_requests` |

Mỗi collection có mô tả, field bắt buộc, tham chiếu rõ trong `database/db_schema.py`
(`Collections` registry, dòng 15–51; validators dòng 109–484).

### 2.2 Relationship Diagram

Mọi tham chiếu đều là **logical reference** (MongoDB không ép ràng buộc):

```
companies
   └── farms (company_id; owner_user_id → users; manager_user_id → users)
          └── zones (farm_id)
                └── trees (farm_id, zone_id)
                       ├── inspections (tree_id, farm_id, zone_id, disease_id → diseases)
                       │      └── detection_results (inspection_id, tree_id, farm_id, company_id)
                       ├── disease_history (tree_id, farm_id, company_id,
                       │                     detection_result_id, detected_by_user_id → users)
                       └── alerts (farm_id, tree_id, company_id, inspection_id,
                                   detection_result_id, disease_history_id, disease_id,
                                   acknowledged_by → users)
          └── seasons (farm_id) ──► harvests / farm_targets / farm_performance (season_id)
users ◄── neighbor_contact_requests (source_farm_id, target_farm_id,
                                    source_user_id, target_user_id,
                                    inspection_id, detection_result_id)
```

### 2.3 Validator Analysis

Tất cả validator: `bsonType: object`, `validationLevel: strict`, `validationAction: error`,
không có `additionalProperties: false` (field phụ được chấp nhận).

**Enum được ép bởi validator (chú ý ngôn ngữ giá trị):**

| Collection.Field | Enum |
|---|---|
| `trees.status` | `Khỏe mạnh`, `Bị bệnh`, `Đang theo dõi` (tiếng Việt) |
| `inspections.health_status` | `Khỏe mạnh`, `Bị bệnh`, `Đang theo dõi` (tiếng Việt) |
| `users.role` | `Admin`, `Company Manager`, `Farm Manager`, `Farm Owner`, `Inspector`, `Technician` (tiếng Anh) |
| `neighbor_contact_requests.status` | `pending`, `waiting_target_consent`, `waiting_source_consent`, `contact_shared`, `rejected`, `cancelled` (tiếng Anh) |

**Field dạng chuỗi tự do nhưng dữ liệu lưu bằng tiếng Việt:**
`disease_history.action` (Đã điều trị/Đã lên lịch điều trị/Theo dõi/Đã phục hồi),
`alerts.priority` (Cao/Trung bình/Thấp/Rất cao), `alerts.alert_type`,
`inspections.predicted_disease`, `detection_results.prediction`, `diseases.name`,
`farm_performance.overall_status`, `seasons.status`.

> ⚠️ Bất kỳ module mới nào viết/đọc status đều phải dùng **giá trị tiếng Việt** cho
> trees/inspections và **giá trị tiếng Anh** cho users.role và NCR.status — giống KPI fix 1.3.1.

### 2.4 Index Analysis (đo trực tiếp — đã được tạo đầy đủ)

**Unique:** `companies.company_name`, `companies.company_code`, `farms.farm_code`,
`users.user_code`, `users.email` (sparse), `diseases.code`, `neighbor_contact_requests.request_code`.

**Non-unique quan trọng:** farms (`company_id`, `owner_user_id`, `district`, `farm_name`);
zones (`farm_id+zone_name`); trees (`farm_id`, `zone_id`, `status`, `variety`);
inspections (`tree_id`, `inspection_date`(-1), `farm_id`, `health_status`,
`predicted_disease`, `confidence`); detection_results (`inspection_id`, `tree_id`, `farm_id`,
`company_id`, `prediction`, `created_at`(-1)); disease_history (`tree_id`, `farm_id`,
`company_id`, `disease`, `date`(-1), `action`); alerts (`created_at`(-1), `priority`,
`farm_id`, `tree_id`, `company_id`, `alert_type`, `status`, `is_read`); seasons/harvests/
farm_targets/farm_performance (`farm_id`, `season_id`, compound `farm_id+season_id`);
NCR (`source_farm_id`, `target_farm_id`, `source_user_id`, `target_user_id`, `status`, `created_at`(-1)).

### 2.5 Data Integrity

- ETL tự chạy khối **validation informational** (không làm fail pipeline) cho 11 đường tham chiếu:
  farms→companies, zones→farms, trees→farms/zones, inspections→trees/diseases,
  detection_results→inspections, disease_history→trees, alerts→farms/trees,
  seasons→farms, harvests→seasons, farm_targets→seasons, farm_performance→seasons, NCR→farms/users.
- **Khiếm khuyết sẵn có (không do bước này):**
  - `transform_inspections` map `disease_id` qua `DISEASE_NAME_TO_CODE` (10 mã); ~2,833/10,000
    inspections mang tên bệnh ngoài map (Phytophthora, Leaf Spot, Nutrient Deficiency…) bị gắn
    `disease_id` về disease "Khỏe mạnh" trong khi `predicted_disease` đúng tên tiếng Việt.
  - `detection_results.tree_id/farm_id/company_id` null trên dữ liệu ETL (chỉ có `inspection_id`).
  - `clean_doc` đổi `rainfall_mm` → `rainfall` khi load (bypass validator, ML dùng `rainfall`).
  - 50/61 users không có `password_hash` (không thể đăng nhập).
- ETL từ chối load khi collection đã có dữ liệu (phải `--drop-existing`), giúp tránh trùng lặp.

### 2.6 Database Reuse Analysis

- **Đủ dữ liệu cho module mới:** ✅ Toàn bộ 15 collection đã có dữ liệu chuẩn.
- **Không cần thay đổi DB** cho module mới thông thường (đọc/ghi theo schema hiện có).
- Chỉ khi module mới cần thực thể mới → thêm collection + validator + index qua
  `database/db_schema.py` + `database/indexes.py` (cần duyệt riêng).
- Nguồn dữ liệu tái tạo: `D:\data\DGA_Enterprise_Dataset.xlsx` (còn tồn tại); ETL deterministic
  (`random.seed(42)`).

---

## 3. Backend Analysis

Stack: FastAPI 0.115 + Motor 3.6 + Pydantic v2. Cấu trúc `backend/app/`:

```
app/
├── main.py                  # bootstrap, CORS, router mount, admin seed (KHÔNG sửa nếu không cần)
├── ai/service.py            # AIService (mock detection) + OllamaService (mock chat)
├── api/v1/                  # 18 routers (auth, users, farms, zones, trees, companies,
│                            #   inspections, detection_results, disease_history, diseases,
│                            #   alerts, notifications, dashboard, ai, history, chat, admin)
├── auth/service.py          # AuthService
├── core/                    # config, security (JWT+bcrypt), dependencies (RoleChecker...),
│                            #   exceptions, exception_handlers, logging, response
├── database/mongodb.py      # MongoDBManager singleton + get_database (KHÔNG sửa)
├── dashboard/service.py     # DashboardService (aggregation read-only)
├── models/enums.py          # UserRole + DB↔API role maps (single source of truth)
├── repositories/            # base.py + 17 repositories
├── schemas/                 # request/response DTO per module
├── services/                # service per module + serialize_* helpers
└── utils/
```

### 3.1 Repository Analysis

- **`BaseRepository`** (`base.py`): `create/get/list/update/delete` + `_serialize/_deserialize`
  (`_id`→`id`). **Tái sử dụng trực tiếp** cho entity mới.
- **Có sẵn các method aggregation dùng lại được:**
  - KPI: `UserRepository.get_kpi_stats`, `TreeRepository.get_kpi_stats`, `InspectionRepository.get_kpi_stats`,
    `DiseaseHistoryRepository.get_kpi_stats`, `CompanyRepository.get_company_stats`.
  - Enrichment (join) mẫu: `_build_enrichment_stages` trong Tree/Inspection/DiseaseHistory/
    DetectionResult/NeighborContactRequest (`$lookup` zones/farms/users).
  - NCR: `count_by_status`, `count_by_direction`, `list_latest`.
  - Dashboard: `TreeRepository.find_all_heatmap`, `count_by_farms`.
- **Lưu ý trùng lặp sẵn có:** `NotificationRepository` và `AlertRepository` cùng ghi collection
  `alerts`; `DiseaseRepository` và `DiseaseHistoryRepository` cùng `disease_history` — module mới
  nên chọn đúng repository theo collection để tránh nhầm lẫn.

### 3.2 Service Analysis

- Mỗi module 1 service (khởi tạo inline trong router handler, nhận `db` qua DI).
- `serialize_*` module-level: `serialize_user`, `serialize_alert`, `serialize_detection_result`,
  `serialize_disease`, `serialize_disease_history`, `serialize_inspection`.
- **Service đọc thuần (tái sử dụng/không đụng):** `DashboardService` (5 endpoint), `FarmerOverviewService`,
  `HistoryService`, `ChatService`, `AIService.check_image_quality`.
- **Service ghi:** toàn bộ CRUD services + `AuthService` + `AIService.detect_disease`
  (ghi `disease_history` + lưu file ảnh).
- `FarmerOverviewService` là mẫu aggregation read-only tốt nhất để copy cho module mới.

### 3.3 DTO Analysis

- Envelope chung: `SuccessResponse[T]`, `PaginatedData[T]`, `PaginatedResponse[T]`,
  `PaginatedWithTotalPagesResponse[T]` (`schemas/response_models.py`); `success_response`/
  `error_response` (`core/response.py`) tự chuyển `ObjectId`→`str`.
- Request/response model đầy đủ cho từng module (user/farm/zone/tree/company/alert/notification/
  inspection/detection_result/disease/disease_history/chat/dashboard/farmer_overview).
- **Bất nhất sẵn có:** `DiseaseHistoryOut` định nghĩa ở 2 file (`schemas/disease.py:21` và
  `schemas/disease_history.py:21`); một số raw dict trả qua `success_response` không khớp hoàn
  toàn `response_model` khai báo. Module mới nên khai báo DTO đúng chuẩn 1-1 với response.

### 3.4 API Analysis

Toàn bộ endpoint (`/api/v1`):

| Router | Endpoints | Auth |
|---|---|---|
| auth | register, login, refresh, me, profile, logout, change-password | public / auth |
| users | CRUD + KPI stats | role-all |
| farms | CRUD + list by owner | role-all |
| zones | CRUD + filter farm_id | role-all |
| trees | CRUD + KPI + digital-id | role-all |
| companies | CRUD + stats | role-all |
| inspections | CRUD + KPI | role-all |
| detection-results | CRUD | role-all |
| disease-history | CRUD + KPI | role-all |
| diseases | CRUD | role-all |
| alerts | CRUD | role-all |
| notifications | list/unread/get/create/mark-read/delete | role-all |
| dashboard | main, heatmap, widgets, farm-performance, farm/{id} | auth / role-all |
| ai | detect, image-quality | role-all |
| history | /history/{tree_id} | auth |
| chat | /chat | auth |
| admin | /admin/users/{user_id}/overview | admin-only |

- **Mẫu router CRUD chuẩn** (diseases.py / alerts.py) dùng lại được ngay.
- ⚠️ `/dashboard`, `/history`, `/chat` chỉ kiểm tra token (không RoleChecker).

### 3.5 Dependency Analysis (Backend)

- **Auth:** JWT HS256 (30 phút access / 7 ngày refresh), bcrypt; token mang `role` DB raw;
  `db_role_to_api`/`api_role_to_db` ở `models/enums.py` (single source of truth).
- **Authorization:** `RoleChecker([roles])` + `allow_all`; **chưa có ownership check**
  (mọi role hợp lệ đều đọc/sửa/xóa được tài nguyên bất kỳ).
- **DI:** `Depends(get_database)` (singleton), `Depends(RoleChecker)`, `PaginationDep`.
- **Tầng KHÔNG được sửa nếu không có phê duyệt:** `main.py`, `database/mongodb.py`,
  `core/security.py`, `core/dependencies.py`, `models/enums.py`, `core/config.py`,
  `api/v1/__init__.py`.

---

## 4. Frontend Analysis

Stack: React 19 + Vite + TypeScript + Tailwind + react-router v7 + axios (không dùng React Query
trong thực tế — các page tự fetch bằng useEffect).

### 4.1 Pages

| Page | Đường dẫn | Trạng thái |
|---|---|---|
| Login / Register | `/login`, `/register` | hoạt động |
| Dashboard | `/dashboard` | hoạt động (API + một số widget Mock) |
| Farm Dashboard | `/dashboard/farm/:farmId` | hoạt động |
| Companies / Farms / Zones / Trees | `/companies`, `/farms`, `/zones`, `/trees` | hoạt động |
| Users + Farmer Overview | `/users`, `/users/:user_id` | hoạt động (verified 95/95) |
| Inspections | `/inspections` | hoạt động |
| Detection Results | `/detection-results` | hoạt động (bị ẩn sidebar; page dùng mockData) |
| Disease History | `/disease-history` | hoạt động |
| Alerts | `/alerts` | hoạt động (page dùng mockData.ts) |
| Diseases | `/diseases` | hoạt động (bị ẩn sidebar) |
| Settings | `/settings` | local-only (localStorage) |

### 4.2 Components

- **Shared (tái sử dụng ngay):** `StatCard`, `DataTable`, `Pagination`, `Toolbar`, `PageHeader`,
  `StatusChip`, `SearchBar`, `FilterBar`, `EmptyState`, `LoadingState`, `ConfirmDialog`,
  `DrawerForm`, `RecordDetailDrawer`, `ChartCard` — 14 components trong `components/common/`,
  được 8+ trang CRUD dùng chung. **Mọi page mới nên dùng bộ này.**
- **Dashboard-specific (21):** `KPISection/KPICard`, `HeatmapGrid`, `SystemOverviewCard`,
  `AgronomistPanel`, `RealtimeInspectionCard`, `FarmPerformanceCard`, `Weather*`, `Shared/*`.
- **Layout:** `AppLayout`, `Sidebar`, `Header`, `Footer`.

### 4.3 Routing & Navigation

- Route tree trong `routes/index.tsx`: bọc `ProtectedRoute` + `AppLayout`; fallback `/login`.
- Sidebar hiển thị 9 mục (`/dashboard, /companies, /farms, /zones, /trees, /users,
  /inspections, /disease-history, /alerts`); ẩn `/detection-results` và `/diseases`
  (qua `HIDDEN_MENU_PATHS`, route vẫn tồn tại).
- **Module mới có page:** thêm route con + (nếu cần) mục sidebar — mẫu có sẵn.

### 4.4 Responsive Structure

- CRUD chuẩn: `flex flex-col h-full space-y-4` (Toolbar → KPI grid → DataTable → Pagination →
  DrawerForm → RecordDetailDrawer → ConfirmDialog).
- KPI grid: `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4`.
- Sidebar collapse (desktop compact) + mobile drawer; auth layout 2 cột (ẩn cột trái trên mobile).

### 4.5 Shared Components / Services / Types

- API layer: `api/axios.ts` (baseURL từ `VITE_API_BASE_URL`), `interceptors.ts` (thêm Bearer token,
  unwrap `{success,data,message}`, map `id`→`_id`, gắn `total/page/...` vào mảng paginated).
- `services/base.service.ts` (`get/getById/post/put/delete`) + 15 service module — **mẫu cho
  service mới**.
- `types/`: 13 file domain interface — module mới thêm type tương ứng.
- **State:** auth qua React Context + localStorage token; data qua state cục bộ + `useEffect`
  (có `initialLoadDone` ref guard); không dùng React Query/Cache.
- **Translation:** `utils/translate.ts` (12 VI dictionary) + `vi(map, value) || value`.

---

## 5. Architecture Analysis

### 5.1 Overall Architecture

Luồng chuẩn (mọi module hiện có đều tuân thủ):

```
MongoDB ──► Repository ──► Service ──► DTO/Schema ──► API (FastAPI) ──► JSON
                                                                          │
UI ◄── React Component ◄── page fetch/state ◄── Frontend Service ◄── axios (envelope unwrap)
```

### 5.2 Request Flow

`Router handler (api/v1) → Service (inline, DI db) → Repository (Motor) → MongoDB` →
trả về `success_response({success, message, data})`; frontend axios interceptor unwrap envelope,
map `id→_id`, gắn pagination meta; page render.

### 5.3 Data Flow & Aggregation Flow

- **Read:** list/get qua `BaseRepository` + enrichment `$lookup` (mẫu `_build_enrichment_stages`);
  KPI qua `get_kpi_stats` (count_documents/distinct); dashboard qua aggregation phức hợp
  (`DashboardService`).
- **Write:** create/update/delete qua `BaseRepository`; validation business ở service.
- **Join:** MongoDB `$lookup` aggregation (không có DB join vật lý); N+1 ở vài chỗ
  (companies stats hydration, ETL) — chấp nhận được ở quy mô hiện tại.

### 5.4 Vị trí module mới trong kiến trúc

Module mới đặt **trong khuôn mẫu có sẵn**: `repositories/<x>_repository.py` +
`services/<x>_service.py` + `schemas/<x>.py` + `api/v1/<x>.py` (đăng ký vào `api/v1/__init__.py`)
và `pages/<x>/<X>.tsx` + route + `services/<x>.service.ts` + `types/<x>.ts`.
Không yêu cầu thay đổi tầng lõi (main/mongodb/security/dependencies/enums/config).

---

## 6. Existing Feature Analysis

| Feature | Liên quan module mới? | Mức ảnh hưởng / nguy cơ Regression |
|---|---|---|
| Dashboard | Có (thường là nơi hiển thị KPI mới) | Trung bình — aggregation đọc thuần; chỉ đụng nếu thêm endpoint/widget |
| Companies / Farms / Zones / Trees | Có (dữ liệu nền) | Thấp — CRUD đứng riêng; chỉ đụng nếu mở rộng field |
| Users | Có (role/auth cho module mới) | Thấp — không đụng trừ khi đổi phân quyền |
| Inspections | Có (nguồn dữ liệu AI/kiểm tra) | Thấp |
| Detection Results | Có (kết quả AI) | Trung bình — page hiện ẩn + mockData; dữ liệu thiếu tree/farm/company |
| Disease History | Có (tiền sử bệnh) | Thấp |
| Alerts | Có thể (module cảnh báo) | Trung bình — page dùng mockData; alerts/notification cùng collection |
| Neighbor Contact Requests | Có thể (nếu module xã hội hóa) | Trung bình — chưa có CRUD/page riêng; chỉ repo + farmer overview |
| Farmer Overview | Có (mẫu aggregation) | Thấp — verified, không đụng trừ khi tái sử dụng pattern |
| AI (detect/agronomist/chat) | Tùy module | Cao nếu module cần AI thật — runtime hiện là **mock** |
| Settings | Không | Thấp |
| Detection-results / Diseases pages | Không (ẩn sidebar) | Thấp |

---

## 7. Scope Boundary

### In Scope
- Thiết kế + triển khai **module mới** theo Solution Design được duyệt (STEP 2+).
- Tái sử dụng: BaseRepository pattern, `get_kpi_stats`, enrichment `$lookup`, `success_response`,
  `RoleChecker`, `PaginationDep`, shared frontend components, base service, type pattern.
- Backend: thêm repository/service/schema/router mới. Frontend: thêm page/route/service/type mới.
- Database: **chỉ đọc** dữ liệu hiện có; chỉ thay đổi DB nếu Solution Design yêu cầu thực thể mới
  và được phê duyệt riêng.

### Out of Scope
- Sửa các lỗi sẵn có không thuộc module mới: authorization ownership, farm list_by_owner,
  zone sort, disease_id mis-mapping, 50 users không password, mockData frontend, AI mock.
- Thay đổi tầng lõi: `main.py`, `database/mongodb.py`, `core/security.py`, `core/dependencies.py`,
  `models/enums.py`, `core/config.py`, `api/v1/__init__.py` (trừ đăng ký router mới).
- Chạy ETL/Seed/backup lại nếu không thuộc phạm vi module.
- Chạy `pytest` trên database production (rủi ro wipe — xem mục 8).
- Commit/merge.

---

## 8. Risk Analysis

### High

| # | Rủi ro | Nguyên nhân |
|---|---|---|
| R1 | **Test suite xóa sạch database production** khi chạy `pytest` | `backend/tests/conftest.py:22-31` fixture autouse `setup_db` gọi `delete_many({})` trên mọi collection của `durian_guardian_ai` (không có test DB riêng, không guard tên DB) — đã gây reset thực tế trong Release 1.3.2 |
| R2 | **Rò rỉ dữ liệu ngang vai trò** | Không có per-resource ownership check; mọi role hợp lệ (`allow_all`) đọc/sửa/xóa được mọi tài nguyên; `FarmRepository.list_by_owner` không lọc theo owner |
| R3 | **KPI/analytics sai nếu gắn nhầm ngôn ngữ status** | Validator ép enum tiếng Việt (trees/inspections) nhưng một số code/frontend vẫn so giá trị tiếng Anh; DB chứa cả 2 dạng ở một vài field |

### Medium

| # | Rủi ro | Nguyên nhân |
|---|---|---|
| R4 | **AI runtime là mock** | `AIService._mock_detection` random, `OllamaService._mock_chat` hardcode; model 1–4 và RAG chưa được app nạp; chat frontend hiển thị placeholder |
| R5 | **Frontend hiển thị dữ liệu mock ở trang active** | `alerts/mockData.ts`, `detection-results/mockData.ts`, dashboard `MockWidgets.tsx` được dùng (mock "Release 2") |
| R6 | **Data integrity trong ETL** | ~2,833 inspections `disease_id` lệch (map 10 mã); detection_results thiếu tree/farm/company; 50/61 users không password |
| R7 | **KPI fallback chỉ tính trên current page** | Nếu server bỏ `stats`, các page KPI đếm trên items hiện tại → số liệu không phải toàn dataset |
| R8 | **Performance aggregation** | Farmer overview ~5–8s, N+1 ở companies stats; có thể tệ hơn với module mới đọc nhiều collection |

### Low

| # | Rủi ro | Nguyên nhân |
|---|---|---|
| R9 | **Trùng lặp abstraction** | NotificationRepository/AlertRepository cùng collection `alerts`; DiseaseRepository/DiseaseHistoryRepository cùng `disease_history`; `DiseaseHistoryOut` trùng ở 2 schema |
| R10 | **Tài liệu lệch code** | README database (10 collections, số cũ), backend README (endpoint risk/weather không tồn tại), doc "routes chưa có" đã có trong code |
| R11 | **Response model không khớp raw dict** | Một số handler trả `success_response` với dict không khớp `response_model` khai báo |

> Theo yêu cầu STEP 1: chỉ nêu rủi ro + nguyên nhân, **không** đưa cách sửa tại đây.

---

## 9. Final Recommendation

**Có thể tiếp tục STEP 2 (thiết kế) — PASS WITH RECOMMENDATIONS.**

Những vấn đề bắt buộc lưu ý trước khi thiết kế:

1. **Xác định rõ module mới** (thực thể, luồng nghiệp vụ, vai trò truy cập) — audit hiện mang tính
   tổng thể vì module chưa được chỉ định.
2. **KHÔNG chạy `pytest`** trên database production cho tới khi `conftest.py` được cô lập
   (test DB riêng + guard tên DB). Mọi bước test trong dự án tiếp theo phải tránh kích hoạt wipe.
3. **Tuân thủ khuôn mẫu phân lớp hiện có** — thêm mới repository/service/schema/router/page;
   không sửa tầng lõi; dùng `serialize_*`, `success_response`, shared components.
4. **Dùng đúng ngôn ngữ giá trị dữ liệu** (tiếng Việt cho trees/inspections status; tiếng Anh cho
   roles, NCR status) và ưu tiên server-side `stats` khi hiển thị KPI.
5. **Xác định phạm vi AI**: nếu module liên quan AI, quyết định dùng mock (hiện tại) hay tích hợp
   model thật — ảnh hưởng lớn tới thiết kế.
6. **Đánh giá lại quyền truy cập** của module mới trong bối cảnh chưa có ownership check (R2).
7. **Bất kỳ thay đổi DB nào** (collection/validator/index) phải có Solution Design riêng và duyệt.

---

## 10. Final Status

**PASS WITH RECOMMENDATIONS**

- Hệ thống đủ dữ liệu, kiến trúc phân lớp rõ ràng, bộ khung tái sử dụng đầy đủ → sẵn sàng thiết kế module mới.
- Điều kiện tiên quyết trước khi thực hiện: xác định module cụ thể + đảm bảo không chạy pytest
  trên production (R1) + chốt phạm vi AI (R4).
- Dừng tại đây theo yêu cầu STEP 1: không Coding, không chuyển sang STEP 2.
