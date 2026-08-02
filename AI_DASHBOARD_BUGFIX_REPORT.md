# Project Information

- **Project:** Durian Guardian AI (DGA)
- **Release:** 2.0
- **Step:** STEP 6.1 — DASHBOARD KPI BUG FIX
- **Agent:** Antigravity IDE
- **Mode:** STRICT AUDIT + FIX
- **Date:** 2026-08-02
- **Final Status:** **BUGFIX COMPLETE**

---

# 1. File Modified

- `backend/app/dashboard/service.py` (Lines 76–78)

---

# 2. Root Cause Analysis

1. **`diseased_trees` Math Inconsistency (6000 / 6000):**
   - Trong MongoDB, các document trong `trees` collection chỉ có trường `status` (`"Khỏe mạnh"`, `"Đang theo dõi"`, `"Bị bệnh"`), trường `health_status` không tồn tại trên dữ liệu mẫu ban đầu (mang giá trị `null` / `missing`).
   - Trong `DashboardService.get_dashboard()`, truy vấn `diseased_filter` được viết bằng toán tử `$or` kết hợp với `$nin`:
     `{"$or": [{"health_status": {"$nin": ["Healthy", "Khỏe mạnh"]}}, {"status": {"$nin": ["Healthy", "Khỏe mạnh"]}}]}`
   - Do `health_status` mang giá trị `null` trên mọi cây, MongoDB đánh giá điều kiện `health_status $nin ["Healthy", "Khỏe mạnh"]` là **TRUE** cho toàn bộ 6000 document! Vì nằm trong toán tử `$or`, MongoDB lập tức trả về **TRUE** cho tất cả 6000 cây trong cơ sở dữ liệu.
   - Kết quả: `diseased_trees` bị tính bằng **6000** (bằng tổng số cây), dù `healthy_trees` đang là 2006 (gây ra mâu thuẫn toán học).

2. **`high_risk_trees` Discrepancy (0 High Risk Trees):**
   - `high_risk_filter` cũ chỉ tìm kiếm chuỗi Regex hẹp `"Phytophthora|High Risk|Nguy cơ cao|thối|xì mủ"`, bỏ qua trường điểm số rủi ro `risk_score >= 70` và trạng thái `"Bị bệnh"`, `"Diseased"`, `"Bệnh"`.
   - Dẫn tới `high_risk_trees` bị trả về **0**, dù trên Heatmap các ô cảnh báo màu đỏ/cam xuất hiện nhiều.

---

# 3. Wrong Query (Before)

```python
healthy_filter = {"$or": [{"health_status": {"$in": ["Healthy", "Khỏe mạnh"]}}, {"status": {"$in": ["Healthy", "Khỏe mạnh"]}}]}
diseased_filter = {"$or": [{"health_status": {"$nin": ["Healthy", "Khỏe mạnh"]}}, {"status": {"$nin": ["Healthy", "Khỏe mạnh"]}}]}  # BUG: $or + $nin on missing health_status matched ALL 6000 trees!
high_risk_filter = {"$or": [{"health_status": {"$regex": "Phytophthora|High Risk|Nguy cơ cao|thối|xì mủ", "$options": "i"}}, {"status": {"$regex": "Phytophthora|High Risk|Nguy cơ cao|thối|xì mủ", "$options": "i"}}]} # BUG: Missed risk_score >= 70 and 'Bị bệnh' status!
```

---

# 4. Correct Query (After)

```python
healthy_filter = {"$or": [{"health_status": {"$in": ["Healthy", "Khỏe mạnh"]}}, {"status": {"$in": ["Healthy", "Khỏe mạnh"]}}]}
diseased_filter = {"$or": [{"health_status": {"$in": ["Diseased", "Bệnh", "Bị bệnh"]}}, {"status": {"$in": ["Diseased", "Bệnh", "Bị bệnh"]}}]}
high_risk_filter = {"$or": [{"risk_score": {"$gte": 70}}, {"health_status": {"$in": ["Diseased", "Bệnh", "Bị bệnh"]}}, {"status": {"$in": ["Diseased", "Bệnh", "Bị bệnh"]}}, {"health_status": {"$regex": "Phytophthora|High Risk|Nguy cơ cao|thối|xì mủ|Nứt thân|Cháy thân", "$options": "i"}}, {"status": {"$regex": "Phytophthora|High Risk|Nguy cơ cao|thối|xì mủ|Nứt thân|Cháy thân", "$options": "i"}}]}
```

---

# 5. Before / After Values Comparison

| KPI Metric | Before Fix (BUG) | After Fix (FIXED) | Verification Status |
|---|:---:|:---:|:---:|
| **`total_trees`** | 6000 | 6000 | ✅ Correct Total |
| **`healthy_trees`** | 2006 | 2006 | ✅ Exact Match |
| **`monitoring_trees`** | 2058 | 2058 | ✅ Exact Match |
| **`diseased_trees`** | **6000** ❌ (Impossible) | **1936** ✅ | ✅ Fixed (Exact Match) |
| **`high_risk_trees`** | **0** ❌ (Missing) | **1936** ✅ | ✅ Fixed (Exact Match) |
| **Mathematical Sum** | $2006 + 6000 \ne 6000$ ❌ | **$2006 + 2058 + 1936 = 6000$** ✅ | ✅ **100% Perfect Match** |

---

# 6. Regression Risk

- **Risk Level:** **LOW**
- **Evaluation:** Chỉ sửa logic bộ lọc MongoDB trong `DashboardService.get_dashboard()` trên Backend. Không làm thay đổi Frontend React, Mobile Flutter, API Contract DTO hay MongoDB Collection Schema.

---

# Final Status

**BUGFIX COMPLETE**
