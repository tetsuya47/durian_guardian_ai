"""Phase 1: Verify the quality dataset before training."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from PIL import Image

root = Path("training_quality/dataset_quality")
splits = ["Train", "Validation", "Test"]
classes = ["Good", "Bad"]

print("=" * 60)
print("  DATASET QUALITY VERIFICATION")
print("=" * 60)

total_good = 0
total_bad = 0
missing_dirs = []

for split in splits:
    for cls in classes:
        d = root / split / cls
        if not d.exists():
            missing_dirs.append(str(d))
            continue
        files = [
            f for f in d.iterdir()
            if f.is_file() and f.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
        ]
        count = len(files)
        if cls == "Good":
            total_good += count
        else:
            total_bad += count
        print(f"  {split}/{cls}: {count} images")

if missing_dirs:
    for d in missing_dirs:
        print(f"  MISSING: {d}")

print(f"\n  Total Good: {total_good}")
print(f"  Total Bad: {total_bad}")
print(f"  Total images: {total_good + total_bad}")

print("\n  Checking for corrupted images...")
corrupted = []
for split in splits:
    for cls in classes:
        d = root / split / cls
        if not d.exists():
            continue
        for f in d.iterdir():
            if f.suffix.lower() not in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
                continue
            try:
                with Image.open(str(f)) as img:
                    img.verify()
            except Exception:
                corrupted.append(str(f))

if corrupted:
    print(f"  CORRUPTED: {len(corrupted)} images")
    for c in corrupted[:10]:
        print(f"    {c}")
else:
    print("  No corrupted images found.")

print("\n  Checking for duplicate filenames...")
all_stems = {}
for split in splits:
    for cls in classes:
        d = root / split / cls
        if not d.exists():
            continue
        for f in d.iterdir():
            if f.suffix.lower() not in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
                continue
            stem = f.stem
            if stem in all_stems:
                all_stems[stem].append(str(f))
            else:
                all_stems[stem] = [str(f)]

dups = {k: v for k, v in all_stems.items() if len(v) > 1}
if dups:
    print(f"  Found {len(dups)} duplicate stems")
    for stem, paths in list(dups.items())[:5]:
        print(f"    {stem}:")
        for p in paths:
            print(f"      {p}")
else:
    print("  No duplicate filenames found.")

print(f"\n  Class imbalance ratio Good:Bad = 1:{total_bad / max(total_good, 1):.2f}")

print("\n" + "=" * 60)
print("  VERIFICATION COMPLETE")
print("=" * 60)
