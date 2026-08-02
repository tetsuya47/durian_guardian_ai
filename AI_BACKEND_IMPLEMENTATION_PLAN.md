# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 3 — BACKEND IMPLEMENTATION PLAN
- **Agent:** Antigravity IDE
- **Mode:** STRICT IMPLEMENTATION PLANNING (READ ONLY)
- **Date:** 2026-08-02

---

# Files To Modify

| File Path | Role in Architecture | Reason for Change | Impact Level |
|---|---|---|:---:|
| `backend/app/ai/service.py` | Orchestration Service | Triển khai Workflow AI chính thức 7 bước đồng bộ đa collection. | **HIGH** |
| `backend/app/repositories/inspection_repository.py` | Data Repository | Thêm/cập nhật hỗ trợ vòng đời status `PROCESSING` $\rightarrow$ `COMPLETED` / `FAILED`. | **MEDIUM** |
| `backend/app/repositories/detection_result_repository.py` | Data Repository | Đảm bảo method `create()` lưu chi tiết chẩn đoán AI vào `detection_results`. | **LOW** |
| `backend/app/repositories/tree_repository.py` | Data Repository | Cập nhật method `update()` hỗ trợ `health_status`, `risk_score`, `last_inspection`. | **MEDIUM** |
| `backend/app/repositories/alert_repository.py` | Data Repository | Đảm bảo method `create()` hỗ trợ tự động tạo cảnh báo khi `severity == "high"`. | **LOW** |

---

# Repository Usage

1. **`InspectionRepository`** (`backend/app/repositories/inspection_repository.py`)
2. **`DetectionResultRepository`** (`backend/app/repositories/detection_result_repository.py`)
3. **`TreeRepository`** (`backend/app/repositories/tree_repository.py`)
4. **`DiseaseRepository`** (`backend/app/repositories/disease_repository.py`)
5. **`AlertRepository`** (`backend/app/repositories/alert_repository.py`)

---

# Dependency Order

Thứ tự chỉnh sửa file backend theo đúng phụ thuộc kiến trúc:

```text
1. backend/app/repositories/inspection_repository.py
   └─ Khai báo các method tạo Inspection (PROCESSING) & cập nhật status (COMPLETED/FAILED)

2. backend/app/repositories/detection_result_repository.py
   └─ Khai báo method create() ghi kết quả chẩn đoán chi tiết

3. backend/app/repositories/tree_repository.py
   └─ Cập nhật method update() ghi nhận health_status, risk_score, last_inspection

4. backend/app/repositories/disease_repository.py
   └─ Khai báo/xác nhận method create() ghi Audit Log

5. backend/app/repositories/alert_repository.py
   └─ Khai báo/xác nhận method create() sinh cảnh báo khi severity == "high"

6. backend/app/ai/service.py
   └─ Phối hợp toàn bộ các Repository theo đúng chuỗi 7 bước AI Workflow chính thức
```

---

# Service Call Graph

```text
AIService.detect_disease(tree_id, file_bytes, filename)
  │
  ├── 1. _analyze_quality(file_bytes)  [OpenCV Quality Check]
  │        └─ (If fails ──► Throw 400 Bad Request)
  │
  ├── 2. InspectionRepository.create()
  │        └─ status = "PROCESSING", health_status = "Đang theo dõi", predicted_disease = "Đang xử lý"
  │
  ├── 3. DiseasePredictor.predict(file_bytes)  [PyTorch EfficientNet-B0 Inference]
  │
  ├── 4. Save image file to disk (/uploads/{uuid}.jpg)
  │
  ├── 5. DetectionResultRepository.create()
  │        └─ Ghi chi tiết prediction, confidence, image_path
  │
  ├── 6. TreeRepository.update()
  │        └─ Cập nhật health_status, risk_score, last_inspection, updated_at
  │
  ├── 7. DiseaseRepository.create()
  │        └─ Ghi vết Audit Log không thay đổi vào disease_history
  │
  ├── 8. [Condition: severity == 'high'] AlertRepository.create()
  │        └─ Tự động tạo cảnh báo nguy cơ cao vào alerts
  │
  └── 9. InspectionRepository.update()
           └─ On Success: status = "COMPLETED", health_status, predicted_disease, confidence
           └─ On Failure: status = "FAILED", error_message = str(exc)
```

---

# Repository Call Graph

Danh sách method chính xác sẽ được gọi từ từng Repository:

- `InspectionRepository.create(inspection_data)`
- `DetectionResultRepository.create(detection_data)`
- `TreeRepository.update(tree_id, update_data)`
- `DiseaseRepository.create(disease_history_data)`
- `AlertRepository.create(alert_data)`
- `InspectionRepository.update(inspection_id, update_data)`

---

# Implementation Phases

- **Phase 1: Inspection Lifecycle Implementation**
  - Khởi tạo lượt kiểm tra với `status="PROCESSING"` ngay khi qua Quality Check.
  - Cập nhật lượt kiểm tra sang `status="COMPLETED"` khi thành công hoặc `status="FAILED"` khi lỗi.
- **Phase 2: AI Detection Result Insertion**
  - Lưu kết quả suy luận AI chi tiết (`prediction`, `confidence`, `image_path`) vào `detection_results`.
- **Phase 3: Tree Status & Risk Score Update**
  - Đồng bộ kết quả AI sang `trees`: cập nhật `health_status`, `risk_score` (10/40/70/90) và `last_inspection`.
- **Phase 4: Disease History Audit Log**
  - Ghi bản ghi Audit Log bất biến vào `disease_history`.
- **Phase 5: High-Risk Alert Auto-Generation**
  - Tự động kiểm tra `severity == "high"` và tạo bản ghi cảnh báo trong `alerts`.

---

# Rollback Strategy

- **Nếu Phase 1 thất bại (Quality Check/Initialization Error):**
  - Catch exception, ném `400 Bad Request` hoặc `500 Server Error`, **0% dữ liệu bị ghi vào cơ sở dữ liệu**.
- **Nếu Phase 2 - 5 thất bại (Lỗi AI Inference / Lỗi Ghi DB):**
  - Catch exception trong khối `try/except`.
  - Thực hiện gọi:
    `InspectionRepository.update(inspection_id, status="FAILED", error_message=str(exc))`
  - Giữ lại bản ghi `Inspection` với trạng thái `FAILED` để phục vụ audit vết hoạt động người dùng. KHÔNG xóa dữ liệu hay dùng rollback phá hủy.

---

# Regression Risk

| Phase | Description | Risk Level | Mitigation Strategy |
|---|---|:---:|---|
| **Phase 1** | Inspection Lifecycle Status | **LOW** | Kiểm soát enum status chuẩn (`PROCESSING`, `COMPLETED`, `FAILED`). |
| **Phase 2** | Detection Result Insert | **LOW** | Ghi độc lập vào collection `detection_results`. |
| **Phase 3** | Tree Status & Risk Update | **MEDIUM** | Kiểm tra kỹ validation schema của `trees`, chỉ update field cho phép. |
| **Phase 4** | Disease History Audit Log | **LOW** | Ghi append-only vào `disease_history`. |
| **Phase 5** | High-Risk Alert Auto-Gen | **LOW** | Bọc trong điều kiện `if severity == 'high'`, không làm gián đoạn API chính. |

---

# Verification Checklist

Sau khi thực hiện coding ở bước tiếp theo, tiến hành kiểm tra theo danh sách:

- [ ] Lượt kiểm tra `inspections` được tạo ban đầu với `status = "PROCESSING"`.
- [ ] Ảnh được lưu thành công vào thư mục `/uploads/` với UUID không trùng lặp.
- [ ] Bản ghi `detection_results` được tạo với thông số AI chính xác (`model`, `prediction`, `confidence`, `image_path`).
- [ ] Master Data `trees` được cập nhật đúng `health_status`, `risk_score` và `last_inspection`.
- [ ] Bản ghi Audit Log `disease_history` được tạo đầy đủ.
- [ ] Cảnh báo `alerts` được tự động tạo khi `severity == "high"`.
- [ ] Lượt kiểm tra `inspections` được cập nhật kết quả cuối cùng với `status = "COMPLETED"`.
- [ ] Nếu cố tình truyền ảnh lỗi/gây ngoại lệ DB, lượt kiểm tra `inspections` cập nhật `status = "FAILED"` và lưu `error_message`.
- [ ] Dashboard tự động phản ánh dữ liệu mới thời gian thực (KPI, Heatmap, Recent Activity, Alerts).

---

# Files Modified

**NONE**

---

# Final Status

**IMPLEMENTATION PLAN COMPLETE**
