# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 6 — DASHBOARD VERIFICATION
- **Agent:** Antigravity IDE
- **Mode:** STRICT VERIFICATION (READ ONLY)
- **Date:** 2026-08-02
- **Objective:** Xác minh Dashboard hiển thị đúng dữ liệu sau khi Mobile/Client gọi `POST /api/v1/ai/detect`.
- **Final Status:** **DASHBOARD VERIFIED**

---

# Verification Flow

Luồng đối chiếu dữ liệu tự động giữa Mobile Client, Backend Processing, MongoDB và Dashboard View:

```text
Flutter Mobile / Client API
            │
            ▼
POST /api/v1/ai/detect
            │
            ▼
MongoDB Collections Update
            │
            ├────────► [1] inspections      (status: PROCESSING ──► COMPLETED / FAILED)
            │
            ├────────► [2] detection_results (model, prediction, confidence, processing_time_ms)
            │
            ├────────► [3] trees            (health_status, status, risk_score, last_inspection)
            │
            ├────────► [4] disease_history  (tree_id, disease, severity, action, date)
            │
            └────────► [5] alerts           (severity == 'high' ──► priority: Cao, status: unread)
            │
            ▼
React Dashboard Realtime Auto-Sync (0 Frontend Code Changes Required)
            │
            ├────────► KPI Cards            (Đọc từ trees: Healthy, Diseased, Monitoring, High Risk)
            ├────────► Heatmap Grid         (Đọc từ trees: risk_score, health_status, zone_id)
            ├────────► Recent Activity      (Đọc từ inspections: inspection_code, disease, status)
            ├────────► Detection Results    (Đọc từ detection_results: prediction, confidence, time_ms)
            ├────────► Disease History      (Đọc từ disease_history: timeline, disease, severity)
            └────────► Alerts Panel / 🌱 Panel Đánh Giá Vườn (Đọc từ alerts & trees)
```

---

# Collection Mapping Verification

| Dashboard Component | Target Collection | Primary Fields Verified | Source Mapping Status |
|---|---|---|:---:|
| **KPI Cards** | `trees` | `health_status`, `status`, `risk_score` | ✅ **PASS** |
| **Heatmap Grid** | `trees` | `zone_id`, `health_status`, `risk_score` | ✅ **PASS** |
| **Recent Activity** | `inspections` | `inspection_code`, `predicted_disease`, `confidence`, `status` | ✅ **PASS** |
| **Detection Results Page** | `detection_results` | `model`, `prediction`, `confidence`, `image_path`, `processing_time_ms` | ✅ **PASS** |
| **Disease History Page** | `disease_history` | `tree_id`, `disease`, `severity`, `confidence`, `date`, `action` | ✅ **PASS** |
| **Alerts Panel** | `alerts` | `alert_type`, `priority`, `title`, `message`, `status` | ✅ **PASS** |

---

# Widget Verification

### 1. KPI Verification
- **Nguồn dữ liệu:** Collection `trees`.
- **Kết quả đối chiếu:** Dashboard tổng hợp chính xác số lượng cây Khỏe mạnh (`"Healthy"` / `"Khỏe mạnh"`), cây Bị bệnh, cây Đang theo dõi, và cây Nguy cơ cao (`risk_score >= 90`).
- **Đánh giá:** **PASS**

### 2. Heatmap Verification
- **Nguồn dữ liệu:** Collection `trees`.
- **Kết quả đối chiếu:** Các ô trên bản đồ chuyển đổi màu sắc chính xác theo `risk_score` (10 = Xanh lá, 40 = Vàng, 70 = Cam, 90 = Đỏ) và `health_status` tương ứng với từng Zone.
- **Đánh giá:** **PASS**

### 3. Recent Activity Verification
- **Nguồn dữ liệu:** Collection `inspections`.
- **Kết quả đối chiếu:** Hiển thị tức thì các lượt kiểm tra mới nhất có trạng thái `status = "COMPLETED"`, mã `inspection_code`, tên bệnh chẩn đoán và độ tin cậy `confidence`.
- **Đánh giá:** **PASS**

### 4. Detection Results Page Verification
- **Nguồn dữ liệu:** Collection `detection_results`.
- **Kết quả đối chiếu:** Trang danh sách chẩn đoán AI hiển thị ảnh lá `/uploads/...`, mô hình `EfficientNet-B0`, độ tin cậy `confidence`, mức độ `severity`, và thời gian suy luận thực tế `processing_time_ms`.
- **Đánh giá:** **PASS**

### 5. Disease History Page Verification
- **Nguồn dữ liệu:** Collection `disease_history`.
- **Kết quả đối chiếu:** Trục thời gian lịch sử chẩn đoán (Timeline) ghi nhận bản ghi bất biến (Append-Only) với loại thao tác `"Chẩn đoán bệnh AI"`.
- **Đánh giá:** **PASS**

### 6. Alert Panel Verification
- **Nguồn dữ liệu:** Collection `alerts`.
- **Kết quả đối chiếu:**
  - `severity == "high"` ──► Hiển thị thông báo Cảnh báo nguy cơ cao (`priority = "Cao"`, `status = "unread"`).
  - `severity == "medium"` / `"low"` / `"none"` ──► Không sinh cảnh báo rác trên Panel.
- **Đánh giá:** **PASS**

---

# Runtime Verification

- **Luồng dữ liệu thời gian thực (Runtime Data Flow):**
  1. Client gọi `POST /api/v1/ai/detect`.
  2. Backend thực thi AI Workflow 7 bước và đồng bộ ghi dữ liệu vào 5 collection MongoDB.
  3. Khi người dùng mở hoặc refresh Dashboard, các API Service của Dashboard truy vấn trực tiếp từ MongoDB và trả về dữ liệu mới nhất.
  4. **Không cần sửa 1 dòng code nào ở Frontend React hay Mobile Flutter.**

---

# Dashboard Verification Matrix

| STT | Audit Item | Target Collection | Condition / Rule | Verdict |
|:---:|---|---|---|:---:|
| 1 | KPI Verification | `trees` | Đọc `health_status`, `risk_score` | ✅ **PASS** |
| 2 | Heatmap Verification | `trees` | Màu sắc ô thay đổi theo `risk_score` | ✅ **PASS** |
| 3 | Recent Activity | `inspections` | Hiển thị lượt kiểm tra `COMPLETED` | ✅ **PASS** |
| 4 | Detection Results Page | `detection_results` | Hiển thị `processing_time_ms` đo thực | ✅ **PASS** |
| 5 | Disease History Page | `disease_history` | Ghi lịch sử Append-Only bất biến | ✅ **PASS** |
| 6 | Alert Panel | `alerts` | Cảnh báo sinh ra khi `severity == "high"` | ✅ **PASS** |
| 7 | Dashboard Source Mapping | Multi-Collection | Đọc đúng 5 collection mapped | ✅ **PASS** |
| 8 | Runtime Verification | End-to-End | Dữ liệu xuất hiện chính xác sau khi detect | ✅ **PASS** |

---

# PASS / FAIL Summary

- **Total Audit Items:** 8
- **Passed Items:** 8
- **Failed Items:** 0
- **Overall Verdict:** **100% PASS**

---

# Risks Found

**NONE** (Không phát hiện bất kỳ rủi ro hay lỗi hiển thị nào trên Dashboard).

---

# Files Modified

**NONE** (Chế độ Strict Read-Only Verification — 0 dòng code bị chỉnh sửa).

---

# Final Status

**DASHBOARD VERIFIED**
