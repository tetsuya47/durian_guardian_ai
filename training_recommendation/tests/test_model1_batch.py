"""Model 1 batch prediction test on 10 random test images."""

import sys; from pathlib import Path; sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
import json
import random
from training.predict import predict as m1_predict

ROOT = Path(__file__).resolve().parent.parent.parent
test_dir = ROOT / "Ten_Classes_of_Durian_Leaf_Diseases/Ten_Classes_of_Durian_Leaf_Diseases/Test"

all_images = []
for cls_dir in sorted(test_dir.iterdir()):
    if cls_dir.is_dir():
        cls_images = list(cls_dir.iterdir())
        cls_images = [f for f in cls_images if f.suffix.lower() in (".jpg", ".jpeg", ".png")]
        all_images.extend(cls_images)

selected = random.sample(all_images, min(10, len(all_images)))
print("=" * 60)
print("  MODEL 1: DISEASE DETECTION — 10 IMAGE TEST")
print("=" * 60)
errors = 0
for i, img_path in enumerate(selected):
    try:
        result = m1_predict(str(img_path))
        actual = img_path.parent.name
        pred = result["predicted_class"]
        mark = "PASS" if pred == actual else "FAIL"
        print(f"  [{i+1}/10] {mark} | actual={actual:30s} | pred={pred:30s} | conf={result['confidence']:.4f}")
    except Exception as e:
        print(f"  [{i+1}/10] ERROR | {img_path.name}: {e}")
        errors += 1

print(f"\n  Results: {len(selected)-errors}/{len(selected)} success, {errors} errors")
print("=" * 60)
