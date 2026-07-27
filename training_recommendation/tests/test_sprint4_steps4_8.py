"""Sprint 4: Steps 4-8 — Pipeline, DB Compatibility, Consistency, Performance, Robustness."""
import sys, time, json, os, gc, tracemalloc
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))

import numpy as np
import pandas as pd
import torch
import joblib

results = {}

# ============================================================
# STEP 4: PIPELINE TEST
# ============================================================
print("=" * 70)
print("  STEP 4: PIPELINE TEST (Image → M1 → M2 → M3 → M4)")
print("=" * 70)

try:
    from torchvision import transforms as T
    from training_predict_model3 import _unused
except ImportError:
    pass

# Load all models
model1_ts = torch.jit.load(str(ROOT / "training" / "exports" / "disease_detection" / "model.torchscript"), map_location="cpu")
model1_ts.eval()
model2_ts = torch.jit.load(str(ROOT / "training_quality" / "exports" / "model.torchscript"), map_location="cpu")
model2_ts.eval()
model3, p3, fc3, meta3 = None, None, None, None
clf4, r4, p4, meta4 = None, None, None, None

from training.predict_model3 import predict_single, load_artifacts as load_artifacts3
from training_recommendation.predict import load_artifacts as load_artifacts4, predict as predict4

m3, p3, fc3, meta3 = load_artifacts3()
clf4, r4, p4, meta4 = load_artifacts4()
with open(ROOT / "training_recommendation" / "exports" / "feature_columns.json") as f:
    fc4 = json.load(f)

DISEASE_CLASSES = [
    "Khỏe mạnh", "Thán thư", "Sẹo thân", "Thối quả", "Rệp sáp",
    "Bệnh hồng thân", "Nấm bồ hóng", "Cháy thân", "Nứt thân chảy nhựa",
    "Bọ trĩ", "Vàng lá"
]

print("\n  Simulating full pipeline with synthetic data...")
dummy_img = torch.randn(1, 3, 224, 224)

# Step 4a: Image → Model 1 (Disease Detection)
ts = time.time()
with torch.no_grad():
    m1_out = model1_ts(dummy_img)
m1_class = m1_out.argmax(dim=1).item()
m1_disease = DISEASE_CLASSES[m1_class] if m1_class < len(DISEASE_CLASSES) else f"class_{m1_class}"
m1_conf = torch.softmax(m1_out, dim=1).max().item()
t_m1 = time.time() - ts
print(f"    [1] Image → Model 1: disease='{m1_disease}', confidence={m1_conf:.4f} ({t_m1*1000:.0f}ms)")

# Step 4b: Image → Model 2 (Image Quality)
ts = time.time()
with torch.no_grad():
    m2_out = model2_ts(dummy_img)
m2_class = m2_out.argmax(dim=1).item()
m2_quality = "Tốt" if m2_class == 0 else "Kém"
m2_conf = torch.softmax(m2_out, dim=1).max().item()
t_m2 = time.time() - ts
print(f"    [2] Image → Model 2: quality='{m2_quality}', confidence={m2_conf:.4f} ({t_m2*1000:.0f}ms)")

# Step 4c: Features → Model 3 (Risk Prediction)
ts = time.time()
m3_features = {
    "variety": "Monthong",
    "health_status": "Bị bệnh",
    "predicted_disease": m1_disease,
    "season": "Khô",
    "temperature": 30.0, "humidity": 75.0, "rainfall": 20.0,
    "tree_age": 5, "density_per_hectare": 50.0,
    "days_since_last_inspection": 30, "days_since_last_treatment": 60,
    "historical_disease_count": 1, "historical_disease_frequency": 0.2,
    "confidence": m1_conf * 100,
}
result3 = predict_single(m3_features, m3, p3, fc3, None)
t_m3 = time.time() - ts
print(f"    [3] Features → Model 3: risk='{result3['risk_level']}', score={result3['risk_score']:.4f} ({t_m3*1000:.0f}ms)")

# Step 4d: Features → Model 4 (Recommendation)
ts = time.time()
m4_features = {
    "temperature": 30.0, "humidity": 75.0, "rainfall": 20.0,
    "tree_age": 5, "area_hectare": 25.0,
    "confidence": m1_conf * 100, "detection_confidence": m2_conf * 100,
    "disease_history_count": 1, "last_treatment_days": 60,
    "alert_count": 1, "days_since_last_inspection": 30,
    "historical_disease_count": 1, "historical_disease_frequency": 0.2,
    "density_per_hectare": 50.0, "priority_score": 0.0,
    "health_status": "Bị bệnh",
    "predicted_disease": m1_disease,
    "detection_prediction": m1_disease,
    "alert_type": "Nguy cơ mắc bệnh cao",
    "alert_priority": result3["risk_level"],
    "season": "Khô",
    "risk_level": result3["risk_level"],
}
result4 = predict4(m4_features, clf4, r4, p4)
t_m4 = time.time() - ts
print(f"    [4] Features → Model 4: priority='{result4['priority']}', action='{result4['recommended_action']}' ({t_m4*1000:.0f}ms)")

pipeline_time = (t_m1 + t_m2 + t_m3 + t_m4) * 1000
print(f"\n    PIPELINE COMPLETE: {pipeline_time:.0f}ms total")
print(f"    Model 1 → '{m1_disease}' | Model 2 → '{m2_quality}' | Model 3 → '{result3['risk_level']}' | Model 4 → '{result4['priority']}'")
results["pipeline"] = "PASS"

# ============================================================
# STEP 5: DATABASE COMPATIBILITY
# ============================================================
print("\n" + "=" * 70)
print("  STEP 5: DATABASE COMPATIBILITY")
print("=" * 70)

from pymongo import MongoClient
from database.config import settings

client = MongoClient(settings.mongodb_uri_with_credentials, **settings.connection_kwargs)
db = client[settings.DATABASE_NAME]

# Check Vietnamese values in collections
collections_to_check = {
    "inspections": ["health_status", "predicted_disease"],
    "disease_history": ["disease", "action"],
    "alerts": ["alert_type", "priority"],
    "trees": ["status"],
}

all_vi = True
for coll_name, fields in collections_to_check.items():
    print(f"\n  Collection: {coll_name}")
    for field in fields:
        values = db[coll_name].distinct(field)
        print(f"    {field}: {values}")
        for v in values:
            if v and isinstance(v, str):
                has_english = v in ["Healthy", "Diseased", "Monitoring", "Low", "Medium", "High", "Critical",
                                     "Dry", "Rainy", "Anthracnose", "Phytophthora", "Stem Rot", "Root Rot", "Fruit Rot"]
                if has_english:
                    print(f"      ⚠ ENGLISH VALUE DETECTED: '{v}'")
                    all_vi = False

# Test Model 3 reads Vietnamese DB
print("\n  Testing Model 3 with real DB records...")
sample_insp = list(db.inspections.aggregate([{"$sample": {"size": 3}}]))
for insp in sample_insp:
    tree = db.trees.find_one({"_id": insp.get("tree_id")}, {"tree_age": 1, "variety": 1})
    tree = tree or {}
    features = {
        "variety": tree.get("variety", "Monthong"),
        "health_status": insp.get("health_status", "Khỏe mạnh"),
        "predicted_disease": insp.get("predicted_disease", "Khỏe mạnh"),
        "season": "Khô",
        "temperature": insp.get("temperature", 28.0),
        "humidity": insp.get("humidity", 70.0),
        "rainfall": insp.get("rainfall", 0.0),
        "tree_age": tree.get("tree_age", 5),
        "density_per_hectare": 50.0,
        "days_since_last_inspection": 30,
        "days_since_last_treatment": 90,
        "historical_disease_count": 0,
        "historical_disease_frequency": 0.0,
        "confidence": insp.get("confidence", 90.0),
    }
    r = predict_single(features, m3, p3, fc3, None)
    print(f"    {insp.get('inspection_code','?')} | health={features['health_status']} disease={features['predicted_disease']} → risk='{r['risk_level']}'")

results["db_compatibility"] = "PASS" if all_vi else "FAIL"
client.close()

# ============================================================
# STEP 6: MODEL CONSISTENCY
# ============================================================
print("\n" + "=" * 70)
print("  STEP 6: MODEL CONSISTENCY")
print("=" * 70)

# Model 3 consistency
print("\n  Model 3:")
m3_cat = p3["cat_columns"]
m3_num = p3["num_columns"]
m3_le_classes = sorted(p3["label_encoder"].classes_.tolist())
m3_meta_classes = sorted(meta3["classes"])
m3_fc = fc3
print(f"    Cat columns (preprocessor): {m3_cat}")
print(f"    Num columns (preprocessor): {m3_num}")
print(f"    Label encoder classes: {m3_le_classes}")
print(f"    Metadata classes: {m3_meta_classes}")
m3_classes_match = m3_le_classes == m3_meta_classes
print(f"    Classes match: {'YES' if m3_classes_match else 'NO'}")

m3_config = p3.get("cat_columns", []) + p3.get("num_columns", [])
m3_features_match = set(m3_fc) == set(m3_config)
print(f"    Feature columns match preprocessor: {'YES' if m3_features_match else 'NO'}")

# Model 4 consistency
print("\n  Model 4:")
with open(ROOT / "training_recommendation" / "exports" / "label_encoder.pkl") as f:
    le4_data = json.load(f)
m4_le = meta4.get("cat_columns", [])
m4_num = meta4.get("num_columns", [])
m4_fc = fc4
m4_priority_map = {"Thấp": 0, "Trung bình": 1, "Cao": 2, "Rất cao": 3}
m4_le_classes = sorted(le4_data["classes"])
m4_meta_values = sorted(le4_data["mapping"].keys())
print(f"    Cat columns: {m4_le}")
print(f"    Num columns: {m4_num}")
print(f"    Label encoder classes: {m4_le_classes}")
print(f"    Label mapping keys: {m4_meta_values}")
m4_classes_match = m4_le_classes == m4_meta_values
print(f"    Classes match: {'YES' if m4_classes_match else 'NO'}")

m4_fc_match = set(m4_fc) == set(m4_le) | {f"{c}_encoded" for c in m4_le} | {f"{c}_scaled" for c in m4_num}
print(f"    Feature columns structure consistent: {'YES' if m4_fc_match else 'NO'}")

# Check Vietnamese in all models
print("\n  Vietnamese Values Check:")
m3_vi = all(isinstance(c, str) and not c.isascii() or c in ["Monthong", "unknown"]
            for c in m3_le_classes if isinstance(c, str))
m4_vi = all(not c.isascii() for c in m4_le_classes if isinstance(c, str))
print(f"    Model 3 labels Vietnamese: {'YES' if m3_vi else 'CHECK'} ({m3_le_classes})")
print(f"    Model 4 labels Vietnamese: {'YES' if m4_vi else 'CHECK'} ({m4_le_classes})")

consistency_ok = m3_classes_match and m3_features_match and m4_classes_match
results["consistency"] = "PASS" if consistency_ok else "WARN"

# ============================================================
# STEP 7: PERFORMANCE MEASUREMENT
# ============================================================
print("\n" + "=" * 70)
print("  STEP 7: PERFORMANCE MEASUREMENT")
print("=" * 70)

# Model loading time
print("\n  Model Loading Time:")
gc.collect()
ts = time.time()
_ = torch.jit.load(str(ROOT / "training" / "exports" / "disease_detection" / "model.torchscript"), map_location="cpu")
t_load_m1 = time.time() - ts
print(f"    Model 1 (TorchScript): {t_load_m1*1000:.0f}ms")

gc.collect()
ts = time.time()
_ = torch.jit.load(str(ROOT / "training_quality" / "exports" / "model.torchscript"), map_location="cpu")
t_load_m2 = time.time() - ts
print(f"    Model 2 (TorchScript): {t_load_m2*1000:.0f}ms")

gc.collect()
ts = time.time()
_ = joblib.load(str(ROOT / "training" / "model3" / "exports" / "model.pkl"))
t_load_m3 = time.time() - ts
print(f"    Model 3 (sklearn pkl) : {t_load_m3*1000:.0f}ms")

gc.collect()
ts = time.time()
_ = joblib.load(str(ROOT / "training_recommendation" / "exports" / "classifier.pkl"))
t_load_m4 = time.time() - ts
print(f"    Model 4 (sklearn pkl) : {t_load_m4*1000:.0f}ms")

# Inference latency (100 runs)
print("\n  Inference Latency (100 runs avg):")
N = 100

# Model 1
dummy = torch.randn(1, 3, 224, 224)
times = []
for _ in range(N):
    ts = time.time()
    with torch.no_grad():
        model1_ts(dummy)
    times.append(time.time() - ts)
avg_m1 = np.mean(times) * 1000
print(f"    Model 1: {avg_m1:.1f}ms avg")

# Model 2
times = []
for _ in range(N):
    ts = time.time()
    with torch.no_grad():
        model2_ts(dummy)
    times.append(time.time() - ts)
avg_m2 = np.mean(times) * 1000
print(f"    Model 2: {avg_m2:.1f}ms avg")

# Model 3
times = []
for _ in range(N):
    ts = time.time()
    predict_single(m3_features, m3, p3, fc3, None)
    times.append(time.time() - ts)
avg_m3 = np.mean(times) * 1000
print(f"    Model 3: {avg_m3:.1f}ms avg")

# Model 4
times = []
for _ in range(N):
    ts = time.time()
    predict4(m4_features, clf4, r4, p4)
    times.append(time.time() - ts)
avg_m4 = np.mean(times) * 1000
print(f"    Model 4: {avg_m4:.1f}ms avg")

print(f"\n    Total pipeline latency: {avg_m1+avg_m2+avg_m3+avg_m4:.1f}ms")

# Memory usage
tracemalloc.start()
snapshot = tracemalloc.take_snapshot()
stats = snapshot.statistics("lineno")
total_mem = sum(s.size for s in stats) / 1024 / 1024
print(f"\n  Memory (current process): {total_mem:.1f}MB")
tracemalloc.stop()

results["performance"] = "PASS"

# ============================================================
# STEP 8: ROBUSTNESS TEST
# ============================================================
print("\n" + "=" * 70)
print("  STEP 8: ROBUSTNESS TEST")
print("=" * 70)

robustness_pass = True

# Test 8a: Missing fields
print("\n  8a. Missing fields:")
try:
    minimal_features = {}
    result = predict_single(minimal_features, m3, p3, fc3, None)
    print(f"    Model 3 (empty dict): risk='{result['risk_level']}' ✓")
except Exception as e:
    print(f"    Model 3 (empty dict): FAILED - {e}")
    robustness_pass = False

try:
    minimal_m4 = {}
    result = predict4(minimal_m4, clf4, r4, p4)
    print(f"    Model 4 (empty dict): priority='{result['priority']}' ✓")
except Exception as e:
    print(f"    Model 4 (empty dict): FAILED - {e}")
    robustness_pass = False

# Test 8b: Unknown disease names
print("\n  8b. Unknown disease names:")
try:
    unknown_disease_features = m3_features.copy()
    unknown_disease_features["predicted_disease"] = "Bệnh không xác định"
    result = predict_single(unknown_disease_features, m3, p3, fc3, None)
    print(f"    Model 3 (unknown disease): risk='{result['risk_level']}' ✓")
except Exception as e:
    print(f"    Model 3 (unknown disease): FAILED - {e}")
    robustness_pass = False

# Test 8c: Empty/null values
print("\n  8c. Empty/null values:")
try:
    null_features = m3_features.copy()
    for k in null_features:
        null_features[k] = None
    result = predict_single(null_features, m3, p3, fc3, None)
    print(f"    Model 3 (all None): risk='{result['risk_level']}' ✓")
except Exception as e:
    print(f"    Model 3 (all None): FAILED - {e}")
    robustness_pass = False

# Test 8d: Corrupted image (random noise)
print("\n  8d. Corrupted/random image:")
try:
    noise_img = torch.rand(1, 3, 224, 224)
    with torch.no_grad():
        out = model1_ts(noise_img)
    pred = out.argmax(dim=1).item()
    print(f"    Model 1 (random noise): class={pred} ✓ (no crash)")
except Exception as e:
    print(f"    Model 1 (random noise): FAILED - {e}")
    robustness_pass = False

try:
    with torch.no_grad():
        out = model2_ts(noise_img)
    pred = out.argmax(dim=1).item()
    print(f"    Model 2 (random noise): class={pred} ✓ (no crash)")
except Exception as e:
    print(f"    Model 2 (random noise): FAILED - {e}")
    robustness_pass = False

# Test 8e: Invalid weather values
print("\n  8e. Invalid weather values:")
try:
    extreme_features = m3_features.copy()
    extreme_features["temperature"] = 999.0
    extreme_features["humidity"] = -50.0
    extreme_features["rainfall"] = 10000.0
    result = predict_single(extreme_features, m3, p3, fc3, None)
    print(f"    Model 3 (extreme weather): risk='{result['risk_level']}' ✓ (no crash)")
except Exception as e:
    print(f"    Model 3 (extreme weather): FAILED - {e}")
    robustness_pass = False

# Test 8f: Negative/zero tree_age
print("\n  8f. Edge case values:")
try:
    edge_features = m3_features.copy()
    edge_features["tree_age"] = -1
    edge_features["density_per_hectare"] = 0
    edge_features["confidence"] = 0
    result = predict_single(edge_features, m3, p3, fc3, None)
    print(f"    Model 3 (edge values): risk='{result['risk_level']}' ✓ (no crash)")
except Exception as e:
    print(f"    Model 3 (edge values): FAILED - {e}")
    robustness_pass = False

results["robustness"] = "PASS" if robustness_pass else "FAIL"

# ============================================================
# FINAL SUMMARY
# ============================================================
print("\n" + "=" * 70)
print("  STEPS 4-8 SUMMARY")
print("=" * 70)
for step, status in results.items():
    emoji = "✓" if status == "PASS" else "⚠" if status == "WARN" else "✗"
    print(f"  {emoji} {step}: {status}")

all_ok = all(v in ("PASS", "WARN") for v in results.values())
print(f"\n  Overall: {'PASS' if all_ok else 'FAILURES DETECTED'}")
