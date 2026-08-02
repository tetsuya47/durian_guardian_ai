# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 2 — AI DATABASE MAPPING
- **Agent:** Antigravity IDE
- **Mode:** STRICT DATABASE MAPPING (READ ONLY)
- **Date:** 2026-08-02

---

# Collection Mapping

### STEP 1: Inspection (`inspections`)
- **Collection Name:** `inspections`
- **Source of Truth:** Backend Inspection Lifecycle (`status="PROCESSING"` $\rightarrow$ `status="COMPLETED"` / `status="FAILED"`).
- **Read Operations:**
  - Query latest inspection by `tree_id` or `farm_id`.
  - Query recent inspection list for Dashboard Recent Activity widget.
- **Create Operations:**
  - Invoked immediately when Quality Check passes (`status="PROCESSING"`).
  - Fields set: `inspection_code`, `tree_id`, `farm_id`, `zone_id`, `inspection_date`, `health_status` (`"Đang theo dõi"`), `predicted_disease` (`"Đang xử lý"`), `confidence` (`0.0`), `status` (`"PROCESSING"`), `created_at`.
- **Update Operations:**
  - Invoked upon completion or failure of AI inference.
  - On Success: Set `status="COMPLETED"`, `health_status` (`"Khỏe mạnh"` / `"Bị bệnh"`), `predicted_disease` (`disease_vi`), `confidence` (`confidence * 100`), `severity`, `remark`, `updated_at`.
  - On Failure: Set `status="FAILED"`, `error_message`, `updated_at`.

---

### STEP 2: AI Detection Result (`detection_results`)
- **Collection Name:** `detection_results`
- **Source of Truth:** AI Predictor Engine output (`EfficientNet-B0`).
- **Read Operations:**
  - Fetch detailed AI diagnostic metrics by `inspection_id` or `detection_result_id`.
- **Create Operations:**
  - Created immediately after AI inference succeeds.
  - Fields set: `inspection_id`, `tree_id`, `farm_id`, `company_id`, `model` (`"EfficientNet-B0"`), `model_version` (`"1.0.0"`), `prediction` (`disease_vi`), `confidence` (`confidence * 100`), `image_path` (`/uploads/{uuid}.jpg`), `image_quality` (`"good"`), `processing_time_ms`, `recommendation`, `created_at`.
- **Update Operations:**
  - **NONE** (Bản ghi kết quả chẩn đoán chi tiết của AI là bất biến).

---

### STEP 3: Tree Update (`trees`)
- **Collection Name:** `trees`
- **Source of Truth:** Master Tree Entity (Được cập nhật trạng thái sức khỏe từ kết quả AI).
- **Fields Updated by AI Event:**
  - `health_status` / `status`: Tên bệnh tiếng Việt (ví dụ: `"Khỏe mạnh"`, `"Thán thư"`, `"Nứt thân chảy nhựa"`).
  - `risk_score`: Điểm số rủi ro tính theo severity (`none` = 10, `low` = 40, `medium` = 70, `high` = 90).
  - `last_inspection`: Timestamp thời điểm vừa chẩn đoán (`datetime.now()`).
  - `updated_at`: Timestamp cập nhật.
- **Fields NOT Updated by AI Event:**
  - `_id`, `tree_code`, `farm_id`, `zone_id`, `variety`, `planting_date`, `tree_age`, `latitude`, `longitude`, `qr_code`, `created_at`.

---

### STEP 4: Disease History (`disease_history`)
- **Collection Name:** `disease_history`
- **Source of Truth:** Immutable Audit Log (Nhật ký ghi vết chẩn đoán và điều trị theo trục thời gian).
- **Read Operations:**
  - Query timeline history of diseases per tree (`list_by_tree`).
- **Create Operations:**
  - Created for every AI scan attempt.
  - Fields set: `tree_id`, `farm_id`, `company_id`, `disease` (`disease_vi`), `date`, `action` (`"Chẩn đoán bệnh AI"`), `severity`, `confidence`, `detection_result_id`, `created_at`.
- **Update Operations:**
  - **NONE** (Bản ghi Audit Log là bất biến).

---

### STEP 5: Alert (`alerts`)
- **Collection Name:** `alerts`
- **Source of Truth:** Backend Rule Engine (Cảnh báo tự động khi nguy cơ cao).
- **Trigger Condition:**
  - Sinh ra **DUY NHẤT** khi AI chẩn đoán bệnh có `severity == "high"` (hoặc confidence $\ge 85\%$ đối với bệnh nguy hiểm như Phytophthora, thối quả, cháy thân, nứt thân chảy nhựa).
- **Create Operations:**
  - Fields set: `farm_id`, `tree_id`, `company_id`, `inspection_id`, `detection_result_id`, `alert_type` (`"Bệnh nghiêm trọng"`), `priority` (`"Cao"` / `"Rất cao"`), `title` (`"Cảnh báo bệnh nguy cơ cao"`), `message` (`"Cây " + tree_code + " phát hiện " + disease_vi`), `recommendation`, `status` (`"unread"`), `is_read` (`false`), `date`, `created_at`.
- **Lifecycle:**
  - Created (`status="unread"`) $\rightarrow$ Updated (`status="read"`, `acknowledged_by`, `acknowledged_at`) khi người dùng xác nhận trên UI.

---

# Repository Mapping

| Collection Name | Target Repository Class | File Location |
|---|---|---|
| `inspections` | `InspectionRepository` | `backend/app/repositories/inspection_repository.py` |
| `detection_results` | `DetectionResultRepository` | `backend/app/repositories/detection_result_repository.py` |
| `trees` | `TreeRepository` | `backend/app/repositories/tree_repository.py` |
| `disease_history` | `DiseaseRepository` | `backend/app/repositories/disease_repository.py` |
| `alerts` | `AlertRepository` | `backend/app/repositories/alert_repository.py` |

---

# Field Mapping

| AI Inference Output | Target Collection | Target Field | Data Type Transformation |
|---|---|---|---|
| `prediction["disease_vi"]` | `inspections` | `predicted_disease` | `string` (Tiếng Việt) |
| `prediction["confidence"]` | `inspections` | `confidence` | `float` ($0.0 \rightarrow 100.0\%$) |
| `prediction["severity"]` | `inspections` | `severity` | `string` (`none`, `low`, `medium`, `high`) |
| `prediction["disease_vi"]` | `detection_results` | `prediction` | `string` |
| `prediction["confidence"]` | `detection_results` | `confidence` | `float` ($0.0 \rightarrow 100.0\%$) |
| `prediction["disease_vi"]` | `trees` | `health_status` / `status` | `string` (`"Khỏe mạnh"` hoặc tên bệnh) |
| Risk score from severity | `trees` | `risk_score` | `int` (`10` / `40` / `70` / `90`) |
| `prediction["disease_vi"]` | `disease_history` | `disease` | `string` |
| `prediction["disease_vi"]` | `alerts` | `message` | `string` (Thông điệp cảnh báo) |

---

# Ownership Mapping

| Collection Name | Primary Owner | Write Source | Read Access |
|---|---|---|---|
| `inspections` | Backend | `AIService` (Workflow `PROCESSING` $\rightarrow$ `COMPLETED`) | Dashboard Recent Activity & Client APIs |
| `detection_results` | AI | `AIService` (PyTorch Inference Output) | Client Detail Modal & API Responses |
| `trees` | Backend | `AIService` (Cập nhật `health_status` & `risk_score`) | Dashboard KPI, Heatmap & Client APIs |
| `disease_history` | AI | `AIService` (Audit Trail Log) | Tree Timeline & Disease History Page |
| `alerts` | Backend Rule Engine | `AIService` (Tự động khi `severity == "high"`) | Dashboard Alerts Widget & Notifications |

---

# Dashboard Mapping

| Dashboard Widget | Target Collection | Primary Fields Read | Tự động cập nhật sau AI Scan |
|---|---|---|:---:|
| **KPI Cards (Khỏe mạnh, Theo dõi, Bệnh)** | `trees` | `health_status`, `status`, `risk_score` | ✅ **CÓ** (Qua Tree Update) |
| **Bản đồ giám sát (Heatmap Grid)** | `trees` | `zone_id`, `health_status`, `risk_score` | ✅ **CÓ** (Qua Tree Update) |
| **Phân bố tình trạng cây (Donut Chart)** | `trees` | `health_status`, `status` | ✅ **CÓ** (Qua Tree Update) |
| **Hoạt động kiểm tra gần đây (Recent Activity)** | `inspections` | `inspection_date`, `predicted_disease`, `confidence`, `severity`, `status` | ✅ **CÓ** (Qua Inspection Create/Update) |
| **🌱 Đánh giá vườn (Rule-Based Insights)** | `alerts`, `trees` | `priority`, `severity`, `health_status` | ✅ **CÓ** (Qua Alert Create & Tree Update) |

---

# Data Flow

```text
Upload Image Bytes + tree_id
         │
         ▼
[1] InspectionRepository.create(status="PROCESSING")
         │
         ▼
[2] AI Predictor Engine (EfficientNet-B0)
         │
         ▼
[3] DetectionResultRepository.create(inspection_id, prediction, confidence, image_path)
         │
         ▼
[4] TreeRepository.update(tree_id, health_status, risk_score)
         │
         ▼
[5] DiseaseRepository.create(tree_id, disease, action="Chẩn đoán bệnh AI")  [Audit Log]
         │
         ▼
[6] AlertRepository.create(...)  [ĐIỀU KIỆN: severity == "high"]
         │
         ▼
[7] InspectionRepository.update(inspection_id, status="COMPLETED")
         │
         ▼
Dashboard UI Refreshes Realtime Data (KPIs, Heatmap, Recent Activity, Alerts)
```

---

# Files Modified

**NONE**

---

# Final Status

**DATABASE MAPPING COMPLETE**
