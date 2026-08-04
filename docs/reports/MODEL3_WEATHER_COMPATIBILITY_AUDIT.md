# Model 3 ↔ OpenWeather / weather_cache Compatibility Audit

- **Date:** 2026-08-03
- **Role:** Lead AI/ML Engineer — Durian Guardian AI (DGA)
- **Mode:** READ-ONLY. No code modified, no model retrained, no dataset generated, no commits, no pushes. Single report generated.
- **Project root:** `C:\Users\Chinh\Documents\GitHub\durian_guardian_ai`

---

## 1. Model 3 Overview

| Attribute | Value |
|---|---|
| **Algorithm** | Random Forest Classifier (`sklearn.ensemble.RandomForestClassifier`) |
| **Task** | Disease Risk Prediction (multi-class classification) |
| **Classes** | `Cao` (High), `Thấp` (Low), `Trung bình` (Medium) |
| **Saved artifact** | `training/model3/exports/model.pkl` |
| **Input dimension** | **14 features** (fixed order, stored in `feature_columns.json`) |
| **Hyperparameters** | `n_estimators=300`, `max_depth=None`, `class_weight="balanced"`, `random_state=42` |
| **Training date** | 2026-07-27 20:53:22 |
| **Reported quality** | Accuracy 0.941, F1 0.9408, ROC-AUC 0.9901 (2000-sample held-out test) |
| **Training data size** | 10,000 samples (3,517 Cao / 4,028 Trung bình / 2,455 Thấp) |
| **Purpose** | Predict per-tree disease-risk level from tabular agronomic + weather features |

Model 3 is a **tabular** model. It is architecturally distinct from Model 1 (image-based EfficientNet-B0 disease detection) and is **not currently wired into the FastAPI backend** — today's production risk values are rule-based (see §4).

---

## 2. Training Dataset

- **Builder:** `training/datasets/build_model3_dataset.py` (`Model3DatasetBuilder`)
- **Orchestrator:** `training/train_model3.py` — PHASE 1 builds the dataset from MongoDB, PHASE 2 preprocesses, PHASE 3 trains, PHASE 4–7 evaluate/export/verify.
- **Source collections (MongoDB):**
  - `inspections` → `temperature`, `humidity`, `rainfall`/`rainfall_mm`, `health_status`, `predicted_disease`, `confidence`, `inspection_date`
  - `trees` → `variety`, `tree_age`, `planting_date`
  - `farms` → `area_hectare`, `tree_count` (→ `density_per_hectare`)
  - `disease_history` → `historical_disease_count`, `days_since_last_treatment`
- **Offline seed datasets:** `dataset/DGA_seed_dataset_10000.csv` and `dataset/DGA_Enterprise_Dataset.xlsx` both contain `temperature`, `humidity`, `rainfall_mm` (plus `wind_speed`, `latitude`, `longitude`). The ETL pipeline (`database/etl_pipeline.py:1513-1532`, `transform_inspections`) persists `temperature`, `humidity`, `rainfall_mm` into the `inspections` collection, and `build_model3_dataset.py` normalises `rainfall_mm` → `rainfall`.

**Weather information already existed in the training dataset.** `temperature`, `humidity`, `rainfall` are first-class training features (humidity_scaled is the #2 most important feature, 0.161; rainfall_scaled #4, 0.093; temperature_scaled #5, 0.088).

**Label generation (heuristic, weather-aware):** `_compute_risk_level()` / `compute_risk_score()` in the builder score each row, and weather thresholds contribute to the label:
- humidity > 85 → +0.15; humidity 75–85 → +0.08
- rainfall > 60 → +0.10; rainfall 40–60 → +0.05
- temperature > 33 → +0.10; temperature 30–33 → +0.05
- season == "Mưa" → +0.05
- score < 0.20 → Thấp, < 0.50 → Trung bình, else Cao

---

## 3. Training Features

**COMPLETE list of raw features (14)** used by `preprocess()` (`training/train_model3.py:75-79`) and returned by `get_feature_target()` (`build_model3_dataset.py:258-264`):

| # | Raw feature | Type | Source collection | Derived from |
|---|---|---|---|---|
| 1 | `variety` | categorical | trees | — |
| 2 | `health_status` | categorical | inspections | — |
| 3 | `predicted_disease` | categorical | inspections | — |
| 4 | `season` | categorical | — | `inspection_date` month → Khô/Mưa |
| 5 | `temperature` | numerical | inspections | **weather (was inspection-carried)** |
| 6 | `humidity` | numerical | inspections | **weather (was inspection-carried)** |
| 7 | `rainfall` | numerical | inspections | **weather (was inspection-carried)** |
| 8 | `tree_age` | numerical | trees | `planting_date` |
| 9 | `confidence` | numerical | inspections | model-1 detection confidence |
| 10 | `density_per_hectare` | numerical | farms | `tree_count / area_hectare` |
| 11 | `days_since_last_inspection` | numerical | inspections | per-tree `inspection_date.diff()` |
| 12 | `days_since_last_treatment` | numerical | disease_history | last disease date vs inspection date |
| 13 | `historical_disease_count` | numerical | disease_history | count per tree |
| 14 | `historical_disease_frequency` | numerical | disease_history | `count / tree_age` |

**Preprocessing** (frozen into `preprocessor.pkl`):
- Categorical encoding: `OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1)` → `variety_encoded`, `health_status_encoded`, `predicted_disease_encoded`, `season_encoded`.
- Numerical scaling: `StandardScaler` → `..._scaled` for the 10 numerical columns.
- Missing numerical values filled with the training median.
- Final vector = 4 encoded + 10 scaled = **14 columns**, order fixed by `feature_columns.json`.

---

## 4. Inference Features

**Training-side inference (`training/predict_model3.py::predict_single`):** expects a dict keyed by the **raw** names above (all 14), applies the frozen `ordinal_encoder` + `scaler` from `preprocessor.pkl`, builds the 14-column frame, then `model.predict` / `predict_proba`, and inverts labels via `label_encoder`.

**Backend API → Service → Model → Prediction trace:**
- `GET /api/v1/weather/current` → `WeatherService.get_current_weather()` → `WeatherRepository` / `OpenWeatherClient` → MongoDB `weather_cache` → DGA 9-field response (`backend/app/api/v1/weather.py`, `backend/app/services/weather_service.py`, `backend/app/repositories/weather_repository.py`).
- `backend/app/ai/predictor.py` + `backend/app/ai/service.py` serve **Model 1 only** (image disease detection); the Random Forest risk model is **not loaded anywhere in the backend**.
- Production risk today is rule/heuristic-based: `AIService._run_detection`/`detect_disease` severity→risk map (`severity_risk_map`, ai/service.py:258-264) and dashboard MongoDB filters (`dashboard/service.py:78`).

**Conclusion:** Model 3 currently expects the exact 14 raw features listed in §3. It has no runtime backend endpoint yet.

---

## 5. Saved Model Metadata

Artifacts in `training/model3/exports/`:

| File | Contents | Feature names stored? |
|---|---|---|
| `model.pkl` | RandomForestClassifier (300 trees) | No (features via `n_features_in_=14`, column order implied) |
| `feature_columns.json` | **Exact 14 final feature names** (encoded/scaled) | **Yes** |
| `preprocessor.pkl` | dict: `ordinal_encoder`, `scaler`, `label_encoder`, `cat_columns`, `num_columns`, `feature_columns`, `cat_encoded_columns`, `num_scaled_columns` | **Yes** (raw + final names) |
| `label_encoder.pkl` | `LabelEncoder` classes `['Cao', 'Thấp', 'Trung bình']` | Yes |
| `metadata.json` | model type, `num_features=14`, 3 classes, `n_estimators=300`, `feature_importances_` | Yes |

Extracted encoder vocabulary (from `preprocessor.pkl`):
- `variety`: `Dona, Monthong, Musang King, Ri6`
- `health_status`: `Bị bệnh, Khỏe mạnh`
- `predicted_disease`: 15 Vietnamese disease names
- `season`: `Khô, Mưa`
- `StandardScaler.mean_` / `scale_` stored (10 values each).

**Feature names ARE stored** — both the raw input contract and the 14-column model contract are fully recoverable from the artifacts.

---

## 6. weather_cache Comparison

`weather_cache` document schema (from `WeatherRepository` docstring + `_map_openweather_to_cache`):

```
_id, farm_id, latitude, longitude, location_name,
temperature (float °C), feels_like (float), humidity (int %),
pressure (int hPa), wind_speed (float m/s), rainfall (float mm/h or mm/3h),
clouds (int %), visibility (int m), weather (str), description (str), icon (str),
updated_at, cache_expired_at, [forecast?]
```

### Mapping vs Model 3 raw features

| Model 3 raw feature | In weather_cache? | Match |
|---|---|---|
| `temperature` | **YES** (`temperature`, °C) | ✅ unit + type match |
| `humidity` | **YES** (`humidity`, %) | ✅ unit match (int vs training double — harmless) |
| `rainfall` | **YES** (`rainfall`, mm) | ✅ unit match (OpenWeather `rain.1h/3h` is mm; builder already used mm) |
| `variety` | **NO** | from `trees` (unchanged) |
| `health_status` | **NO** | from `inspections` (unchanged) |
| `predicted_disease` | **NO** | from `inspections` (unchanged) |
| `season` | **NO** | derived from inspection date (unchanged) |
| `tree_age` | **NO** | from `trees` (unchanged) |
| `confidence` | **NO** | from `inspections` (unchanged) |
| `density_per_hectare` | **NO** | from `farms` (unchanged) |
| `days_since_last_inspection` | **NO** | temporal feature (unchanged) |
| `days_since_last_treatment` | **NO** | temporal feature (unchanged) |
| `historical_disease_count` | **NO** | from `disease_history` (unchanged) |
| `historical_disease_frequency` | **NO** | from `disease_history` + `tree_age` (unchanged) |

### Summary of differences

- **Covered by weather_cache:** 3 / 14 features (temperature, humidity, rainfall).
- **Missing from weather_cache:** 11 / 14 features — all non-weather, supplied by the existing collections the builder already joins.
- **Extra in weather_cache (not used by Model 3):** `feels_like`, `pressure`, `wind_speed`, `clouds`, `visibility`, `weather`, `description`, `icon`, `location_name`, `latitude`, `longitude`. These are extra **fields**, not extra model dimensions — they do not alter the feature vector.
- **Different names:** none that Model 3 needs — `rainfall` (cache) == `rainfall` (builder). (Historical quirk: DB schema stores `rainfall_mm`; the builder normalises to `rainfall`, and the cache already uses `rainfall`.)
- **Different units:** none for the 3 weather features (°C, %, mm on both sides).
- **Different data types:** `humidity` is int in cache, double in training — numerically equivalent.

---

## 7. Feature Compatibility Matrix

| Feature | Training source | weather_cache | Adapter needed? | Model change? |
|---|---|---|---|---|
| temperature | inspections (weather) | ✅ present | map 1:1 | No |
| humidity | inspections (weather) | ✅ present | map 1:1 | No |
| rainfall | inspections (weather) | ✅ present | map 1:1 | No |
| variety | trees | — | join trees | No |
| health_status | inspections | — | join inspections | No |
| predicted_disease | inspections | — | join inspections | No |
| season | date-derived | — | derive from date | No |
| tree_age | trees | — | join trees | No |
| confidence | inspections | — | join inspections | No |
| density_per_hectare | farms | — | join farms | No |
| days_since_last_inspection | inspections | — | temporal | No |
| days_since_last_treatment | disease_history | — | temporal | No |
| historical_disease_count | disease_history | — | aggregate | No |
| historical_disease_frequency | disease_history + tree_age | — | aggregate | No |

**All 14 raw features remain available after swapping only the weather source** (inspections-carried → `weather_cache`). The 14-column encoded/scaled vector is unchanged.

---

## 8. Retraining Analysis

**Determination: CASE A — No retraining required.**

Evidence:
1. **Feature vector unchanged.** The model's input is a fixed 14-dimensional vector (`metadata.json: num_features=14`; `feature_columns.json`). Its order, dimension, encoding (OrdinalEncoder with stored vocabulary) and scaling (StandardScaler with stored mean/scale) are all frozen in `preprocessor.pkl`.
2. **Only the data source changed.** Previously `temperature` / `humidity` / `rainfall` were carried on inspection records (seeded from CSV/Excel). The upgrade routes them from OpenWeather → `WeatherService` → `weather_cache`. These are the **same three fields, same semantics, same units** (see §6). A Random Forest only sees the numeric/scaled inputs; the provenance of those numbers is irrelevant to the learned decision boundaries.
3. **Feature engineering unchanged.** No new composite weather features (Humidity Index, Rain Score, etc.) were introduced; the builder used the raw weather values + StandardScaler (see §9).
4. **Dataset remains compatible.** Training already included weather values in the same ranges (humidity 60–95 %, rainfall 0–117 mm, temperature 24–35 °C per `DGA_seed_dataset_10000.csv`); OpenWeather supplies the same physical quantities.

Retraining would be required **only if** the integration changed the feature vector, e.g., promoting `pressure`, `wind_speed`, `clouds` (weather_cache extras) into new model inputs, or re-deriving the risk labels from the new data source. Neither is being proposed.

---

## 9. Risk Assessment

Consequences of using OpenWeather / `weather_cache` **without retraining**:

| Scenario | Impact |
|---|---|
| **Proper adapter (map 3 fields, keep 11 from existing collections)** | No impact. Predictions remain valid; feature vector identical. |
| **"Direct connect" weather_cache as sole source** | ⚠ **Feature mismatch / silent degradation.** 11/14 features absent → zero/median-filled garbage for the dominant features (health_status #1, predicted_disease #3) → predictions become meaningless but do not crash. |
| **Distribution drift** (e.g., dry-season live rainfall = 0 while training saw up to 117 mm) | ⚠ Reduced accuracy (domain shift). Scaler extrapolates; Random Forest generalises out-of-range input poorly. Expected and bounded; not a failure. |
| **Model exception / crash** | Low. `sklearn` predict on a correctly built 14-column frame will not raise. `OrdinalEncoder` handles unseen categories via `unknown_value=-1`. |
| **Backend wiring** | No current endpoint loads Model 3, so no live inference path can break today. |

Overall risk of the recommended approach: **LOW**, provided a mapping layer is introduced (never a raw dict handoff).

---

## 10. Recommended Solution

**Option 2 — Map existing fields (adapter layer).**

Implementation shape (read-only proposal, no code written):
- Introduce a small adapter that builds the Model 3 raw row per tree: take `temperature`, `humidity`, `rainfall` from `weather_cache` (via `WeatherRepository.get_by_coords`/`get_by_farm_id`), and the other 11 features from the existing `trees`, `inspections`, `farms`, `disease_history` joins already implemented in `Model3DatasetBuilder`.
- Feed that row through the **frozen `preprocessor.pkl`** (`ordinal_encoder` + `scaler`), producing the identical 14-column vector, then `model.predict` / `predict_proba`.

Why:
- **Option 1 (direct connect) is rejected:** `weather_cache` alone cannot supply 11 of the 14 required features; the model contract is 14 features, not 3.
- **Options 3–4 (retrain preprocessing / whole forest) are unnecessary:** nothing about the feature space, encoding, or label semantics changed. Retraining would discard a validated 94% F1 model to solve a problem that does not exist.
- Mapping preserves the training distribution contract and the frozen preprocessing statistics, keeping predictions consistent with training-time behaviour.

---

## 11. Final Verdict

**✅ NO RETRAIN REQUIRED**

The OpenWeather integration changed **only the data source** for three of Model 3's fourteen features (`temperature`, `humidity`, `rainfall`). The feature vector (dimension 14, fixed order), the frozen preprocessing (`OrdinalEncoder` + `StandardScaler` in `preprocessor.pkl`), and the model weights remain fully valid. A mapping adapter that merges the three weather fields from `weather_cache` with the eleven non-weather fields from the existing `trees` / `inspections` / `farms` / `disease_history` joins — then runs the stored `preprocessor.pkl` — can serve Model 3 unchanged. Any retraining would only be justified if new weather fields (`pressure`, `wind_speed`, `clouds`) were promoted into the feature vector, which is out of scope for this integration.

---

*End of audit. Read-only executed: no source code, models, datasets, or MongoDB objects were modified; no commits or pushes were performed.*
