"""Standalone evaluation script for trained models.

Usage:
    python training/evaluate.py --config training/configs/model1.yaml
    python training/evaluate.py --config training/configs/model1.yaml --checkpoint training/checkpoints/best_model.pt
"""

import argparse
import json
import sys
from pathlib import Path
from typing import List, Optional

import torch
from torch.utils.data import DataLoader

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.config_loader import ConfigLoader
from training.utils.seed import seed_everything
from training.utils.logger import Logger
from training.models.registry import create_model_from_config
from training.engine.tester import Tester
from training.losses import create_loss
from training.metrics import get_metric
from training.datasets.loaders import ImageClassificationDataset
from training.datasets.preprocess import get_val_transform


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Model Evaluation",
    )
    parser.add_argument("--config", type=str, required=True,
                        help="Path to YAML config")
    parser.add_argument("--checkpoint", type=str, default=None,
                        help="Path to checkpoint (default: training/checkpoints/{model}/best_model.pt)")
    parser.add_argument("--device", type=str, default=None,
                        help="Override device")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    config_path = PROJECT_ROOT / args.config
    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    seed_everything(config.get("training", {}).get("seed", 42))
    log_config = config.get("logging", {})
    logger = Logger.get_logger("evaluate", level=log_config.get("level", "INFO"))

    device_name = args.device or ("cuda" if torch.cuda.is_available() else "cpu")
    device = torch.device(device_name)

    model_name = config.get("model", {}).get("name", "model")
    logger.info("Evaluating model: %s", model_name)

    model = create_model_from_config(config)
    model = model.to(device)

    checkpoint_path = args.checkpoint
    if checkpoint_path is None:
        model_dir = Path("training") / "checkpoints" / model_name
        checkpoint_path = str(model_dir / "best_model.pt")

    checkpoint_path = PROJECT_ROOT / checkpoint_path
    if checkpoint_path.exists():
        checkpoint = torch.load(str(checkpoint_path), map_location=device)
        if "model_state_dict" in checkpoint:
            model.load_state_dict(checkpoint["model_state_dict"])
        else:
            model.load_state_dict(checkpoint)
        logger.info("Loaded checkpoint: %s", checkpoint_path)
    else:
        logger.warning("Checkpoint not found: %s", checkpoint_path)

    dataset_cfg = config.get("dataset", {})
    root = PROJECT_ROOT / dataset_cfg.get("root", "dataset")
    test_dir = root / dataset_cfg.get("test_split", "Test")
    target_size = tuple(dataset_cfg.get("target_size", [224, 224]))
    mean = tuple(dataset_cfg.get("mean", [0.485, 0.456, 0.406]))
    std = tuple(dataset_cfg.get("std", [0.229, 0.224, 0.225]))
    val_transform = get_val_transform(target_size, mean, std)
    batch_size = config.get("training", {}).get("batch_size", 32)
    num_workers = dataset_cfg.get("num_workers", 4)

    test_dataset = ImageClassificationDataset(
        root_dir=str(test_dir),
        transform=val_transform,
        validate_images=True,
        logger=logger,
    )
    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True,
    )

    loss_fn = create_loss(config)
    metric_names = config.get("metrics", ["accuracy"])
    metric_fns = []
    for name in metric_names:
        if name not in ("confusion_matrix", "pr_curve", "classification_report"):
            try:
                metric_fns.append(get_metric(name))
            except ValueError:
                pass

    tester = Tester(model, config, loss_fn, test_loader, metric_fns, device, logger)
    results = tester.run()

    output_dir = PROJECT_ROOT / "training" / "results" / model_name
    output_dir.mkdir(parents=True, exist_ok=True)
    tester.save_report(results, str(output_dir / "evaluation_report.json"))

    logger.info("Evaluation complete. Report saved to %s", output_dir / "evaluation_report.json")


if __name__ == "__main__":
    main()
