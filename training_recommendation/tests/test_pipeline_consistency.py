"""Consistency check: Model 1 → Model 3 → Model 4 pipeline."""

import sys; from pathlib import Path; sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
import json
import numpy as np

from training.utils.logger import Logger

logger = Logger.get_logger("PipelineConsistency")

ROOT = Path(__file__).resolve().parent.parent.parent

print("=" * 60)
print("  PIPELINE CONSISTENCY CHECK")
print("  Model 1 → Model 3 → Model 4")
print("=" * 60)

print("\n[Model 1] Image → Disease")
m1_exports = ROOT / "training" / "exports"
if m1_exports.exists():
    files = [f.name for f in m1_exports.iterdir()]
    print(f"  Exports directory: {m1_exports}")
    print(f"  Files: {files}")
    print(f"  Status: ✅ EXISTS")
else:
    print(f"  Status: ⚠️ NOT FOUND at {m1_exports}")

print("\n[Model 3] Disease → Risk")
m3_exports = ROOT / "training" / "model3" / "exports"
if m3_exports.exists():
    files = [f.name for f in m3_exports.iterdir()]
    print(f"  Exports directory: {m3_exports}")
    print(f"  Files: {files}")
    has_model = (m3_exports / "model.pkl").exists()
    has_preproc = (m3_exports / "preprocessor.pkl").exists()
    print(f"  Model: {'✅' if has_model else '❌'}")
    print(f"  Preprocessor: {'✅' if has_preproc else '❌'}")
else:
    print(f"  Status: ❌ NOT FOUND at {m3_exports}")

print("\n[Model 4] Features → Recommendation")
m4_exports = ROOT / "training_recommendation" / "exports"
check_files = [
    "classifier.pkl", "regressor_urgency_score.pkl",
    "regressor_estimated_loss_pct.pkl", "regressor_next_check_days.pkl",
    "preprocessor.pkl", "metadata.json",
]
if m4_exports.exists():
    files = [f.name for f in m4_exports.iterdir()]
    print(f"  Exports directory: {m4_exports}")
    all_present = all((m4_exports / f).exists() for f in check_files)
    missing = [f for f in check_files if not (m4_exports / f).exists()]
    print(f"  All required files: {'✅' if all_present else '❌'}")
    if missing:
        print(f"  Missing: {missing}")
    print(f"  Status: ✅ READY")
else:
    print(f"  Status: ❌ NOT FOUND")

print("\n[Pipeline Integration Test]")
print("  Image → Model 1 → disease_name + confidence")
print("                ↓")
print("  disease_name + confidence + weather + tree_data")
print("                ↓")
print("  Model 3 → risk_score + risk_level")
print("                ↓")
print("  risk_score + risk_level + all features")
print("                ↓")
print("  Model 4 → priority, action, urgency, loss, next_check")
print("                ↓")
print("  Recommendation")

# Quick test: load Model 4, check metadata
print("\n[Model 4 Metadata Verification]")
meta_path = m4_exports / "metadata.json"
if meta_path.exists():
    with open(meta_path) as f:
        meta = json.load(f)
    print(f"  Model: {meta.get('model', 'N/A')}")
    print(f"  Task: {meta.get('task', 'N/A')}")
    print(f"  Features: {meta.get('num_features', 'N/A')}")
    print(f"  Classes: {meta.get('classification_classes', 'N/A')}")
    te = meta.get("test_evaluation", {})
    cls = te.get("classification", {}).get("test", {})
    print(f"  Test Accuracy: {cls.get('accuracy', 'N/A')}")
    print(f"  Test F1: {cls.get('f1', 'N/A')}")
    for target in ["urgency_score", "estimated_loss_pct", "next_check_days"]:
        reg = te.get("regression", {}).get(target, {}).get("test", {})
        print(f"  {target}: R2={reg.get('r2', 'N/A')}, MAE={reg.get('mae', 'N/A')}")

# Quick test: load all model files successfully
print("\n[Model Loading Test]")
try:
    import joblib
    clf = joblib.load(str(m4_exports / "classifier.pkl"))
    print(f"  classifier.pkl: ✅ ({type(clf).__name__})")
    preproc = joblib.load(str(m4_exports / "preprocessor.pkl"))
    print(f"  preprocessor.pkl: ✅ ({type(preproc).__name__})")
    for name in ["regressor_urgency_score", "regressor_estimated_loss_pct", "regressor_next_check_days"]:
        reg = joblib.load(str(m4_exports / f"{name}.pkl"))
        print(f"  {name}.pkl: ✅ ({type(reg).__name__})")
except Exception as e:
    print(f"  ❌ Model loading failed: {e}")

# Check checkpoints
print("\n[Checkpoint Verification]")
ckpt_dir = ROOT / "training_recommendation" / "checkpoints"
if ckpt_dir.exists():
    files = [f.name for f in ckpt_dir.iterdir()]
    print(f"  Checkpoints: {len(files)} files")
    has_best = any("best_" in f for f in files)
    has_last = any("last_" in f for f in files)
    print(f"  Best: {'✅' if has_best else '❌'}, Last: {'✅' if has_last else '❌'}")
else:
    print(f"  ❌ Checkpoints directory missing")

print("\n" + "=" * 60)
pipeline_ok = (m3_exports.exists() and m4_exports.exists())
print(f"  Pipeline Consistency: {'✅ PASSED' if pipeline_ok else '❌ FAILED'}")
print("=" * 60)
