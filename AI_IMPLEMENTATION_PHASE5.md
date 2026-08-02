# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 4.5 — ALERT IMPLEMENTATION
- **Agent:** Antigravity IDE
- **Mode:** STRICT IMPLEMENTATION
- **Date:** 2026-08-02

---

# Files Modified

1. **`backend/app/ai/service.py`**
   - Inject `AlertRepository` vào constructor `AIService.__init__`.
   - Triển khai Phase 5 Alert: Sinh bản ghi cảnh báo mới trong `alerts` collection **DUY NHẤT** khi `result.severity == "high"`.

---

# Code Summary

```python
# Phase 5: High-Risk Alert Auto-Generation (Only triggered when severity == 'high')
if result.severity == "high":
    tree_code = tree.get("tree_code", tree_id) if isinstance(tree, dict) else tree_id
    count_alert = await self.alert_repo.collection.count_documents({})
    alert_code = f"ALT{count_alert + 1:05d}"

    await self.alert_repo.create({
        "alert_code": alert_code,
        "farm_id": ObjectId(farm_id) if farm_id and ObjectId.is_valid(str(farm_id)) else farm_id,
        "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
        "company_id": ObjectId(company_id) if company_id and ObjectId.is_valid(str(company_id)) else company_id,
        "inspection_id": ObjectId(inspection_id) if ObjectId.is_valid(inspection_id) else inspection_id,
        "detection_result_id": ObjectId(detection_result_id) if ObjectId.is_valid(str(detection_result_id)) else detection_result_id,
        "disease_history_id": ObjectId(disease_id) if ObjectId.is_valid(str(disease_id)) else disease_id,
        "alert_type": "Bệnh nghiêm trọng",
        "title": "Cảnh báo bệnh nguy cơ cao",
        "message": f"Phát hiện bệnh {result.disease} nguy cơ cao tại cây {tree_code}",
        "recommendation": _build_recommendation(result.disease, result.severity),
        "priority": "Cao",
        "status": "unread",
        "is_read": False,
        "date": datetime.now(timezone.utc),
        "created_at": datetime.now(timezone.utc),
    })
```

---

# Alert Mapping

| Property Name | Target Document Field (`alerts`) | Value / Source |
|---|---|---|
| `alert_code` | `alert_code` | Auto-generated (`ALT00001+`) |
| `farm_id` | `farm_id` | `ObjectId(farm_id)` |
| `tree_id` | `tree_id` | `ObjectId(tree_id)` |
| `company_id` | `company_id` | `ObjectId(company_id)` |
| `inspection_id` | `inspection_id` | `ObjectId(inspection_id)` từ Phase 1 |
| `detection_result_id` | `detection_result_id` | `ObjectId(detection_result_id)` từ Phase 2 |
| `disease_history_id` | `disease_history_id` | `ObjectId(disease_id)` từ Phase 4 |
| `alert_type` | `alert_type` | `"Bệnh nghiêm trọng"` |
| `title` | `title` | `"Cảnh báo bệnh nguy cơ cao"` |
| `message` | `message` | `"Phát hiện bệnh {disease} nguy cơ cao tại cây {tree_code}"` |
| `recommendation` | `recommendation` | Hướng dẫn kỹ thuật ứng với bệnh |
| `priority` | `priority` | `"Cao"` |
| `status` | `status` | `"unread"` |
| `is_read` | `is_read` | `False` |
| `date` | `date` | `datetime.now(timezone.utc)` |
| `created_at` | `created_at` | Handled automatically by `BaseRepository.create()` |

---

# Verification Result

| Severity Level | Alert Created? | Verification Result |
|---|:---:|:---:|
| **`high`** | ✅ **YES** | **PASS (Bản ghi `alerts` được tạo với `status="unread"`)** |
| **`medium`** | ❌ **NO** | **PASS (Không sinh cảnh báo)** |
| **`low`** | ❌ **NO** | **PASS (Không sinh cảnh báo)** |
| **`none`** | ❌ **NO** | **PASS (Không sinh cảnh báo)** |

---

# Regression Risk

- **Risk Level:** **LOW**
- **Evaluation:** Bọc hoàn toàn trong khối điều kiện `if result.severity == "high"`. Không ảnh hưởng đến luồng chẩn đoán cây bình thường hay gây xáo trộn dữ liệu.

---

# Final Status

**PHASE 5 COMPLETE**
