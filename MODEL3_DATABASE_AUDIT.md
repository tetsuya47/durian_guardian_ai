# Model 3: Disease Risk Prediction — Database Audit Report

## 1. MongoDB Overview

| Item | Value |
|------|-------|
| Connection | `mongodb://localhost:27017` |
| Database | `durian_guardian_ai` |
| Total collections | 10 |
| Total documents | **29,186** |

## 2. Collection Inventory

| Collection | Documents | Data Quality | Notes |
|-----------|:---------:|:------------:|-------|
| `companies` | 10 | ✅ 100% complete | 10 companies across Đắk Lắk province |
| `farms` | 10 | ✅ 100% complete | 10 farms, 1 per company |
| `zones` | 100 | ⚠️ partial | `soil_type` & `irrigation` fields exist but ALL NULL |
| `trees` | 6,000 | ✅ 100% complete | 4 varieties, age 1-14 years, 3 statuses |
| `users` | 50 | ⚠️ partial | `email` & `password_hash` 100% NULL |
| `diseases` | 15 | ✅ complete | Disease master data |
| `inspections` | **10,000** | ✅ 100% complete | Core dataset for Model 3 |
| `detection_results` | 10,000 | ✅ complete | 1:1 with inspections, all from YOLOv11 |
| `disease_history` | 2,136 | ✅ complete | 1,799 unique trees, action always "Treatment Applied" |
| `alerts` | 875 | ✅ complete | All priority=High |

## 3. Schema Detail Per Collection

### `inspections` (10,000 docs — PRIMARY for Model 3)

| Field | Type | Present | Missing | Unique Values |
|-------|:----:|:-------:|:-------:|:-------------:|
| `tree_id` | ObjectId | 10,000 | 0 | 4,858 unique trees |
| `farm_id` | ObjectId | 10,000 | 0 | 10 farms |
| `disease_id` | ObjectId | 10,000 | 0 | 15 diseases |
| `inspection_date` | Date | 10,000 | 0 | 901 unique dates (2024-01-01 → 2026-06-19) |
| `temperature` | double | 10,000 | 0 | 22.0–36.0°C (avg 29.0) |
| `humidity` | double | 10,000 | 0 | 55.0–95.0% (avg 75.2) |
| `rainfall` | double | 10,000 | 0 | 0.0–80.0mm (avg 40.3) |
| `health_status` | string | 10,000 | 0 | `Healthy` (5,657) / `Diseased` (4,343) |
| `predicted_disease` | string | 10,000 | 0 | 15 disease classes |
| `confidence` | double | 10,000 | 0 | 1,980 unique values (80.0–99.9) |
| `inspection_code` | string | 10,000 | 0 | 10,000 unique |

### `trees` (6,000 docs)

| Field | Type | Present | Missing | Unique Values |
|-------|:----:|:-------:|:-------:|:-------------:|
| `tree_code` | string | 6,000 | 0 | 6,000 unique |
| `farm_id` | ObjectId | 6,000 | 0 | 10 farms |
| `zone_id` | ObjectId | 6,000 | 0 | 100 zones |
| `variety` | string | 6,000 | 0 | Dona(1,532), Ri6(1,571), Monthong(1,417), Musang King(1,480) |
| `planting_date` | Date | 6,000 | 0 | 2012-01-01 → 2025-12-31 |
| `tree_age` | int | 6,000 | 0 | 1–14 years |
| `status` | string | 6,000 | 0 | Healthy(2,006), Monitoring(2,058), Diseased(1,936) |

### `zones` (100 docs)

| Field | Type | Present | Missing | Notes |
|-------|:----:|:-------:|:-------:|:------|
| `farm_id` | ObjectId | 100 | 0 | 10 farms × 10 zones each |
| `zone_name` | string | 100 | 0 | ZONE_A → ZONE_J |
| `tree_count` | int | 100 | 0 | 36 unique values |
| `soil_type` | — | **0** | **100** | ❌ Field exists but ALL NULL |
| `irrigation` | — | **0** | **100** | ❌ Field exists but ALL NULL |

### `disease_history` (2,136 docs)

| Field | Type | Present | Unique |
|-------|:----:|:-------:|:------:|
| `tree_id` | ObjectId | 2,136 | 1,799 unique trees |
| `disease` | string | 2,136 | 14 disease classes |
| `date` | Date | 2,136 | 822 unique dates (2024-01-02 → 2026-06-18) |
| `action` | string | 2,136 | 1 value: `Treatment Applied` |

## 4. Inspection Statistics

| Metric | Value |
|--------|-------|
| Total inspections | 10,000 |
| Unique trees inspected | 4,858 (out of 6,000 = 81%) |
| Inspections per tree | min=1, max=9, **avg=2.06** |
| Trees with 1 inspection | 1,865 |
| Trees with 2 inspections | 1,584 |
| Trees with 3 inspections | 1,261 |
| Trees with 5+ inspections | 148 |
| Trees never inspected | 1,142 |

### Health vs Disease
| Status | Count | % |
|--------|:----:|:--:|
| Healthy | 5,657 | 56.6% |
| Diseased | 4,343 | 43.4% |

### Disease Distribution (excluding Healthy)
| Disease | Count | % |
|---------|:----:|:--:|
| Powdery Mildew | 343 | 3.4% |
| Stem Rot | 335 | 3.4% |
| Algae Spot | 327 | 3.3% |
| Fruit Rot | 313 | 3.1% |
| Root Rot | 312 | 3.1% |
| Sooty Mold | 309 | 3.1% |
| Scale Insect | 308 | 3.1% |
| Nutrient Deficiency | 307 | 3.1% |
| Phytophthora | 307 | 3.1% |
| Mealybug | 306 | 3.1% |
| Anthracnose | 299 | 3.0% |
| Dieback | 297 | 3.0% |
| Leaf Spot | 297 | 3.0% |
| Canker | 283 | 2.8% |

→ **Near-uniform distribution** across 14 disease classes (each ~3%).

## 5. Feature Availability Analysis

Model 3 (`model3.yaml`) specifies these features and target:

### Numerical Features

| Feature | Status | Source | Action Required |
|---------|:------:|--------|:---------------:|
| `temperature` | ✅ **OK** | `inspections.temperature` | None |
| `humidity` | ✅ **OK** | `inspections.humidity` | None |
| `rainfall` | ✅ **OK** | `inspections.rainfall` | None |
| `tree_age` | ✅ **OK** | `trees.tree_age` | Join on `tree_id` |
| `density_per_hectare` | ⚠️ **Computable** | `farms.tree_count` / `area_hectare` | Compute ratio |
| `days_since_last_inspection` | ⚠️ **Computable** | `inspections` per tree | Self-join, sort by date, diff |
| `days_since_last_treatment` | ⚠️ **Computable** | Join with `disease_history` | Requires temporal join |
| `historical_disease_count` | ⚠️ **Computable** | `disease_history` per tree | Count records per tree |
| `historical_disease_frequency` | ⚠️ **Computable** | `disease_history` per tree | Count/time window |

### Categorical Features

| Feature | Status | Source | Action Required |
|---------|:------:|--------|:---------------:|
| `tree_variety` | ✅ **OK** | `trees.variety` | Join on `tree_id` |
| `health_status` | ✅ **OK** | `inspections.health_status` | None |
| `zone_type` | ❌ **MISSING** | `zones` | Field does not exist in any collection |
| `soil_type` | ❌ **ALL NULL** | `zones.soil_type` | Field exists but 100% NULL |
| `irrigation_type` | ❌ **ALL NULL** | `zones.irrigation` | Field exists but 100% NULL |
| `season` | ⚠️ **Derivable** | `inspection_date` | Extract month → season mapping |

### Target Label

| Label | Status | Action Required |
|-------|:------:|:---------------|
| `risk_level` (low/medium/high) | ❌ **MISSING** | Must be defined and created |

## 6. Target Label (`risk_level`) — Gap Analysis

**`risk_level` does NOT exist in any MongoDB collection.** There are multiple approaches to create it:

### Option A: Rule-Based from Existing Fields (Recommended)

| risk_level | Rule | Count (est.) |
|:----------:|------|:------------:|
| **Low** | Tree is `Healthy` AND has 0 disease history records | ~2,000+ |
| **Medium** | Tree is in `Monitoring` status OR has 1–2 disease history records | ~2,000+ |
| **High** | Tree is currently `Diseased` OR has 3+ disease history records OR multiple re-inspections with disease | ~2,000+ |

### Option B: Binary (Simpler for MVP)
- `is_diseased` = 1 if `health_status == "Diseased"`, else 0
- This makes it a binary classification problem
- Richer features than leaf images used by Model 1

### Option C: Multi-class from Disease History
- `risk_level` = Low (never diseased), Medium (1 past disease event), High (2+ past disease events OR currently diseased)

**Recommendation:** Use Option A (3-class) to match `model3.yaml`'s `["low", "medium", "high"]`.

## 7. Data Readiness Verdict

| Criterion | Verdict | Notes |
|-----------|:-------:|-------|
| **Total samples** | ✅ SUFFICIENT | 10,000 inspections |
| **Unique trees** | ✅ SUFFICIENT | 4,858 with inspections |
| **Temporal span** | ✅ SUFFICIENT | 2.5 years (Jan 2024 – Jun 2026) |
| **Weather features** | ✅ **COMPLETE** | temp, humidity, rainfall — 0% missing |
| **Tree features** | ✅ **COMPLETE** | age, variety, status |
| **Categorical zone features** | ❌ **ALL NULL** | `soil_type`, `irrigation`, `zone_type` unusable |
| **Derived temporal features** | ⚠️ **Need computing** | days_since, density, historical counts |
| **Target label `risk_level`** | ❌ **MISSING** | Must be created from rules |
| **Label balance** | ⚠️ **Need to verify** | Depends on rule definition |

## 8. Conclusion

### MongoDB has ENOUGH data to train Model 3, but requires preprocessing.

- **Ready as-is:** 10,000 labeled samples with weather data, tree metadata, health status
- **Must be created:** `risk_level` target label (rule-based from `health_status` + `disease_history`)
- **Must be dropped:** `zone_type`, `soil_type`, `irrigation_type` (all NULL/empty)
- **Must be computed:** `season`, `density_per_hectare`, `days_since_last_inspection`, `days_since_last_treatment`, `historical_disease_count`, `historical_disease_frequency`

### Existing Pipeline Support

The file `database/dataset_builder/mongodb_reader.py` already provides `MongoDBDatasetBuilder.build_risk_dataset()` which joins inspections + trees + zones + farms. This is a good starting point.

### Recommended Training Pipeline

```
MongoDB
  │
  ├─ inspections ───┐
  ├─ trees ─────────┤
  ├─ farms ─────────┤
  ├─ zones ─────────┤
  └─ disease_hist ──┘
       │
       ▼
  build_risk_dataset()      ← extend MongoDBDatasetBuilder
       │
       ├─ Join collections (tree_id → trees, farm_id → farms)
       ├─ Drop: soil_type, irrigation_type, zone_type
       ├─ Compute: season, density, temporal features
       ├─ Create: risk_level (rule-based label)
       ├─ Encode: tree_variety, health_status
       ├─ Scale: numerical features (StandardScaler)
       │
       ▼
  train_test_split (80/20 stratified)
       │
       ▼
  RandomForestClassifier (or XGBoost)
       │
       ▼
  Evaluate: accuracy, precision, recall, F1, ROC-AUC
       │
       ▼
  Export: .pkl, .onnx
```

**Model 3 CAN proceed to training once `risk_level` label definition is finalized.**<｜end▁of▁thinking｜>

<｜｜DSML｜｜tool_calls>
<｜｜DSML｜｜invoke name="todowrite">
<｜｜DSML｜｜parameter name="todos" string="false">[{"priority":"high","content":"Read project structure and MongoDB configuration","status":"completed"},{"priority":"high","content":"Connect to MongoDB and list databases/collections","status":"completed"},{"priority":"high","content":"Analyze schema, missing data, nulls, unique values per collection","status":"completed"},{"priority":"high","content":"Determine features, labels, and training readiness for Model 3","status":"completed"},{"priority":"high","content":"Write MODEL3_DATABASE_AUDIT.md","status":"completed"}]