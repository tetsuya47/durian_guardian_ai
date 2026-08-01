# SOLUTION_DESIGN — Responsive UI Optimization (Release 1.3.2)

**Project:** Durian Guardian AI (DGA)
**Module:** Responsive UI Optimization — Release 1.3.2 (Frontend-only)
**Date:** 2026-08-01
**Method:** 100% design only — Không Coding, không đổi Database/Backend/API, không tạo page/feature mới.

---

## 1. Executive Summary

Release 1.3.2 là gói **tối ưu giao diện responsive toàn diện** cho toàn bộ Frontend hiện tại của DGA
Portal (Dashboard + toàn bộ trang + các component dùng chung). Mục tiêu: đảm bảo mọi màn hình
(Desktop / Tablet / Mobile) hiển thị nhất quán về breakpoint, grid, spacing, overflow và chiều
rộng/cao, **giữ nguyên 100% Design System hiện tại** (màu sắc, bán kính 18px, shadow token, font).

Khảo sát thực tế (đọc toàn bộ `frontend/src`) cho thấy hệ thống hiện **đã responsive ở tầng khung**
(sidebar off-canvas < 1024px, backdrop, grid KPI `sm/lg`, DataTable có `overflow-x-auto`, drawer
full-width < 560px, ConfirmDialog chuẩn). Tuy nhiên tồn tại **nhóm lệch chuẩn tập trung**:

| Nhóm vấn đề | Ví dụ điển hình |
|---|---|
| Chiều cao/chiều rộng cứng (px) không có biến thể breakpoint | `KPISection` `grid-cols-5`, StatCard `80px/130px`, ChartCard `320px`, Dashboard grid rows `520px/420px`, HeatmapGrid ≥ `417px` không scroll ngang |
| KPI dàn 5 cột cứng trên mobile | `KPISection.tsx:19`, `FarmDashboard.tsx:176` |
| Header/Sidebar/Footer thiếu chiến lược mobile | breadcrumb không ẩn, drawer sidebar 280px trên viewport 320px, Footer 3 đoạn chữ không wrap |
| Pagination không wrap / Toolbar title không wrap | chuỗi nút trang ~400px có thể tràn card |
| Chiều cao card không nhất quán giữa các họ | KPI 116px (live) vs 130px (mock), pie radii 95/150 vs 60/80 |
| Auth 2 trang lệch breakpoint | Login dùng `md`, Register dùng `lg` |
| Long-text cell chỉ `truncate`, không break | DataTable cell `truncate` (không `break-words`) |

**Giải pháp:** Không thêm component mới, không đổi Design System. Chỉ (1) áp bộ breakpoint chuẩn,
(2) responsive hóa padding/spacing, (3) chuyển các kích thước cứng sang `min-height` + biến thể
breakpoint, (4) chuẩn hóa grid KPI theo tầng `2→3→5 cột`, (5) bọc scroll ngang cho các widget min-width
cố định, (6) thống nhất hành vi mobile của Header/Sidebar/Footer/Pagination/Drawer. Toàn bộ thay đổi
nằm trong các file `frontend/src/**` (JSX/Tailwind), không động vào API layer, không đổi type/service.

**Kết luận:** Giải pháp khả thi, rủi ro thấp, phạm vi khép kín, có thể chuyển sang STEP 3 (Coding).

---

## 2. UI Wireframe

Design System được giữ nguyên: màu gốc `#0F3D2E` (sidebar), nền `#F7F8FA/#F5F7FB`, card trắng
`rounded-[18px] shadow-[0_2px_8px_rgba(0,0,0,0.05)]`, header 72px. Dưới đây mô tả bố cục ở 3 tầng
breakpoint cho từng nhóm màn hình (đại diện cho toàn bộ trang CRUD giống hệt nhau).

**Breakpoint chuẩn (giữ nguyên Tailwind mặc định):**
`sm: 640px · md: 768px · lg: 1024px · xl: 1280px · 2xl: 1400px (container)`

---

### 2.1 Desktop (≥ 1024px)

**A) Trang CRUD / list (đại diện: Companies, Farms, Zones, Trees, Users, Inspections, …)**
```
┌──────────────────────────────┬──────────────────────────────────────────────┐
│ SIDEBAR (static 280px)       │ HEADER (72px: hamburger | breadcrumb | search│
│ #0F3D2E, logo, 9 nav items   │ ─ bell ─ avatar)                             │
│ ──────────────────────────── │ ─────────────────────────────────────────────│
│ ═ logo ═                      │  p-6 (24px gutter)                          │
│  Nav items (icon + label)    │  ┌─ PageHeader ────────────── [＋ Thêm mới] ─┐│
│                              │  ┌─ Toolbar: [Tên module] | [search] [filters]┐│
│  collapse ▾ 80px hoặc 280px  │  │  [＋ filter chip] [＋ action]            ││
│                              │  └───────────────────────────────────────────┘│
│                              │  ┌ KPI: grid-cols-1 sm:2 lg:4 ─ 4 StatCard  ┐│
│                              │  │ [KPI1] [KPI2] [KPI3] [KPI4] (h-80px)     ││
│                              │  └───────────────────────────────────────────┘│
│                              │  ┌ DataTable (giữ layout + overflow-x-auto)  ┐│
│                              │  │ thead | cột A | cột B | … | Hành động     ││
│                              │  │ (truncate cell + title tooltip)           ││
│                              │  └───────────────────────────────────────────┘│
│                              │  ┌ Pagination: info ─── [< 1 2 3 … 7 >]     ┐│
│                              │  └───────────────────────────────────────────┘│
│                              │  ─────────────────────────────────────────────│
│                              │  FOOTER: DGA | Version 1.0 | © 2026          │
└──────────────────────────────┴──────────────────────────────────────────────┘
```
- Toolbar: hàng ngang (search 200px+, filter chips, action phải).
- Drawer Form / Detail: right-sheet `max-w-[560px]`, nội dung dạng cột label 160px + value.

**B) Dashboard (≥ 1024px)**
```
┌ SIDEBAR ┬─────────────────────────────────────────────────────────────┐
│         │ Header (72px)                                               │
│         ├ KPI: grid-cols-5 (2→3→5 tầng) [KPI1…KPI5, 116px]           │
│         ├ ┌───────────────┬──────────────┬──────────────────────────┐ │
│         │ │ col1 (2/3)    │ col2 (1/3)   │ (lg:grid-cols-3,          │ │
│         │ │ SystemOverview│ Agronomist   │  rows auto/520/420)       │ │
│         │ │ Heatmap       │ Realtime     │                           │ │
│         │ │ FarmPerf      │              │                           │ │
│         │ └───────────────┴──────────────┴──────────────────────────┘ │
└─────────┴─────────────────────────────────────────────────────────────┘
```
- Heatmap đủ ≥417px nội dung (20×18px cells) — nằm trong cột 2/3 desktop, không bị cắt.

**C) Auth (Login/Register)**
```
┌────────────────────────────────┬──────────────────────────────────┐
│ HERO (hidden md:flex, 58% -    │ FORM panel (flex-1, card        │
│ gradient #05231A→#145A3C)      │ max-w-[580px], p-16)            │
│  logo, slogan, 2x2 features    │  email / password / submit /     │
└────────────────────────────────┴  link register ─────────────────┘
```

### 2.2 Tablet (640–1023px)

- **Sidebar:** trở thành off-canvas drawer 280px (hoặc `min(280px, 85vw)`) + backdrop `bg-black/40`;
  tự collapse khi < 1024px (giữ logic hiện có).
- **CRUD list:** `p-6` → `p-5`; Toolbar xếp dọc (`flex-col lg:flex-row`); search full-width;
  KPI `grid-cols-2`; DataTable giữ layout hiện có (scroll ngang qua `overflow-x-auto`); Pagination xếp dọc + nút wrap.
- **Dashboard:** main grid chuyển flex-column (đã có sẵn < lg); mỗi widget full-width;
  KPI `grid-cols-3`; Heatmap được bọc `overflow-x-auto` để cuộn ngang trong cột full-width.
- **Header:** breadcrumb giữ (≥ md hiển thị); dropdown notification `max-w-[calc(100vw-2rem)]`.

### 2.3 Mobile (< 640px)

- **Header:** breadcrumb **ẩn** (`hidden md:flex`) → chỉ còn hamburger + logo nhỏ + search/bell/avatar;
  `px-4`; các dropdown `right-0` với `max-w-[calc(100vw-2rem)]` (tránh sát mép, không tràn).
- **Sidebar drawer:** rộng `min(280px, 85vw)` (viewport 320px → drawer 272px, phần nền còn lộ 48px +
  backdrop); label `truncate`.
- **CRUD list:** `p-4`; KPI `grid-cols-1`; Pagination xếp dọc, chuỗi nút `flex-wrap` (hoặc ẩn trang
  giữa, chỉ 3 nút) không tràn; footer `flex-wrap`.
- **Drawer Form/Detail:** full-width cạnh–cạnh (đã có sẵn nhờ `w-full max-w-[560px]`);
  label detail `w-[120px]` + value `break-words`.
- **Dashboard:** KPI `grid-cols-2`; StatCard/KPICard text giảm cấp (`32px`); Heatmap scroll ngang;
  card chart `h-[280px]`.
- **Auth:** hero ẩn, form card `p-8`, đầy đủ chiều cao `min-h-screen`, scroll dọc nếu cần.

---

## 3. UX Flow

### 3.1 User Journey — Duyệt & quản lý dữ liệu (trên mọi thiết bị)
```
Đăng nhập → (mobile: mở sidebar qua hamburger) → chọn module trong Sidebar
  → trang List hiển thị Toolbar + KPI + bảng + phân trang
  → tìm kiếm / lọc → bảng cập nhật → mở Detail drawer từ hàng
  → thêm/sửa qua Drawer Form → lưu → toast thành công → danh sách refresh
  → (mobile) đóng drawer → quay về List
```

### 3.2 Click Flow
| Bước | Desktop | Tablet | Mobile |
|---|---|---|---|
| Mở module | Click nav Sidebar | Click nav Sidebar (static → drawer nếu đang đóng) | Hamburger → Sidebar drawer → click nav |
| Tìm kiếm | Toolbar search (inline) | Toolbar search (full-width) | Header search icon → dropdown `w-64 sm:w-72` |
| Xem chi tiết | Click hàng → Detail drawer (phải) | Click hàng → Detail drawer (full-width) | Click hàng → Detail drawer (full-width) |
| Thêm/Sửa | Click action → Drawer Form (560px) | Click action → Drawer Form (full-width) | Click action → Drawer Form (full-width) |
| Xóa | Click delete → ConfirmDialog | ConfirmDialog | ConfirmDialog (card gần full-screen + `p-4`) |
| Phân trang | Click nút số | Click nút số (wrap) | Scroll nút số (wrap) / nút trước-sau |

### 3.3 Navigation Flow
```
Sidebar → Page (route) → Detail (RecordDetailDrawer, không đổi route) → Back
Back: desktop = nút "Back" toolbar / đóng drawer; mobile = đóng drawer (X) → về List đã giữ state
```

### 3.4 Back Navigation
- List → Detail: **drawer, không điều hướng route** → "Back" là nút đóng (X) hoặc click backdrop —
  giữ nguyên hành vi hiện có, state danh sách/tìm kiếm/trang được bảo toàn.
- Sub-page (duy nhất): Farm Dashboard `/dashboard/farm/:farmId` → nút "←" trên Header trang quay về
  `/dashboard`; trên mobile chuyển thành `flex-wrap` để nút không tràn.

### 3.5 Loading Experience
- Giữ `LoadingState` hiện có (skeleton KPI/table/card), chỉ responsive hóa chiều cao:
  `h-[220px]`/`h-[360px]` giữ, đảm bảo khớp skeleton với chiều cao thật của card sau khi chuẩn hóa
  (KPI 116px, ChartCard 320px…). Không thay đổi animate `animate-pulse`.

### 3.6 Error Handling
- Giữ nguyên: error toast + `EmptyState`; interceptor axios unwrap lỗi `{success,message}`.
- Không thay đổi luồng lỗi; chỉ đảm bảo `EmptyState`/`LoadingState` hiển thị đủ trong container
  `min-h` responsive.

### 3.7 Empty Experience
- `EmptyState` (icon + title + desc, `max-w-lg mx-auto`) — giữ nguyên, responsive sẵn.
- Bảng rỗng: cell `colSpan` với thông báo trung tâm — giữ nguyên.

### 3.8 Success Experience
- Giữ nguyên toast success + refresh danh sách sau CRUD.
- Form thành công: đóng drawer, toast, danh sách cập nhật — không đổi.

---

## 4. API Design

### 4.1 Kết luận
**Không có API nào bị thay đổi, thêm mới hoặc xóa.** Toàn bộ giao diện gọi lại các endpoint hiện có;
không thêm request/response field; permission giữ nguyên.

### 4.2 API tái sử dụng (không đổi)
| Mục tiêu giao diện | API tái sử dụng | Method | Permission (hiện có) |
|---|---|---|---|
| List/Filters của mọi module | `/users`, `/farms`, `/zones`, `/trees`, `/companies`, `/inspections`, `/detection-results`, `/disease-history`, `/diseases`, `/alerts` | GET (list, `page/page_size/search`) | role-all |
| CRUD | mỗi module `/…/:id` (PUT/DELETE) + POST `/…` | POST/PUT/DELETE | role-all |
| Detail | GET `/…/:id` | GET | role-all |
| Dashboard | `/dashboard`, `/dashboard/heatmap`, `/dashboard/widgets`, `/dashboard/farm-performance`, `/dashboard/farm/{farmId}` | GET | auth/role-all |
| Farm overview | `/users/{user_id}/overview` (admin) | GET | admin |
| KPI | `get_kpi_stats` (server-side stats trong envelope) | GET | role-all |
| Auth | `/auth/login`, `/auth/register`, `/auth/me`, `/auth/refresh`, `/auth/profile`, `/auth/change-password` | POST/GET | public/auth |
| AI | `/ai/detect`, `/ai/image-quality`, `/chat` | POST | role-all/auth |

### 4.3 API cần bổ sung
**Không có.**

### 4.4 API tuyệt đối không được sửa
Toàn bộ endpoint, response envelope `{success, message, data}`, pagination meta
(`total/page/page_size/total_pages`), mapping `id↔_id`, các `stats` field của KPI.
> ⚠️ Mọi thay đổi giao diện chỉ nằm ở tầng JSX/Tailwind. Không đổi `frontend/src/api/**`,
> `frontend/src/services/**`, `frontend/src/types/**`.

---

## 5. DTO Design

### 5.1 Kết luận
**Không có DTO nào bị thêm/sửa/xóa.** Giao diện tái sử dụng toàn bộ type/service hiện có.

### 5.2 Tái sử dụng (giữ nguyên)
| Nhóm | File (frontend) | Ghi chú |
|---|---|---|
| Envelope response | `src/services/base.service.ts` + axios interceptor | `id↔_id` map, unwrap, pagination meta — không đổi |
| Entity types | `src/types/*.ts` (13 file: user, farm, zone, tree, company, inspection, detection, disease, alert, …) | không đổi |
| KPI stats DTO | field `stats` trong response (server `get_kpi_stats`) | không đổi |

### 5.3 Validation Rule
- Không đổi validation nào (hiện: ngoài form client, backend Pydantic + Mongo validator).
- Chỉ có các ràng buộc trình bày: text dài hiển thị `truncate` + `title` tooltip; label detail
  `w-[120px] sm:w-[160px]`; input `w-full` trong drawer.

### 5.4 Đảm bảo tương thích
- **DB:** không đổi — giao diện không thêm field mới.
- **Frontend:** không đổi types/services — không gây lệch mapping `id/_id`.

---

## 6. Repository Flow

### 6.1 Kết luận
**Không có thay đổi Backend/Repository.** Luồng dữ liệu giữ nguyên là nền tảng mà giao diện bám theo:

```
MongoDB (15 collection)
   ↓
Repository (BaseRepository + repository/module)  — read/write qua Motor
   ↓
Service (module service + serialize_* + success_response)
   ↓
DTO (Pydantic request/response)
   ↓
API (FastAPI /api/v1/…, RoleChecker + PaginationDep)
   ↓
Frontend Service (axios → interceptor unwrap, id→_id, meta) → component → UI
```

### 6.2 Mô tả luồng cho từng thao tác giao diện (không đổi)
- **List (đọc):** GET list → repository find + enrichment `$lookup` → service serialize →
  envelope paginated → interceptor gắn `total/page/...` → bảng render.
- **Detail:** GET `/:id` → repository get + serialize → drawer render.
- **Create/Update/Delete:** POST/PUT/DELETE → repository write → success response → frontend
  đóng drawer + toast + refetch list.
- **KPI:** `get_kpi_stats` (count_documents/distinct, read-only) → `stats` trong envelope →
  StatCard/KPICard render; fallback: đếm trên items hiện tại khi thiếu `stats` (giữ logic hiện có).

---

## 7. Aggregation Flow

### 7.1 Kết luận
**Không thêm/thay đổi bất kỳ Aggregation nào.** Các pipeline hiện có (Dashboard, KPI stats,
enrichment `$lookup`) giữ nguyên vì bước này không đổi Backend. Giao diện chỉ thay đổi **cách trình
bày kết quả** (grid/breakpoint/overflow), không đổi nguồn dữ liệu.

### 7.2 Mô tả luồng aggregation hiện có (để giao diện bám theo, không sửa)
```
Collection (trees / inspections / detection_results / disease_history / alerts / …)
   ↓
Repository (get_kpi_stats, DashboardService aggregation)
   ↓  Aggregation các bước đã có:
   ↓   Match  — filter (farm_id, date range, status …)
   ↓   Lookup — join zones/farms/users (enrichment)
   ↓   Project — field giữ lại
   ↓   (Unwind/Group nếu có)
   ↓   Sort / Limit — theo thứ tự request
Service → DTO → API
   ↓
Frontend → KPICard / ChartCard / HeatmapGrid / DataTable render
```
> Giao diện chỉ đọc dữ liệu aggregation đã trả về; mọi tính toán hiển thị lại (tỉ lệ %, format số)
> nằm trong component hiện có — không đổi.

---

## 8. Navigation Flow

### 8.1 Sidebar → Page
| Route | Menu Sidebar | Trạng thái |
|---|---|---|
| `/dashboard` | Dashboard | hiển thị |
| `/companies` | Doanh nghiệp | hiển thị |
| `/farms` | Vườn | hiển thị |
| `/zones` | Vùng | hiển thị |
| `/trees` | Cây | hiển thị |
| `/users`, `/users/:user_id` | Người dùng | hiển thị |
| `/inspections` | Kiểm tra | hiển thị |
| `/disease-history` | Lịch sử bệnh | hiển thị |
| `/alerts` | Cảnh báo | hiển thị |
| `/detection-results` | (ẩn qua `HIDDEN_MENU_PATHS`) | route tồn tại |
| `/diseases` | (ẩn) | route tồn tại |
| `/dashboard/farm/:farmId` | (con của Dashboard) | route tồn tại |
| `/settings` | Settings | local-only |

- **Desktop:** sidebar static 280px/80px; click nav → route → `<Outlet>`.
- **Tablet/Mobile:** hamburger mở drawer + backdrop; click nav → đóng drawer + navigate.

### 8.2 Page → Detail → Back
```
Sidebar → List Page (route) 
   ├─ Click hàng → RecordDetailDrawer (không đổi route) → nút Đóng (X) → về List giữ state
   ├─ Thêm/Sửa → DrawerForm → Lưu → toast → đóng → List refresh
   └─ Xóa → ConfirmDialog → Xác nhận → toast → List refresh
Dashboard → Farm Dashboard (/dashboard/farm/:farmId) → nút "←" → /dashboard
```

### 8.3 Breadcrumb / Action / Back Button
| Thành phần | Hành vi hiện tại | Điều chỉnh (design) |
|---|---|---|
| Breadcrumb Header | `PORTAL / label` luôn hiển thị | **ẩn < md** (`hidden md:flex`) |
| Action Button (Thêm mới…) | PageHeader actions `flex-wrap` | giữ nguyên |
| Back Button | FarmDashboard header `justify-between` | chuyển `flex-wrap` để không tràn trên mobile |
| Đóng Drawer | nút X + click backdrop | giữ nguyên |

---

## 9. Sequence Diagram

### 9.1 Luồng mở List (mọi thiết bị) — không đổi backend
```
Admin/User                 Frontend (React)                API (FastAPI)          Service/Repo        MongoDB
   │  click nav sidebar        │                              │                       │                  │
   │──────────────────────────>│ GET /api/v1/<module>?page..  │                       │                  │
   │                           │─────────────────────────────>│ list() (enrich lookup) │                 │
   │                           │                              │──────────────────────>│ find(...)        │
   │                           │                              │                       │─────────────────>│ query
   │                           │                              │                       │<─────────────────│ docs
   │                           │                              │<──────────────────────│ serialize + envelope
   │                           │<─────────────────────────────│ 200 {success,data,meta}
   │                           │ interceptor: unwrap, id→_id, attach pagination meta
   │                           │──────────────────────────────│ (render DataTable + KPI stats)
   │<──────────────────────────│
```
### 9.2 Luồng Detail (Drawer) — không đổi
```
User → click hàng → Frontend GET /:id → API → Service serialize → Repo find_one → MongoDB
   → trả về → Frontend mở RecordDetailDrawer render label/value (responsive: label 120/160px)
   → Đóng (X/backdrop) → về List giữ state (không gọi lại API)
```
### 9.3 Luồng Thêm/Sửa (DrawerForm)
```
User → click Thêm/Sửa → DrawerForm mở → nhập → submit POST/PUT /<module> | /<module>/:id
   → API → Service validate → Repo insert/update → MongoDB
   → 200/201 {success,message,data} → Frontend toast + đóng drawer + refetch list
   → lỗi 4xx/5xx → toast error + giữ form (không đóng)
```
### 9.4 Luồng Dashboard
```
User → /dashboard → GET /dashboard, /dashboard/heatmap, /dashboard/widgets,
        /dashboard/farm-performance (song song) → API → DashboardService aggregation
   → Repo (match/lookup/project/group) → MongoDB → return → Frontend render KPISection,
     HeatmapGrid, ChartCard, FarmPerformanceCard (grid responsive 2/3/5; heatmap overflow-x-auto)
```

---

## 10. Scope Boundary

### In Scope (Frontend-only, trong `frontend/src/**`)
| Nhóm | Chi tiết |
|---|---|
| Breakpoint & Grid | Áp chuẩn `sm 640 / md 768 / lg 1024 / xl 1280`; chuẩn hóa grid KPI `2→3→5 cột`; grid CRUD `1/2/4` (giữ) |
| Spacing | Content padding `p-6` → `px-4 sm:px-6 py-4 sm:py-6`; gap chuẩn hóa `gap-2 sm:gap-3` |
| Chiều cao/chiều rộng | Chuyển kích thước cứng sang `min-height`/biến thể: StatCard 80→`min-h-[76px]`, KPICard 116→responsive, ChartCard 320→`h-[280px] sm:h-[320px]`, Dashboard rows 520/420 → chỉ ở `lg`, Heatmap 480 → `min-h` responsive |
| Tables | Giữ nguyên layout bảng hiện có (không đổi min-width, không đổi cột, không đổi cách trình bày nghiệp vụ); chỉ cải thiện hành vi responsive qua `overflow-x-auto` + wrapper responsive + cuộn ngang — không redesign bảng |
| Sidebar/Header/Footer | Drawer `min(280px, 85vw)`; breadcrumb ẩn < md; dropdown `max-w-[calc(100vw-2rem)]`; footer `flex-wrap` |
| Pagination | Nút `flex-wrap` + `overflow-x-auto`; giảm số nút hiển thị trên mobile (5→3) |
| Dashboard widgets | Heatmap bọc `overflow-x-auto` (giải quyết min-width 417px); header widget `flex-wrap`; pie radii của TreeDistributionCard responsive |
| Drawers/Dialogs | Drawer giữ `w-full max-w-[560px]`; label detail `w-[120px] sm:w-[160px]` + value `break-words`; title drawer `truncate` |
| Auth | Thống nhất breakpoint hero (Login `md`, Register đổi `md`); card `p-8 sm:p-16` |
| Toolbar/PageHeader | Title `truncate` (bỏ `whitespace-nowrap`); PageHeader title `text-[24px] md:text-[32px]` |
| Consistency | KPI 116px (live) là chuẩn — không còn 130px mock (mock đã legacy); đồng bộ skeleton khớp chiều cao card |

### Out of Scope
- **Database / Backend / API:** tuyệt đối không đổi (xem §4.4).
- **Frontend API layer:** `src/api/**`, `src/services/**`, `src/types/**` — không đổi.
- **Design System:** không đổi màu sắc (`#0F3D2E`, HSL tokens), bán kính 18px, shadow token, font, UI Kit.
- **Tính năng mới / Page mới:** không thêm page, không thêm widget dữ liệu mới.
- **Dark mode:** token có sẵn nhưng không bật/thiết lập theme provider.
- **Sửa lỗi backend/ETL/authorization/AI mock:** ngoài phạm vi (đã liệt kê ở AUDIT_REPORT).
- **Chạy `pytest`:** cấm tuyệt đối (rủi ro wipe DB — R1).
- **Commit/merge.**

---

## 11. Risk Analysis

### High
| # | Rủi ro | Nguyên nhân |
|---|---|---|
| R1 | **Test suite xóa sạch DB production nếu chạy `pytest`** | `backend/tests/conftest.py:22-31` autouse `setup_db` → `delete_many({})` trên `durian_guardian_ai_1` (không test-DB riêng) — đã gây reset thật ở 1.3.2. Việc verify giao diện phải hoàn toàn bằng chạy thủ công, không chạy test |
| R2 | **Đụng tầng UI Kit / màu sắc / radius do sửa rộng** | Thay đổi trên nhiều file; người thực hiện có thể thêm class làm đổi màu/bán kính/typography ngoài phạm vi. Bắt buộc review diff từng class |

### Medium
| # | Rủi ro | Nguyên nhân |
|---|---|---|
| R3 | **Lệch skeleton vs chiều cao card thật** | Chuẩn hóa `min-height` card khiến skeleton cố định (220/360px) không khớp → nhảy layout khi load xong. Cần đồng bộ skeleton với chiều cao chuẩn mới |
| R4 | **Bọc wrapper responsive cho DataTable có thể ảnh hưởng sticky thead / scroll** | Giữ nguyên layout bảng hiện có (không đổi min-width, không đổi cột); nếu thêm wrapper chỉ để cuộn ngang, phải giữ `overflow-x-auto`, sticky thead `sticky top-0` và không đổi cấu trúc cột |
| R5 | **Heatmap responsive đổi kích thước cell** | Nếu không chỉ bọc `overflow-x-auto` mà đổi `gridTemplateColumns: repeat(20,18px)`, sẽ phá tỉ lệ grid/heatmap và tooltip định vị. Chỉ bọc scroll, không đổi kích thước cell |
| R6 | **Pagination thu gọn số nút** | Giảm số trang hiển thị có thể khiến người dùng thiếu ngữ cảnh trang; cần giữ ellipsis và chỉ áp dụng < sm |
| R7 | **Dashboard grid rows 520/420px chỉ ở lg** | Dưới lg (flex column) các widget tự cao theo nội dung; nếu không set `min-h` phù hợp, chart có thể bị méo (pie radii cố định 95/150) |

### Low
| # | Rủi ro | Nguyên nhân |
|---|---|---|
| R8 | **Drawer 560px giữ nguyên, không đổi chiều cao** | Body drawer chỉ `overflow-y-auto`, không `overflow-x-auto`; form wide (select dài) có thể bị cắt ở full-width mobile — low vì input đều `w-full` |
| R9 | **Register đổi hero `lg`→`md`** | Lệch giữa 2 trang auth nếu chỉ đổi 1; thay đổi nhỏ, dễ review |
| R10 | **Chạm file legacy mock (`pages/dashboard/components/`)** | Mock widgets không render trên Dashboard; nếu nhầm file sẽ vô ích. Chỉ sửa cây `components/dashboard/**` đang được dùng |

> Theo yêu cầu STEP 2: chỉ nêu nguyên nhân + biện pháp giảm thiểu bằng phạm vi review, **không Coding**.

---

## RESPONSIVE PRINCIPLES

- Preserve existing desktop layout whenever possible.
- Prevent horizontal overflow before resizing components.
- Use responsive wrappers before changing component size.
- Reduce spacing before reducing component dimensions.
- Stack sections only when screen width requires it.
- Never change business information hierarchy.
- Never hide business information to achieve responsiveness.
- Keep shared components reusable across the Admin Portal.
- Responsive behavior must remain consistent across every page.
- Desktop has higher priority than Tablet.
- Tablet has higher priority than Mobile.
- Responsive optimization must not change existing UX flow.

---

## UI LOCK STATUS

**Status:** LOCKED

### Allowed

- Responsive
- Breakpoint
- Grid
- Flex
- Width
- Height
- Gap
- Padding
- Margin
- Overflow
- Typography Scaling
- Mobile Behavior
- Tablet Behavior
- Desktop Layout

### Forbidden

- Database
- MongoDB
- Backend
- API
- DTO
- Repository
- Service
- Aggregation Logic
- Business Logic
- CRUD Logic
- Authentication
- Authorization
- Sidebar Structure
- Routes
- Navigation Structure
- Dashboard Features
- Widget Features
- Feature Changes
- Theme
- Design System
- Color Palette
- Icons
- Font Family
- DataTable redesign
- Card redesign
- Business information hierarchy
- Responsive behavior inconsistency
- Widget replacement
- Layout restructuring
- New UI components
- New navigation
- New pages
- Existing page removal

**Result:** Frontend Layout Only

---

## IMPLEMENTATION RULES

Every future implementation MUST satisfy ALL rules.

- ✓ Frontend only
- ✓ Layout only
- ✓ Responsive only
- ✓ No Database change
- ✓ No Backend change
- ✓ No API change
- ✓ No DTO change
- ✓ No Repository change
- ✓ No Service change
- ✓ No Aggregation change
- ✓ No Business Logic
- ✓ No CRUD Logic
- ✓ No Feature Change
- ✓ No Route Change
- ✓ No Navigation Change
- ✓ No Sidebar Change
- ✓ No Dashboard Feature Change
- ✓ No Data Mapping Change
- ✓ No Mock Data
- ✓ Reuse existing Shared Components
- ✓ Keep existing Design System
- ✓ Keep existing UI language
- ✓ Keep existing visual identity
- ✓ Fix layout globally before fixing individual pages
- ✓ Shared Components first
- ✓ Dashboard and CRUD pages must follow the same spacing system
- ✓ Do not introduce page-specific responsive behavior
- ✓ Every responsive rule must be reusable
- ✓ Every layout change must preserve visual consistency
- ✓ No duplicated responsive logic
- ✓ Existing Design System is the single source of truth

Violation of ANY rule means implementation must STOP immediately.

---

## Responsive Priority

```
Foundation Layout
    ↓
Shared Components
    ↓
CRUD Pages
    ↓
Dashboard
    ↓
Authentication
    ↓
Final Polish
```

Every implementation phase must follow this order.

---

## 12. Final Recommendation

**Coding is NOT approved.**

Implementation may start only after STEP 3 approval.

Implementation must follow:

```
Phase A — Layout Foundation
    ↓
Review
    ↓
Phase B — Shared Components
    ↓
Review
    ↓
Phase C — CRUD Pages
    ↓
Review
    ↓
Phase D — Dashboard
    ↓
Review
    ↓
Phase E — Authentication + Final Polish
    ↓
Review
    ↓
Finish
```

Do not merge phases.

Do not skip reviews.

---

## 13. Final Status

**APPROVED WITH CHANGES**

- Đã revoke: bỏ mọi thay đổi min-width/khối layout bảng — DataTable giữ nguyên layout hiện có.
- Đã bổ sung: RESPONSIVE PRINCIPLES + UI LOCK STATUS (LOCKED) + IMPLEMENTATION RULES + Responsive Priority — mọi implementation phải tuân thủ.
- Coding **KHÔNG được duyệt**; chỉ bắt đầu sau khi STEP 3 duyệt, theo thứ tự Phase A–E (không gộp phase, không bỏ review).
- Dừng tại đây theo yêu cầu STEP 2.2: không Coding, không tạo file khác, không chuyển sang STEP 3.

---

## DESIGN_REVISION_REPORT

### Sections Updated

- Responsive Principles Added
- UI Lock Updated
- Implementation Rules Updated
- Responsive Priority Added
- Final Recommendation Updated

### Final Status

**APPROVED WITH CHANGES**
