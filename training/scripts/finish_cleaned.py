from PIL import Image
from pathlib import Path
from collections import defaultdict, Counter
import json

CLEAN = Path('dataset_cleaned')
IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}

all_files = sorted([f for f in CLEAN.rglob('*') if f.suffix.lower() in IMAGE_EXTS])
print(f'Total files: {len(all_files)}')

# Convert remaining RGBA/PA/P
converted = 0
for i, img_path in enumerate(all_files):
    try:
        img = Image.open(img_path)
        mode = img.mode
        if mode in ('RGBA', 'PA') or (mode == 'P' and 'transparency' in img.info):
            if mode == 'P':
                img = img.convert('RGBA')
            img = img.convert('RGB')
            img.save(img_path)
            converted += 1
        img.close()
    except Exception as e:
        print(f'Error {img_path}: {e}')
    if (i + 1) % 500 == 0:
        print(f'  processed {i+1}, converted {converted}', flush=True)

print(f'Converted: {converted}')

# Verify all openable
bad = 0
for f in all_files:
    try:
        with Image.open(f) as img:
            img.load()
    except Exception:
        bad += 1
        print(f'Corrupted: {f}')
print(f'Corrupted files: {bad}')

# Generate manifest
manifest = []
for img_path in all_files:
    rel = img_path.relative_to(CLEAN)
    parts = rel.parts
    manifest.append({'file': str(rel), 'class': parts[1], 'split': parts[0]})

with open(CLEAN / 'dataset_manifest.json', 'w') as f:
    json.dump(manifest, f, indent=2)
print(f'Manifest entries: {len(manifest)}')

# Class distribution
cls_split = defaultdict(lambda: Counter())
for m in manifest:
    cls_split[m['class']][m['split']] += 1
print('\nClass distribution:')
for c in sorted(cls_split):
    d = cls_split[c]
    t = sum(d.values())
    tr = d.get('Train', 0)
    va = d.get('Validation', 0)
    te = d.get('Test', 0)
    print(f'  {c}: Tr={tr} Val={va} Te={te} = {t}')
grand = sum(sum(d.values()) for d in cls_split.values())
print(f'Grand total: {grand}')
