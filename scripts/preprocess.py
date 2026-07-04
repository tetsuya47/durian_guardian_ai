#!/usr/bin/env python3
"""
Data Preprocessing
==================

Load raw images from dataset/Train, Validation, Test,
apply preprocessing, augmentation, and save as TFRecords
or NumPy arrays for training.

Usage:
    python scripts/preprocess.py
    python scripts/preprocess.py --target-size 224 224
    python scripts/preprocess.py --augment --rotation 20
"""

import argparse
import logging
import sys
import time
from pathlib import Path
from typing import List, Optional, Tuple

import cv2
import numpy as np
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

logger = logging.getLogger("durian_guardian.preprocess")

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


def setup_logging(verbose: bool) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stdout,
    )


class ImagePreprocessor:
    def __init__(
        self,
        target_size: Tuple[int, int] = (224, 224),
        normalize: bool = True,
        augment: bool = False,
        rotation_range: int = 0,
        zoom_range: float = 0.0,
        horizontal_flip: bool = False,
        brightness_range: Optional[Tuple[float, float]] = None,
    ):
        self.target_size = target_size
        self.normalize = normalize
        self.augment = augment
        self.rotation_range = rotation_range
        self.zoom_range = zoom_range
        self.horizontal_flip = horizontal_flip
        self.brightness_range = brightness_range

    def load_and_resize(self, image_path: str) -> Optional[np.ndarray]:
        try:
            img = Image.open(image_path).convert("RGB")
            img = img.resize(self.target_size, Image.Resampling.LANCZOS)
            return np.array(img, dtype=np.float32)
        except Exception as exc:
            logger.warning("Cannot load %s: %s", image_path, exc)
            return None

    def normalize_image(self, image: np.ndarray) -> np.ndarray:
        return image / 255.0

    def apply_augmentation(self, image: np.ndarray) -> np.ndarray:
        img = image.astype(np.uint8)
        if self.rotation_range > 0:
            angle = np.random.uniform(-self.rotation_range, self.rotation_range)
            h, w = img.shape[:2]
            M = cv2.getRotationMatrix2D((w // 2, h // 2), angle, 1.0)
            img = cv2.warpAffine(img, M, (w, h), borderMode=cv2.BORDER_REFLECT)

        if self.zoom_range > 0:
            scale = 1 + np.random.uniform(-self.zoom_range, self.zoom_range)
            h, w = img.shape[:2]
            nh, nw = int(h * scale), int(w * scale)
            img = cv2.resize(img, (nw, nh), interpolation=cv2.INTER_LINEAR)
            if scale > 1:
                y = (nh - h) // 2
                x = (nw - w) // 2
                img = img[y:y + h, x:x + w]
            else:
                pad_h = (h - nh) // 2
                pad_w = (w - nw) // 2
                img = cv2.copyMakeBorder(
                    img, pad_h, h - nh - pad_h, pad_w, w - nw - pad_w,
                    cv2.BORDER_REFLECT,
                )

        if self.horizontal_flip and np.random.random() > 0.5:
            img = cv2.flip(img, 1)

        if self.brightness_range:
            factor = np.random.uniform(*self.brightness_range)
            img = np.clip(img.astype(np.float32) * factor, 0, 255).astype(np.uint8)

        return img.astype(np.float32)

    def process_image(self, image_path: str) -> Optional[np.ndarray]:
        img = self.load_and_resize(image_path)
        if img is None:
            return None
        if self.augment:
            img = self.apply_augmentation(img)
        if self.normalize:
            img = self.normalize_image(img)
        return img

    def process_dataset_split(
        self, split_path: Path
    ) -> Tuple[np.ndarray, np.ndarray, List[str]]:
        images: List[np.ndarray] = []
        labels: List[int] = []
        paths: List[str] = []

        for class_idx, class_name in enumerate(DISEASE_CLASSES):
            class_dir = split_path / class_name
            if not class_dir.exists():
                logger.warning("Missing class directory: %s", class_dir)
                continue

            image_files = sorted(class_dir.iterdir())
            for img_path in image_files:
                if img_path.suffix.lower() not in (".jpg", ".jpeg", ".png", ".bmp", ".webp"):
                    continue
                processed = self.process_image(str(img_path))
                if processed is not None:
                    images.append(processed)
                    labels.append(class_idx)
                    paths.append(str(img_path))

        if not images:
            return np.array([]), np.array([]), []

        return np.array(images), np.array(labels), paths


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Data Preprocessing",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--target-size", nargs=2, type=int, default=[224, 224],
                        help="Target image size (height width)")
    parser.add_argument("--no-normalize", action="store_true",
                        help="Skip image normalization")
    parser.add_argument("--augment", action="store_true",
                        help="Apply data augmentation")
    parser.add_argument("--rotation", type=int, default=20,
                        help="Max rotation angle for augmentation")
    parser.add_argument("--zoom", type=float, default=0.1,
                        help="Max zoom range for augmentation")
    parser.add_argument("--flip", action="store_true",
                        help="Apply horizontal flip augmentation")
    parser.add_argument("--brightness", type=float, nargs=2, default=None,
                        help="Brightness range (min max)")
    parser.add_argument("--output", type=str, default="training/preprocessed",
                        help="Output directory for preprocessed data")
    parser.add_argument("--verbose", action="store_true",
                        help="Enable debug logging")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    setup_logging(args.verbose)

    dataset_dir = PROJECT_ROOT / "dataset"
    output_dir = PROJECT_ROOT / args.output
    output_dir.mkdir(parents=True, exist_ok=True)

    preprocessor = ImagePreprocessor(
        target_size=tuple(args.target_size),
        normalize=not args.no_normalize,
        augment=args.augment,
        rotation_range=args.rotation,
        zoom_range=args.zoom,
        horizontal_flip=args.flip,
        brightness_range=tuple(args.brightness) if args.brightness else None,
    )

    for split_name in ("Train", "Validation", "Test"):
        split_path = dataset_dir / split_name
        if not split_path.exists():
            logger.warning("Split not found: %s", split_path)
            continue

        logger.info("Processing %s...", split_name)
        t0 = time.time()
        images, labels, paths = preprocessor.process_dataset_split(split_path)
        elapsed = time.time() - t0

        if len(images) == 0:
            logger.warning("  No images processed for %s", split_name)
            continue

        out_file = output_dir / f"{split_name.lower()}.npz"
        np.savez_compressed(
            str(out_file),
            images=images,
            labels=labels,
            paths=paths,
            class_names=DISEASE_CLASSES,
            target_size=args.target_size,
        )
        logger.info("  Saved %d samples to %s (%.2fs)", len(images), out_file, elapsed)

    logger.info("Done.")


if __name__ == "__main__":
    main()
