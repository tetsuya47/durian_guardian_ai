import hashlib, json, random, shutil
from pathlib import Path
from collections import defaultdict, Counter
from PIL import Image

random.seed(42)
ORIG = Path('dataset')
CLEAN = Path('dataset_cleaned')
IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}
CLASS_NAME_MAP = {'stem_cracking_ gummosis': 'stem_cracking_gummosis'}
SPLITS = ['Train', 'Validation', 'Test']

# Hash all files
md5_groups = defaultdict(list)
for split in SPLITS:
    sp = ORIG / split
    if not sp.exists():
        continue
    for cls_dir in sp.iterdir():
        if not cls_dir.is_dir():
            continue
        for f in cls_dir.iterdir():
            if f.suffix.lower() not in IMAGE_EXTS:
                continue
            h = hashlib.md5(f.read_bytes()).hexdigest()
            md5_groups[h].append((split, cls_dir.name, f.name, str(f)))

print(f'Total groups (unique hashes): {len(md5_groups)}')

# Pick best per group (highest resolution)
selected = []
for h, recs in md5_groups.items():
    best = None
    best_score = -1
    for split, cls, name, path in recs:
        try:
            img = Image.open(path)
            w, hd = img.size
            score = w * hd
            img.close()
            if score > best_score:
                best_score = score
                best = (split, cls, name, path)
        except Exception:
            pass
    selected.append(best)

print(f'Selected unique images: {len(selected)}')

# Group by normalized class
by_class = defaultdict(list)
for split, cls, name, path in selected:
    ncls = CLASS_NAME_MAP.get(cls, cls)
    by_class[ncls].append((split, cls, name, path))

# Assign splits per class (80/10/10)
assigned = []
for ncls, items in by_class.items():
    random.shuffle(items)
    n = len(items)
    n_val = max(1, round(n * 0.1))
    n_test = max(1, round(n * 0.1))
    n_train = n - n_val - n_test
    if n_train < 1:
        n_val = max(0, n - 1)
        n_test = 0
        n_train = 1
    splits_list = ['Train'] * n_train + ['Validation'] * n_val + ['Test'] * n_test
    random.shuffle(splits_list)
    for (split, cls, name, path), new_split in zip(items, splits_list):
        ncls = CLASS_NAME_MAP.get(cls, cls)
        h = hashlib.md5(open(path, 'rb').read()).hexdigest()
        assigned.append((new_split, ncls, h, path, name))

print(f'Total assigned: {len(assigned)}')
split_counts = Counter(a[0] for a in assigned)
print(f'Split distribution: {dict(split_counts)}')

# Copy with hash-based filenames
copied = 0
errors = 0
for i, (sp, nc, h, src_path, orig_name) in enumerate(assigned):
    ext = Path(src_path).suffix
    dst_dir = CLEAN / sp / nc
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / f'{h}{ext}'
    try:
        shutil.copy2(src_path, dst)
        copied += 1
    except Exception as e:
        errors += 1
        print(f'Error {src_path}: {e}')
    if (i + 1) % 1000 == 0:
        print(f'  copied {copied}', flush=True)

print(f'Copied: {copied}, Errors: {errors}')

# RGBA -> RGB
all_files = sorted([f for f in CLEAN.rglob('*') if f.suffix.lower() in IMAGE_EXTS])
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
    if (i + 1) % 500 == 0:
        print(f'  processed {i+1}, converted {converted}', flush=True)

print(f'RGBA converted: {converted}')

# Final count
total = len(all_files)
print(f'Total files: {total}')
print(f'Match expected: {total == len(assigned)}')

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
    print(f'  {c}: Tr={d["Train"]} Val={d["Validation"]} Te={d["Test"]} = {t}')
print(f'Grand total: {sum(sum(d.values()) for d in cls_split.values())}')
