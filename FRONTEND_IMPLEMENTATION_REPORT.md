# Frontend Implementation Report — Release 1.3
## Admin Farmer Activity Overview

---

## Project Information

| Field | Value |
|---|---|
| **Project** | Durian Guardian AI |
| **Release** | 1.3 — Admin Farmer Activity Overview (Phase 4) |
| **Date** | 2026-08-01 |
| **Author** | opencode |
| **Stack** | React 19 + Vite + TypeScript |
| **Status** | Implemented theo Solution Design đã APPROVED (STEP 3) |

---

## Executive Summary

Triển khai giao diện **Farmer Activity Overview** trong Users Module (không tạo module mới,
không đổi Sidebar, không ảnh hưởng Dashboard). Flow: Users → Farm Owner row action →
`/users/:user_id`.

Action **chỉ hiển thị với Farm Owner** (`db_role === "Farm Owner"`). Mọi dữ liệu lấy trực
tiếp từ MongoDB qua API `GET /admin/users/{user_id}/overview`. **Không Mock / Fake / Hardcode /
Random Data.**

---

## Danh sách file

### File tạo mới

| # | File | Chức năng |
|---|---|---|
| 1 | `frontend/src/pages/users/FarmerOverview.tsx` | Trang "Tổng quan hoạt động" hiển thị đầy đủ: Farmer Profile, Farm Overview, Inspection + AI Detection Overview, Alert Overview, Neighbor Contact, Recent Activities. |
| 2 | `frontend/src/services/farmerOverview.service.ts` | `FarmerOverviewService` — gọi `GET /admin/users/{user_id}/overview`, trả về `FarmerOverview`. |
| 3 | `frontend/src/types/farmerOverview.ts` | Interfaces tương ứng DTO backend: `FarmerProfile`, `FarmOverview`, `InspectionStats`, `DetectionStats`, `InspectionOverview`, `AlertOverview`, `NeighborOverview`, `ActivityItem`, `FarmerOverview`, `FarmerAddress`. Cấu trúc phẳng `{profile, farm, inspection, alerts, neighbor, activities}`. |

### File sửa đổi

| # | File | Chức năng thay đổi |
|---|---|---|
| 4 | `frontend/src/pages/users/Users.tsx` | Thêm action "Tổng quan hoạt động" (icon UserCog) trong cột Thao tác, **chỉ hiển thị với Farm Owner**. Không ảnh hưởng User CRUD (add/edit/delete/view giữ nguyên). |
| 5 | `frontend/src/routes/index.tsx` | Thêm route `/users/:user_id` trỏ tới `FarmerOverviewPage` (đúng Solution Design). |
| 6 | `frontend/src/types/user.ts` | Thêm field `db_role?: string` vào interface `User`. |
| 7 | `frontend/src/utils/translate.ts` | Thêm nhãn tiếng Việt: role `farmer` / `Farm Owner` / `enterprise_admin` / `field_technician` / `farm_manager`, `USER_STATUS_VI` (ACTIVE), `NCR_STATUS_VI` (6 trạng thái neighbor contact). |

---

## Giải thích chức năng từng file

### 1. `frontend/src/pages/users/FarmerOverview.tsx`

- Nhận `user_id` từ URL qua `useParams`; gọi `farmerOverviewService.getOverview(user_id)` trong `useEffect` (async `.then/.catch/.finally`, hỗ trợ retry + back).
- Các section theo đúng Solution Design:
  - **Farmer Profile** — avatar initials, họ tên, mã user, email/phone, địa chỉ, farm, công ty, trạng thái, ngày tạo.
  - **Farm Overview** — StatCard: Tổng vườn, Tổng ô, Tổng cây, Diện tích, Quận/huyện.
  - **Inspection Overview** — Số đợt kiểm tra, lần kiểm tra gần nhất, khối AI Detection (Khỏe mạnh / Có bệnh / Tỷ lệ phát hiện).
  - **Alert Overview** — Critical / Warning / Normal.
  - **Neighbor Contact** — Đã gửi / Đã nhận / Chờ xử lý / Chờ đồng ý / Đã chia sẻ liên hệ / Bị từ chối / Đã hủy.
  - **Recent Activities** — timeline merge inspection / detection / alert / neighbor, icon + màu theo `SOURCE_META`, giảm dần theo thời gian, hiển thị bằng `formatDateTime`.
- State: `loading` (LoadingState), `error` (thông báo + Thử lại + Quay lại danh sách).
- Không có dữ liệu giả — mọi số liệu render trực tiếp từ response API.

### 2. `frontend/src/services/farmerOverview.service.ts`

- Kế thừa `BaseService`; `getOverview(userId)` gọi `GET /admin/users/${userId}/overview`.
- Response interceptor (axios) tự unwrap envelope `{success, message, data}` → trả về đúng `FarmerOverview`.

### 3. `frontend/src/types/farmerOverview.ts`

- Interfaces khớp 1-1 với DTO backend (`FarmerOverviewDTO`), đảm bảo type-safe khi render.

### 4. `frontend/src/pages/users/Users.tsx`

- Thêm `useNavigate`, `isFarmOwner(row)` kiểm tra `db_role === "Farm Owner"` (giá trị role gốc DB) với fallback `role === "Farm Owner"`.
- `handleOverviewClick` điều hướng tới `/users/{id}`.
- Chỉ thêm UI, không đổi logic CRUD hiện có.

### 5. `frontend/src/routes/index.tsx`

- Thêm route con `users/:user_id` bên trong `AppLayout`. Không đổi route hiện có, không đổi Sidebar.

### 6. `frontend/src/types/user.ts`

- Bổ sung `db_role` — giá trị role nguyên bản trong DB (cần thiết để lọc chính xác Farm Owner mà không phụ thuộc bản dịch role API).

### 7. `frontend/src/utils/translate.ts`

- Bổ sung nhãn tiếng Việt cho role mới, `NCR_STATUS_VI` và `USER_STATUS_VI.ACTIVE` phục vụ render.

---

## Xác nhận tuân thủ yêu cầu chung

| Yêu cầu | Xác nhận |
|---|---|
| Không Mock Data | ✅ Không có dữ liệu giả — toàn bộ render từ API. |
| Không Fake Data / Random Data | ✅ Không. |
| Không Hardcode | ✅ Không hardcode giá trị dữ liệu; chỉ dùng nhãn dịch trong `translate.ts` và cấu hình UI. |
| Users Page: action chỉ với Farm Owner | ✅ `isFarmOwner(row)` gate action; User CRUD không đổi. |
| Routing đúng thiết kế | ✅ `/users`, `/users/:user_id`. |
| Farmer Overview hiển thị đầy đủ section | ✅ Profile / Farm / Inspection / Alert / Neighbor / Recent Activities. |
| API Service | ✅ `GET /admin/users/{user_id}/overview`. |
| Interfaces khớp DTO | ✅ `types/farmerOverview.ts`. |
| Không tạo module mới / không đổi Sidebar / không ảnh hưởng Dashboard | ✅. |
| Không ảnh hưởng Users / Farms / Inspections / Alerts | ✅ Chỉ thêm UI gated + route mới. |

---

## Kết quả kiểm tra (đã thực hiện)

- `tsc -b`: sạch đối với toàn bộ file thuộc feature (các lỗi TS còn lại nằm ở file không thuộc phạm vi).
- ESLint: sạch trên các file mới/sửa.
- `vite build`: thành công.
- Kiểm tra envelope unwrap qua axios interceptor: `getOverview` trả về đúng `FarmerOverview`.

---

# Release 1.3 — UI Refinement: Sidebar Simplification

## Tóm tắt

Đơn giản hóa Sidebar DGA Portal: ẩn hai module chưa cần thiết trong Release 1.3 —
**Kết quả nhận diện** và **Bệnh** — khỏi mục điều hướng. **Frontend only**:
không sửa Backend, Database, API; không xóa source code / component / route / page.

## Backend Implementation Report — No Changes

| Phạm vi | Thay đổi |
|---|---|
| Backend | ✅ Không thay đổi |
| Database | ✅ Không thay đổi |
| API | ✅ Không thay đổi |

## File sửa đổi

| # | File | Thay đổi |
|---|---|---|
| 1 | `frontend/src/components/layout/Sidebar.tsx` | Thêm hằng số `HIDDEN_MENU_PATHS` (`Set` chứa `/detection-results`, `/diseases`) và lọc các item này **ở mức render** khi dựng danh sách menu. |

## Sidebar items removed

Hai mục điều hướng đã bị ẩn khỏi Sidebar:

- **Kết quả nhận diện** (`/detection-results`)
- **Bệnh** (`/diseases`)

Sidebar sau khi hoàn thành còn đúng 9 mục:

| # | Mục điều hướng | Path |
|---|---|---|
| 1 | Bảng điều khiển | `/dashboard` |
| 2 | Công ty | `/companies` |
| 3 | Trang trại | `/farms` |
| 4 | Khu vực | `/zones` |
| 5 | Cây | `/trees` |
| 6 | Người dùng | `/users` |
| 7 | Kiểm tra | `/inspections` |
| 8 | Lịch sử phát sinh bệnh | `/disease-history` |
| 9 | Cảnh báo | `/alerts` |

## Existing routes preserved

- Route `detection-results` và `diseases` vẫn được đăng ký trong `frontend/src/routes/index.tsx`.
- Page/component `DetectionResults` và `Diseases` vẫn tồn tại nguyên vẹn.
- Service `detectionResult.service.ts` và `disease.service.ts` không đổi.
- Breadcrumb mapping trong `Header.tsx` cho hai path này vẫn giữ nguyên (deep-link không bị broken).

## Navigation verified / No broken navigation

- Các item còn lại giữ nguyên `path`, `icon`, `isActive` logic — không đổi hành vi điều hướng.
- Cách triển khai dùng **filter lúc render** nên không xóa dòng mã nào: toàn bộ định nghĩa menu vẫn nằm trong source, chỉ không hiển thị — đáp ứng yêu cầu "không xóa source code" và tái sử dụng trong Release sau.
- Kiểm tra `tsc -b` (không có lỗi mới trên `Sidebar.tsx`) và `eslint` (sạch) trên file đã sửa.

## No regression detected

- Chỉ đụng duy nhất `Sidebar.tsx` (tầng hiển thị); không ảnh hưởng Dashboard, Users, Farmer Activity Overview, Inspection, Alerts, History.
- Không đổi route, không đổi layout `AppLayout`, không đổi Header ngoài việc giữ nguyên breadcrumb.

---

# Release 1.3.1 — KPI Aggregation Fix (Frontend)

## Tóm tắt

Các KPI card trên 4 trang (Users, Trees, Inspections, Disease History) được chuyển sang
**dùng dữ liệu server** (`data.stats` do backend aggregation toàn bộ dữ liệu) thay vì tính từ
item của trang hiện tại. Frontend giữ fallback đếm theo page nếu `stats` không có.

Chỉ sửa **state + logic đọc dữ liệu** — không đổi layout, giao diện, route, service, type DTO.

## Root cause (frontend)

1. KPI đếm từ `items` đang tải (current page) → không phản ánh toàn bộ dữ liệu.
2. So status tiếng Anh (`Healthy`/`Monitoring`/`Diseased`/`Treatment Applied`) với giá trị
   **tiếng Việt** trong DB (`Khỏe mạnh`/`Đang theo dõi`/`Bị bệnh`/`Đã điều trị`) → đếm sai/0.
3. Users đếm theo `u.role` (`enterprise_admin`/...) thay vì `u.db_role`
   (`Admin`/`Inspector`/`Company Manager`/`Farm Manager`).

## File sửa đổi

| # | File | Thay đổi |
|---|---|---|
| 1 | `frontend/src/pages/users/Users.tsx` | Thêm `kpiStats` state; bắt từ `data.stats` trong mọi path fetch; đổi counting role sang `db_role`; ưu tiên `kpiStats`, fallback filter theo page (khớp EN + VI). |
| 2 | `frontend/src/pages/trees/Trees.tsx` | Thêm `kpiStats` state; bắt ở 2 path fetch; healthy/monitoring/diseased dùng `kpiStats`, fallback khớp cả `Khỏe mạnh`/`Healthy`, `Đang theo dõi`/`Monitoring`, `Bị bệnh`/`Diseased`. |
| 3 | `frontend/src/pages/inspections/Inspections.tsx` | Thêm `kpiStats` state; bắt ở 2 path fetch; `healthyCount` khớp `Healthy`/`Khỏe mạnh`; `todayInspections` + `passRate` dùng server, fallback theo page. |
| 4 | `frontend/src/pages/disease-history/DiseaseHistory.tsx` | Thêm `kpiStats` state; bắt ở 2 path fetch; processed/unprocessed/unique diseases dùng server, fallback theo page. |

> Tránh lỗi lint mới: thay `(data as any).stats` bằng generic có kiểu
> (`User[] & { total?: number; stats?: {...} }`, tương tự cho 3 trang còn lại).

## Hành vi fallback

- Khi `data.stats` tồn tại → dùng giá trị aggregation của server.
- Khi không có → đếm lại trên items hiện tại nhưng so status theo **cả tiếng Anh và tiếng Việt**,
  Users đếm theo `db_role` — fallback không còn cho kết quả sai 0 như trước.

## Xác nhận tuân thủ yêu cầu chung

| Yêu cầu | Xác nhận |
|---|---|
| Không Mock / Fake / Hardcode | ✅ KPI từ API, không giá trị cứng. |
| Không đổi UI / layout / route / service | ✅ Chỉ state + logic đọc dữ liệu. |
| Không đổi DTO / type hiện có | ✅ Không sửa `types/`; chỉ thêm kiểu inline cho generic. |
| Không ảnh hưởng Dashboard / các module khác | ✅. |

## Kết quả kiểm tra (đã thực hiện)

- `tsc -b`: **0 lỗi TS mới** (các lỗi còn lại là pre-existing ở Header/Login/Dashboard/Settings/Trees `detailStatsLoading`).
- ESLint trên 4 trang sửa đổi: **0 vi phạm mới** (các flag còn lại là pre-existing `no-explicit-any`).
- Đối chiếu API → UI: 4 tập KPI card hiển thị đúng giá trị `data.stats` (61 users / 6000 trees / 10000 inspections / 2136 records).

---

# Release 1.3.2 — Responsive UI Optimization (Phase A: Layout Foundation)

## Tóm tắt

Phase A triển khai **Layout Foundation** theo `SOLUTION_DESIGN.md` (đã APPROVED ở STEP 3):
chỉ sửa tầng layout toàn cục (App Layout, Sidebar, Header, Footer, breakpoint config, global
overflow) để thiết lập nền responsive nhất quán. **Không đụng** Shared Components (Phase B),
CRUD Pages (Phase C), Dashboard (Phase D), Authentication (Phase E), không tạo component/page
mới, không đổi route/navigation, không đổi Design System (màu/radius/shadow/font).

## 1. Files Modified

| # | File | Thay đổi |
|---|---|---|
| 1 | `frontend/src/layouts/AppLayout.tsx` | Content wrapper `p-6` → `px-4 sm:px-6 py-4 sm:py-6` (responsive padding). |
| 2 | `frontend/src/components/layout/Sidebar.tsx` | Mobile drawer width `280px` → `min(280px, 85vw)` — trên desktop giữ nguyên 280px, trên mobile không tràn viewport hẹp. |
| 3 | `frontend/src/components/layout/Header.tsx` | Header padding `px-6` → `px-4 lg:px-6`; breadcrumb ẩn < md (`hidden md:flex`); 3 dropdown (search `w-72`, notif `w-80`, profile `w-56`) thêm `max-w-[calc(100vw-2rem)]`. |
| 4 | `frontend/src/components/layout/Footer.tsx` | `px-6` → `px-4 sm:px-6`; thêm `flex-wrap gap-2` (không tràn trên màn hình hẹp). |
| 5 | `frontend/tailwind.config.js` | Thêm `screens` tường minh = giá trị mặc định Tailwind (`sm 640 / md 768 / lg 1024 / xl 1280 / 2xl 1536`) — chuẩn hóa breakpoint, không đổi hành vi. |
| 6 | `frontend/src/index.css` | Global overflow control: `html, body { overflow-x: hidden; }` (chống tràn ngang trang). |

> Chỉ sửa 6 file tầng layout/config. Không sửa bất kỳ page, component dùng chung, service, type, route nào.

## 2. Layout Foundation Changes

- **Content Container:** padding global `p-6` (24px cố định) → `px-4 sm:px-6 py-4 sm:py-6`:
  mobile 16px, từ `sm` (≥640px) trở lên vẫn 24px — **desktop không đổi gì**, giữ đúng 100% visual.
- **Container Width:** giữ nguyên — không hardcode max-width mới, không đổi `flex-1 min-w-0 overflow-hidden`.
- **Page Width:** giữ nguyên hành vi hiện có (page tự dãn theo content wrapper).
- **Height calculation:** giữ nguyên `h-screen` root + `main flex-1 overflow-y-auto` (không đổi scroll model).
- **Global margin/gap:** không đổi hệ gap hiện có (các page tự quản lý `space-y-4` của riêng mình — ngoài phạm vi Phase A).

## 3. Responsive Foundation

- Chỉ triển khai hành vi responsive **toàn cục** theo chuẩn Desktop → Laptop → Tablet → Mobile:
  - Desktop/Laptop (≥1024px): Sidebar static 280px, Header `px-6`, breadcrumb hiển thị — giữ nguyên.
  - Tablet (640–1023px): content padding `sm:px-6`, breadcrumb hiển thị (≥md), sidebar drawer qua backdrop.
  - Mobile (<640px): padding `px-4`, breadcrumb ẩn, sidebar drawer `min(280px,85vw)`, dropdown clamp `max-w-[calc(100vw-2rem)]`, footer wrap.
- **Không có page-specific responsive logic** — mọi thay đổi nằm ở tầng layout dùng chung.

## 4. Overflow Improvements

- **Horizontal page overflow:** thêm `overflow-x: hidden` cho `html, body` (global) — chống scroll ngang trang do phần tử dư.
- **Fixed-width layout overflow:** Sidebar drawer không còn ép `280px` trên viewport < 330px (dùng `min(280px, 85vw)`).
- **Header dropdown:** 3 dropdown neo phải không còn chạm/tràn mép trái màn hình hẹp (`max-w-[calc(100vw-2rem)]`).
- **Footer:** `flex-wrap` cho 3 đoạn chữ, không tràn khi viewport hẹp.
- Không thêm double scrollbar: giữ nguyên model `main overflow-y-auto` duy nhất; không thêm scroll ngang cấp trang.

## 5. Spacing Improvements

- Global content padding chuẩn hóa theo tầng: `16px` (mobile) / `24px` (≥sm) — giảm spacing trước khi giảm dimension (đúng RESPONSIVE PRINCIPLES).
- Footer padding đồng bộ `px-4 sm:px-6`.
- Không thay đổi visual hierarchy, không đổi màu/radius/shadow.

## 6. Breakpoint Improvements

- `tailwind.config.js` thêm `screens` tường minh (`sm 640 / md 768 / lg 1024 / xl 1280 / 2xl 1536`) = đúng mặc định Tailwind.
- Kết quả: breakpoint được chuẩn hóa, khai báo tập trung tại config, toàn bộ Admin Portal dùng chung một chuẩn; không breakpoint page-specific nào được thêm.

## 7. Regression Summary

- **Build:** `npm run build` (tsc -b + vite) với Phase A cho tập lỗi **giống hệt baseline** (8 lỗi TS
  pre-existing tại Header/Login/Dashboard/Settings/Trees — không thuộc file Phase A); **0 lỗi mới**.
  Đã kiểm chứng bằng build trên baseline (`git stash` trước khi Phase A) để đối chiếu.
- **Layout desktop:** mọi thay đổi chỉ có biến thể `sm:/lg:/md:` — desktop ≥1024px giữ nguyên 100% visual (padding 24px, sidebar 280px, breadcrumb hiển thị, dropdown width cũ).
- **Navigation:** không đổi route, không đổi Sidebar structure, không đổi Header structure/breadcrumb mapping — navigation hoạt động như cũ.
- **API calls:** không đụng `src/api/**`, `src/services/**`, `src/types/**` — API calls không đổi.
- **Business logic:** không đổi — Phase A chỉ JSX/Tailwind.
- **Không chạy `pytest`** (rủi ro wipe DB R1).

## 8. Final Status

**PASS**

- Phase A (Layout Foundation) hoàn thành theo đúng Scope.
- Tuân thủ UI LOCK STATUS + IMPLEMENTATION RULES (Frontend/Layout/Responsive only).
- Dừng tại đây theo yêu cầu STEP 4A: chờ review trước khi sang Phase B (Shared Components).

---

# Release 1.3.2 — Phase B

> **Phase B: Shared Components (Responsive Optimization).**
> Chỉ sửa `frontend/src/components/common/*` (component dùng chung). Không sửa page nghiệp vụ,
> không sửa Dashboard/CRUD page, không thêm component mới, không đổi DB/Backend/API/service/type/route.

## 1. Files Modified

| # | File | Thay đổi |
|---|---|---|
| 1 | `frontend/src/components/common/StatCard.tsx` | Compact card: bỏ fixed `height: 80px` → `min-h-[76px]` (card tự co giãn theo nội dung, không còn ép cứng). |
| 2 | `frontend/src/components/common/ChartCard.tsx` | Bỏ fixed `height: 320px` → `h-[280px] sm:h-[320px]` (mobile thấp hơn, desktop giữ nguyên 320px). |
| 3 | `frontend/src/components/common/Pagination.tsx` | Thêm mobile detection (`matchMedia < 640px`); mobile rút gọn cửa sổ nút từ ~5 → 3 số; container nút `flex-wrap` + `overflow-x-auto`. |
| 4 | `frontend/src/components/common/Toolbar.tsx` | Title bỏ `whitespace-nowrap` → `truncate` + `min-w-0` (title dài không tràn, cắt gọn với ellipsis). |
| 5 | `frontend/src/components/common/PageHeader.tsx` | Non-compact title `text-[32px]` → `text-[24px] md:text-[32px]`; thêm `min-w-0` cho khối text, `shrink-0` cho actions. |
| 6 | `frontend/src/components/common/DataTable.tsx` | Wrapper chỉ thêm `min-w-0` (tương thích flex); **giữ nguyên** `minWidth: 900px`, cột, thead sticky, cách trình bày bảng. |
| 7 | `frontend/src/components/common/RecordDetailDrawer.tsx` | Title `truncate` + `min-w-0`; label detail `w-[160px]` → `w-[120px] sm:w-[160px]`; value thêm `break-words min-w-0`. |
| 8 | `frontend/src/components/common/DrawerForm.tsx` | Title `truncate` + `min-w-0`; header thêm `gap-4` (ngăn chữ title chạm nút đóng). |

> Chỉ sửa 8 file shared components. Không sửa page, layout, config, service, type, route.

## 2. Shared Components Updated

- **Common Cards:** `StatCard` (compact), `ChartCard` — chuyển fixed height → `min-height`/biến thể breakpoint.
- **Common Tables Wrapper:** `DataTable` — chỉ cải thiện wrapper (`min-w-0`), không redesign bảng.
- **Page Header Components:** `PageHeader` — typography scale responsive + min-width cho khối text/actions.
- **Page Section / Statistic Cards:** `StatCard` compact (KPI dùng chung toàn CRUD) — height linh hoạt.
- **Shared States:** `LoadingState`, `EmptyState` — đã responsive từ trước (`w-full`, `max-w-lg mx-auto`), giữ nguyên, không redesign.
- **Dialogs/Drawers:** `DrawerForm`, `RecordDetailDrawer` — title không tràn trên mobile, detail value wrap.
- **Search/Filter/Toolbar:** `SearchBar`, `FilterBar`, `Toolbar` — đã responsive; Toolbar title thêm `truncate`.

## 3. Responsive Improvements

- **StatCard compact:** height linh hoạt `min-h-[76px]` — trên mobile vẫn vừa nội dung, không ép cứng 80px.
- **Pagination:** trên mobile (< 640px) chỉ hiển thị tối đa 3 số trang (giữ trang đầu/trang cuối + `…`),
  chuỗi nút `flex-wrap` — không tràn khỏi card trên màn hình hẹp; **desktop giữ nguyên logic nút cũ**.
- **PageHeader:** title 24px trên mobile, 32px từ `md` trở lên — đúng thang đo typography responsive, desktop không đổi.
- **Toolbar:** title dài dùng ellipsis thay vì giãn container.
- **Drawer detail:** label thu hẹp còn 120px trên mobile (desktop vẫn 160px), value `break-words` — dữ liệu dài không tràn ngang.

## 4. Typography Improvements

- **PageHeader** non-compact: `text-[32px]` cố định → `text-[24px] md:text-[32px]` (chỉ đổi size, không đổi font family/weight/màu).
- **Toolbar** title: `whitespace-nowrap` → `truncate` (cùng cỡ chữ `text-lg`, cùng weight/màu).
- **Không đổi** font family, font weight, color palette, letter-spacing của bất kỳ component nào.

## 5. Grid Improvements

- Không có grid page-specific mới (đúng UI LOCK — Forbidden: page-specific grids).
- Lưới dùng chung (KPI `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4`) nằm ở page (Phase C) — Phase B chỉ
  đảm bảo các phần tử bên trong component (icon/title/value của StatCard, header của ChartCard) không
  vỡ trên grid co giãn.
- `min-w-0` được thêm vào DataTable wrapper để lưới flex cha có thể co bảng mà không tràn.

## 6. Table Wrapper Improvements

- `DataTable` **chỉ** cải thiện wrapper: thêm `min-w-0` cho khối ngoài (compatibility với flex parent).
- Giữ nguyên: `minWidth: 900px` của bảng, cấu trúc cột/`colgroup`, `thead sticky`, `overflow-x-auto` trong,
  empty/skeleton rows, hover/transition — đúng thiết kế "không redesign bảng, không đổi min-width".

## 7. Regression Summary

- **Build:** `npm run build` (tsc -b + vite) với Phase B cho tập lỗi TS **giống hệt baseline**
  (8 lỗi pre-existing tại Header/Login/Dashboard/Settings×4/Trees — không thuộc file Phase B); **0 lỗi mới**.
- **ESLint:** sạch trên cả 8 file shared components đã sửa.
- **Desktop appearance:** mọi thay đổi có biến thể `sm:/md:` hoặc chỉ tác động trường hợp overflow;
  desktop ≥ 1024px giữ nguyên 100% visual (PageHeader 32px, drawer label 160px, Pagination đủ nút, ChartCard 320px).
- **Routes:** không đổi route/navigation.
- **API:** không đụng `src/api/**`, `src/services/**`, `src/types/**`.
- **Business logic:** không đổi — Phase B chỉ JSX/Tailwind + 1 hook responsive (Pagination).
- **Dashboard/Farmer Overview:** Dashboard dùng bộ component riêng (`components/dashboard/**` — Phase D),
  không đụng; FarmerOverview dùng `StatCard compact` + `PageHeader compact` — thay đổi an toàn (min-h, desktop giữ nguyên).
- **Design System:** không đổi màu/radius/shadow/font.
- **Không chạy `pytest`** (rủi ro wipe DB R1).

## 8. Known Issues

- `StatCard` compact desktop cao 76px thay vì 80px trước đây (đúng theo SOLUTION_DESIGN §10: `80px → min-h-[76px]`) — khác biệt 4px, không đổi nội dung.
- `ChartCard` hiện chưa được page nào sử dụng (được chuẩn bị sẵn cho Phase D Dashboard) — thay đổi height không ảnh hưởng màn hình hiện tại.
- Các lỗi TS pre-existing (Header `Alert.title`, Login unused `Check`, Dashboard unused `DashboardSkeleton`, Settings×4, Trees unused `detailStatsLoading`) vẫn còn — nằm ngoài phạm vi Phase B.

## 9. Final Status

**PASS**

- Phase B (Shared Components) hoàn thành theo đúng Scope.
- Tuân thủ UI LOCK STATUS + IMPLEMENTATION RULES (không component mới, không page-specific, không redesign DataTable, không đổi Design System).
- Dừng tại đây theo yêu cầu STEP 4B: chờ review trước khi sang Phase C (CRUD Pages).

---

# Release 1.3.2 — Phase C

> **Phase C: CRUD Pages (Responsive Optimization).**
> Chỉ sửa layout + hành vi responsive của các trang CRUD được phép. Không đụng Dashboard (Phase D),
> Auth (Phase E), Detection Results / Diseases (ngoài scope), không đổi Backend/API/service/type/route.

## 1. Files Modified

| # | File | Thay đổi |
|---|---|---|
| 1 | `frontend/src/pages/users/FarmerOverview.tsx` | Dòng hoạt động gần đây: thêm `min-w-0` cho khối title + `truncate min-w-0` cho `item.type`, `shrink-0` cho timestamp nowrap — chống tràn ngang trên màn hình rất hẹp. |

> Các trang list CRUD còn lại **không cần sửa**: đã đồng nhất + responsive từ trước (thừa hưởng
> Layout Foundation Phase A + Shared Components Phase B). Phase C xác nhận và chỉ sửa điểm lệch duy nhất.

## 2. CRUD Pages Updated

| Trang | Trạng thái |
|---|---|
| Companies | Verified — không cần sửa (container/Toolbar/KPI/Table/Pagination chuẩn) |
| Farms | Verified — không cần sửa (cell nowrap ngắn, nằm trong bảng scroll ngang) |
| Zones | Verified — không cần sửa |
| Trees | Verified — không cần sửa |
| Users | Verified — không cần sửa (3 filter wrap OK) |
| Inspections | Verified — không cần sửa |
| Disease History | Verified — không cần sửa |
| Alerts | Verified — không cần sửa |
| Farmer Overview | **Đã sửa** — activity item title `truncate` + `min-w-0` (chống tràn mobile) |

## 3. Responsive Improvements

- **Container:** tất cả 9 trang dùng `flex flex-col h-full space-y-4` đồng nhất; padding ngang đã do
  Layout Foundation xử lý (`px-4 sm:px-6 py-4 sm:py-6`) — không trang nào tự thêm padding gây trùng lặp.
- **KPI grid:** mọi trang list đều `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3` — đúng thiết kế
  Mobile 1 / Tablet 2 / Desktop 4. FarmerOverview: `grid-cols-2 lg:grid-cols-4` (detail view — giữ nguyên).
- **FarmerOverview (fix duy nhất):** title hoạt động không còn đẩy tràn khi timestamp `nowrap`;
  title cắt ellipsis, timestamp giữ nguyên vị trí phải.
- **Overflow:** không trang nào có fixed-width gây tràn ngang; toàn bộ bảng dùng `overflow-x-auto`
  của DataTable; `html, body { overflow-x: hidden }` (Phase A) chặn scroll ngang dư.

## 4. Toolbar Improvements

- Mọi trang dùng đúng shared `Toolbar` (Phase B đã responsive: `flex-col lg:flex-row`, search
  `w-full lg:w-auto`, title `truncate`, action `lg:ml-auto`).
- Bộ filter truyền qua `children` đều là `flex items-center gap-3` — nằm trong wrapper `flex flex-wrap`
  của Toolbar, tự xuống dòng trên mobile (Users có 3 filter vẫn wrap tốt).
- **Không trang nào có toolbar trùng lặp** (mỗi trang đúng 1 Toolbar).

## 5. Table Wrapper Verification

- Tất cả trang dùng `DataTable` chuẩn với `columns`/`rows`/`loading`/`emptyState` như cũ.
- Không đổi cột, không đổi sort, không đổi logic pagination, không đổi sticky, không đổi
  `minWidth: 900px`, không redesign bảng — đúng Forbidden list.
- Chỉ wrapper (Phase B) đã chịu trách nhiệm responsive; trang không bọc bảng trong container phụ nào khác.

## 6. Drawer Improvements

- Trang dùng đúng shared `DrawerForm` + `RecordDetailDrawer` (Phase B: title `truncate`, label
  `w-[120px] sm:w-[160px]`, value `break-words`) — trang không định nghĩa drawer riêng.
- FarmerOverview không có drawer; nội dung detail dạng section/card đã responsive từ trước
  (`grid-cols-1 md:grid-cols-2`, `flex-1 min-w-0`, `truncate`).

## 7. Regression Summary

- **Build:** `npm run build` (tsc -b + vite) với Phase C cho tập lỗi TS **giống hệt baseline**
  (8 lỗi pre-existing Header/Login/Dashboard/Settings×4/Trees) — **0 lỗi mới**.
- **ESLint:** sạch trên file đã sửa (`FarmerOverview.tsx`).
- **Desktop appearance:** fix chỉ tác động khi thiếu không gian ngang; desktop đủ rộng nên
  title/timestamp hiển thị đầy đủ như cũ.
- **Logic / API / Service / Route:** không đổi — Phase C chỉ thay đổi class JSX trong FarmerOverview.
- **Filter / Search / Pagination / Permissions:** không đổi.
- **Không chạy `pytest`** (rủi ro wipe DB R1).

## 8. Responsive Coverage

| Breakpoint | Trạng thái |
|---|---|
| Desktop ≥1024px | 9/9 trang giữ nguyên 100% visual |
| Tablet 640–1023px | KPI 2 cột, Toolbar xếp dọc + search full-width, bảng scroll ngang, Pagination wrap — không tràn |
| Mobile <640px | KPI 1 cột, filter wrap, Pagination 3 nút (Phase B), FarmerOverview activity title truncate — không tràn |

## 9. Known Issues

- Lỗi TS pre-existing (Header `Alert.title`, Login unused `Check`, Dashboard unused `DashboardSkeleton`,
  Settings×4, Trees unused `detailStatsLoading`) vẫn còn — ngoài phạm vi Phase C.
- Detection Results / Diseases nằm ngoài danh sách trang được phép của Phase C → không sửa (có thể xem
  xét ở Phase sau nếu được phép).
- Filter select trong Toolbar không set `max-width`: với option rất dài có thể rộng hơn viewport cực hẹp
  (edge case, không nằm trong design) — ghi nhận, không xử lý ở Phase C.

## 10. Final Status

**PASS**

- Phase C (CRUD Pages) hoàn thành theo đúng Scope: 8/9 trang verified (không cần sửa), FarmerOverview được fix 1 điểm tràn.
- Tuân thủ UI LOCK STATUS + IMPLEMENTATION RULES (không component mới, không đổi bảng, không đổi logic, Frontend-only).
- Dừng tại đây theo yêu cầu STEP 4C: chờ review trước khi sang Phase D (Dashboard).

---

# Release 1.3.2 — Phase D

> **Scope:** Dashboard Page + Dashboard Grid + KPI Cards + Dashboard Widgets + Charts + Heatmap +
> AI Agronomist + Recent Activities. Frontend-only. Desktop ≥1280px giữ nguyên 100% visual;
> laptop 1024–1279px chống tràn ngang; tablet xếp chồng tự nhiên; mobile 1 cột KPI, widget full-width.

## 1. Files Modified

| # | File | Thay đổi |
|---|---|---|
| 1 | `frontend/src/components/dashboard/KPISection.tsx` | KPI grid `grid-cols-5` → `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5` |
| 2 | `frontend/src/pages/dashboard/Dashboard.tsx` | Grid chính: rows `auto 520px 420px` chỉ áp dụng ở `lg` (arbitrary property `lg:[grid-template-rows:...]`); skeleton KPI grid responsive |
| 3 | `frontend/src/pages/dashboard/FarmDashboard.tsx` | KPI grid responsive; header `flex-wrap gap-2`; Heatmap card `height:480px` → `min-h-[480px]` + `lg:h-[480px]`; scroll container thêm `overflow-x-auto` |
| 4 | `frontend/src/components/dashboard/HeatmapCard.tsx` | Scroll container thêm `overflow-x-auto` (scroll ngang cho heatmap ≥417px trên mobile/tablet) |
| 5 | `frontend/src/components/dashboard/DashboardHeader.tsx` | Title `text-[24px] md:text-[32px]`, subtitle `text-[14px] md:text-[18px]` |

## 2. Dashboard Grid Improvements

- **Grid chính `Dashboard.tsx`:** hàng `auto 520px 420px` chỉ áp dụng `lg` (≥1024px) qua
  `lg:[grid-template-rows:auto_520px_420px]`; dưới `lg` bố cục là `flex-col` nên các widget tự xếp
  chồng full-width, không còn buộc chiều cao cứng gây tràn/cắt trên tablet/mobile.
- Desktop ≥1280px: grid giữ nguyên 3 cột + 2 hàng 520px/420px — không đổi visual.
- Laptop 1024–1279px: cột vẫn 3, chiều cao row không đổi — không tràn ngang.

## 3. KPI Card Improvements

- **Grid KPI chuẩn hóa theo tầng `1→2→3→5`:** `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5`.
  - Mobile <640px: **1 card/hàng** (đủ rộng cho value 48px + icon 56px, không tràn).
  - Tablet 640–1023px: 2 cột.
  - Laptop 1024–1279px: 3 cột (chống tràn).
  - Desktop ≥1280px: 5 cột — **giữ nguyên như cũ**.
- **Không đổi** giá trị / API / icon / màu / typography của KPICard (value vẫn `text-[48px]`).
- Áp dụng cho cả 2 dashboard: `KPISection` (Dashboard tổng) + `FarmDashboard` (trang farm),
  và skeleton KPI (`Dashboard.tsx`).

## 4. Widget Improvements

- `FarmDashboard` header: thêm `gap-2 flex-wrap` — không tràn khi thiếu không gian ngang trên mobile.
- `SystemOverviewCard` / `FarmPerformanceCard` / `RealtimeInspectionCard` / `TreeDistributionCard` /
  `WeatherForecastCard` / `WeatherIntelligenceCard` / `WeatherMetric`: **verified không cần sửa** —
  đã dùng flex-col + `min-w-0` + `truncate`, wrap tốt trên mọi breakpoint.
- `WeatherChart` (Recharts `ResponsiveContainer` width/height 100%): đã responsive, không đổi data/options.

## 5. Chart Improvements

- **Không đổi** bất kỳ chart nào: không đổi data, không đổi options, không đổi wrapper chart.
- `TreeDistributionCard` (PieChart radii 95/150), `WeatherChart` (BarChart): ResponsiveContainer
  tự co giãn theo chiều cao container (row 420px → `lg`; mobile `h-full` full-width) — không cần sửa.

## 6. Heatmap Improvements

- **`FarmDashboard` Heatmap card:** `height: 480px` cố định → `minHeight: 480px` + `lg:h-[480px]`
  (đúng thiết kế "Heatmap 480 → min-h responsive"): mobile/tablet card có thể cao hơn nếu cần,
  desktop giữ đúng 480px để căn hàng với card "Khu vực rủi ro cao".
- **Scroll ngang:** container heatmap (cả `HeatmapCard` và `FarmDashboard`) thêm `overflow-x-auto`
  — grid `repeat(20, 18px)` (~417px min) cuộn ngang trong cột full-width thay vì tràn/ẩn trên
  mobile/tablet.
- Không đổi map logic / markers / data / popup (`HeatmapGrid`, `HeatmapPopup` giữ nguyên).

## 7. AI Agronomist Improvements

- `AgronomistPanel`: verified — chỉ spacing/layout (`p-4`, `gap-3`, `max-w-[80%]` tin nhắn,
  `whitespace-pre-line`, input full-width `flex-1`) đã responsive trên mobile.
- **Không đổi** AI logic / API / prompts / fallback.

## 8. Recent Activities Improvements

- `RealtimeInspectionCard` + `InspectionTable`: verified — list dạng card, title `truncate`,
  thời gian ngắn, nút xem `shrink-0` — không tràn trên mobile.
- **Không đổi** order / nguồn dữ liệu / timestamps.

## 9. Regression Summary

- **Build:** `npm run build` (tsc -b + vite) cho tập lỗi TS **giống hệt baseline** (8 lỗi pre-existing:
  Header `Alert.title`, Login unused `Check`, Dashboard unused `DashboardSkeleton`, Settings×4,
  Trees unused `detailStatsLoading`) — **0 lỗi mới**.
- **ESLint:** trên 5 file đã sửa chỉ còn 2 lỗi + 2 warning pre-existing (DashboardSkeleton unused,
  set-state-in-effect, exhaustive-deps) — không lỗi mới từ Phase D.
- **Desktop appearance:** mọi thay đổi đều dùng variant `sm:/lg:/xl:` nên desktop ≥1280px không đổi.
- **Logic / API / Service / Route / Chart data / AI:** không đổi — Phase D chỉ thay đổi class JSX
  (grid/flex/height/overflow) + typography scale của DashboardHeader.
- **Không chạy `pytest`** (rủi ro wipe DB R1).

## 10. Known Issues

- Lỗi TS pre-existing (8 lỗi Header/Login/Dashboard/Settings×4/Trees) vẫn còn — ngoài phạm vi Phase D.
- `DashboardSkeleton` (Shared/SkeletonCard) chưa được dùng ở Dashboard.tsx — baseline, không xử lý.
- `RecommendationTable` hiện không được import ở bất kỳ đâu (dead code) — giữ nguyên, không sửa.
- Weather widgets dùng mock data (`generateMockData` seed) — đã có từ trước, nằm ngoài phạm vi Phase D.

## 11. Final Status

**PASS**

- Phase D (Dashboard) hoàn thành đúng Scope: grid KPI `1→2→3→5` (mobile 1 / tablet 2 / laptop 3 /
  desktop 5), dashboard rows chỉ `lg`, heatmap `min-h` + scroll ngang, header dashboard typography scale.
- Tuân thủ UI LOCK STATUS + IMPLEMENTATION RULES (không component mới, không đổi chart/AI/logic/API,
  Frontend-only).
- Dừng tại đây theo yêu cầu STEP 4D: chờ review trước khi sang Phase E (Authentication + Final Polish).

---

# Release 1.3.2 — Phase E

> **Scope:** Authentication (Login / Register / Forgot Password UI) + Final UI Polish toàn bộ
> Shared Components còn lại + Consistency. Frontend-only. Desktop ≥1024px giữ nguyên 100%.

## 1. Files Modified

| # | File | Thay đổi |
|---|---|---|
| 1 | `frontend/src/pages/auth/Login.tsx` | Card form padding mobile `p-10` → `p-8 sm:p-16` (đúng thiết kế §2.3: auth form card `p-8` trên mobile); hàng "Ghi nhớ đăng nhập + Quên mật khẩu?" thêm `flex-wrap gap-3` (chống tràn ngang mobile) |

## 2. Authentication Improvements

- **Login:**
  - Hàng checkbox "Ghi nhớ đăng nhập" + nút "Quên mật khẩu?" trước đây `flex items-center justify-between`
    → **tràn ngang trên viewport hẹp** (320px: ~150px + ~100px > 208px content). Đã thêm `flex-wrap gap-3`:
    nút "Quên mật khẩu?" xuống hàng dưới khi thiếu không gian, desktop giữ nguyên 1 hàng.
  - Card form padding mobile giảm `p-10` (40px) → `p-8` (32px) khớp design §2.3; `sm:` giữ `p-16`.
  - Hero panel `hidden md:flex` + mobile logo `md:hidden`, `min-h-screen`, scroll dọc — đã đúng, không sửa.
- **Register:** verified — không cần sửa (form `max-w-[400px]`, input `w-full`, không hàng nào cố định
  gây tràn; branding panel `hidden lg:flex` + mobile logo `lg:hidden`).
- **Forgot Password:** **không tồn tại** trang/route riêng — chỉ là nút "Quên mật khẩu?" không điều hướng
  (pre-existing). Không tạo trang mới (tuân thủ "không phát triển tính năng mới").
- Không đổi logic login/register, không đổi API, không đổi luồng auth, không đổi DTO.

## 3. Shared Components Review (Final UI Polish)

Đã review toàn bộ Shared Components còn lại chưa xử lý ở Phase B:

| Component | Trạng thái |
|---|---|
| `SearchBar` | Verified — `w-full`, icon absolute, nút xóa absolute — responsive |
| `FilterBar` | Verified — `flex-col sm:flex-row sm:flex-wrap sm:items-center` — responsive |
| `LoadingState` | Verified — skeleton `w-full`, thanh `w-1/3`/`w-2/3` — responsive |
| `EmptyState` | Verified — `p-8`, text `max-w-sm`, wrap — responsive |
| `StatusChip` | Verified — `min-w-[80px]` + `px-3`, tăng chiều rộng theo label, không tràn |
| `ConfirmDialog` | Verified — `fixed inset-0 p-4`, dialog `w-full max-w-md`, 2 nút khớp mobile 320px |
| `DrawerForm` / `RecordDetailDrawer` | Đã xử lý Phase B — không đụng |
| `Toolbar` / `Pagination` / `PageHeader` / `DataTable` / `StatCard` / `ChartCard` | Đã xử lý Phase B — không đụng |
| `AppLayout` / `Sidebar` / `Header` / `Footer` | Đã xử lý Phase A — không đụng |

→ **Không có file Shared Component nào cần sửa ở Phase E** (tất cả đã responsive).

## 4. Consistency

- CRUD Pages (Phase C), Dashboard (Phase D), Authentication (Phase E) dùng cùng Design System:
  cùng màu `#1E8449`/emerald, cùng border `gray-100/200`, cùng radius `rounded-xl/rounded-[10px]/rounded-[18px]`,
  cùng font, cùng animation đã có.
- Không redesign, không component mới/xoá, không đổi màu/icon/font/animation.

## 5. Regression Summary

- **Build:** `npm run build` (tsc -b + vite) cho tập lỗi TS **giống hệt baseline** (8 lỗi pre-existing:
  Header `Alert.title`, Login unused `Check`, Dashboard unused `DashboardSkeleton`, Settings×4,
  Trees unused `detailStatsLoading`) — **0 lỗi mới**.
- **ESLint:** trên `Login.tsx` chỉ còn lỗi pre-existing unused `Check` — không lỗi mới từ Phase E.
- **Desktop appearance:** 2 thay đổi đều có variant `sm:`/`flex-wrap` → desktop ≥1024px không đổi.
- **Logic / API / Routes / Navigation / Auth Flow:** không đổi.
- **Không chạy `pytest`** (rủi ro wipe DB R1).

## 6. Known Issues

- Lỗi TS pre-existing (8 lỗi Header/Login/Dashboard/Settings×4/Trees) vẫn còn — ngoài phạm vi Phase E.
- Nút "Quên mật khẩu?" trên Login không có trang đích (không navigate) — pre-existing, không thêm tính năng.
- `RecommendationTable`, `DashboardSkeleton` là dead code — giữ nguyên, không sửa.

## 7. Final Status

**PASS**

- Phase E (Authentication + Final Polish) hoàn thành: Login fix 2 điểm (padding mobile theo design §2.3 +
  wrap chống tràn), Register + 6 shared components còn lại verified không cần sửa, consistency đạt.
- Tuân thủ UI LOCK STATUS + IMPLEMENTATION RULES (không feature mới, không đổi logic/API/routes/auth flow,
  không redesign, Frontend-only).
- Dừng tại đây theo yêu cầu STEP 4E: **không chạy STEP 5 (Verification), không Manual Review,
  không Git Commit, không Merge — chờ Review.**

---

# Release 1.3.2 — Heatmap Bug Fix (STEP 4D.1)

> **Scope:** Bug fix có chủ đích cho duy nhất blocker tìm thấy trong STEP 6 Manual Review tại viewport
> 320px (Mobile-min). Không phải phase triển khai mới, không tối ưu UI thêm.

## 1. Root Cause

Tại viewport 320×640, header row của HeatmapCard (`div.flex.items-center.justify-between`) không thể wrap:

- Nội dung cần thiết: block tiêu đề (icon + `<h3>` + subtitle) + block điều khiển (2 select + nút refresh).
- Tại 320px, bề rộng nội dung card ≈ 246px nhưng block điều khiển cần ≈ 246px và tiêu đề cần thêm →
  tổng vượt quá bề rộng container.
- Row không có `flex-wrap` → các item ép nằm trên 1 dòng và **tràn ngang**; `main.scrollWidth = 357`
  vs `clientWidth = 320` (overflow ≈ 37px).
- Kết quả: **nút "Làm mới bản đồ nhiệt" nằm hoàn toàn ngoài viewport** (rect x 333→357, card right edge 283)
  → không nhìn thấy, không click được; select "Lọc theo khu vực" (rect x 219→327) bị cắt 7px.

## 2. Files Modified

| File | Thay đổi |
|---|---|
| `frontend/src/components/dashboard/HeatmapCard.tsx` | Chỉ sửa **1 dòng** — className của title/header row. Không đụng grid dashboard, heatmap, map, business logic, API, shared components, hay trang khác. |

## 3. Fix Applied

Row header:
`flex items-center justify-between`
→ `flex flex-wrap items-center justify-between gap-2 xl:flex-nowrap xl:gap-0`

- `flex-wrap`: trên màn hình hẹp (<1280px), block điều khiển wrap xuống hàng riêng khi không đủ chỗ →
  tiêu đề giữ nguyên hàng 1, 2 select + nút refresh nằm trọn hàng 2, luôn hiển thị và dùng được.
- `gap-2`: tạo khoảng cách dọc giữa hàng tiêu đề và hàng điều khiển khi wrap.
- `xl:flex-nowrap` + `xl:gap-0` (≥1280px): khôi phục đúng hành vi cũ của desktop/laptop —
  layout desktop giữ nguyên 100% (không wrap, không đổi vị trí).
- Không giảm font-size, không xoá/ẩn control, không redesign card, không đổi hành vi nghiệp vụ.

## 4. Regression Check

Đo lại bằng Playwright (real Chromium, dữ liệu thật, login `bao@gmail.com`) tại 5 viewport:

| Viewport | docOverflow | main overflow | Refresh button | Filter select | Kết luận |
|---|---|---|---|---|---|
| 1440×900 (Desktop) | 0 | 0 | hiển thị (x1004→1028) | hiển thị (x890→998) | PASS — giống hệt pre-fix (card h=240, h3 61px/96px, controls t=440) |
| 1366×768 (Laptop) | 0 | 0 | hiển thị | hiển thị | PASS — giống hệt pre-fix |
| 768×1024 (Tablet) | 0 | 0 | hiển thị (x709→733) | hiển thị (x595→703) | PASS — tiêu đề + controls cùng hàng |
| 390×844 (Mobile) | 0 | 0 | hiển thị (x263→287) | hiển thị (x149→257) | PASS — controls wrap hàng 2, đủ rộng |
| 320×640 (Mobile-min) | 0 | 0 | hiển thị (x263→287) | hiển thị (x149→257) | **PASS — fix đúng blocker** |

- 320px: trước fix `main.scrollWidth 357` (overflow 37px), nút refresh ở x333→357 (ngoài viewport).
  Sau fix: `mainOver = 0`, nút refresh x263→287 và select x149→257 nằm gọn trong viewport, không bị cắt.
- Desktop/Laptop: kích thước card (335×240), vị trí controls (t=440), tiêu đề ép trái (61px/96px) —
  **đo được giống hệt trạng thái pre-fix** → "Desktop layout unchanged" đạt.
- `npx tsc -b`: vẫn đúng 8 lỗi pre-existing baseline, **0 lỗi mới** (không có lỗi nào thuộc `HeatmapCard.tsx`).
- Không JS error mới, không console error mới trên Dashboard.

## 5. Final Status

**PASS**

- Blocker STEP 6 (heatmap controls bị cắt/nút refresh không truy cập được tại 320px) đã được sửa
  bằng thay đổi tối thiểu 1 dòng trong `HeatmapCard.tsx`.
- Toàn bộ regression (Desktop/Laptop/Tablet/Mobile/Mobile-min) đạt, không tràn ngang, không clipping,
  desktop giữ nguyên 100%.
- Backend: **không có thay đổi** (xem BACKEND_IMPLEMENTATION_REPORT.md).
- Dừng theo yêu cầu STEP 4D.1: **không chạy STEP 5, không chạy STEP 6, không Git Commit,
  không Merge — chờ Review.**

---

# Release 1.3.2 — Dashboard Layout Refinement (STEP 4D.2)

> **Scope:** Tinh chỉnh layout Dashboard quay về bố cục Release cũ (grid 3 cột). KHÔNG sửa Responsive,
> KHÔNG thêm breakpoint, KHÔNG đổi Tailwind screens, KHÔNG sửa mobile/tablet, KHÔNG đụng component khác.
> Chỉ điều chỉnh: height / min-height / grid-template-rows / gap / align-self / self-start.

## 1. Root Cause

Dashboard hiện tại (grid `lg:grid-cols-3`, rows `auto 520px 420px`, đo tại desktop 1440×900):

| Card | Trước | Vấn đề |
|---|---|---|
| Tổng quan hệ thống (Overview) | cao **520px** | Bị kéo giãn đúng chiều cao row 2 (= Heatmap) → **khoảng trắng lớn bên trong card**; vi phạm "Overview không được cao bằng Heatmap" |
| Bản đồ giám sát cây trồng (Heatmap) | cao **520px** | Cao hơn ngưỡng mục tiêu 430~470px |
| AI Agronomist | cao **564px** | Là `flex: 6` của 60% cột 3 (span rows 2-3) → phụ thuộc chiều cao Heatmap, không độc lập, vượt 430~470px |
| Hoạt động kiểm tra gần đây (Recent Activity) | top **905px** | Trong cột 3 (`flex: 4`) bắt đầu thấp hơn row 3 → **không thẳng hàng** với Farm Performance (top 861px) |

Ngoài ra: Pie (Phân bố tình trạng cây) bị đẩy xuống top 861px vì row 2 quá cao (520px).

## 2. Layout Fix

Chỉ sửa `frontend/src/pages/dashboard/Dashboard.tsx` (không đụng component card nào):

| Vị trí | Trước | Sau |
|---|---|---|
| Grid rows | `lg:[grid-template-rows:auto_520px_420px]` | `lg:[grid-template-rows:auto_450px_420px]` |
| Overview (grid item) | kéo giãn đủ row 2 (520px) | bọc `lg:self-start` → co đúng chiều cao content (~307px) |
| AI Agronomist (cột 3) | `style={{ flex: 6, minHeight: 0 }}` | `className="lg:h-[450px] min-h-0"` → chiều cao cố định 450px, độc lập |
| Hoạt động kiểm tra gần đây (cột 3) | `style={{ flex: 4, minHeight: 0 }}` | `className="flex-1 min-h-0"` → lấp phần còn lại của cột 3 (= chiều cao row 3, top thẳng hàng Farm Performance) |

- Tất cả class dùng variant `lg:` → dưới 1024px (tablet/mobile) vẫn là flex-col như cũ, **không đổi**.
- Không đổi typography, không đổi KPI, không đổi card, không đổi logic/API/data.
- Cột 3 (row-span-2) = 450 + gap 20 + 420 = 890px; Agronomist 450px + gap 20 + Inspection flex-1 (420px)
  → Inspection top trùng đúng top row 3 → thẳng hàng Pie / Farm Performance.

## 3. Files Modified

| File | Thay đổi |
|---|---|
| `frontend/src/pages/dashboard/Dashboard.tsx` | Grid rows 520→450; Overview bọc `lg:self-start`; Agronomist `lg:h-[450px]`; Inspection `flex-1`. Chỉ layout, không đụng logic. |
| Các component card (SystemOverviewCard, HeatmapCard, AgronomistPanel, TreeDistributionCard, FarmPerformanceCard, RealtimeInspectionCard) | **KHÔNG sửa** |

## 4. Before / After (đo bằng Playwright, desktop 1440×900)

| Card | Before | After |
|---|---|---|
| Overview | top 321 · cao 520 | top 321 · cao **307** (content) |
| Heatmap | cao 520 | cao **450** |
| AI Agronomist | cao 564 | cao **450** (độc lập) |
| Pie (Phân bố) | top 861 · cao 420 | top **791** · cao 420 (dịch lên 70px, sát dưới Overview) |
| Farm Performance | top 861 · cao 420 | top **791** · cao 420 |
| Recent Activity (Kiểm tra) | top 905 · cao 376 | top **791** · cao **420** (thẳng hàng Farm Performance) |
| Grid tổng | cao 1096 | cao **1026** |

→ Thoả tất cả 6 mục tiêu UI: Overview co content & không cao bằng Heatmap; Heatmap 430~470;
Agronomist 430~470 độc lập; Pie sát dưới Overview; Farm Performance thẳng hàng Pie;
Recent Activity thẳng hàng Farm Performance.

## 5. Regression Check

- **Desktop 1440×900:** `docOverflow=0`, `mainOver=0`; heatmap giữ nguyên data (legend "An toàn 2006"),
  scroll grid vẫn hoạt động (content 6744px trong box scrollable), filter + refresh visible (t=440, giống pre-fix).
- **Tablet 768×1024 / Mobile 390×844 / Mobile-min 320×640:** vẫn flex-col (`gridTemplateColumns: none`),
  `docOverflow=0`, `mainOver=0` → **không thay đổi** (mọi thay đổi chỉ áp dụng `lg:` ≥1024px).
- **TypeScript:** `npx tsc -b` → vẫn đúng 8 lỗi pre-existing baseline, **0 lỗi mới** (không thuộc `Dashboard.tsx`).
- **JS/console/network:** không lỗi mới trên Dashboard.

## 6. LOCK STATUS

| Lock | Trạng thái |
|---|---|
| Backend / Database / MongoDB / API / Repository / Service / DTO | LOCKED — không đụng |
| Authentication / Authorization / ETL / Business Logic | LOCKED — không đụng |
| Routing / Sidebar / Navigation | LOCKED — không đụng |
| KPI Logic / Heatmap Logic / Farm Performance Logic / Chart Logic / AI Agronomist Logic | LOCKED — không đụng |
| Responsive / breakpoint / Tailwind screens / mobile / tablet | LOCKED — không sửa (mọi thay đổi `lg:` only) |

## 7. Final Result

**PASS**

- Dashboard quay về bố cục grid 3 cột chuẩn của Release cũ với tinh chỉnh chiều cao: Overview co content,
  Heatmap & AI Agronomist 450px, Pie / Farm Performance / Recent Activity thẳng hàng ở row 3.
- Chỉ đụng 1 file `Dashboard.tsx`, chỉ dùng height / grid-template-rows / gap / self-start, không đổi
  typography / KPI / card / logic.
- Backend: **không có thay đổi**.
- Dừng theo yêu cầu STEP 4D.2: **không chạy STEP 5, không chạy STEP 6, không Git Commit,
  không Merge — chờ Review.**

---

