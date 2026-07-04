"""Image augmentations module with configurable transforms.

All augmentations are controllable via YAML configuration
and can be toggled on/off without code changes.
"""

from typing import Any, Dict, List, Optional

import torch
import torchvision.transforms as T
import torchvision.transforms.functional as F


class ImageAugmentation:
    """Configurable image augmentation pipeline built from YAML config."""

    def __init__(self, config: Dict[str, Any]) -> None:
        self.config = config
        self.transforms = self._build()

    def _build(self) -> T.Compose:
        transforms = []
        aug_factory = {
            "RandomHorizontalFlip": lambda p: T.RandomHorizontalFlip(p=p),
            "RandomVerticalFlip": lambda p: T.RandomVerticalFlip(p=p),
            "RandomRotation": lambda degrees, **kw: T.RandomRotation(degrees=degrees, **kw),
            "ColorJitter": lambda **kw: T.ColorJitter(**kw),
            "RandomAffine": lambda degrees, **kw: T.RandomAffine(degrees=degrees, **kw),
            "RandomPerspective": lambda distortion_scale, p: T.RandomPerspective(
                distortion_scale=distortion_scale, p=p
            ),
            "GaussianBlur": lambda kernel_size, sigma: T.GaussianBlur(
                kernel_size=kernel_size, sigma=sigma
            ),
            "RandomCrop": lambda size, **kw: T.RandomCrop(size=size, **kw),
            "RandomResizedCrop": lambda size, **kw: T.RandomResizedCrop(size=size, **kw),
            "RandAugment": lambda n, m: T.RandAugment(num_ops=n, magnitude=m),
            "TrivialAugmentWide": lambda: T.TrivialAugmentWide(),
            "AugMix": lambda **kw: T.AugMix(**kw),
            "RandomErasing": lambda p, scale, ratio: T.RandomErasing(
                p=p, scale=scale, ratio=ratio
            ),
        }

        for aug_name, aug_params in self.config.items():
            if aug_name in aug_factory:
                try:
                    if isinstance(aug_params, dict):
                        transform = aug_factory[aug_name](**aug_params)
                    else:
                        transform = aug_factory[aug_name](aug_params)
                    transforms.append(transform)
                except Exception as exc:
                    import logging
                    logging.getLogger("Augmentation").warning(
                        "Failed to build '%s': %s", aug_name, exc
                    )

        return T.Compose(transforms)

    def __call__(self, x: torch.Tensor) -> torch.Tensor:
        return self.transforms(x)

    def __len__(self) -> int:
        return len(self.transforms.transforms)


class Cutout:
    """Random Cutout augmentation for improved generalization."""

    def __init__(self, size: int = 16, p: float = 0.5) -> None:
        self.size = size
        self.p = p

    def __call__(self, x: torch.Tensor) -> torch.Tensor:
        if torch.rand(1).item() >= self.p:
            return x
        _, h, w = x.shape
        y = torch.randint(0, h - self.size + 1, (1,)).item()
        x_ = torch.randint(0, w - self.size + 1, (1,)).item()
        x[:, y:y + self.size, x_:x_ + self.size] = 0
        return x
