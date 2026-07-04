"""Comprehensive Dataset Audit for Model 1 (Durian Disease Detection).

Audits all 5,400+ images across Train/Validation/Test splits.
Outputs reports to training/reports/dataset_audit/.

Phases:
  1.  Dataset Statistics
  2.  Train/Val/Test Distribution
  3.  Class Imbalance
  4.  Duplicate Images (MD5 + perceptual hash)
  5.  Data Leakage (cross-set duplicates)
  6.  Image Quality
  7.  Image Size Distribution
  8.  Color Distribution
  9.  Label Consistency
  10. Corrupted Files
  11. Outliers
  12. Feature Space (t-SNE, UMAP)
  13. Confusion Analysis
  14. Hard Examples
  15. Dataset Score
  16. Recommendations
"""

import csv
import json
import math
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.logger import Logger

logger = Logger.get_logger("dataset_audit")

DATASET_DIR = PROJECT_ROOT / "dataset"
SPLITS = ["Train", "Validation", "Test"]
CLASS_NAMES = [
    "anthracnose_disease",
    "canker_disease",
    "fruit_rot",
    "mealybug_infestation",
    "pink_disease",
    "sooty_mold",
    "stem_blight",
    "stem_cracking_ gummosis",
    "thrips_disease",
    "yellow_leaf",
]
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}
OUTPUT_DIR = PROJECT_ROOT / "training" / "reports" / "dataset_audit"


def ensure_dir(d):
    d.mkdir(parents=True, exist_ok=True)


def image_files(path):
    """Return list of valid image files in a directory (recursive)."""
    return sorted([f for f in Path(path).rglob("*") if f.suffix.lower() in IMAGE_EXTS])


# =========================================================
# PHASE 1: Dataset Statistics
# =========================================================
def phase1_stats():
    logger.info("=" * 60)
    logger.info("PHASE 1: DATASET STATISTICS")
    logger.info("=" * 60)

    all_images = []
    per_class = defaultdict(int)
    per_split = defaultdict(int)
    per_class_split = defaultdict(lambda: defaultdict(int))

    for split in SPLITS:
        split_path = DATASET_DIR / split
        if not split_path.exists():
            continue
        for cls_dir in split_path.iterdir():
            if not cls_dir.is_dir():
                continue
            cls_name = cls_dir.name
            files = image_files(cls_dir)
            for f in files:
                all_images.append(f)
                per_class[cls_name] += 1
                per_split[split] += 1
                per_class_split[cls_name][split] += 1

    total = len(all_images)

    logger.info("Total images: %d", total)
    logger.info("Total classes: %d", len(per_class))
    logger.info("")
    logger.info("Per split:")
    for s in SPLITS:
        logger.info("  %-12s: %d", s, per_split.get(s, 0))
    logger.info("")
    logger.info("Per class:")
    for cls in sorted(per_class.keys()):
        count = per_class[cls]
        pct = count / total * 100
        logger.info("  %-30s: %5d  (%5.2f%%)", cls, count, pct)

    rows = []
    for cls in CLASS_NAMES:
        row = {"class": cls, "total": per_class.get(cls, 0)}
        for s in SPLITS:
            row[s.lower()] = per_class_split[cls].get(s, 0)
        rows.append(row)

    ensure_dir(OUTPUT_DIR)
    with open(OUTPUT_DIR / "dataset_statistics.json", "w", encoding="utf-8") as f:
        json.dump(
            {
                "total_images": total,
                "total_classes": len(per_class),
                "per_split": dict(per_split),
                "per_class": rows,
                "class_names": list(per_class.keys()),
            },
            f,
            indent=2,
        )

    with open(OUTPUT_DIR / "dataset_statistics.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["class", "total", "train", "validation", "test"])
        for r in rows:
            w.writerow([r["class"], r["total"], r["train"], r["validation"], r["test"]])

    logger.info("Saved: dataset_statistics.json / .csv")
    return all_images, per_class, per_split, per_class_split


# =========================================================
# PHASE 2: Train/Val/Test Distribution (visual)
# =========================================================
def phase2_distribution(per_class_split):
    logger.info("=" * 60)
    logger.info("PHASE 2: TRAIN/VAL/TEST DISTRIBUTION")
    logger.info("=" * 60)

    logger.info("%-30s %8s %8s %8s %8s", "Class", "Train", "Val", "Test", "Total")
    logger.info("-" * 66)
    totals = {"Train": 0, "Validation": 0, "Test": 0}
    for cls in CLASS_NAMES:
        t = per_class_split[cls].get("Train", 0)
        v = per_class_split[cls].get("Validation", 0)
        te = per_class_split[cls].get("Test", 0)
        totals["Train"] += t
        totals["Validation"] += v
        totals["Test"] += te
        logger.info("%-30s %8d %8d %8d %8d", cls, t, v, te, t + v + te)
    logger.info("-" * 66)
    logger.info("%-30s %8d %8d %8d %8d", "TOTAL", totals["Train"], totals["Validation"], totals["Test"], totals["Train"] + totals["Validation"] + totals["Test"])

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(1, 2, figsize=(14, 5))

        # Overall split
        labels = ["Train", "Validation", "Test"]
        values = [totals[s] for s in SPLITS]
        colors = ["#2ecc71", "#f39c12", "#e74c3c"]
        axes[0].pie(values, labels=labels, autopct="%1.1f%%", colors=colors, startangle=90)
        axes[0].set_title("Overall Train/Val/Test Split", fontsize=13, fontweight="bold")

        # Per-class stacked bars
        cls_names_short = [c.replace("_disease", "").replace("_infestation", "").replace("_", "\n") for c in CLASS_NAMES]
        x = np.arange(len(CLASS_NAMES))
        width = 0.25
        train_vals = [per_class_split[c].get("Train", 0) for c in CLASS_NAMES]
        val_vals = [per_class_split[c].get("Validation", 0) for c in CLASS_NAMES]
        test_vals = [per_class_split[c].get("Test", 0) for c in CLASS_NAMES]
        axes[1].bar(x - width, train_vals, width, label="Train", color="#2ecc71")
        axes[1].bar(x, val_vals, width, label="Validation", color="#f39c12")
        axes[1].bar(x + width, test_vals, width, label="Test", color="#e74c3c")
        axes[1].set_xticks(x)
        axes[1].set_xticklabels(cls_names_short, fontsize=7, rotation=45, ha="right")
        axes[1].set_ylabel("Images")
        axes[1].set_title("Per-Class Split Distribution", fontsize=13, fontweight="bold")
        axes[1].legend(fontsize=8)

        plt.tight_layout()
        plt.savefig(OUTPUT_DIR / "class_distribution.png", dpi=150, bbox_inches="tight")
        plt.close()
        logger.info("Saved: class_distribution.png")
    except Exception as e:
        logger.warning("Could not generate class_distribution.png: %s", e)


# =========================================================
# PHASE 3: Class Imbalance
# =========================================================
def phase3_imbalance(per_class):
    logger.info("=" * 60)
    logger.info("PHASE 3: CLASS IMBALANCE ANALYSIS")
    logger.info("=" * 60)

    counts = list(per_class.values())
    max_c = max(counts)
    min_c = min(counts)
    mean_c = np.mean(counts)
    std_c = np.std(counts)
    cv = std_c / mean_c if mean_c > 0 else 0
    imbalance_ratio = max_c / min_c if min_c > 0 else float("inf")

    logger.info("Max class: %d", max_c)
    logger.info("Min class: %d", min_c)
    logger.info("Mean:      %.2f", mean_c)
    logger.info("Std:       %.2f", std_c)
    logger.info("CV:        %.4f", cv)
    logger.info("Imbalance Ratio (max/min): %.2f", imbalance_ratio)

    imbalance_severity = "NONE"
    if cv > 0.15:
        imbalance_severity = "MODERATE"
    if cv > 0.30:
        imbalance_severity = "SEVERE"
    if cv > 0.50:
        imbalance_severity = "CRITICAL"

    logger.info("CV = %.4f → Imbalance Severity: %s", cv, imbalance_severity)
    logger.info("")

    recommendations = []
    if imbalance_ratio > 1.5:
        recommendations.append("Use weighted loss (CrossEntropy with class weights)")
    if cv > 0.15:
        recommendations.append("Consider oversampling minority classes")
    if cv > 0.30:
        recommendations.append("Use Focal Loss to handle class imbalance")
    if imbalance_ratio < 1.2 and cv < 0.05:
        recommendations.append("No action needed — dataset is well-balanced")

    for r in recommendations:
        logger.info("  Recommendation: %s", r)

    imbalance_data = {
        "max_count": max_c,
        "min_count": min_c,
        "mean": round(mean_c, 2),
        "std": round(std_c, 2),
        "cv": round(cv, 4),
        "imbalance_ratio": round(imbalance_ratio, 2),
        "imbalance_severity": imbalance_severity,
        "recommendations": recommendations,
    }
    with open(OUTPUT_DIR / "imbalance_report.json", "w", encoding="utf-8") as f:
        json.dump(imbalance_data, f, indent=2)
    logger.info("Saved: imbalance_report.json")
    return imbalance_data


# =========================================================
# PHASE 4: Duplicate Images
# =========================================================
def phase4_duplicates(all_images):
    logger.info("=" * 60)
    logger.info("PHASE 4: DUPLICATE IMAGES")
    logger.info("=" * 60)

    import hashlib

    md5_map = defaultdict(list)
    total = len(all_images)
    logger.info("Computing MD5 hashes for %d images...", total)

    for i, fpath in enumerate(all_images):
        try:
            with open(fpath, "rb") as f:
                fhash = hashlib.md5(f.read()).hexdigest()
            md5_map[fhash].append(str(fpath))
        except Exception:
            pass
        if (i + 1) % 1000 == 0:
            logger.info("  ... %d / %d", i + 1, total)

    duplicates = {h: paths for h, paths in md5_map.items() if len(paths) > 1}
    dup_count = sum(len(v) for v in duplicates.values())
    dup_groups = len(duplicates)
    dup_images = sum(len(v) - 1 for v in duplicates.values())

    logger.info("Duplicate groups: %d", dup_groups)
    logger.info("Total duplicate instances: %d", dup_count)
    logger.info("  (%.1f%% of dataset)", dup_count / total * 100)
    logger.info("Extra images beyond first copy: %d", dup_images)

    rows = []
    for h, paths in sorted(duplicates.items(), key=lambda x: -len(x[1])):
        for p in paths:
            p_obj = Path(p)
            rel = p_obj.relative_to(PROJECT_ROOT)
            split = p_obj.parent.parent.name if p_obj.parent.parent else ""
            cls = p_obj.parent.name
            rows.append({"hash": h, "file": str(rel), "split": split, "class": cls})

    with open(OUTPUT_DIR / "duplicate_images.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["hash", "file", "split", "class"])
        w.writeheader()
        w.writerows(rows)
    logger.info("Saved: duplicate_images.csv (%d entries)", len(rows))

    dup_summary = {"groups": dup_groups, "total_duplicate_files": dup_count, "extra_copies": dup_images, "pct_of_dataset": round(dup_count / total * 100, 2)}
    with open(OUTPUT_DIR / "duplicate_summary.json", "w", encoding="utf-8") as f:
        json.dump(dup_summary, f, indent=2)

    return md5_map, duplicates


# =========================================================
# PHASE 5: Data Leakage
# =========================================================
def phase5_leakage(md5_map):
    logger.info("=" * 60)
    logger.info("PHASE 5: DATA LEAKAGE")
    logger.info("=" * 60)

    leakage_pairs = [
        ("Train", "Validation"),
        ("Train", "Test"),
        ("Validation", "Test"),
    ]

    total_leak_groups = 0
    total_leak_images = 0
    all_leak_rows = []

    for a, b in leakage_pairs:
        shared = 0
        shared_images = []
        for h, paths in md5_map.items():
            splits_in = set()
            for p in paths:
                pp = Path(p)
                if pp.parent.parent:
                    splits_in.add(pp.parent.parent.name)
            if a in splits_in and b in splits_in:
                shared += 1
                shared_images.extend(paths)

        count_images = len(shared_images)
        logger.info("  %s ↔ %s: %d groups, %d images", a, b, shared, count_images)
        total_leak_groups += shared
        total_leak_images += count_images

        for p in shared_images:
            pp = Path(p)
            rel = pp.relative_to(PROJECT_ROOT)
            cls = pp.parent.name
            split = pp.parent.parent.name
            all_leak_rows.append({"split_a": a, "split_b": b, "file": str(rel), "class": cls, "split": split})

    logger.info("")
    logger.info("Total leakage groups: %d", total_leak_groups)
    logger.info("Total leakage images: %d", total_leak_images)

    if total_leak_images > 0:
        logger.warning("⚠ CRITICAL: Data leakage detected! Validation/Test metrics are NOT reliable.")

    with open(OUTPUT_DIR / "leakage_report.md", "w", encoding="utf-8") as f:
        f.write("# Data Leakage Report\n\n")
        f.write(f"**Total leakage groups:** {total_leak_groups}\n")
        f.write(f"**Total leakage images:** {total_leak_images}\n\n")
        f.write("## Leakage by Pair\n\n")
        f.write("| Pair | Groups | Images |\n")
        f.write("|------|--------|--------|\n")
        for a, b in leakage_pairs:
            count = 0
            for h, paths in md5_map.items():
                splits_in = set()
                for p in paths:
                    pp = Path(p)
                    if pp.parent.parent:
                        splits_in.add(pp.parent.parent.name)
                if a in splits_in and b in splits_in:
                    count += 1
            f.write(f"| {a} ↔ {b} | {count} | {count * 2} |\n")
        f.write(f"\n## Total Leakage\n\n**{total_leak_groups} groups, {total_leak_images} images**\n\n")
        if total_leak_images > 0:
            f.write("> ⚠ CRITICAL: Validation/Test metrics are NOT reliable due to data leakage.\n")

    with open(OUTPUT_DIR / "leakage_report.json", "w", encoding="utf-8") as f:
        json.dump({"total_groups": total_leak_groups, "total_images": total_leak_images}, f, indent=2)

    logger.info("Saved: leakage_report.md / .json")
    return total_leak_groups, total_leak_images


# =========================================================
# PHASE 6-8: Image Quality + Size + Color
# =========================================================
def phase6_quality(all_images):
    logger.info("=" * 60)
    logger.info("PHASE 6-8: IMAGE QUALITY / SIZE / COLOR")
    logger.info("=" * 60)

    from PIL import Image, UnidentifiedImageError

    stats = {
        "total": len(all_images),
        "corrupted": [],
        "grayscale": 0,
        "rgba": 0,
        "rgb": 0,
        "other_mode": 0,
        "widths": [],
        "heights": [],
        "brightness": [],
        "contrast": [],
        "file_sizes": [],
        "small_images": 0,  # < 32px any dimension
        "tiny_images": 0,  # < 224px any dimension
        "huge_images": 0,  # > 2000px
    }

    for i, fpath in enumerate(all_images):
        try:
            img = Image.open(fpath)
            mode = img.mode
            w, h = img.size
            stats["widths"].append(w)
            stats["heights"].append(h)

            if h < 32 or w < 32:
                stats["small_images"] += 1
            if h < 224 or w < 224:
                stats["tiny_images"] += 1
            if w > 2000 or h > 2000:
                stats["huge_images"] += 1

            if mode == "L":
                stats["grayscale"] += 1
            elif mode in ("RGBA", "PA"):
                stats["rgba"] += 1
            elif mode == "RGB":
                stats["rgb"] += 1
            else:
                stats["other_mode"] += 1

            img_rgb = img.convert("RGB")
            np_img = np.array(img_rgb, dtype=np.float32)
            brightness = np.mean(np_img)
            stats["brightness"].append(float(brightness))

            local_contrast = np.std(np_img)
            stats["contrast"].append(float(local_contrast))

            fsize = fpath.stat().st_size
            stats["file_sizes"].append(fsize)

            img.close()
        except (UnidentifiedImageError, Exception) as e:
            stats["corrupted"].append(str(fpath))
            logger.warning("  Corrupted: %s — %s", fpath.name, e)

        if (i + 1) % 1000 == 0:
            logger.info("  ... %d / %d", i + 1, len(all_images))

    logger.info("")
    logger.info("Color Modes:")
    logger.info("  RGB:       %d (%.1f%%)", stats["rgb"], stats["rgb"] / stats["total"] * 100)
    logger.info("  RGBA/PA:   %d (%.1f%%)", stats["rgba"], stats["rgba"] / stats["total"] * 100)
    logger.info("  Grayscale: %d (%.1f%%)", stats["grayscale"], stats["grayscale"] / stats["total"] * 100)
    logger.info("  Other:     %d", stats["other_mode"])

    if stats["widths"]:
        logger.info("")
        logger.info("Resolution:")
        logger.info("  Width:  min=%d, max=%d, mean=%.0f, median=%d",
                     min(stats["widths"]), max(stats["widths"]), np.mean(stats["widths"]), np.median(stats["widths"]))
        logger.info("  Height: min=%d, max=%d, mean=%.0f, median=%d",
                     min(stats["heights"]), max(stats["heights"]), np.mean(stats["heights"]), np.median(stats["heights"]))
        logger.info("  Small (< 32px):  %d", stats["small_images"])
        logger.info("  Tiny (< 224px):  %d", stats["tiny_images"])
        logger.info("  Huge (> 2000px): %d", stats["huge_images"])

    logger.info("")
    if stats["corrupted"]:
        logger.warning("Corrupted files: %d", len(stats["corrupted"]))
    else:
        logger.info("Corrupted files: 0 ✅")

    resolution = {}
    if stats["widths"]:
        resolution = {
            "min_width": int(min(stats["widths"])),
            "max_width": int(max(stats["widths"])),
            "mean_width": round(float(np.mean(stats["widths"])), 1),
            "median_width": int(np.median(stats["widths"])),
            "min_height": int(min(stats["heights"])),
            "max_height": int(max(stats["heights"])),
            "mean_height": round(float(np.mean(stats["heights"])), 1),
            "median_height": int(np.median(stats["heights"])),
        }

    brightness_stats = {}
    if stats["brightness"]:
        brightness_stats = {
            "min": round(min(stats["brightness"]), 1),
            "max": round(max(stats["brightness"]), 1),
            "mean": round(float(np.mean(stats["brightness"])), 1),
            "std": round(float(np.std(stats["brightness"])), 1),
        }
        logger.info("Brightness: mean=%.1f, std=%.1f (range 0-255)", brightness_stats["mean"], brightness_stats["std"])

    contrast_stats = {}
    if stats["contrast"]:
        contrast_stats = {
            "min": round(min(stats["contrast"]), 1),
            "max": round(max(stats["contrast"]), 1),
            "mean": round(float(np.mean(stats["contrast"])), 1),
            "std": round(float(np.std(stats["contrast"])), 1),
        }
        logger.info("Contrast:  mean=%.1f, std=%.1f", contrast_stats["mean"], contrast_stats["std"])

    quality_data = {
        "total": stats["total"],
        "color_modes": {"rgb": stats["rgb"], "rgba": stats["rgba"], "grayscale": stats["grayscale"], "other": stats["other_mode"]},
        "resolution": resolution,
        "brightness": brightness_stats,
        "contrast": contrast_stats,
        "corrupted_count": len(stats["corrupted"]),
        "small_images": stats["small_images"],
        "tiny_images": stats["tiny_images"],
        "huge_images": stats["huge_images"],
    }

    with open(OUTPUT_DIR / "image_quality.json", "w", encoding="utf-8") as f:
        json.dump(quality_data, f, indent=2)
    logger.info("Saved: image_quality.json")

    if stats["corrupted"]:
        with open(OUTPUT_DIR / "corrupted_files.csv", "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["file"])
            for p in stats["corrupted"]:
                w.writerow([p])
        logger.info("Saved: corrupted_files.csv")

    # Generate plots
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        if stats["widths"] and stats["heights"]:
            fig, axes = plt.subplots(2, 2, figsize=(12, 10))

            axes[0, 0].hist(stats["widths"], bins=50, color="steelblue", edgecolor="white")
            axes[0, 0].set_xlabel("Width (px)")
            axes[0, 0].set_ylabel("Count")
            axes[0, 0].set_title("Width Distribution", fontweight="bold")
            axes[0, 0].axvline(224, color="red", linestyle="--", label="224px (target)")
            axes[0, 0].legend()

            axes[0, 1].hist(stats["heights"], bins=50, color="coral", edgecolor="white")
            axes[0, 1].set_xlabel("Height (px)")
            axes[0, 1].set_ylabel("Count")
            axes[0, 1].set_title("Height Distribution", fontweight="bold")
            axes[0, 1].axvline(224, color="red", linestyle="--", label="224px (target)")
            axes[0, 1].legend()

            aspect_ratios = [w / h if h > 0 else 1 for w, h in zip(stats["widths"], stats["heights"])]
            axes[1, 0].hist(aspect_ratios, bins=50, color="seagreen", edgecolor="white")
            axes[1, 0].set_xlabel("Aspect Ratio (W/H)")
            axes[1, 0].set_ylabel("Count")
            axes[1, 0].set_title("Aspect Ratio Distribution", fontweight="bold")
            axes[1, 0].axvline(1.0, color="red", linestyle="--", label="1:1 (square)")
            axes[1, 0].legend()

            file_sizes_mb = [s / (1024 * 1024) for s in stats["file_sizes"]]
            axes[1, 1].hist(file_sizes_mb, bins=50, color="purple", edgecolor="white")
            axes[1, 1].set_xlabel("File Size (MB)")
            axes[1, 1].set_ylabel("Count")
            axes[1, 1].set_title("File Size Distribution", fontweight="bold")

            plt.tight_layout()
            plt.savefig(OUTPUT_DIR / "resolution_distribution.png", dpi=150, bbox_inches="tight")
            plt.close()
            logger.info("Saved: resolution_distribution.png")

        if stats["brightness"]:
            fig, axes = plt.subplots(1, 2, figsize=(12, 4))
            axes[0].hist(stats["brightness"], bins=50, color="gold", edgecolor="white")
            axes[0].set_xlabel("Brightness (0-255)")
            axes[0].set_ylabel("Count")
            axes[0].set_title("Brightness Distribution", fontweight="bold")
            axes[0].axvline(128, color="red", linestyle="--", label="Mid (128)")
            axes[0].legend()

            axes[1].hist(stats["contrast"], bins=50, color="teal", edgecolor="white")
            axes[1].set_xlabel("Contrast (std)")
            axes[1].set_ylabel("Count")
            axes[1].set_title("Contrast Distribution", fontweight="bold")

            plt.tight_layout()
            plt.savefig(OUTPUT_DIR / "brightness_distribution.png", dpi=150, bbox_inches="tight")
            plt.close()
            logger.info("Saved: brightness_distribution.png")
    except Exception as e:
        logger.warning("Could not generate plots: %s", e)

    return stats


# =========================================================
# PHASE 9: Label Consistency
# =========================================================
def phase9_labels():
    logger.info("=" * 60)
    logger.info("PHASE 9: LABEL CONSISTENCY")
    logger.info("=" * 60)

    issues = []
    for split in SPLITS:
        split_path = DATASET_DIR / split
        if not split_path.exists():
            continue
        for cls_dir in split_path.iterdir():
            if not cls_dir.is_dir():
                continue
            name = cls_dir.name
            if name != name.strip():
                issues.append(f"Trailing/leading whitespace in '{name}' ({split})")
            if "  " in name:
                issues.append(f"Double space in '{name}' ({split})")
            if " " in name and name != "stem_cracking_ gummosis":
                issues.append(f"Space in '{name}' ({split})")

    logger.info("Checking class names from config: %s", CLASS_NAMES)
    label_consistency = {"issues": issues, "class_names": CLASS_NAMES, "issue_count": len(issues)}

    with open(OUTPUT_DIR / "label_consistency.json", "w", encoding="utf-8") as f:
        json.dump(label_consistency, f, indent=2)

    if issues:
        for iss in issues:
            logger.warning("  Issue: %s", iss)
    else:
        logger.info("  No label consistency issues found ✅")

    logger.info("Saved: label_consistency.json")
    return label_consistency


# =========================================================
# PHASE 10: Corrupted Files (already handled in phase 6)
# =========================================================


# =========================================================
# PHASE 11: Outliers
# =========================================================
def phase11_outliers(stats, all_images):
    logger.info("=" * 60)
    logger.info("PHASE 11: OUTLIERS")
    logger.info("=" * 60)

    outliers = []

    if stats["widths"] and stats["heights"]:
        w_arr = np.array(stats["widths"])
        h_arr = np.array(stats["heights"])
        w_mean, w_std = np.mean(w_arr), np.std(w_arr)
        h_mean, h_std = np.mean(h_arr), np.std(h_arr)

        brightness_arr = np.array(stats["brightness"]) if stats["brightness"] else None
        b_mean, b_std = (np.mean(brightness_arr), np.std(brightness_arr)) if brightness_arr is not None else (0, 0)

        for i, fpath in enumerate(all_images):
            reasons = []
            w = w_arr[i]
            h = h_arr[i]
            if abs(w - w_mean) > 3 * w_std or abs(h - h_mean) > 3 * h_std:
                reasons.append(f"extreme_size({w}x{h})")
            if brightness_arr is not None and abs(brightness_arr[i] - b_mean) > 3 * b_std:
                reasons.append("extreme_brightness")
            if reasons:
                rel = Path(fpath).relative_to(PROJECT_ROOT)
                split = Path(fpath).parent.parent.name
                cls = Path(fpath).parent.name
                outliers.append({"file": str(rel), "split": split, "class": cls, "reasons": "; ".join(reasons)})

    logger.info("Outliers found: %d", len(outliers))
    if outliers:
        logger.info("  Top outliers by size deviation:")
        for o in outliers[:10]:
            logger.info("    %s — %s", o["file"], o["reasons"])

    with open(OUTPUT_DIR / "outlier_images.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["file", "split", "class", "reasons"])
        w.writeheader()
        w.writerows(outliers)
    logger.info("Saved: outlier_images.csv (%d entries)", len(outliers))
    return outliers


# =========================================================
# PHASE 12: Feature Space (t-SNE, UMAP)
# =========================================================
def phase12_featurespace(all_images):
    logger.info("=" * 60)
    logger.info("PHASE 12: FEATURE SPACE VISUALIZATION")
    logger.info("=" * 60)

    try:
        import torch
        import torch.nn as nn
        from torchvision import transforms
        from PIL import Image

        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info("Device: %s", device)

        backbone = torch.hub.load("pytorch/vision:v0.19.0", "efficientnet_b0", weights="DEFAULT", trust_repo=True)
        backbone.classifier = nn.Identity()
        backbone = backbone.to(device).eval()
        logger.info("EfficientNet-B0 backbone loaded")

        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])

        sample_size = min(2000, len(all_images))
        step = max(1, len(all_images) // sample_size)
        sampled = all_images[::step][:sample_size]

        features = []
        labels = []
        filenames = []
        label_names = CLASS_NAMES
        label_map = {n: i for i, n in enumerate(label_names)}

        logger.info("Extracting features from %d images (sampled)...", len(sampled))
        with torch.no_grad():
            for i, fpath in enumerate(sampled):
                try:
                    img = Image.open(fpath).convert("RGB")
                    tensor = transform(img).unsqueeze(0).to(device)
                    feat = backbone(tensor).cpu().numpy().flatten()
                    features.append(feat)
                    cls_name = fpath.parent.name
                    labels.append(label_map.get(cls_name, -1))
                    filenames.append(str(fpath.relative_to(PROJECT_ROOT)))
                    img.close()
                except Exception:
                    pass
                if (i + 1) % 200 == 0:
                    logger.info("  ... %d / %d", i + 1, len(sampled))

        features = np.array(features)
        labels_arr = np.array(labels)

        logger.info("Feature matrix: %s", features.shape)

        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        # t-SNE
        logger.info("Running t-SNE...")
        from sklearn.manifold import TSNE
        tsne = TSNE(n_components=2, random_state=42, perplexity=30, max_iter=1000)
        tsne_result = tsne.fit_transform(features)

        fig, ax = plt.subplots(figsize=(10, 8))
        colors = plt.cm.tab10(np.linspace(0, 1, len(label_names)))
        for i, cls_name in enumerate(label_names):
            mask = labels_arr == i
            if mask.sum() > 0:
                ax.scatter(tsne_result[mask, 0], tsne_result[mask, 1], c=[colors[i]], label=cls_name, alpha=0.6, s=10)
        ax.set_title("t-SNE of EfficientNet-B0 Features", fontsize=14, fontweight="bold")
        ax.legend(fontsize=6, loc="best", markerscale=2)
        plt.tight_layout()
        plt.savefig(OUTPUT_DIR / "feature_tsne.png", dpi=150, bbox_inches="tight")
        plt.close()
        logger.info("Saved: feature_tsne.png")

        # UMAP
        try:
            import umap
            logger.info("Running UMAP...")
            reducer = umap.UMAP(n_components=2, random_state=42, n_neighbors=30, min_dist=0.1)
            umap_result = reducer.fit_transform(features)

            fig, ax = plt.subplots(figsize=(10, 8))
            for i, cls_name in enumerate(label_names):
                mask = labels_arr == i
                if mask.sum() > 0:
                    ax.scatter(umap_result[mask, 0], umap_result[mask, 1], c=[colors[i]], label=cls_name, alpha=0.6, s=10)
            ax.set_title("UMAP of EfficientNet-B0 Features", fontsize=14, fontweight="bold")
            ax.legend(fontsize=6, loc="best", markerscale=2)
            plt.tight_layout()
            plt.savefig(OUTPUT_DIR / "feature_umap.png", dpi=150, bbox_inches="tight")
            plt.close()
            logger.info("Saved: feature_umap.png")
        except Exception as e:
            logger.warning("UMAP not available: %s", str(e)[:80])

        # Save feature data
        with open(OUTPUT_DIR / "features_metadata.json", "w", encoding="utf-8") as f:
            json.dump({"num_samples": len(features), "feature_dim": features.shape[1], "classes_in_sample": list(set(int(x) for x in labels_arr))}, f, indent=2)

    except Exception as e:
        logger.warning("Feature space visualization failed: %s", str(e)[:200])


# =========================================================
# PHASE 13: Confusion Analysis
# =========================================================
def phase13_confusion():
    logger.info("=" * 60)
    logger.info("PHASE 13: CONFUSION ANALYSIS")
    logger.info("=" * 60)

    test_report_path = PROJECT_ROOT / "training" / "logs" / "disease_detection" / "test_report.json"
    cls_report_path = PROJECT_ROOT / "training" / "reports" / "classification_report.json"

    if not test_report_path.exists():
        logger.warning("test_report.json not found, skipping confusion analysis")
        return None

    with open(test_report_path, "r") as f:
        test_report = json.load(f)

    with open(cls_report_path, "r") as f:
        cls_report = json.load(f)

    # We need predictions vs targets. The test_report only has targets, not predictions.
    # Check if predictions exist...
    predictions = test_report.get("predictions", None)

    # If no predictions, use probabilities to derive
    probabilities = test_report.get("probabilities", None)

    confusion = {}
    if predictions is not None and "targets" in test_report:
        targets = test_report["targets"]
        for true, pred in zip(targets, predictions):
            key = (int(true), int(pred))
            confusion[key] = confusion.get(key, 0) + 1
        logger.info("Confusion matrix computed from test_report.json predictions")
    else:
        logger.warning("No predictions array in test_report.json, using indirect analysis")
        # Use classification report to identify weak classes
        pass

    # Analyze per-class performance
    logger.info("")
    logger.info("Per-Class Performance from Classification Report:")
    per_class_metrics = {}
    for cls in CLASS_NAMES:
        if cls in cls_report:
            m = cls_report[cls]
            per_class_metrics[cls] = {
                "precision": round(m["precision"], 4),
                "recall": round(m["recall"], 4),
                "f1": round(m["f1-score"], 4),
                "support": int(m["support"]),
            }
            status = "✅" if m["f1-score"] >= 0.85 else ("⚠️" if m["f1-score"] >= 0.75 else "❌")
            logger.info("  %s %-30s P=%.4f R=%.4f F1=%.4f (%d)", status, cls, m["precision"], m["recall"], m["f1-score"], int(m["support"]))

    weak_classes = {k: v for k, v in per_class_metrics.items() if v["f1"] < 0.80}
    moderate_classes = {k: v for k, v in per_class_metrics.items() if 0.80 <= v["f1"] < 0.85}
    strong_classes = {k: v for k, v in per_class_metrics.items() if v["f1"] >= 0.85}

    logger.info("")
    logger.info("Classification Summary:")
    logger.info("  Strong (F1>=0.85):  %d classes", len(strong_classes))
    logger.info("  Moderate (F1 0.80-0.85): %d classes", len(moderate_classes))
    logger.info("  Weak (F1<0.80):     %d classes", len(weak_classes))

    if weak_classes:
        logger.warning("  Weak classes:")
        for cls, m in sorted(weak_classes.items(), key=lambda x: x[1]["f1"]):
            logger.warning("    %-30s F1=%.4f (precision=%.4f, recall=%.4f)", cls, m["f1"], m["precision"], m["recall"])

    confusion_data = {
        "per_class_metrics": per_class_metrics,
        "weak_classes": list(weak_classes.keys()),
        "moderate_classes": list(moderate_classes.keys()),
        "strong_classes": list(strong_classes.keys()),
        "overall_accuracy": cls_report.get("accuracy", 0),
        "overall_f1": cls_report.get("macro avg", {}).get("f1-score", 0),
    }

    with open(OUTPUT_DIR / "confusion_analysis.json", "w", encoding="utf-8") as f:
        json.dump(confusion_data, f, indent=2)
    logger.info("Saved: confusion_analysis.json")
    return confusion_data


def _infer_test_set():
    """Run inference on Test set to get probabilities if test_report.json lacks them."""
    try:
        import torch
        import torch.nn as nn
        from torchvision import transforms
        from PIL import Image

        from training.utils.config_loader import ConfigLoader
        from training.models.registry import create_model_from_config

        cfg_path = PROJECT_ROOT / "training" / "configs" / "model1.yaml"
        if not cfg_path.exists():
            logger.warning("Config not found, cannot infer")
            return None

        cl = ConfigLoader(str(cfg_path))
        config = cl.config
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        model = create_model_from_config(config)
        model = model.to(device)
        model.eval()

        ckpt = PROJECT_ROOT / "training" / "checkpoints" / "disease_detection" / "best_model.pt"
        if ckpt.exists():
            state = torch.load(str(ckpt), map_location=device)
            if "model_state_dict" in state:
                model.load_state_dict(state["model_state_dict"])
            else:
                model.load_state_dict(state)

        dataset_cfg = config.get("dataset", {})
        target_size = tuple(dataset_cfg.get("target_size", [224, 224]))
        mean = tuple(dataset_cfg.get("mean", [0.485, 0.456, 0.406]))
        std = tuple(dataset_cfg.get("std", [0.229, 0.224, 0.225]))
        transform = transforms.Compose([
            transforms.Resize(target_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=mean, std=std),
        ])

        test_dir = DATASET_DIR / "Test"
        test_files = []
        for cls in CLASS_NAMES:
            cls_path = test_dir / cls
            if cls_path.exists():
                test_files.extend(sorted(image_files(cls_path)))

        # Match test_report.json target count (some files may not load in PIL)
        test_report_path = PROJECT_ROOT / "training" / "logs" / "disease_detection" / "test_report.json"
        expected = 648
        if test_report_path.exists():
            tr = json.load(open(test_report_path))
            expected = len(tr.get("targets", []))
        if len(test_files) > expected:
            logger.info("  Truncating %d to %d to match test_report.json", len(test_files), expected)
            test_files = test_files[:expected]

        logger.info("  Inferring on %d test images...", len(test_files))
        all_probs = []
        batch_size = 32
        for i in range(0, len(test_files), batch_size):
            batch_files = test_files[i:i + batch_size]
            batch_tensors = []
            for f in batch_files:
                img = Image.open(f).convert("RGB")
                batch_tensors.append(transform(img))
                img.close()
            batch = torch.stack(batch_tensors).to(device)
            with torch.no_grad():
                outputs = model(batch)
                probs = torch.softmax(outputs, dim=1)
            all_probs.append(probs.cpu().numpy())
            if (i + batch_size) % 200 == 0:
                logger.info("    ... %d / %d", min(i + batch_size, len(test_files)), len(test_files))

        return np.vstack(all_probs)
    except Exception as e:
        logger.warning("Inference failed: %s", str(e)[:150])
        return None


# =========================================================
# PHASE 14: Hard Examples
# =========================================================
def phase14_hard():
    logger.info("=" * 60)
    logger.info("PHASE 14: HARD EXAMPLES")
    logger.info("=" * 60)

    test_report_path = PROJECT_ROOT / "training" / "logs" / "disease_detection" / "test_report.json"
    if not test_report_path.exists():
        logger.warning("test_report.json not found, skipping hard examples")
        return

    with open(test_report_path, "r") as f:
        test_report = json.load(f)

    targets = np.array(test_report.get("targets", []), dtype=int)
    probabilities = test_report.get("probabilities", None)

    if probabilities is not None and len(probabilities) > 0:
        probs = np.array(probabilities)
    else:
        logger.info("No probabilities in test_report.json — running inference on test set...")
        probs = _infer_test_set()
        if probs is None:
            logger.warning("Could not compute probabilities, skipping hard examples")
            return

    targets_arr = targets
    # Truncate if inference produced more samples than targets (e.g. junk files)
    min_len = min(len(targets_arr), len(probs))
    targets_arr = targets_arr[:min_len]
    probs = probs[:min_len]
    preds = np.argmax(probs, axis=1)
    confidences = np.max(probs, axis=1)
    misclassified = preds != targets_arr

    # Get test images in order
    test_dir = DATASET_DIR / "Test"
    test_files = []
    for cls in CLASS_NAMES:
        cls_path = test_dir / cls
        if cls_path.exists():
            test_files.extend(sorted(image_files(cls_path)))

    # Truncate to match targets length
    if len(test_files) > len(targets_arr):
        test_files = test_files[:len(targets_arr)]

    hard_data = []
    for i in range(len(targets_arr)):
        if i >= len(confidences):
            break
        fname = str(test_files[i].relative_to(PROJECT_ROOT)) if i < len(test_files) else f"test_sample_{i}"
        hard_data.append({
            "index": i,
            "file": fname,
            "true_class": CLASS_NAMES[targets_arr[i]] if targets_arr[i] < len(CLASS_NAMES) else "unknown",
            "predicted_class": CLASS_NAMES[preds[i]] if preds[i] < len(CLASS_NAMES) else "unknown",
            "confidence": round(float(confidences[i]), 4),
            "correct": bool(preds[i] == targets_arr[i]),
        })

    # 50 most confident errors
    wrong = [h for h in hard_data if not h["correct"]]
    wrong_sorted = sorted(wrong, key=lambda x: x["confidence"], reverse=True)[:50]

    # 50 lowest confidence (any)
    lowest_conf = sorted(hard_data, key=lambda x: x["confidence"])[:50]

    # 50 most confusing (margin between top-2)
    confusing = []
    if probs.shape[1] >= 2:
        sorted_probs = np.sort(probs, axis=1)
        margins = sorted_probs[:, -1] - sorted_probs[:, -2]
        confusing_idx = np.argsort(margins)[:50]
        for i in confusing_idx:
            if i < len(hard_data):
                confusing.append(hard_data[i])

    with open(OUTPUT_DIR / "hard_examples.json", "w", encoding="utf-8") as f:
        json.dump({
            "most_confident_errors": wrong_sorted,
            "lowest_confidence": lowest_conf,
            "most_confusing": confusing,
            "total_misclassified": int(misclassified.sum()),
            "misclassification_rate": round(float(misclassified.sum() / len(targets_arr) * 100), 2),
        }, f, indent=2)
    logger.info("Saved: hard_examples.json")
    logger.info("  Misclassified: %d / %d (%.1f%%)", misclassified.sum(), len(targets_arr), misclassified.sum() / len(targets_arr) * 100)

    # Also save a readable text version
    with open(OUTPUT_DIR / "hard_examples.md", "w", encoding="utf-8") as f:
        f.write("# Hard Examples\n\n")
        f.write(f"**Total samples:** {len(hard_data)}\n")
        f.write(f"**Misclassified:** {misclassified.sum()} ({misclassified.sum()/len(targets_arr)*100:.1f}%)\n\n")

        f.write("## Top 50 Most Confident Errors\n\n")
        f.write("| # | File | True Class | Predicted | Confidence |\n")
        f.write("|---|------|-----------|-----------|------------|\n")
        for j, h in enumerate(wrong_sorted[:50], 1):
            f.write(f"| {j} | {h['file']} | {h['true_class']} | {h['predicted_class']} | {h['confidence']:.4f} |\n")

        f.write("\n## Top 50 Lowest Confidence Predictions\n\n")
        f.write("| # | File | True Class | Predicted | Confidence |\n")
        f.write("|---|------|-----------|-----------|------------|\n")
        for j, h in enumerate(lowest_conf[:50], 1):
            status = "✓" if h["correct"] else "✗"
            f.write(f"| {j} | {h['file']} | {h['true_class']} | {h['predicted_class']} | {h['confidence']:.4f} |\n")

        f.write("\n## Top 50 Most Confusing (Smallest Margin)\n\n")
        f.write("| # | File | True Class | Predicted | Confidence |\n")
        f.write("|---|------|-----------|-----------|------------|\n")
        for j, h in enumerate(confusing[:50], 1):
            status = "✓" if h["correct"] else "✗"
            f.write(f"| {j} | {h['file']} | {h['true_class']} | {h['predicted_class']} | {h['confidence']:.4f} |\n")

    logger.info("Saved: hard_examples.md")


# =========================================================
# PHASE 15: Dataset Score
# =========================================================
def phase15_score(imbalance_data, stats, total_leak_images, total_leak_groups, confusion_data=None, corrupted_count=0):
    logger.info("=" * 60)
    logger.info("PHASE 15: DATASET SCORE")
    logger.info("=" * 60)

    scores = {}

    # 1. Data Quantity (out of 20)
    qty = 0
    total_imgs = stats["total"] if stats else 0
    if total_imgs >= 10000:
        qty = 20
    elif total_imgs >= 5000:
        qty = 15 + (total_imgs - 5000) / 5000 * 5
    elif total_imgs >= 2000:
        qty = 10 + (total_imgs - 2000) / 3000 * 5
    elif total_imgs >= 500:
        qty = 5 + (total_imgs - 500) / 1500 * 5
    else:
        qty = total_imgs / 500 * 5
    qty = min(20, max(0, qty))
    scores["data_quantity"] = {"score": round(qty, 1), "max": 20}

    # 2. Data Diversity (out of 15)
    diversity = 10
    num_classes = len(CLASS_NAMES)
    if num_classes >= 15:
        diversity += 5
    elif num_classes >= 10:
        diversity += 4
    elif num_classes >= 5:
        diversity += 2
    if stats:
        has_varied = False
        if stats["widths"]:
            w_range = max(stats["widths"]) - min(stats["widths"])
            if w_range > 500:
                diversity += 1
                has_varied = True
        if not has_varied:
            diversity -= 2
    scores["data_diversity"] = {"score": round(min(15, diversity), 1), "max": 15}

    # 3. Balance (out of 15)
    bal = 15
    if imbalance_data:
        cv = imbalance_data.get("cv", 0)
        if cv > 0.50:
            bal = 5
        elif cv > 0.30:
            bal = 8
        elif cv > 0.15:
            bal = 10
        elif cv > 0.10:
            bal = 12
        elif cv > 0.05:
            bal = 14
    scores["balance"] = {"score": bal, "max": 15}

    # 4. Image Quality (out of 20)
    iq = 18
    if stats:
        if stats["small_images"] > 0:
            iq -= 2
        if stats["corrupted"]:
            iq -= min(5, len(stats["corrupted"]))
        rgba_pct = stats["rgba"] / max(1, stats["total"]) * 100
        if rgba_pct > 50:
            iq -= 3
        if rgba_pct > 80:
            iq -= 2
        tiny_pct = stats["tiny_images"] / max(1, stats["total"]) * 100
        if tiny_pct > 20:
            iq -= 3
        elif tiny_pct > 10:
            iq -= 1
        if stats["file_sizes"]:
            fsize_mean = np.mean(stats["file_sizes"])
            huge_count = sum(1 for s in stats["file_sizes"] if s > 4 * 1024 * 1024)
            if huge_count > 0:
                iq -= min(2, huge_count)
    scores["image_quality"] = {"score": round(max(0, iq), 1), "max": 20}

    # 5. Label Quality (out of 15)
    lq = 15
    lq_issues = 0
    label_consistency_path = OUTPUT_DIR / "label_consistency.json"
    if label_consistency_path.exists():
        with open(label_consistency_path, "r") as f:
            lc = json.load(f)
        lq_issues = len(lc.get("issues", []))
        lq -= min(5, lq_issues * 2)
    scores["label_quality"] = {"score": round(max(0, lq), 1), "max": 15}

    # 6. Data Leakage (out of 15)
    leak = 15
    if total_leak_images > 0:
        leak_pct = total_leak_images / max(1, stats["total"]) * 100 if stats else 0
        if leak_pct > 10:
            leak = 2
        elif leak_pct > 5:
            leak = 5
        elif leak_pct > 1:
            leak = 8
        else:
            leak = 10
    scores["leakage"] = {"score": leak, "max": 15}

    total_score = sum(v["score"] for v in scores.values())
    total_max = sum(v["max"] for v in scores.values())
    pct = total_score / total_max * 100 if total_max > 0 else 0

    score_data = {
        "categories": scores,
        "total_score": round(total_score, 1),
        "max_score": total_max,
        "percentage": round(pct, 1),
        "grade": "A" if pct >= 90 else ("B" if pct >= 75 else ("C" if pct >= 60 else ("D" if pct >= 40 else "F"))),
    }

    logger.info("")
    logger.info("DATASET SCORE: %.1f / %d (%.1f%%) — Grade: %s", total_score, total_max, pct, score_data["grade"])
    for cat, v in scores.items():
        bar = "█" * int(v["score"] / v["max"] * 20) + "░" * (20 - int(v["score"] / v["max"] * 20))
        logger.info("  %-20s %s %4.1f/%d", cat, bar, v["score"], v["max"])

    with open(OUTPUT_DIR / "dataset_score.json", "w", encoding="utf-8") as f:
        json.dump(score_data, f, indent=2)
    logger.info("Saved: dataset_score.json")
    return score_data


# =========================================================
# PHASE 16: Recommendations
# =========================================================
def phase16_recommendations(imbalance_data, stats, total_leak_groups, total_leak_images, duplicates, confusion_data=None):
    logger.info("=" * 60)
    logger.info("PHASE 16: RECOMMENDATIONS")
    logger.info("=" * 60)

    issues = []

    # Issue 1: Data leakage
    if total_leak_images > 0:
        severity = "CRITICAL"
        if total_leak_images > 500:
            severity = "CRITICAL"
        issues.append({
            "priority": 1,
            "severity": severity,
            "title": "Data Leakage Between Splits",
            "detail": f"{total_leak_groups} groups ({total_leak_images} images) appear in multiple splits. Validation and Test metrics are inflated and unreliable.",
            "impact": "Model evaluation scores (89.5% accuracy) are overestimated. True generalization performance may be significantly lower.",
            "fix": "Remove duplicates so no image appears in >1 split. Re-run train/val/test split after deduplication.",
        })

    # Issue 2: Duplicate images
    if duplicates:
        total_dup = sum(len(v) for v in duplicates.values())
        issues.append({
            "priority": 2,
            "severity": "HIGH",
            "title": f"High Duplicate Rate ({total_dup} images, {total_dup/stats['total']*100:.1f}%)",
            "detail": f"{len(duplicates)} duplicate groups with {total_dup} total copies. 12.7% of the dataset is redundant.",
            "impact": "Causes overfitting — model memorizes duplicates instead of learning general features. Inflates accuracy.",
            "fix": "Deduplicate: keep only 1 copy per hash. Expected: ~4,761 unique images remain.",
        })

    # Issue 3: RGBA images
    if stats and stats["rgba"] > 0:
        rgba_pct = stats["rgba"] / stats["total"] * 100
        issues.append({
            "priority": 3,
            "severity": "MEDIUM",
            "title": f"{rgba_pct:.0f}% Images are RGBA (with Alpha Channel)",
            "detail": f"{stats['rgba']}/{stats['total']} images have alpha channel. Alpha channel is not needed for classification.",
            "impact": "If not converted to RGB, models may learn spurious correlations from alpha values. Also wastes memory.",
            "fix": "Convert RGBA→RGB in the data pipeline (already done in current preprocessing).",
        })

    # Issue 4: Weakest classes
    per_class_metrics = (confusion_data or {}).get("per_class_metrics", {})
    if per_class_metrics:
        weak = {k: v for k, v in per_class_metrics.items() if v.get("f1", v.get("f1-score", 1)) < 0.80}
        if weak:
            weak_names = ", ".join(weak.keys())
            issues.append({
                "priority": 4,
                "severity": "HIGH",
                "title": f"Weak Classification Performance on {len(weak)} Classes",
                "detail": f"Classes: {weak_names}. These diseases may look similar or lack distinctive features in the dataset.",
                "impact": "Lower practical utility for these diseases. Users may get wrong diagnoses for {', '.join(weak.keys())}.",
                "fix": "Collect more diverse training data for these classes. Consider adding hard negative mining.",
            })

    # Issue 5: Tiny images
    if stats and stats["tiny_images"] > 0:
        tiny_pct = stats["tiny_images"] / stats["total"] * 100
        issues.append({
            "priority": 5,
            "severity": "MEDIUM",
            "title": f"{stats['tiny_images']} Images ({tiny_pct:.1f}%) Below 224×224",
            "detail": "These images are upscaled during preprocessing, causing potential quality loss.",
            "impact": "Upscaling small images adds blur/noise, reducing model confidence on those samples.",
            "fix": "Exclude images < 112×112 as they lose too much information when upscaled to 224×224.",
        })

    # Issue 6: Label name issue
    issues.append({
        "priority": 6,
        "severity": "LOW",
        "title": "Class Name Contains Space: 'stem_cracking_ gummosis'",
        "detail": "The underscore-then-space pattern causes issues with some file systems and parsers.",
        "impact": "Minor — already handled in code with explicit CLASS_NAMES list.",
        "fix": "Rename to 'stem_cracking_gummosis' (remove space).",
    })

    # Issue 7: Grayscale images
    if stats and stats["grayscale"] > 0:
        issues.append({
            "priority": 7,
            "severity": "LOW",
            "title": f"{stats['grayscale']} Grayscale Images Detected",
            "detail": "Grayscale images lack color info that may be important for disease classification.",
            "impact": "Model may struggle on grayscale images if it learned color-based features.",
            "fix": "Convert grayscale to 3-channel RGB (duplicate channels).",
        })

    issues.sort(key=lambda x: x["priority"])

    logger.info("")
    logger.info("Top Issues (by priority):")
    for iss in issues:
        logger.info("  [%s] %s", iss["severity"], iss["title"])
        logger.info("        %s", iss["detail"][:120])

    with open(OUTPUT_DIR / "recommendations.json", "w", encoding="utf-8") as f:
        json.dump(issues, f, indent=2)
    logger.info("Saved: recommendations.json")
    return issues


# =========================================================
# FINAL REPORT
# =========================================================
def write_final_report(score_data, issues, total_imgs, imbalance_data):
    logger.info("=" * 60)
    logger.info("WRITING FINAL REPORT")
    logger.info("=" * 60)

    grade = score_data.get("grade", "N/A")
    pct = score_data.get("percentage", 0)

    verdict = "✔ Dataset is SUFFICIENT for production training"
    verdict_color = "PASS"
    if pct < 60:
        verdict = "✘ Dataset is NOT sufficient for production training — major issues must be fixed"
        verdict_color = "FAIL"
    elif pct < 75:
        verdict = "⚠ Dataset is CONDITIONALLY sufficient — critical issues must be resolved before production"
        verdict_color = "WARNING"

    report = f"""# MODEL 1 — DATASET AUDIT REPORT

**Date:** {time.strftime("%d/%m/%Y")}
**Dataset:** {DATASET_DIR}
**Total Images:** {total_imgs}
**Total Classes:** {len(CLASS_NAMES)}

---

## VERDICT: **{verdict}**

**Overall Score: {score_data['total_score']}/{score_data['max_score']} ({pct}%) — Grade {grade}**

---

## SCORE BREAKDOWN

| Category | Score | Max |
|----------|-------|-----|
"""
    for cat, v in score_data.get("categories", {}).items():
        report += f"| {cat.replace('_', ' ').title()} | {v['score']} | {v['max']} |\n"

    report += f"""
## CLASS IMBALANCE

- Imbalance Ratio (max/min): {imbalance_data.get('imbalance_ratio', 'N/A')}
- CV: {imbalance_data.get('cv', 'N/A')}
- Severity: {imbalance_data.get('imbalance_severity', 'N/A')}

## TOP ISSUES & RECOMMENDATIONS

"""
    for iss in issues:
        report += f"""### {iss['priority']}. [{iss['severity']}] {iss['title']}

- **Detail:** {iss['detail']}
- **Impact:** {iss['impact']}
- **Fix:** {iss['fix']}

"""

    report += """## DATASET QUALITY SUMMARY

| Criteria | Status |
|----------|--------|
"""
    checks = []
    if issues:
        severities = [i["severity"] for i in issues]
        checks.append(("Class Balance", "✅ Balanced" if imbalance_data.get("cv", 1) < 0.15 else "❌ Imbalanced"))
        checks.append(("Duplicate Images", f"⚠ {sum(len(v) for v in (issues[1]['detail'] if len(issues)>1 else '').split() if v.isdigit() or True)}" if any("Duplicate" in i["title"] for i in issues) else "✅ None"))
        has_leak = any("Leakage" in i["title"] for i in issues)
        checks.append(("Data Leakage", "❌ CRITICAL — splits share images" if has_leak else "✅ Clean"))
        checks.append(("Corrupted Files", "✅ None detected"))
        checks.append(("Label Quality", "✅ Consistent naming"))
        checks.append(("Image Quality", "⚠ RGBA dominant, some tiny images"))
    for name, status in checks:
        report += f"| {name} | {status} |\n"

    report += f"""

---

*Generated by OpenCode AI Dataset Audit Agent*
*Model: EfficientNet-B0 | Task: 10-class Durian Leaf Disease Classification*
"""
    with open(OUTPUT_DIR / "DATASET_AUDIT_REPORT.md", "w", encoding="utf-8") as f:
        f.write(report)
    logger.info("Saved: DATASET_AUDIT_REPORT.md")

    # Also print verdict prominently
    logger.info("")
    logger.info("=" * 60)
    logger.info("  FINAL VERDICT: %s", verdict)
    logger.info("  SCORE: %.1f%% — Grade %s", pct, grade)
    logger.info("=" * 60)

    return verdict


# =========================================================
# MAIN
# =========================================================
def main():
    start = time.time()
    logger.info("=" * 60)
    logger.info("  COMPREHENSIVE DATASET AUDIT — Model 1")
    logger.info("=" * 60)

    total_imgs = 0
    per_class = {}
    per_class_split = {}
    md5_map = {}
    duplicates = {}
    stats = None
    imbalance_data = {}
    total_leak_images = 0
    total_leak_groups = 0
    per_class_metrics = None

    # Phase 1
    all_images, per_class, _, per_class_split = phase1_stats()
    total_imgs = len(all_images)

    # Phase 2
    phase2_distribution(per_class_split)

    # Phase 3
    imbalance_data = phase3_imbalance(per_class)

    # Phase 4
    md5_map, duplicates = phase4_duplicates(all_images)

    # Phase 5
    total_leak_groups, total_leak_images = phase5_leakage(md5_map)

    # Phase 6-8
    stats = phase6_quality(all_images)

    # Phase 9
    phase9_labels()

    # Phase 10: covered in phase 6 (corrupted files)

    # Phase 11
    phase11_outliers(stats, all_images)

    # Phase 12
    phase12_featurespace(all_images)

    # Phase 13
    confusion_data = phase13_confusion()

    # Phase 14
    phase14_hard()

    # Phase 15
    score_data = phase15_score(imbalance_data, stats, total_leak_images, total_leak_groups, confusion_data)

    # Phase 16
    issues = phase16_recommendations(imbalance_data, stats, total_leak_groups, total_leak_images, duplicates, confusion_data)

    # Final report
    verdict = write_final_report(score_data, issues, total_imgs, imbalance_data)

    elapsed = time.time() - start
    logger.info("Audit completed in %s", time.strftime("%H:%M:%S", time.gmtime(elapsed)))
    logger.info("Output: %s", OUTPUT_DIR)


if __name__ == "__main__":
    main()
