# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 4.2 — DETECTION RESULT IMPLEMENTATION
- **Agent:** Antigravity IDE
- **Mode:** STRICT IMPLEMENTATION
- **Date:** 2026-08-02

---

# Files Modified

1. **`backend/app/ai/service.py`**
   - Inject `DetectionResultRepository` vào constructor `AIService.__init__`.
   - Đo thời gian suy luận AI thực tế bằng `time.perf_counter()` (loại bỏ giá trị hardcode `120.0`).
   - Ghi bản ghi mới vào collection `detection_results` ngay sau khi AI suy luận thành công.

---

# Code Summary

```python
# 1. Constructor Injection in AIService
class AIService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.disease_repo = DiseaseRepository(db)
        self.tree_repo = TreeRepository(db)
        self.inspection_repo = InspectionRepository(db)
        self.detection_result_repo = DetectionResultRepository(db)
        self._predictor = DiseasePredictor()

# 2. Real Processing Time Measurement & Detection Result Creation in detect_disease()
start_time = time.perf_counter()
prediction = quality.get("prediction")
if not prediction:
    prediction = self._predictor.predict(file_bytes)
inference_time_ms = round((time.perf_counter() - start_time) * 1000, 2)

# Save Detection Result to detection_results collection
count_det = await self.detection_result_repo.collection.count_documents({})
detection_code = f"DET{count_det + 1:05d}"

await self.detection_result_repo.create({
    "detection_code": detection_code,
    "inspection_id": ObjectId(inspection_id) if ObjectId.is_valid(inspection_id) else inspection_id,
    "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
    "farm_id": ObjectId(farm_id) if farm_id and ObjectId.is_valid(str(farm_id)) else farm_id,
    "company_id": ObjectId(company_id) if company_id and ObjectId.is_valid(str(company_id)) else company_id,
    "model": "EfficientNet-B0",
    "model_version": "1.0.0",
    "prediction": result.disease,
    "confidence": round(float(result.confidence) * 100, 2),
    "severity": result.severity,
    "image_path": rel_image_url,
    "image_quality": "good" if quality.get("passed") else "normal",
    "processing_time_ms": inference_time_ms,
    "recommendation": _build_recommendation(result.disease, result.severity),
    "created_at": datetime.now(timezone.utc),
})
```

---

# Detection Result Mapping

| Property Name | Target Document Field (`detection_results`) | Value / Source |
|---|---|---|
| `detection_code` | `detection_code` | Auto-generated (`DET00001+`) |
| `inspection_id` | `inspection_id` | `ObjectId(inspection_id)` từ Phase 1 |
| `tree_id` | `tree_id` | `ObjectId(tree_id)` |
| `farm_id` | `farm_id` | `ObjectId(farm_id)` |
| `company_id` | `company_id` | `ObjectId(company_id)` |
| `model` | `model` | `"EfficientNet-B0"` |
| `model_version` | `model_version` | `"1.0.0"` |
| `prediction` | `prediction` | `disease_vi` (Ví dụ: `"Thán thư"`, `"Khỏe mạnh"`) |
| `confidence` | `confidence` | `round(confidence * 100, 2)` ($0.0 \rightarrow 100.0\%$) |
| `severity` | `severity` | `none` \| `low` \| `medium` \| `high` |
| `image_path` | `image_path` | `/uploads/{uuid}.jpg` |
| `processing_time_ms` | `processing_time_ms` | Đã đo thực tế qua `time.perf_counter()` |
| `created_at` | `created_at` | `datetime.now(timezone.utc)` |

---

# Processing Time Measurement

- **Phương pháp đo:** Sử dụng `time.perf_counter()` bọc xung quanh khối gọi `self._predictor.predict(file_bytes)`.
- **Độ chính xác:** Làm tròn 2 chữ số thập phân (đơn vị: miligiây `ms`).
- **Giá trị Hardcode (`120.0`):** Đã loại bỏ hoàn toàn khỏi quy trình tính toán `processing_time_ms`.

---

# Verification Result

| Hạng mục Kiểm tra | Kết quả |
|---|:---:|
| **Python Syntax Check (`py_compile`)** | **PASS (0 errors)** |
| **DetectionResult Document Created** | **PASS** |
| **`inspection_id` & `tree_id` Linked Correctly** | **PASS** |
| **Confidence & Severity Mapped Correctly** | **PASS** |
| **Real Processing Time Measured (`time.perf_counter()`)** | **PASS** |
| **API Response Contract Preserved** | **PASS** |
| **Mobile & Frontend Unaffected** | **PASS** |

---

# Regression Risk

- **Risk Level:** **LOW**
- **Evaluation:** Ghi độc lập vào collection `detection_results`. Không làm ảnh hưởng đến các service khác hay hợp đồng dữ liệu của API.

---

# Final Status

**PHASE 2 COMPLETE**
