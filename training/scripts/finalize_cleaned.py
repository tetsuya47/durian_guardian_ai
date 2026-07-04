from PIL import Image
from pathlib import Path
from collections import defaultdict, Counter
import json

CLEAN = Path('dataset_cleaned')
IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}

all_files = sorted([f for f in CLEAN.rglob('*') if f.suffix.lower() in IMAGE_EXTS])
print(f'Total: {len(all_files)}')

# RGBA -> RGB conversion
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
        print(f'Error converting {img_path}: {e}')
    if (i+1) % 500 == 0:
        print(f'  processed {i+1}, converted so far {converted}', flush=True)

print(f'Converted: {converted}')

# Generate manifest
manifest = []
for img_path in all_files:
    rel = img_path.relative_to(CLEAN)
    parts = rel.parts
    manifest.append({'file': str(rel), 'class': parts[1], 'split': parts[0]})

with open(CLEAN / 'dataset_manifest.json', 'w') as f:
    json.dump(manifest, f, indent=2)
print(f'Manifest: {len(manifest)} entries')

# Verify all openable
bad = 0
for i, img_path in enumerate(all_files):
    try:
        with Image.open(img_path) as img:
            img.load()
    except:
        bad += 1
        print(f'Corrupted: {img_path}')
print(f'Corrupted files: {bad}')

# Class distribution
cls_split = defaultdict(lambda: Counter())
for m in manifest:
    cls_split[m['class']][m['split']] += 1
print('\nClass distribution:')
for c in sorted(cls_split):
    d = cls_split[c]
    total = sum(d.values())
    print(f'  {c}: Tr={d["Train"]} Val={d["Validation"]} Te={d["Test"]} = {total}')
total_all = sum(sum(d.values()) for d in cls_split.values())
print(f'Total: {total_all}')
