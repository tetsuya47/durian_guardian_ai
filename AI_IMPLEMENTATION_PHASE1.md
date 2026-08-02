# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 4.1 — INSPECTION LIFECYCLE IMPLEMENTATION
- **Agent:** Antigravity IDE
- **Mode:** STRICT IMPLEMENTATION
- **Date:** 2026-08-02

---

# Files Modified

1. **`backend/app/ai/service.py`**
   - Inject `InspectionRepository` vào constructor `AIService.__init__`.
   - Triển khai vòng đời `Inspection`:
     - Khởi tạo `inspections` document ngay sau Quality Check với `status="PROCESSING"`.
     - Cập nhật `inspections` document sang `status="COMPLETED"` khi chẩn đoán thành công.
     - Cập nhật `inspections` document sang `status="FAILED"` kèm `error_message` khi gặp ngoại lệ/lỗi.

---

# Code Summary

```python
# 1. Constructor Injection in AIService
class AIService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.disease_repo = DiseaseRepository(db)
        self.tree_repo = TreeRepository(db)
        self.inspection_repo = InspectionRepository(db)
        self._predictor = DiseasePredictor()

# 2. Phase 1 Inspection Lifecycle in detect_disease()
# Create Inspection with status="PROCESSING" right after Quality Check passes
inspection_id = await self.inspection_repo.create({
    "inspection_code": inspection_code,
    "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
    "farm_id": ObjectId(farm_id) if farm_id and ObjectId.is_valid(str(farm_id)) else farm_id,
    "zone_id": ObjectId(zone_id) if zone_id and ObjectId.is_valid(str(zone_id)) else zone_id,
    "inspection_date": datetime.now(timezone.utc),
    "health_status": "Đang theo dõi",
    "predicted_disease": "Đang xử lý",
    "confidence": 0.0,
    "status": "PROCESSING",
})

try:
    # Run AI prediction & process image
    ...
    # On Success: Update Inspection to status="COMPLETED"
    await self.inspection_repo.update(
        inspection_id,
        {
            "status": "COMPLETED",
            "health_status": health_status_vi,
            "predicted_disease": result.disease,
            "confidence": round(result.confidence * 100, 2),
            "severity": result.severity,
            "remark": f"Chẩn đoán AI: {result.disease} ({result.severity})",
        },
    )
    return DetectionResponse(...)
except Exception as exc:
    # On Failure: Update Inspection to status="FAILED" and save error message
    await self.inspection_repo.update(
        inspection_id,
        {
            "status": "FAILED",
            "error_message": str(exc),
        },
    )
    raise BadRequestException(...) from exc
```

---

# Inspection Lifecycle Verification

- ✅ **PROCESSING State:** Bản ghi `inspections` được khởi tạo ngay khi qua Quality Check với `status="PROCESSING"`.
- ✅ **COMPLETED State:** Cập nhật `status="COMPLETED"`, `health_status`, `predicted_disease`, `confidence` khi AI suy luận thành công.
- ✅ **FAILED State:** Cập nhật `status="FAILED"` cùng `error_message` khi phát sinh ngoại lệ trong quá trình AI execution/lưu DB.
- ✅ **Zero Rollback Loss:** Không xóa bản ghi `Inspection` khi xảy ra lỗi, bảo toàn 100% vết hoạt động kiểm tra của người dùng.
- ✅ **Strict Scope Compliance:** Không tạo Detection Result, không update Tree, không ghi Disease History, không tạo Alert, không sửa Frontend/Mobile/Router/API Contract.

---

# Verification Result

| Hạng mục Kiểm tra | Kết quả |
|---|:---:|
| **Python Syntax Check (`py_compile`)** | **PASS (0 errors)** |
| **Inspection Created (PROCESSING)** | **PASS** |
| **Inspection Updated (COMPLETED)** | **PASS** |
| **Inspection Updated (FAILED)** | **PASS** |
| **API Response Contract Preserved** | **PASS** |
| **Mobile & Frontend Unaffected** | **PASS** |

---

# Regression Risk

- **Risk Level:** **LOW**
- **Evaluation:** Thay đổi hoàn toàn cục bộ bên trong `AIService.detect_disease()`. Không làm thay đổi signature hàm hay cấu trúc response DTO của API.

---

# Final Status

**PHASE 1 COMPLETE**
