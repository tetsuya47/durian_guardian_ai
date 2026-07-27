"""Sprint 4: Complete AI System Validation — Steps 1-3."""
import sys, time, json, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))

results = {}

# ============================================================
# STEP 1: MODEL INVENTORY
# ============================================================
print("=" * 70)
print("  STEP 1: MODEL INVENTORY")
print("=" * 70)

models_info = {
    "Model 1 - Disease Detection": {
        "algorithm": "EfficientNet-B0",
        "framework": "PyTorch",
        "config": ROOT / "training" / "configs" / "model1.yaml",
        "exports_dir": ROOT / "training" / "exports" / "disease_detection",
        "files": ["model.pt", "model.torchscript", "model.onnx"],
        "classes": 11,
    },
    "Model 2 - Image Quality": {
        "algorithm": "MobileNetV3-Small",
        "framework": "PyTorch",
        "config": ROOT / "training_quality" / "configs" / "model2.yaml",
        "exports_dir": ROOT / "training_quality" / "exports",
        "files": ["model.pt", "model.torchscript", "model.onnx"],
        "classes": 2,
    },
    "Model 3 - Disease Risk Prediction": {
        "algorithm": "RandomForestClassifier",
        "framework": "scikit-learn",
        "config": ROOT / "training" / "configs" / "model3.yaml",
        "exports_dir": ROOT / "training" / "model3" / "exports",
        "files": ["model.pkl", "preprocessor.pkl", "label_encoder.pkl", "feature_columns.json", "metadata.json"],
        "classes": 3,
    },
    "Model 4 - Recommendation Engine": {
        "algorithm": "Multi-task RandomForest",
        "framework": "scikit-learn",
        "config": ROOT / "training_recommendation" / "configs" / "model4.yaml",
        "exports_dir": ROOT / "training_recommendation" / "exports",
        "files": ["classifier.pkl", "regressor_urgency_score.pkl", "regressor_estimated_loss_pct.pkl",
                   "regressor_next_check_days.pkl", "preprocessor.pkl", "label_encoder.pkl",
                   "feature_columns.json", "metadata.json"],
        "classes": 4,
    },
}

for name, info in models_info.items():
    print(f"\n  {name}")
    print(f"    Algorithm    : {info['algorithm']}")
    print(f"    Framework    : {info['framework']}")
    print(f"    Classes      : {info['classes']}")
    print(f"    Config       : {info['config'].name} ({'EXISTS' if info['config'].exists() else 'MISSING'})")
    print(f"    Exports Dir  : {info['exports_dir'].name}/")
    all_exist = True
    for f in info["files"]:
        p = info["exports_dir"] / f
        exists = p.exists()
        size = p.stat().st_size if exists else 0
        size_str = f"{size/1024/1024:.1f}MB" if size > 1024*1024 else f"{size/1024:.1f}KB" if size > 1024 else f"{size}B"
        status = f"OK ({size_str})" if exists else "MISSING"
        if not exists:
            all_exist = False
        print(f"      {f:<42} {status}")
    results[name] = {"inventory": "PASS" if all_exist else "FAIL"}

print()

# ============================================================
# STEP 2: VERIFY EXPORTED FILES (load test)
# ============================================================
print("=" * 70)
print("  STEP 2: VERIFY EXPORTED FILES (load test)")
print("=" * 70)

# --- Model 1 ---
print("\n  Model 1 - Disease Detection:")
try:
    import torch
    ts = time.time()
    model1_pt = torch.load(str(ROOT / "training" / "exports" / "disease_detection" / "model.pt"),
                           map_location="cpu", weights_only=False)
    t1 = time.time() - ts
    print(f"    model.pt        : LOADED ({t1:.3f}s)")
except Exception as e:
    print(f"    model.pt        : FAILED - {e}")

try:
    ts = time.time()
    model1_ts = torch.jit.load(str(ROOT / "training" / "exports" / "disease_detection" / "model.torchscript"),
                                map_location="cpu")
    t2 = time.time() - ts
    print(f"    model.torchscript: LOADED ({t2:.3f}s)")
except Exception as e:
    print(f"    model.torchscript: FAILED - {e}")

try:
    ts = time.time()
    import onnxruntime as ort
    model1_onnx = ort.InferenceSession(str(ROOT / "training" / "exports" / "disease_detection" / "model.onnx"))
    t3 = time.time() - ts
    print(f"    model.onnx      : LOADED ({t3:.3f}s)")
except Exception as e:
    print(f"    model.onnx      : FAILED - {e}")

# --- Model 2 ---
print("\n  Model 2 - Image Quality:")
try:
    ts = time.time()
    model2_pt = torch.load(str(ROOT / "training_quality" / "exports" / "model.pt"),
                           map_location="cpu", weights_only=False)
    t1 = time.time() - ts
    print(f"    model.pt        : LOADED ({t1:.3f}s)")
except Exception as e:
    print(f"    model.pt        : FAILED - {e}")

try:
    ts = time.time()
    model2_ts = torch.jit.load(str(ROOT / "training_quality" / "exports" / "model.torchscript"),
                                map_location="cpu")
    t2 = time.time() - ts
    print(f"    model.torchscript: LOADED ({t2:.3f}s)")
except Exception as e:
    print(f"    model.torchscript: FAILED - {e}")

try:
    ts = time.time()
    model2_onnx = ort.InferenceSession(str(ROOT / "training_quality" / "exports" / "model.onnx"))
    t3 = time.time() - ts
    print(f"    model.onnx      : LOADED ({t3:.3f}s)")
except Exception as e:
    print(f"    model.onnx      : FAILED - {e}")

# --- Model 3 ---
print("\n  Model 3 - Disease Risk Prediction:")
try:
    import joblib
    ts = time.time()
    model3 = joblib.load(str(ROOT / "training" / "model3" / "exports" / "model.pkl"))
    t1 = time.time() - ts
    preproc3 = joblib.load(str(ROOT / "training" / "model3" / "exports" / "preprocessor.pkl"))
    le3 = joblib.load(str(ROOT / "training" / "model3" / "exports" / "label_encoder.pkl"))
    with open(ROOT / "training" / "model3" / "exports" / "feature_columns.json") as f:
        fc3 = json.load(f)
    with open(ROOT / "training" / "model3" / "exports" / "metadata.json") as f:
        meta3 = json.load(f)
    print(f"    model.pkl       : LOADED ({t1:.3f}s)")
    print(f"    preprocessor.pkl: LOADED")
    print(f"    label_encoder   : {le3.classes_.tolist()}")
    print(f"    features        : {len(fc3)} columns")
    print(f"    metadata classes: {meta3.get('classes', 'N/A')}")
    results["Model 3 - Disease Risk Prediction"]["load"] = "PASS"
except Exception as e:
    print(f"    FAILED - {e}")
    results["Model 3 - Disease Risk Prediction"]["load"] = "FAIL"

# --- Model 4 ---
print("\n  Model 4 - Recommendation Engine:")
try:
    ts = time.time()
    clf4 = joblib.load(str(ROOT / "training_recommendation" / "exports" / "classifier.pkl"))
    reg4_urg = joblib.load(str(ROOT / "training_recommendation" / "exports" / "regressor_urgency_score.pkl"))
    reg4_loss = joblib.load(str(ROOT / "training_recommendation" / "exports" / "regressor_estimated_loss_pct.pkl"))
    reg4_check = joblib.load(str(ROOT / "training_recommendation" / "exports" / "regressor_next_check_days.pkl"))
    preproc4 = joblib.load(str(ROOT / "training_recommendation" / "exports" / "preprocessor.pkl"))
    with open(ROOT / "training_recommendation" / "exports" / "label_encoder.pkl") as f:
        le4 = json.load(f)
    with open(ROOT / "training_recommendation" / "exports" / "feature_columns.json") as f:
        fc4 = json.load(f)
    with open(ROOT / "training_recommendation" / "exports" / "metadata.json") as f:
        meta4 = json.load(f)
    t1 = time.time() - ts
    print(f"    classifier.pkl  : LOADED ({t1:.3f}s)")
    print(f"    regressors (3)  : LOADED")
    print(f"    preprocessor.pkl: LOADED")
    print(f"    label_encoder   : {le4['classes']}")
    print(f"    features        : {len(fc4)} columns")
    print(f"    metadata classes: {meta4.get('classification_classes', 'N/A')}")
    results["Model 4 - Recommendation Engine"]["load"] = "PASS"
except Exception as e:
    print(f"    FAILED - {e}")
    results["Model 4 - Recommendation Engine"]["load"] = "FAIL"

# ============================================================
# STEP 3: VERIFY INFERENCE
# ============================================================
print("\n" + "=" * 70)
print("  STEP 3: VERIFY INFERENCE")
print("=" * 70)

# --- Model 1 Inference ---
print("\n  Model 1 - Disease Detection (11-class image classification):")
try:
    import torchvision.transforms as T
    model1_ts.eval()
    dummy_img = torch.randn(1, 3, 224, 224)
    ts = time.time()
    with torch.no_grad():
        out1 = model1_ts(dummy_img)
    t1 = time.time() - ts
    pred_class = out1.argmax(dim=1).item()
    prob = torch.softmax(out1, dim=1).max().item()
    print(f"    Input  : torch.Tensor [1, 3, 224, 224]")
    print(f"    Output : class={pred_class}, confidence={prob:.4f}")
    print(f"    Time   : {t1*1000:.1f}ms")
    results["Model 1 - Disease Detection"]["inference"] = "PASS"
except Exception as e:
    print(f"    FAILED - {e}")
    results["Model 1 - Disease Detection"]["inference"] = "FAIL"

# --- Model 2 Inference ---
print("\n  Model 2 - Image Quality (binary classification):")
try:
    model2_ts.eval()
    dummy_img = torch.randn(1, 3, 224, 224)
    ts = time.time()
    with torch.no_grad():
        out2 = model2_ts(dummy_img)
    t2 = time.time() - ts
    pred_class = out2.argmax(dim=1).item()
    prob = torch.softmax(out2, dim=1).max().item()
    print(f"    Input  : torch.Tensor [1, 3, 224, 224]")
    print(f"    Output : class={pred_class}, confidence={prob:.4f}")
    print(f"    Time   : {t2*1000:.1f}ms")
    results["Model 2 - Image Quality"]["inference"] = "PASS"
except Exception as e:
    print(f"    FAILED - {e}")
    results["Model 2 - Image Quality"]["inference"] = "FAIL"

# --- Model 3 Inference ---
print("\n  Model 3 - Disease Risk Prediction (tabular classification):")
try:
    import numpy as np
    import pandas as pd
    from training.predict_model3 import predict_single, load_artifacts as load_artifacts3
    sample3 = {
        "variety": "Monthong",
        "health_status": "Bị bệnh",
        "predicted_disease": "Thán thư",
        "season": "Khô",
        "temperature": 31.0,
        "humidity": 78.0,
        "rainfall": 15.0,
        "tree_age": 5,
        "density_per_hectare": 50.0,
        "days_since_last_inspection": 30,
        "days_since_last_treatment": 60,
        "historical_disease_count": 2,
        "historical_disease_frequency": 0.4,
        "confidence": 88.0,
    }
    m3, p3, fc3, meta3_loaded = load_artifacts3()
    ts = time.time()
    result3 = predict_single(sample3, m3, p3, fc3, None)
    t3 = time.time() - ts
    print(f"    Input  : Vietnamese features (health_status=Bị bệnh, predicted_disease=Thán thư)")
    print(f"    Output : risk_level='{result3['risk_level']}', risk_score={result3['risk_score']:.4f}")
    print(f"    Time   : {t3*1000:.1f}ms")
    results["Model 3 - Disease Risk Prediction"]["inference"] = "PASS"
except Exception as e:
    print(f"    FAILED - {e}")
    import traceback; traceback.print_exc()
    results["Model 3 - Disease Risk Prediction"]["inference"] = "FAIL"

# --- Model 4 Inference ---
print("\n  Model 4 - Recommendation Engine (multi-output tabular):")
try:
    from training_recommendation.predict import load_artifacts, predict as predict4
    sample4 = {
        "temperature": 29.0, "humidity": 78.0, "rainfall": 35.0,
        "tree_age": 5, "area_hectare": 25.0,
        "confidence": 85.0, "detection_confidence": 87.0,
        "disease_history_count": 0, "last_treatment_days": 120,
        "alert_count": 0, "days_since_last_inspection": 60,
        "historical_disease_count": 0, "historical_disease_frequency": 0.0,
        "density_per_hectare": 50.0, "priority_score": 0.0,
        "health_status": "Khỏe mạnh", "predicted_disease": "Khỏe mạnh",
        "detection_prediction": "Khỏe mạnh",
        "alert_type": "None", "alert_priority": "None",
        "season": "Khô", "risk_level": "Thấp",
    }
    m4, r4, p4, meta4 = load_artifacts()
    ts = time.time()
    result4 = predict4(sample4, m4, r4, p4)
    t4 = time.time() - ts
    print(f"    Input  : Vietnamese features (health=Khỏe mạnh, season=Khô, risk=Thấp)")
    print(f"    Output : priority='{result4['priority']}', action='{result4['recommended_action']}'")
    print(f"             urgency={result4['urgency_score']:.4f}, loss={result4['estimated_loss_pct']:.2f}%, check={result4['next_check_days']}d")
    print(f"    Time   : {t4*1000:.1f}ms")
    results["Model 4 - Recommendation Engine"]["inference"] = "PASS"
except Exception as e:
    print(f"    FAILED - {e}")
    import traceback; traceback.print_exc()
    results["Model 4 - Recommendation Engine"]["inference"] = "FAIL"

# ============================================================
# SUMMARY
# ============================================================
print("\n" + "=" * 70)
print("  STEPS 1-3 SUMMARY")
print("=" * 70)
for name, r in results.items():
    inv = r.get("inventory", "N/A")
    ld = r.get("load", "N/A")
    inf = r.get("inference", "N/A")
    print(f"  {name}")
    print(f"    Inventory: {inv}  |  Load: {ld}  |  Inference: {inf}")
all_pass = all(
    r.get("inventory") == "PASS" and r.get("inference") == "PASS"
    for r in results.values()
)
print(f"\n  Overall: {'ALL PASS' if all_pass else 'SOME FAILURES'}")
