#!/usr/bin/env python3
"""
Dataset Split Utility
=====================

Analyze and optionally re-split the dataset.
Current split: Train/Validation/Test are already separated.

Usage:
    python scripts/split_dataset.py --analyze
    python scripts/split_dataset.py --stats
    python scripts/split_dataset.py --validate-consistency
"""

import argparse
import logging
import sys
from collections import Counter
from pathlib import Path
from typing import List, Optional

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

logger = logging.getLogger("durian_guardian.split")

DISEASE_CLASSES = [
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

SPLITS = ["Train", "Validation", "Test"]


def setup_logging(verbose: bool) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stdout,
    )


def analyze_dataset(dataset_dir: Path) -> dict:
    stats: dict = {}
    for split in SPLITS:
        split_path = dataset_dir / split
        if not split_path.exists():
            logger.warning("Split not found: %s", split_path)
            continue

        class_counts: dict = {}
        total = 0
        for class_name in DISEASE_CLASSES:
            class_dir = split_path / class_name
            if not class_dir.exists():
                count = 0
            else:
                count = len([
                    f for f in class_dir.iterdir()
                    if f.suffix.lower() in (".jpg", ".jpeg", ".png", ".bmp", ".webp")
                ])
            class_counts[class_name] = count
            total += count

        stats[split] = {
            "total": total,
            "classes": class_counts,
        }
    return stats


def print_stats(stats: dict) -> None:
    logger.info("")
    logger.info("=" * 80)
    logger.info("  DATASET DISTRIBUTION REPORT")
    logger.info("=" * 80)

    header = f"{'Class':40s}"
    for split in SPLITS:
        header += f" {split:>12s}"
    header += f" {'Total':>8s}"
    logger.info(header)
    logger.info("-" * 80)

    grand_totals = {s: stats[s]["total"] for s in SPLITS if s in stats}
    for class_name in DISEASE_CLASSES:
        row = f"{class_name:40s}"
        class_total = 0
        for split in SPLITS:
            if split in stats:
                count = stats[split]["classes"].get(class_name, 0)
                row += f" {count:>12d}"
                class_total += count
        row += f" {class_total:>8d}"
        logger.info(row)

    logger.info("-" * 80)
    total_row = f"{'TOTAL':40s}"
    all_total = 0
    for split in SPLITS:
        if split in stats:
            total_row += f" {stats[split]['total']:>12d}"
            all_total += stats[split]["total"]
    total_row += f" {all_total:>8d}"
    logger.info(total_row)
    logger.info("=" * 80)


def validate_consistency(dataset_dir: Path) -> bool:
    valid = True
    for split in SPLITS:
        split_path = dataset_dir / split
        if not split_path.exists():
            logger.error("Missing split: %s", split)
            valid = False
            continue

        existing_classes = set(d.name for d in split_path.iterdir() if d.is_dir())
        expected_classes = set(DISEASE_CLASSES)
        missing = expected_classes - existing_classes
        extra = existing_classes - expected_classes

        if missing:
            logger.warning("%s - Missing classes: %s", split, ", ".join(sorted(missing)))
            valid = False
        if extra:
            logger.warning("%s - Unexpected classes: %s", split, ", ".join(sorted(extra)))

    if valid:
        logger.info("All splits valid and consistent.")
    return valid


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Dataset Split Utility",
    )
    parser.add_argument("--analyze", action="store_true",
                        help="Show dataset distribution")
    parser.add_argument("--stats", action="store_true",
                        help="Show detailed statistics")
    parser.add_argument("--validate-consistency", action="store_true",
                        help="Validate dataset structure")
    parser.add_argument("--verbose", action="store_true",
                        help="Enable debug logging")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    setup_logging(args.verbose)

    dataset_dir = PROJECT_ROOT / "dataset"

    if not dataset_dir.exists():
        logger.error("Dataset directory not found: %s", dataset_dir)
        sys.exit(1)

    if args.validate_consistency:
        valid = validate_consistency(dataset_dir)
        if not valid:
            logger.warning("Dataset has inconsistencies.")

    if args.analyze or args.stats:
        stats = analyze_dataset(dataset_dir)
        print_stats(stats)

    if not any([args.analyze, args.stats, args.validate_consistency]):
        logger.info("Use --analyze, --stats, or --validate-consistency.")
        stats = analyze_dataset(dataset_dir)
        print_stats(stats)


if __name__ == "__main__":
    main()
