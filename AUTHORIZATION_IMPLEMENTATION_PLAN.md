# AUTHORIZATION IMPLEMENTATION PLAN (DGA RELEASE 1.4.0)

**Release:** 1.4.0  
**Mode:** STRICT IMPLEMENTATION PLAN  
**Status:** **AWAITING APPROVAL (NO CODE MODIFIED)**

---

## 1. Current Roles Audit

Trong phiên bản hiện tại, hệ thống tồn tại mô hình phân quyền Enterprise nhiều cấp độ phức tạp:
- **DB Roles:** `Admin`, `Company Manager`, `Farm Manager`, `Inspector`, `Technician`, `Farm Owner`.
- **API Roles (`UserRole` Enum):** `enterprise_admin`, `farm_manager`, `field_technician`, `farmer`.
- **Bất cập:** Mô hình quá cồng kềnh đối với đối tượng khách hàng mục tiêu của DGA (Nông dân, Chủ vườn, Trang trại vừa và nhỏ).

---

## 2. Target Roles (Đơn giản hóa 2 Role)

Triển khai mô hình 2 Role duy nhất trên toàn hệ thống:

| Role | Tên vai trò | Phạm vi Quyền hạn (Scope) |
|---|---|---|
| **ADMIN** | Quản trị viên hệ thống | - Có toàn quyền hệ thống (Full System Access).<br>- CRUD mọi tài nguyên (Companies, Users, Farms, Zones, Trees, Inspections, Alerts).<br>- Xem Dashboard tổng thể toàn hệ thống.<br>- Truy cập 100% Menu & Route. |
| **USER** | Nông dân / Chủ vườn | - Chỉ thao tác trên dữ liệu thuộc sở hữu của chính mình (Ownership Restricted).<br>- Xem Dashboard lọc theo trang trại sở hữu.<br>- Menu truy cập: Dashboard, Trang trại, Khu vực, Cây, Kiểm tra, Lịch sử bệnh, Cảnh báo.<br>- **Ẩn hoàn toàn Menu & Route:** Công ty (`/companies`), Người dùng (`/users`). Trả về **403 Forbidden** nếu cố tình truy cập. |

---

## 3. Authorization Matrix (Ma trận Quyền hạn)

| Quyền / Hành động | ADMIN | USER (Chủ sở hữu) |
|---|:---:|:---:|
| **Xem Dashboard Tổng** | ✔ | ❌ (Chỉ xem Farm của mình) |
| **Quản lý Công ty (`/companies`)** | ✔ | ❌ (403 Forbidden) |
| **Quản lý Người dùng (`/users`)** | ✔ | ❌ (403 Forbidden) |
| **Xem Trang trại (`/farms`)** | ✔ (Tất cả) | ✔ (Chỉ Farm sở hữu) |
| **Tạo / Sửa / Xóa Trang trại** | ✔ | ✔ (Trong phạm vi sở hữu) |
| **Xem Khu vực (`/zones`)** | ✔ (Tất cả) | ✔ (Chỉ Zone thuộc Farm sở hữu) |
| **Tạo / Sửa / Xóa Khu vực** | ✔ | ✔ (Trong phạm vi sở hữu) |
| **Xem Cây (`/trees`)** | ✔ (Tất cả) | ✔ (Chỉ Cây thuộc Farm sở hữu) |
| **Tạo / Sửa / Xóa Cây** | ✔ | ✔ (Trong phạm vi sở hữu) |
| **Xem & Kiểm tra (`/inspections`)** | ✔ (Tất cả) | ✔ (Chỉ Inspection của mình) |
| **Xem Lịch sử bệnh (`/disease-history`)**| ✔ (Tất cả) | ✔ (Chỉ dữ liệu cây của mình) |
| **Xem Cảnh báo (`/alerts`)** | ✔ (Tất cả) | ✔ (Chỉ Cảnh báo liên quan cây của mình) |

---

## 4. API Protection Matrix

| API Endpoint | HTTP Method | ADMIN | USER | Ownership Rule / Condition |
|---|:---:|:---:|:---:|---|
| `/api/v1/companies/*` | ALL | ✔ | ❌ (403) | Yêu cầu Role ADMIN. |
| `/api/v1/users/*` | ALL | ✔ | ❌ (403) | Yêu cầu Role ADMIN. |
| `/api/v1/farms` | GET | ✔ | ✔ | ADMIN: trả tất cả. USER: chỉ trả Farm có `owner_id == current_user.id`. |
| `/api/v1/farms/{id}` | GET/PUT/DELETE | ✔ | ✔ (Nếu thuộc sở hữu) | Kiểm tra `farm.owner_id == current_user.id`, ngược lại 403. |
| `/api/v1/zones` | GET/POST | ✔ | ✔ | ADMIN: tất cả. USER: chỉ Zone thuộc Farm sở hữu. |
| `/api/v1/zones/{id}` | GET/PUT/DELETE | ✔ | ✔ (Nếu thuộc sở hữu) | Kiểm tra Zone thuộc Farm của User, ngược lại 403. |
| `/api/v1/trees` | GET/POST | ✔ | ✔ | ADMIN: tất cả. USER: chỉ Cây thuộc Farm sở hữu. |
| `/api/v1/trees/{id}` | GET/PUT/DELETE | ✔ | ✔ (Nếu thuộc sở hữu) | Kiểm tra Cây thuộc Farm của User, ngược lại 403. |
| `/api/v1/inspections` | GET/POST | ✔ | ✔ | ADMIN: tất cả. USER: chỉ Inspection của User. |
| `/api/v1/alerts` | GET | ✔ | ✔ | ADMIN: tất cả. USER: chỉ Alert thuộc Cây/Farm của User. |
| `/api/v1/dashboard/*` | GET | ✔ | ✔ | ADMIN: dữ liệu tổng. USER: dữ liệu tự động lọc theo Farm sở hữu. |

---

## 5. Frontend Menu Matrix

| Menu Item | Path | Status ADMIN | Status USER | Action khi USER truy cập trực tiếp URL |
|---|---|:---:|:---:|---|
| **Bảng điều khiển** | `/dashboard` | Hiển thị | Hiển thị | Cho phép (Dữ liệu lọc theo Farm) |
| **Công ty** | `/companies` | Hiển thị | **ẨN (Hidden)** | Chuyển hướng về `/dashboard` + Toast 403 |
| **Trang trại** | `/farms` | Hiển thị | Hiển thị | Cho phép |
| **Khu vực** | `/zones` | Hiển thị | Hiển thị | Cho phép |
| **Cây** | `/trees` | Hiển thị | Hiển thị | Cho phép |
| **Người dùng** | `/users` | Hiển thị | **ẨN (Hidden)** | Chuyển hướng về `/dashboard` + Toast 403 |
| **Kiểm tra** | `/inspections` | Hiển thị | Hiển thị | Cho phép |
| **Lịch sử bệnh** | `/disease-history` | Hiển thị | Hiển thị | Cho phép |
| **Cảnh báo** | `/alerts` | Hiển thị | Hiển thị | Cho phép |

---

## 6. Frontend Route Matrix

| Route Path | Protected Component | Allowed Roles | Hành vi khi sai Role |
|---|---|---|---|
| `/dashboard` | `DashboardPage` | `ADMIN`, `USER` | Allow |
| `/companies` | `CompaniesPage` | `ADMIN` | Redirect `/dashboard` (403 Forbidden) |
| `/users` | `UsersPage` | `ADMIN` | Redirect `/dashboard` (403 Forbidden) |
| `/users/:user_id` | `FarmerOverviewPage` | `ADMIN` | Redirect `/dashboard` (403 Forbidden) |
| `/farms` | `FarmsPage` | `ADMIN`, `USER` | Allow (Filter list) |
| `/zones` | `ZonesPage` | `ADMIN`, `USER` | Allow (Filter list) |
| `/trees` | `TreesPage` | `ADMIN`, `USER` | Allow (Filter list) |
| `/inspections` | `InspectionsPage` | `ADMIN`, `USER` | Allow (Filter list) |

---

## 7. CRUD Matrix (Chi tiết thao tác dữ liệu)

```
ADMIN:   [C]reate   [R]ead   [U]pdate   [D]elete   (ALL RESOURCES)
USER:    [C]reate*  [R]ead*  [U]pdate*  [D]elete*  (*OWNED RESOURCES ONLY)
```

---

## 8. Ownership Rules (Quy tắc Xác minh Sở hữu)

1. **Farm Ownership:**
   `farm.owner_id == current_user.id` hoặc `farm.created_by == current_user.id`.
2. **Zone Ownership:**
   `zone.farm_id` nằm trong danh sách `user_farm_ids`.
3. **Tree Ownership:**
   `tree.farm_id` nằm trong danh sách `user_farm_ids`.
4. **Inspection Ownership:**
   `inspection.inspector_id == current_user.id` hoặc `inspection.farm_id` nằm trong `user_farm_ids`.
5. **Alert Ownership:**
   `alert.farm_id` nằm trong `user_farm_ids`.

---

## 9. Files Cần Sửa (Khi được Phê duyệt)

### Frontend (5 Files)
1. **`frontend/src/components/layout/Sidebar.tsx`**: Ẩn Menu `Công ty` & `Người dùng` khi `user.role === 'USER'`.
2. **`frontend/src/routes/index.tsx`**: Bổ sung `AdminRoute` bảo vệ các route `/companies`, `/users`.
3. **`frontend/src/pages/companies/Companies.tsx`**: Chặn render nếu không phải Admin.
4. **`frontend/src/pages/users/Users.tsx`**: Chặn render nếu không phải Admin.
5. **`frontend/src/pages/dashboard/Dashboard.tsx`**: Tự động áp dụng bộ lọc `farmFilter` theo trang trại người dùng sở hữu.

### Backend (6 Files)
1. **`backend/app/models/enums.py`**: Chuẩn hóa Enum `UserRole` gồm 2 giá trị `admin` và `user`.
2. **`backend/app/core/dependencies.py`**: Cập nhật helper `require_admin` và `verify_ownership`.
3. **`backend/app/api/v1/companies.py`**: Thêm dependency `require_admin` (403 nếu `USER`).
4. **`backend/app/api/v1/users.py`**: Thêm dependency `require_admin` (403 nếu `USER`).
5. **`backend/app/api/v1/farms.py`**: Lọc danh sách theo `owner_id` đối với `USER` và kiểm tra 403 khi GET/PUT/DELETE.
6. **`backend/app/api/v1/dashboard.py`**: Lọc KPI và Heatmap theo `user_farm_ids` đối với `USER`.

---

## 10. Files KHÔNG Sửa (Strict Lock Status)

- 🔒 **Database:** MongoDB Schemas, Collections, Indexing, Seed, Migration scripts (`backend/seed_demo.py`, `database/*`).
- 🔒 **API Contract:** DTOs, Pydantic Schemas, URL Endpoints, JSON Request/Response structures.
- 🔒 **Design System:** Utility classes, Colors, Fonts, Spacing, Shared UI Components (`Card`, `KPICard`, `Button`).
- 🔒 **Core AI & Inspection Logic:** Algorithms, detection pipelines, disease history formats.

---

## 11. Regression Risk & Mitigation (Quản lý Rủi ro)

| Rủi ro | Nguyên nhân | Biện pháp khắc phục (Mitigation) |
|---|---|---|
| **Admin mất quyền truy cập** | Đổi tên role trong JWT làm sai lệch mã hóa. | Bảo lưu tài khoản Admin `bao@gmail.com` với role `admin` cố định. |
| **USER có 0 Farm bị lỗi Dashboard** | Khi USER mới tạo chưa có farm nào, Dashboard nhận mảng rỗng. | Xử lý `EmptyState` hiển thị thông báo "Chưa có trang trại nào" thay vì ném ngoại lệ. |
| **Lỗi Route Bypass** | Người dùng gõ trực tiếp `/users` trên thanh địa chỉ. | Route Guard trên Frontend chuyển hướng ngay về `/dashboard`, Backend kiểm tra 403 ở tất cả Endpoint. |

---

## 12. LOCK STATUS SUMMARY

- **DATABASE:** 🔒 LOCKED
- **API CONTRACT:** 🔒 LOCKED
- **DESIGN SYSTEM:** 🔒 LOCKED
- **UI STRUCTURE:** 🟡 PARTIAL (Show/Hide Menu, Routes, Buttons per Role)

---

**KẾT LUẬN:** Đã lập xong toàn bộ Kế hoạch Triển khai Phân quyền 2 Role (Admin/User). **KHÔNG CÓ CODE NÀO BỊ THAY ĐỔI**. Đang chờ phê duyệt (Approval) từ bạn để tiến hành thi hành code ở bước tiếp theo.
