# Scope

- **Release:** 1.4.0
- **Step:** STEP 1 — AUTHORIZATION AUDIT
- **Date:** 2026-08-02

---

# LOCK STATUS

- **Database:** 🔒 LOCKED (No schema/index/validator modifications)
- **Backend:** 🔒 LOCKED (No service/repository/route logic modifications)
- **Frontend:** 🔒 LOCKED (No component/router/style modifications)
- **API:** 🔒 LOCKED (No contract/DTO/endpoint modifications)
- **Routes:** 🔒 LOCKED (No route guard/navigation modifications)

---

# Authentication Audit

- **Login Flow:**
  - Route: `POST /api/v1/auth/login` (`app/api/v1/auth.py`)
  - Logic: `AuthService.login()` verifies user email and checks `password_hash` via `verify_password()` (`app/auth/service.py`).
  - Result: Generates JWT `access_token` and `refresh_token`, saves `refresh_token` to DB user document.
- **JWT Creation:**
  - File: `app/core/security.py`
  - Function: `create_access_token(sub, role)` embeds `sub` (User ID) and `role` (DB Role string) into JWT payload.
  - Expiry: Configured via `ACCESS_TOKEN_EXPIRE_MINUTES`.
- **JWT Decode:**
  - File: `app/core/security.py`
  - Function: `decode_token(token)` decodes JWT payload using `SECRET_KEY` and `ALGORITHM="HS256"`.
- **Current User Dependency:**
  - File: `app/core/dependencies.py`
  - Function: `get_current_user_id(credentials)` extracts `sub` claim from Bearer token header. Returns `user_id` string. Raises `401 Unauthorized` if missing/invalid.
  - Function: `get_current_user_role(credentials)` extracts `role` claim from Bearer token header. Maps DB role string to API enum value via `db_role_to_api()`.
- **Refresh Token Flow:**
  - Route: `POST /api/v1/auth/refresh` (`app/api/v1/auth.py`)
  - Logic: `AuthService.refresh()` decodes refresh token, validates against DB stored `refresh_token`, generates new token pair.
- **Logout Flow:**
  - Route: `POST /api/v1/auth/logout` (`app/api/v1/auth.py`)
  - Logic: `AuthService.logout()` clears stored `refresh_token` in DB user document.
- **Password Hash:**
  - File: `app/core/security.py`
  - Implementation: Uses `passlib.context.CryptContext(schemes=["bcrypt"])` for hashing and verification.
- **Authentication Middleware:**
  - CORS middleware is configured in `app/main.py`.
  - Authentication is handled per-route via `FastAPI` dependency injection (`Depends(get_current_user_id)`).

---

# User Model Audit

- **User Schema (Pydantic):**
  - File: `app/schemas/user.py`
  - Models: `UserRegister`, `UserLogin`, `UserOut`, `UserProfileUpdate`, `TokenOut`, `TokenRefresh`, `ChangePassword`.
- **User Entity & Collection:**
  - Collection: `users` in MongoDB database `durian_guardian`.
  - Fields in DB document: `_id`, `id`, `user_code`, `full_name`, `email`, `password_hash`, `role`, `refresh_token`, `created_at`, `updated_at`.
- **Field Audit Results:**
  - `role`: **FOUND** (Stores DB role string e.g. `'Admin'`, `'Farm Owner'`, `'Inspector'`, `'Technician'`).
  - `permissions`: **NOT FOUND** (No permissions array or ACL list in User entity).
  - `company_id`: **NOT FOUND** (User document does not contain `company_id` reference).
  - `farm_id`: **NOT FOUND** (User document does not contain explicit `farm_id` reference; farms reference user via `owner_id`).
  - `owner_id`: **NOT FOUND** (Not present in User document; present in Farm document as `owner_id`).
  - `assignment`: **NOT FOUND** (No assignment mapping collection or field).

---

# Current Roles

- **Role Definitions in Code:**
  - File: `app/models/enums.py`
  - Enum Class: `UserRole(str, enum.Enum)`:
    - `farmer = "farmer"`
    - `field_technician = "field_technician"`
    - `farm_manager = "farm_manager"`
    - `enterprise_admin = "enterprise_admin"`
- **DB ↔ API Mapping (`_DB_TO_API_ROLE`):**
  - `'Admin'` $\rightarrow$ `enterprise_admin`
  - `'Company Manager'` $\rightarrow$ `farm_manager`
  - `'Farm Manager'` $\rightarrow$ `farm_manager`
  - `'Inspector'` $\rightarrow$ `field_technician`
  - `'Technician'` $\rightarrow$ `farmer`
  - `'Farm Owner'` $\rightarrow$ `farmer`
- **Role Usage Locations:**
  - `app/api/v1/*.py`: `allow_all = RoleChecker([r.value for r in UserRole])` is applied to every single route.
  - Effective behavior: All authenticated users currently pass all role checks across all routes.

---

# Dependency Audit

- `get_current_user`: **NOT FOUND** (Only `get_current_user_id` returning `str` exists).
- `get_current_active_user`: **NOT FOUND**.
- `require_admin`: **NOT FOUND** (Only generic `RoleChecker` exists; currently initialized with all roles `[r.value for r in UserRole]`).
- `verify_permission`: **NOT FOUND**.
- `ownership`: **NOT FOUND** (No dependency or helper function checking resource ownership against `current_user_id`).
- `permission helper`: **NOT FOUND**.

---

# Sidebar Audit

- File: `frontend/src/components/layout/Sidebar.tsx`
- Navigation Menu Items:

| Label | Path | File | Role Condition Check |
|---|---|---|:---:|
| **Bảng điều khiển** | `/dashboard` | `Sidebar.tsx` (L.31) | **None** (Visible to all) |
| **Công ty** | `/companies` | `Sidebar.tsx` (L.32) | **None** (Visible to all) |
| **Trang trại** | `/farms` | `Sidebar.tsx` (L.33) | **None** (Visible to all) |
| **Khu vực** | `/zones` | `Sidebar.tsx` (L.34) | **None** (Visible to all) |
| **Cây** | `/trees` | `Sidebar.tsx` (L.35) | **None** (Visible to all) |
| **Người dùng** | `/users` | `Sidebar.tsx` (L.36) | **None** (Visible to all) |
| **Kiểm tra** | `/inspections` | `Sidebar.tsx` (L.37) | **None** (Visible to all) |
| **Kết quả nhận diện** | `/detection-results` | `Sidebar.tsx` (L.38) | Hidden by `HIDDEN_MENU_PATHS` |
| **Lịch sử phát sinh bệnh** | `/disease-history` | `Sidebar.tsx` (L.39) | **None** (Visible to all) |
| **Cảnh báo** | `/alerts` | `Sidebar.tsx` (L.40) | **None** (Visible to all) |
| **Bệnh** | `/diseases` | `Sidebar.tsx` (L.41) | Hidden by `HIDDEN_MENU_PATHS` |

---

# Routes Audit

- File: `frontend/src/routes/index.tsx` & `frontend/src/routes/ProtectedRoute.tsx`

- **React Routes:** Defined via `createBrowserRouter`.
- **Protected Route:** `ProtectedRoute` checks `isAuthenticated` via `useAuth()`. If false, redirects to `/login`.
- **Public Routes:** `/login`, `/register`.
- **Private Routes:** All child routes under `/` wrapped in `ProtectedRoute`.
- **Admin Route:** **NOT FOUND**.
- **Role Route:** **NOT FOUND** (No role-based guard or permission checking on any frontend route).

---

# API Authorization Audit

| API Endpoint | HTTP Method | Authentication | Role Check | Ownership Check |
|---|:---:|:---:|:---:|:---:|
| `/api/v1/auth/login` | POST | Public | None | None |
| `/api/v1/auth/register` | POST | Public | None | None |
| `/api/v1/auth/me` | GET | `get_current_user_id` | None | Self (`user_id`) |
| `/api/v1/companies` | GET | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/companies/{id}` | GET/PUT/DELETE | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/users` | GET | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/users/{id}` | GET/PUT/DELETE | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/farms` | GET/POST | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/farms/{id}` | GET/PUT/DELETE | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/zones` | GET/POST | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/zones/{id}` | GET/PUT/DELETE | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/trees` | GET/POST | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/trees/{id}` | GET/PUT/DELETE | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/inspections` | GET/POST | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/inspections/{id}` | GET/PUT/DELETE | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/disease-history` | GET | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/alerts` | GET | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/dashboard/kpi` | GET | `get_current_user_id` | `RoleChecker(All)` | None |
| `/api/v1/dashboard/heatmap` | GET | `get_current_user_id` | `RoleChecker(All)` | None |

---

# CRUD Authorization Audit

| Module | Create Check | Read Check | Update Check | Delete Check | Current Permission Enforcement Location |
|---|:---:|:---:|:---:|:---:|---|
| **Companies** | All Users | All Users | All Users | All Users | `app/api/v1/companies.py` (`RoleChecker` allows all roles) |
| **Users** | All Users | All Users | All Users | All Users | `app/api/v1/users.py` (`RoleChecker` allows all roles) |
| **Farms** | All Users | All Users | All Users | All Users | `app/api/v1/farms.py` (`RoleChecker` allows all roles) |
| **Zones** | All Users | All Users | All Users | All Users | `app/api/v1/zones.py` (`RoleChecker` allows all roles) |
| **Trees** | All Users | All Users | All Users | All Users | `app/api/v1/trees.py` (`RoleChecker` allows all roles) |
| **Inspections** | All Users | All Users | All Users | All Users | `app/api/v1/inspections.py` (`RoleChecker` allows all roles) |
| **Alerts** | N/A | All Users | N/A | N/A | `app/api/v1/alerts.py` (`RoleChecker` allows all roles) |
| **Disease History**| N/A | All Users | N/A | N/A | `app/api/v1/disease_history.py` (`RoleChecker` allows all roles) |

---

# Dashboard Audit

- **Dashboard Page:** `frontend/src/pages/dashboard/Dashboard.tsx`
- **Dashboard Data Behavior:** **GLOBAL DATA** (Returns system-wide metrics for all users regardless of role).
- **Widget Details:**

| Widget | API Endpoint | Repository | Service | Current Filter | Ownership Check |
|---|---|---|---|---|:---:|
| **KPI Section** | `/api/v1/dashboard/kpi` | `TreeRepository`, `InspectionRepository` | `DashboardService` | Optional `farm_id` query param | **GLOBAL DATA** |
| **Heatmap Grid** | `/api/v1/dashboard/heatmap` | `ZoneRepository`, `TreeRepository` | `DashboardService` | Optional `farm_id`, `zone_id` | **GLOBAL DATA** |
| **Tree Distribution** | `/api/v1/dashboard/kpi` | `TreeRepository` | `DashboardService` | Optional `farm_id` query param | **GLOBAL DATA** |
| **Farm Performance** | `/api/v1/dashboard/performance` | `FarmRepository` | `DashboardService` | Optional `farm_id` query param | **GLOBAL DATA** |
| **Recent Activity** | `/api/v1/inspections` | `InspectionRepository` | `InspectionService` | Optional `farm_id` query param | **GLOBAL DATA** |

---

# Ownership Audit

- **Backend Field Search for Ownership:**
  - `owner_id`: **FOUND** (Present in `farms` collection e.g. `farm["owner_id"]`).
  - `farm_id`: **FOUND** (Present in `zones`, `trees`, `inspections`, `alerts` collections).
  - `company_id`: **FOUND** (Present in `farms` collection e.g. `farm["company_id"]`).
  - `assignment`: **NOT FOUND**.
  - `relation`: **NOT FOUND**.
- **Current Enforcement State:**
  - Backend services accept `user_id` as a parameter in several list methods (e.g. `FarmService.list_farms(user_id, ...)`), but repository queries currently do not enforce `owner_id == user_id` strictly for read/update/delete operations.
  - Ownership filtering is **PARTIAL**.

---

# Frontend Authorization Audit

- **Hidden Menu by Role:** **NOT FOUND** (All items in `Sidebar.tsx` except internal hidden paths are visible to every user).
- **Hidden Button by Role:** **NOT FOUND** (Create, Edit, Delete buttons are rendered for all authenticated users).
- **Route Guard by Role:** **NOT FOUND** (`ProtectedRoute.tsx` only checks authentication status `isAuthenticated`).
- **JWT Decode Location:**
  - File: `frontend/src/services/base.service.ts` / `frontend/src/auth/`
  - Token is stored in `localStorage` (`access_token`).
- **User Context Location:**
  - File: `frontend/src/context/AuthContext.tsx` or `useAuth` hook. Stores user profile object returned from `/api/v1/auth/me`.

---

# Findings

- **Authentication Flow:** **FOUND**
- **User Model Role Field:** **FOUND**
- **User Permissions Array:** **NOT FOUND**
- **User Company/Farm Assignment Fields:** **NOT FOUND**
- **Current Role Definitions:** **FOUND**
- **Generic RoleChecker:** **FOUND**
- **`require_admin` Dependency:** **NOT FOUND**
- **`get_current_user` Object Dependency:** **NOT FOUND**
- **`verify_permission` Helper:** **NOT FOUND**
- **Ownership Verification Helper:** **NOT FOUND**
- **Sidebar Menu Role Filtering:** **NOT FOUND**
- **Frontend Route Guard by Role:** **NOT FOUND**
- **Frontend Button Hiding by Role:** **NOT FOUND**
- **API Role Enforcement:** **PARTIAL** (All routes use `RoleChecker(All)`).
- **API Ownership Enforcement:** **PARTIAL** (`farms` has `owner_id`, but enforcement in repositories is incomplete).
- **Dashboard Scope Filter:** **GLOBAL DATA**

---

# Files Scanned

1. `backend/app/main.py`
2. `backend/app/api/v1/__init__.py`
3. `backend/app/api/v1/auth.py`
4. `backend/app/api/v1/companies.py`
5. `backend/app/api/v1/users.py`
6. `backend/app/api/v1/farms.py`
7. `backend/app/api/v1/zones.py`
8. `backend/app/api/v1/trees.py`
9. `backend/app/api/v1/inspections.py`
10. `backend/app/api/v1/disease_history.py`
11. `backend/app/api/v1/alerts.py`
12. `backend/app/api/v1/dashboard.py`
13. `backend/app/auth/service.py`
14. `backend/app/core/dependencies.py`
15. `backend/app/core/security.py`
16. `backend/app/models/enums.py`
17. `backend/app/schemas/user.py`
18. `backend/app/schemas/user_crud.py`
19. `frontend/src/routes/index.tsx`
20. `frontend/src/routes/ProtectedRoute.tsx`
21. `frontend/src/components/layout/Sidebar.tsx`
22. `frontend/src/pages/dashboard/Dashboard.tsx`
23. `frontend/src/pages/companies/Companies.tsx`
24. `frontend/src/pages/users/Users.tsx`

---

# Files Modified

**NONE**

---

# Final Status

**AUDIT COMPLETE**
