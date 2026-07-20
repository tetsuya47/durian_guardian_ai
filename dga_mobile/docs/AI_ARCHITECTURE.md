# AI Architecture — Durian Guardian AI

This document covers the design parameters, weights, and layers of the 4 embedded AI models.

## 1. Model Matrix

| Model | ID | Architecture | Framework | File Format | Disk Size |
|---|---|---|---|---|---|
| **Disease Detection** | Model 1 | EfficientNet-B0 | PyTorch | `.pt` (state_dict) | 15.6 MB |
| **Image Quality** | Model 2 | MobileNet-V3-Small | PyTorch | `.pt` (state_dict) | 4.2 MB |
| **Risk Prediction** | Model 3 | Random Forest Classifier | Scikit-Learn | `.pkl` | 39.9 MB |
| **Recommendation** | Model 4 | Random Forest Ensemble | Scikit-Learn | `.pkl` (x6 files) | 29.3 MB |

---

## 2. Model 1 (Disease Detection)
- **Classifier Head**: Replaced linear classifier with `nn.Linear(in_features, 11)` matching target disease class logits.
- **Classes**: `anthracnose_disease`, `canker_disease`, `fruit_rot`, `Healthy`, `mealybug_infestation`, `pink_disease`, `sooty_mold`, `stem_blight`, `stem_cracking_gummosis`, `thrips_disease`, `yellow_leaf`.

---

## 3. Model 2 (Image Quality)
- **Backbone**: MobileNet-V3-Small.
- **Classifier Head**: adapted to `nn.Sequential(Linear(in_features, 256) -> Hardswish -> Dropout -> Linear(256, 2))`.
- **Heuristic Encoders**: Integrated Laplacian variance blur detectors and RGB luminosity testers.

---

## 4. Model 3 (Risk Prediction)
- **Input Pipeline**: Enriched with `OrdinalEncoder` (categorical fields) and `StandardScaler` (numerical fields).
- **Target**: Evaluates tree health levels to output classification probabilities.

---

## 5. Model 4 (Recommendation Engine)
- **Ensemble Elements**:
  - 1 Random Forest Classifier (Care priority level).
  - 3 Random Forest Regressors (Urgency score [0..1], Estimated loss percentage [0..100], and Next inspection timeline in days).
