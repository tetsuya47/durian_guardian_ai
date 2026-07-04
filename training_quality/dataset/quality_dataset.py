from pathlib import Path
from typing import Callable, List, Optional, Tuple

import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image

from training_quality.utils.logger import Logger

logger = Logger.get_logger("QualityImageDataset")

CLASS_NAMES = ["Good", "Bad"]


class QualityImageDataset(Dataset):
    def __init__(
        self,
        root_dir: str,
        transform: Optional[Callable] = None,
        validate_images: bool = True,
    ):
        self.root_dir = Path(root_dir).resolve()
        self.transform = transform
        self.samples: List[Tuple[str, int]] = []
        self.corrupted_count = 0

        if not self.root_dir.exists():
            raise FileNotFoundError(f"Dataset root not found: {self.root_dir}")

        self._load_samples(validate_images)
        logger.info(
            "Dataset loaded: %d samples, %d classes, %d corrupted removed",
            len(self.samples),
            len(CLASS_NAMES),
            self.corrupted_count,
        )

    def _load_samples(self, validate_images: bool):
        for class_idx, class_name in enumerate(CLASS_NAMES):
            class_dir = self.root_dir / class_name
            if not class_dir.exists():
                logger.warning("Class directory not found: %s", class_dir)
                continue
            for img_path in sorted(class_dir.iterdir()):
                if not img_path.is_file():
                    continue
                ext = img_path.suffix.lower()
                if ext not in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
                    continue
                if validate_images:
                    try:
                        with Image.open(str(img_path)) as img:
                            img.verify()
                    except Exception:
                        self.corrupted_count += 1
                        continue
                self.samples.append((str(img_path), class_idx))

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor]:
        img_path, label = self.samples[idx]
        image = Image.open(img_path).convert("RGB")
        if self.transform:
            image = self.transform(image)
        return image, torch.tensor(label, dtype=torch.long)


def get_train_transform(target_size: Tuple[int, int], mean: tuple, std: tuple) -> Callable:
    from torchvision import transforms
    return transforms.Compose([
        transforms.Resize(target_size),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomRotation(degrees=15),
        transforms.ColorJitter(brightness=0.15, contrast=0.15, saturation=0.15),
        transforms.ToTensor(),
        transforms.Normalize(mean=mean, std=std),
    ])


def get_val_transform(target_size: Tuple[int, int], mean: tuple, std: tuple) -> Callable:
    from torchvision import transforms
    return transforms.Compose([
        transforms.Resize(target_size),
        transforms.ToTensor(),
        transforms.Normalize(mean=mean, std=std),
    ])


def create_dataloaders(config: dict) -> Tuple[DataLoader, DataLoader, DataLoader, QualityImageDataset]:
    dataset_cfg = config.get("dataset", {})
    root = Path(dataset_cfg.get("root", "training_quality/dataset_quality"))
    if not root.is_absolute():
        root = Path.cwd() / root
    target_size = tuple(dataset_cfg.get("target_size", [224, 224]))
    mean = tuple(dataset_cfg.get("mean", [0.485, 0.456, 0.406]))
    std = tuple(dataset_cfg.get("std", [0.229, 0.224, 0.225]))
    batch_size = config.get("training", {}).get("batch_size", 64)
    num_workers = dataset_cfg.get("num_workers", 4)
    pin_memory = dataset_cfg.get("pin_memory", True)

    train_transform = get_train_transform(target_size, mean, std)
    val_transform = get_val_transform(target_size, mean, std)

    train_dataset = QualityImageDataset(
        root_dir=str(root / "Train"),
        transform=train_transform,
        validate_images=True,
    )
    val_dataset = QualityImageDataset(
        root_dir=str(root / "Validation"),
        transform=val_transform,
        validate_images=False,
    )
    test_dataset = QualityImageDataset(
        root_dir=str(root / "Test"),
        transform=val_transform,
        validate_images=False,
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=pin_memory,
    )
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=pin_memory,
    )
    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=pin_memory,
    )

    return train_loader, val_loader, test_loader, test_dataset
