# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 3.1 — PRE-IMPLEMENTATION AUDIT
- **Agent:** Antigravity IDE
- **Mode:** STRICT PRE-CODING AUDIT (READ ONLY)
- **Date:** 2026-08-02

---

# Repository Audit

Tất cả các repository đều kế thừa từ `BaseRepository` (`backend/app/repositories/base.py`):

| Repository Class | Method `create()` | Method `update()` | Trạng thái Audit |
|---|:---:|:---:|:---:|
| **`InspectionRepository`** | **FOUND** (BaseRepository) | **FOUND** (BaseRepository) | Sẵn sàng sử dụng |
| **`DetectionResultRepository`** | **FOUND** (BaseRepository) | **FOUND** (BaseRepository) | Sẵn sàng sử dụng |
| **`TreeRepository`** | **FOUND** (BaseRepository) | **FOUND** (BaseRepository) | Sẵn sàng sử dụng |
| **`DiseaseRepository`** | **FOUND** (BaseRepository) | **FOUND** (BaseRepository) | Sẵn sàng sử dụng |
| **`AlertRepository`** | **FOUND** (BaseRepository) | **FOUND** (BaseRepository) | Sẵn sàng sử dụng |

---

# Service Audit

Kiểm tra `backend/app/ai/service.py` - Lớp `AIService`:

- **Repository đang được khởi tạo trong `__init__`:**
  - `self.disease_repo = DiseaseRepository(db)` (**FOUND**)
  - `self.tree_repo = TreeRepository(db)` (**FOUND**)
- **Repository chưa được khởi tạo trong `__init__` (Cần bổ sung ở STEP 4):**
  - `self.inspection_repo = InspectionRepository(db)` (**NOT YET INJECTED**)
  - `self.detection_result_repo = DetectionResultRepository(db)` (**NOT YET INJECTED**)
  - `self.alert_repo = AlertRepository(db)` (**NOT YET INJECTED**)

---

# Dependency Audit

- **Constructor Injection:** `AIService(db)` nhận `AsyncIOMotorDatabase`.
- **FastAPI Router Dependency Injection:**
  - `user_id: str = Depends(get_current_user_id)` (**FOUND**)
  - `db: AsyncIOMotorDatabase = Depends(get_database)` (**FOUND**)
- **Dependency Flow:** Hợp lệ, chuẩn kiến trúc FastAPI & Motor Async.

---

# Processing Time Audit

- **Kiểm tra `processing_time_ms` trong `detect_disease()`:**
  - Hiện tại: `inference_time_ms = 120.0` (Dòng 202 `service.py`).
  - Đánh giá: **NOT IMPLEMENTED (HARDCODED)**.
  - Cần thay thế bằng phép đo thời gian thực tế `time.perf_counter()` ở STEP 4.

---

# Dashboard Dependency

- **Cơ sở dữ liệu Dashboard hiện đang đọc:**
  - **`trees`**: **FOUND** (Dùng cho KPI Cards & Heatmap Grid)
  - **`inspections`**: **FOUND** (Dùng cho Recent Activity Widget)
  - **`alerts`**: **FOUND** (Dùng cho Cảnh báo nguy cơ cao & Panel Đánh Giá Vườn)
  - **`detection_results`**: **NOT FOUND** (Dashboard không đọc trực tiếp `detection_results`, đọc qua `inspections`)

---

# API Contract

- **Endpoint:** `POST /api/v1/ai/detect`
- **Request:** Form-Data (`tree_id: str`, `file: UploadFile`)
- **Response Model:** `SuccessResponse[DetectionResponse]`
- **Đánh giá:** **API CONTRACT STABLE** (Không cần thay đổi request/response schema).

---

# Implementation Readiness

| Hạng mục Kiểm tra | Trạng thái |
|---|:---:|
| **Repository Ready** | **YES** |
| **Service Ready** | **YES** |
| **API Ready** | **YES** |
| **Dashboard Ready** | **YES** |
| **Overall Ready** | **YES** |

---

# Files Modified

**NONE**

---

# Final Status

**READY FOR STEP 4**
