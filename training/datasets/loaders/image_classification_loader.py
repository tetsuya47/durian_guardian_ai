"""Image classification dataset loader with corruption detection and reporting."""

import logging
from pathlib import Path
from typing import Callable, Dict, List, Optional, Tuple

import torch
from torch.utils.data import Dataset
from PIL import Image

from training.utils.logger import Logger


class ImageClassificationDataset(Dataset):
    """Image classification dataset with data validation.

    Automatically detects corrupted images and validates dataset integrity.
    """

    def __init__(
        self,
        root_dir: str,
        transform: Optional[Callable] = None,
        class_names: Optional[List[str]] = None,
        validate_images: bool = True,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        self.root_dir = Path(root_dir)
        self.transform = transform
        self.logger = logger or Logger.get_logger("ImageClassificationDataset")
        self.samples: List[Tuple[str, int]] = []
        self.class_to_idx: Dict[str, int] = {}
        self.idx_to_class: Dict[int, str] = {}
        self.corrupted_images: List[str] = []
        self.image_stats: Dict[str, int] = {}

        if class_names:
            for idx, name in enumerate(class_names):
                self.class_to_idx[name] = idx
                self.idx_to_class[idx] = name
        else:
            self._build_class_index()

        self._load_samples()

        if validate_images:
            self._validate_images()

        self.logger.info(
            "Dataset loaded: %d samples, %d classes, %d corrupted removed",
            len(self.samples), len(self.class_to_idx), len(self.corrupted_images),
        )

    def _build_class_index(self) -> None:
        class_dirs = sorted([
            d for d in self.root_dir.iterdir()
            if d.is_dir() and not d.name.startswith(".")
        ])
        for idx, class_dir in enumerate(class_dirs):
            self.class_to_idx[class_dir.name] = idx
            self.idx_to_class[idx] = class_dir.name

    def _load_samples(self) -> None:
        for class_name, class_idx in self.class_to_idx.items():
            class_dir = self.root_dir / class_name
            if not class_dir.exists():
                self.logger.warning("Class directory not found: %s", class_dir)
                continue
            image_files = sorted([
                f for f in class_dir.iterdir()
                if f.is_file() and f.suffix.lower() in (
                    ".jpg", ".jpeg", ".png", ".bmp", ".webp"
                )
            ])
            for img_path in image_files:
                self.samples.append((str(img_path), class_idx))

    def _validate_images(self) -> None:
        valid_samples = []
        corrupt_count = 0
        size_stats: Dict[str, int] = {}
        format_stats: Dict[str, int] = {}

        for img_path, label in self.samples:
            try:
                with Image.open(img_path) as img:
                    img.verify()
                with Image.open(img_path) as img:
                    img.load()
                    size_key = f"{img.size[0]}x{img.size[1]}"
                    size_stats[size_key] = size_stats.get(size_key, 0) + 1
                    fmt_key = img.format or "unknown"
                    format_stats[fmt_key] = format_stats.get(fmt_key, 0) + 1
                valid_samples.append((img_path, label))
            except Exception as exc:
                corrupt_count += 1
                self.corrupted_images.append(img_path)
                self.logger.warning("Corrupted image: %s - %s", img_path, exc)

        self.samples = valid_samples
        self.image_stats["total_valid"] = len(valid_samples)
        self.image_stats["total_corrupt"] = corrupt_count
        self.image_stats["size_distribution"] = size_stats
        self.image_stats["format_distribution"] = format_stats

    def get_dataset_report(self) -> Dict:
        class_counts: Dict[str, int] = {}
        for _, label in self.samples:
            class_name = self.idx_to_class[label]
            class_counts[class_name] = class_counts.get(class_name, 0) + 1

        return {
            "total_samples": len(self.samples),
            "num_classes": len(self.class_to_idx),
            "corrupted_images": len(self.corrupted_images),
            "corrupted_list": self.corrupted_images[:100],
            "class_distribution": class_counts,
            "image_stats": self.image_stats,
            "class_names": list(self.class_to_idx.keys()),
        }

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor]:
        img_path, label = self.samples[idx]
        image = Image.open(img_path).convert("RGB")

        if self.transform:
            image = self.transform(image)

        return image, torch.tensor(label, dtype=torch.long)
