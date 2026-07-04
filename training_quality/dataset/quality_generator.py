import random
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import cv2
import numpy as np
from PIL import Image

from training_quality.utils.logger import Logger

logger = Logger.get_logger("QualityDatasetGenerator")


QUALITY_DEGRADATIONS = [
    "gaussian_blur",
    "motion_blur",
    "underexposure",
    "overexposure",
    "gaussian_noise",
    "jpeg_compression",
    "random_crop",
    "occlusion",
    "low_resolution",
]

CLASS_NAMES = ["Good", "Bad"]


def _gaussian_blur(img: np.ndarray, kernel_size: int, sigma: float) -> np.ndarray:
    if kernel_size % 2 == 0:
        kernel_size += 1
    return cv2.GaussianBlur(img, (kernel_size, kernel_size), sigma)


def _motion_blur(img: np.ndarray, kernel_size: int) -> np.ndarray:
    kernel = np.zeros((kernel_size, kernel_size))
    kernel[int((kernel_size - 1) / 2), :] = np.ones(kernel_size)
    kernel = kernel / kernel_size
    return cv2.filter2D(img, -1, kernel)


def _adjust_gamma(img: np.ndarray, gamma: float) -> np.ndarray:
    inv_gamma = 1.0 / gamma
    table = np.array([(i / 255.0) ** inv_gamma * 255 for i in range(256)]).astype("uint8")
    return cv2.LUT(img, table)


def _gaussian_noise(img: np.ndarray, std: float) -> np.ndarray:
    noise = np.random.randn(*img.shape).astype(np.float32) * std * 255
    noisy = img.astype(np.float32) + noise
    return np.clip(noisy, 0, 255).astype(np.uint8)


def _jpeg_compress(img: np.ndarray, quality: int) -> np.ndarray:
    encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), quality]
    _, enc_img = cv2.imencode(".jpg", img, encode_param)
    dec_img = cv2.imdecode(enc_img, cv2.IMREAD_COLOR)
    return dec_img


def _random_crop(img: np.ndarray, scale: float) -> np.ndarray:
    h, w = img.shape[:2]
    new_h, new_w = int(h * scale), int(w * scale)
    top = random.randint(0, h - new_h) if h > new_h else 0
    left = random.randint(0, w - new_w) if w > new_w else 0
    cropped = img[top : top + new_h, left : left + new_w]
    return cv2.resize(cropped, (w, h), interpolation=cv2.INTER_LINEAR)


def _occlude(img: np.ndarray, num_boxes: int, box_size_ratio: float) -> np.ndarray:
    h, w = img.shape[:2]
    result = img.copy()
    for _ in range(num_boxes):
        box_h = int(h * box_size_ratio * random.uniform(0.5, 1.5))
        box_w = int(w * box_size_ratio * random.uniform(0.5, 1.5))
        box_h = max(5, min(box_h, h))
        box_w = max(5, min(box_w, w))
        y = random.randint(0, h - box_h) if h > box_h else 0
        x = random.randint(0, w - box_w) if w > box_w else 0
        result[y : y + box_h, x : x + box_w] = 0
    return result


def _low_resolution(img: np.ndarray, scale_factor: float) -> np.ndarray:
    h, w = img.shape[:2]
    small_h, small_w = max(1, int(h * scale_factor)), max(1, int(w * scale_factor))
    small = cv2.resize(img, (small_w, small_h), interpolation=cv2.INTER_LINEAR)
    return cv2.resize(small, (w, h), interpolation=cv2.INTER_LINEAR)


_DEGRADATION_FUNCTIONS = {
    "gaussian_blur": lambda img, cfg: _gaussian_blur(
        img,
        random.choice(cfg["kernel_sizes"]),
        random.uniform(*cfg["sigma_range"]),
    ),
    "motion_blur": lambda img, cfg: _motion_blur(
        img,
        random.choice(cfg["kernel_sizes"]),
    ),
    "underexposure": lambda img, cfg: _adjust_gamma(
        img,
        random.uniform(*cfg["gamma_range"]),
    ),
    "overexposure": lambda img, cfg: _adjust_gamma(
        img,
        random.uniform(*cfg["gamma_range"]),
    ),
    "gaussian_noise": lambda img, cfg: _gaussian_noise(
        img,
        random.uniform(*cfg["std_range"]),
    ),
    "jpeg_compression": lambda img, cfg: _jpeg_compress(
        img,
        random.randint(*cfg["quality_range"]),
    ),
    "random_crop": lambda img, cfg: _random_crop(
        img,
        random.uniform(*cfg["scale_range"]),
    ),
    "occlusion": lambda img, cfg: _occlude(
        img,
        random.randint(*cfg["num_boxes_range"]),
        random.uniform(*cfg["box_size_range"]),
    ),
    "low_resolution": lambda img, cfg: _low_resolution(
        img,
        random.uniform(*cfg["scale_factor_range"]),
    ),
}


def _degrade_image(img: np.ndarray, degradations_config: dict) -> np.ndarray:
    available = [
        name
        for name in QUALITY_DEGRADATIONS
        if name in degradations_config and degradations_config[name].get("probability", 0) > 0
    ]
    if not available:
        return img
    chosen = random.choice(available)
    cfg = degradations_config[chosen]
    result = _DEGRADATION_FUNCTIONS[chosen](img, cfg)
    return result


class QualityDatasetGenerator:
    def __init__(
        self,
        source_root: str,
        output_root: str,
        degradations_config: dict,
        bad_samples_per_good: int = 2,
        val_split_ratio: float = 0.1,
        test_split_ratio: float = 0.1,
        seed: int = 42,
        target_size: Tuple[int, int] = (224, 224),
    ):
        self.source_root = Path(source_root).resolve()
        self.output_root = Path(output_root).resolve()
        self.degradations_config = degradations_config
        self.bad_samples_per_good = bad_samples_per_good
        self.val_split_ratio = val_split_ratio
        self.test_split_ratio = test_split_ratio
        self.seed = seed
        self.target_size = target_size

        random.seed(seed)
        np.random.seed(seed)

        self.SPLITS = ["Train", "Validation", "Test"]

    def collect_source_images(self) -> List[Path]:
        extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
        images = []
        for split in ["Train", "Validation", "Test"]:
            split_dir = self.source_root / split
            if not split_dir.exists():
                continue
            for class_dir in sorted(split_dir.iterdir()):
                if not class_dir.is_dir():
                    continue
                for img_path in class_dir.iterdir():
                    if img_path.suffix.lower() in extensions:
                        images.append(img_path)
        logger.info("Collected %d source images from %s", len(images), self.source_root)
        return images

    def _assign_split(self, idx: int, total: int) -> str:
        val_start = int(total * (1 - self.val_split_ratio - self.test_split_ratio))
        test_start = int(total * (1 - self.test_split_ratio))
        if idx < val_start:
            return "Train"
        elif idx < test_start:
            return "Validation"
        else:
            return "Test"

    def _relative_stem(self, src_path: Path) -> str:
        rel = src_path.relative_to(self.source_root)
        stem = rel.with_suffix("").as_posix().replace("/", "__")
        return stem

    def _save_image(self, img_array: np.ndarray, output_path: Path):
        output_path.parent.mkdir(parents=True, exist_ok=True)
        pil_img = Image.fromarray(cv2.cvtColor(img_array, cv2.COLOR_BGR2RGB))
        pil_img.save(str(output_path), quality=95)

    def generate(self) -> dict:
        source_images = self.collect_source_images()
        random.shuffle(source_images)

        stats = {"good": 0, "bad": 0, "total": 0, "splits": {s: {"good": 0, "bad": 0} for s in self.SPLITS}}

        if self.output_root.exists():
            shutil.rmtree(str(self.output_root))
            logger.info("Cleaned existing output directory: %s", self.output_root)

        for idx, src_path in enumerate(source_images):
            split = self._assign_split(idx, len(source_images))
            unique_stem = self._relative_stem(src_path)
            rel_name = f"{unique_stem}{src_path.suffix}"

            good_dir = self.output_root / split / "Good"
            good_path = good_dir / rel_name
            self._save_image(cv2.imread(str(src_path)), good_path)
            stats["good"] += 1
            stats["splits"][split]["good"] += 1

            bad_dir = self.output_root / split / "Bad"
            img_bgr = cv2.imread(str(src_path))
            if img_bgr is None:
                continue

            for _ in range(self.bad_samples_per_good):
                degraded = _degrade_image(img_bgr.copy(), self.degradations_config)
                bad_name = f"{unique_stem}_bad_{_}{src_path.suffix}"
                bad_path = bad_dir / bad_name
                self._save_image(degraded, bad_path)
                stats["bad"] += 1
                stats["splits"][split]["bad"] += 1

            if (idx + 1) % 500 == 0:
                logger.info("  Processed %d / %d source images...", idx + 1, len(source_images))

        stats["total"] = stats["good"] + stats["bad"]
        logger.info(
            "Dataset generated: %d total (Good=%d, Bad=%d)",
            stats["total"], stats["good"], stats["bad"],
        )
        for s in self.SPLITS:
            g = stats["splits"][s]["good"]
            b = stats["splits"][s]["bad"]
            logger.info("  %s: Good=%d  Bad=%d  Total=%d", s, g, b, g + b)

        return stats


def generate_dataset_from_config(config: dict) -> dict:
    dataset_cfg = config.get("dataset", {})
    source_root = Path(dataset_cfg.get("source_root", "Ten_Classes_of_Durian_Leaf_Diseases/Ten_Classes_of_Durian_Leaf_Diseases"))
    if not source_root.is_absolute():
        source_root = Path.cwd() / source_root
    output_root = Path(dataset_cfg.get("root", "training_quality/dataset_quality"))
    if not output_root.is_absolute():
        output_root = Path.cwd() / output_root
    gen_cfg = dataset_cfg.get("generator", {})
    target_size = tuple(dataset_cfg.get("target_size", [224, 224]))

    generator = QualityDatasetGenerator(
        source_root=str(source_root),
        output_root=str(output_root),
        degradations_config=gen_cfg.get("degradations", {}),
        bad_samples_per_good=gen_cfg.get("bad_samples_per_good", 2),
        val_split_ratio=gen_cfg.get("val_split_ratio", 0.1),
        test_split_ratio=gen_cfg.get("test_split_ratio", 0.1),
        seed=gen_cfg.get("seed", 42),
        target_size=target_size,
    )
    return generator.generate()
