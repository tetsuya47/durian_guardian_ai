"""Image preprocessing pipeline."""

from typing import List, Optional, Tuple, Union

import torch
import torchvision.transforms as T
import torchvision.transforms.functional as F
from PIL import Image


class ImagePreprocessor:
    """Configurable image preprocessing pipeline.

    Supports resizing, normalization, color conversion, and tensor conversion.
    """

    def __init__(
        self,
        target_size: Tuple[int, int] = (224, 224),
        mean: Tuple[float, ...] = (0.485, 0.456, 0.406),
        std: Tuple[float, ...] = (0.229, 0.224, 0.225),
        normalize: bool = True,
        to_tensor: bool = True,
    ) -> None:
        self.target_size = target_size
        self.mean = mean
        self.std = std
        self.normalize = normalize
        self.to_tensor_flag = to_tensor

        transforms = [T.Resize(target_size)]
        if to_tensor:
            transforms.append(T.ToTensor())
        if normalize:
            transforms.append(T.Normalize(mean=mean, std=std))

        self.transform = T.Compose(transforms)

    def __call__(self, image: Image.Image) -> torch.Tensor:
        return self.transform(image.convert("RGB"))

    def preprocess_numpy(self, image_array: "np.ndarray") -> torch.Tensor:
        image = Image.fromarray(image_array)
        return self.transform(image)

    def to_pil(self, tensor: torch.Tensor) -> Image.Image:
        if self.normalize:
            mean = torch.tensor(self.mean).view(3, 1, 1)
            std = torch.tensor(self.std).view(3, 1, 1)
            tensor = tensor * std + mean
        tensor = tensor.clamp(0, 1) * 255
        tensor = tensor.byte().permute(1, 2, 0)
        return Image.fromarray(tensor.numpy())


def get_train_transform(
    target_size: Tuple[int, int] = (224, 224),
    mean: Tuple[float, ...] = (0.485, 0.456, 0.406),
    std: Tuple[float, ...] = (0.229, 0.224, 0.225),
    augmentation_config: Optional[dict] = None,
) -> T.Compose:
    """Build training transform with optional augmentations."""
    transforms = [T.Resize(target_size)]

    if augmentation_config:
        aug_transforms = _build_augmentations(augmentation_config)
        transforms.extend(aug_transforms)

    transforms.append(T.ToTensor())
    transforms.append(T.Normalize(mean=mean, std=std))
    return T.Compose(transforms)


def get_val_transform(
    target_size: Tuple[int, int] = (224, 224),
    mean: Tuple[float, ...] = (0.485, 0.456, 0.406),
    std: Tuple[float, ...] = (0.229, 0.224, 0.225),
) -> T.Compose:
    """Build validation/test transform (no augmentation)."""
    return T.Compose([
        T.Resize(target_size),
        T.ToTensor(),
        T.Normalize(mean=mean, std=std),
    ])


def _build_augmentations(config: dict) -> list:
    transforms = []
    aug_map = {
        "RandomHorizontalFlip": T.RandomHorizontalFlip,
        "RandomVerticalFlip": T.RandomVerticalFlip,
        "RandomRotation": lambda **kw: T.RandomRotation(**kw),
        "ColorJitter": lambda **kw: T.ColorJitter(**kw),
        "RandomAffine": lambda **kw: T.RandomAffine(**kw),
        "RandomPerspective": lambda **kw: T.RandomPerspective(**kw),
        "GaussianBlur": lambda **kw: T.GaussianBlur(**kw),
        "RandomCrop": lambda **kw: T.RandomCrop(**kw),
        "RandomResizedCrop": lambda **kw: T.RandomResizedCrop(**kw),
        "RandAugment": lambda **kw: T.RandAugment(**kw),
        "TrivialAugmentWide": lambda **kw: T.TrivialAugmentWide(**kw),
        "AugMix": lambda **kw: T.AugMix(**kw),
    }

    for aug_name, aug_params in config.items():
        if aug_name in aug_map:
            aug_fn = aug_map[aug_name]
            try:
                transforms.append(aug_fn(**aug_params))
            except Exception as exc:
                import logging
                logging.warning("Failed to build augmentation '%s': %s", aug_name, exc)
    return transforms
