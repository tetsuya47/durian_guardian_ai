"""Main training entry point for Durian Guardian AI Framework.

Unified training script that:
1. Loads YAML config
2. Sets up datasets with validation
3. Creates model via ModelFactory
4. Configures optimizer, scheduler, loss, metrics
5. Runs training with callbacks
6. Evaluates on test set
7. Exports model

Usage:
    python training/train.py --config training/configs/model1.yaml
    python training/train.py --config training/configs/model1.yaml --resume training/checkpoints/last_model.pt
"""

import argparse
import json
import logging
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

import torch
from torch.utils.data import DataLoader

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.config_loader import ConfigLoader
from training.utils.seed import seed_everything
from training.utils.logger import Logger
from training.models.registry import create_model_from_config
from training.engine.trainer import Trainer
from training.engine.tester import Tester
from training.engine.export_manager import ExportManager
from training.optimizers import create_optimizer
from training.schedulers import create_scheduler
from training.losses import create_loss
from training.metrics import get_metric, compute_all_metrics
from training.callbacks import (
    ModelCheckpoint,
    EarlyStopping,
    CSVLogger,
    TensorBoard,
    ReduceLROnPlateau,
    GradientNormMonitor,
)
from training.datasets.loaders import ImageClassificationDataset
from training.datasets.preprocess import get_train_transform, get_val_transform
from training.datasets.samplers import BalancedBatchSampler


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Training Framework",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--config", type=str, required=True,
                        help="Path to YAML config file")
    parser.add_argument("--resume", type=str, default=None,
                        help="Resume from checkpoint path")
    parser.add_argument("--seed", type=int, default=None,
                        help="Override random seed")
    parser.add_argument("--epochs", type=int, default=None,
                        help="Override number of epochs")
    parser.add_argument("--batch-size", type=int, default=None,
                        help="Override batch size")
    parser.add_argument("--lr", type=float, default=None,
                        help="Override learning rate")
    parser.add_argument("--device", type=str, default=None,
                        help="Override device (cuda/cpu)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Run one batch to verify pipeline")
    return parser.parse_args(argv)


def build_callbacks(config: Dict[str, Any], checkpoint_dir: Path,
                    log_dir: Path, tensorboard_dir: Path) -> list:
    callbacks = []
    cb_configs = config.get("callbacks", [])

    for cb_cfg in cb_configs:
        name = cb_cfg.get("name", "")
        params = cb_cfg.get("params", {})

        if name == "ModelCheckpoint":
            params.setdefault("checkpoint_dir", str(checkpoint_dir))
            callbacks.append(ModelCheckpoint(**params))
        elif name == "EarlyStopping":
            callbacks.append(EarlyStopping(**params))
        elif name == "CSVLogger":
            callbacks.append(CSVLogger(**params))
        elif name == "TensorBoard":
            callbacks.append(TensorBoard(**params))
        elif name == "ReduceLROnPlateau":
            callbacks.append(ReduceLROnPlateau(**params))
        elif name == "GradientNormMonitor":
            callbacks.append(GradientNormMonitor(**params))

    return callbacks


def validate_dataset(dataset, name: str, logger) -> dict:
    report = dataset.get_dataset_report()
    logger.info("")
    logger.info("Dataset Report: %s", name)
    logger.info("  Total samples: %d", report["total_samples"])
    logger.info("  Num classes  : %d", report["num_classes"])
    logger.info("  Corrupted    : %d", report["corrupted_images"])
    logger.info("  Class distribution:")
    for cls_name, count in sorted(report["class_distribution"].items()):
        logger.info("    %-40s: %d", cls_name, count)
    if report.get("image_stats", {}).get("size_distribution"):
        logger.info("  Image sizes:")
        for size, count in report["image_stats"]["size_distribution"].items():
            logger.info("    %s: %d", size, count)
    return report


def main() -> None:
    args = parse_args()
    config_path = PROJECT_ROOT / args.config
    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    seed = args.seed or config.get("training", {}).get("seed", 42)
    deterministic = config.get("training", {}).get("deterministic", True)
    benchmark = config.get("training", {}).get("benchmark", False)
    seed_everything(seed, deterministic, benchmark)

    log_config = config.get("logging", {})
    log_level = log_config.get("level", "INFO")
    log_format = log_config.get("format", "%(asctime)s [%(levelname)s] %(name)s: %(message)s")

    logging.basicConfig(level=getattr(logging, log_level.upper(), logging.INFO),
                        format=log_format,
                        datefmt="%Y-%m-%d %H:%M:%S")

    logger = Logger.get_logger(
        name="training",
        level=log_level,
        log_file=log_config.get("file", None),
        format_string=log_format,
    )

    model_name = config.get("model", {}).get("name", "model")
    checkpoint_dir = PROJECT_ROOT / "training" / "checkpoints" / model_name
    log_dir = PROJECT_ROOT / "training" / "logs" / model_name
    tensorboard_dir = PROJECT_ROOT / "training" / "tensorboard" / model_name
    export_dir = PROJECT_ROOT / "training" / "exports" / model_name
    for d in [checkpoint_dir, log_dir, tensorboard_dir, export_dir]:
        d.mkdir(parents=True, exist_ok=True)

    device_name = args.device or ("cuda" if torch.cuda.is_available() else "cpu")
    device = torch.device(device_name)
    logger.info("Device: %s", device)
    logger.info("Config: %s", config_path)

    logger.info("")
    logger.info("=" * 60)
    logger.info("  MODEL: %s", model_name)
    logger.info("=" * 60)

    logger.info("Creating model...")
    model = create_model_from_config(config)
    model = model.to(device)

    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    logger.info("Total params: %d | Trainable: %d", total_params, trainable_params)

    dataset_cfg = config.get("dataset", {})
    root = PROJECT_ROOT / dataset_cfg.get("root", "dataset")
    train_dir = root / dataset_cfg.get("train_split", "Train")
    val_dir = root / dataset_cfg.get("val_split", "Validation")
    test_dir = root / dataset_cfg.get("test_split", "Test")
    target_size = tuple(dataset_cfg.get("target_size", [224, 224]))
    mean = tuple(dataset_cfg.get("mean", [0.485, 0.456, 0.406]))
    std = tuple(dataset_cfg.get("std", [0.229, 0.224, 0.225]))

    logger.info("Loading datasets...")
    train_transform = get_train_transform(target_size, mean, std,
                                           config.get("augmentation", {}).get("train", None))
    val_transform = get_val_transform(target_size, mean, std)

    train_dataset = ImageClassificationDataset(
        root_dir=str(train_dir),
        transform=train_transform,
        validate_images=True,
        logger=logger,
    )
    validate_dataset(train_dataset, "Train", logger)

    val_dataset = ImageClassificationDataset(
        root_dir=str(val_dir),
        transform=val_transform,
        validate_images=True,
        logger=logger,
    )

    test_dataset = ImageClassificationDataset(
        root_dir=str(test_dir),
        transform=val_transform,
        validate_images=True,
        logger=logger,
    )

    batch_size = args.batch_size or config.get("training", {}).get("batch_size", 32)
    num_workers = dataset_cfg.get("num_workers", 4)
    pin_memory = dataset_cfg.get("pin_memory", True)

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=pin_memory,
        drop_last=True,
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

    loss_fn = create_loss(config)
    optimizer = create_optimizer(model, config)
    scheduler = create_scheduler(optimizer, config, steps_per_epoch=len(train_loader))

    callbacks = build_callbacks(config, checkpoint_dir, log_dir, tensorboard_dir)
    epochs = args.epochs or config.get("training", {}).get("epochs", 50)

    if args.resume:
        config["training"]["resume_from"] = args.resume

    if args.lr:
        for param_group in optimizer.param_groups:
            param_group["lr"] = args.lr

    metric_names = config.get("metrics", ["accuracy"])
    metric_fns = []
    for name in metric_names:
        if name in ("confusion_matrix", "pr_curve", "classification_report"):
            continue
        try:
            metric_fns.append(get_metric(name))
        except ValueError:
            logger.warning("Unknown metric: %s", name)

    trainer = Trainer(
        model=model,
        config=config,
        optimizer=optimizer,
        loss_fn=loss_fn,
        train_loader=train_loader,
        val_loader=val_loader,
        scheduler=scheduler,
        callbacks=callbacks,
        device=device,
        logger=logger,
    )

    if args.dry_run:
        logger.info("DRY RUN: Running one batch...")
        images, labels = next(iter(train_loader))
        images = images.to(device)
        labels = labels.to(device)
        outputs = model(images)
        loss = loss_fn(outputs, labels)
        logger.info("Single batch OK: loss=%.4f, output_shape=%s", loss.item(), outputs.shape)
        logger.info("Dry run completed successfully.")
        return

    logger.info("Starting training for %d epochs...", epochs)
    t0 = time.time()
    training_results = trainer.train()
    elapsed = time.time() - t0
    logger.info("Training completed in %.2f seconds (%.2f min)", elapsed, elapsed / 60)

    logger.info("")
    logger.info("=" * 60)
    logger.info("  TEST EVALUATION")
    logger.info("=" * 60)

    best_checkpoint = checkpoint_dir / "best_model.pt"
    if best_checkpoint.exists():
        trainer.load_checkpoint(best_checkpoint)
        logger.info("Loaded best checkpoint for testing")

    tester = Tester(
        model=model,
        config=config,
        loss_fn=loss_fn,
        test_loader=test_loader,
        metrics=metric_fns,
        device=device,
        logger=logger,
    )
    test_results = tester.run()

    report_path = log_dir / "test_report.json"
    tester.save_report(test_results, str(report_path))

    logger.info("")
    logger.info("=" * 60)
    logger.info("  EXPORTING MODEL")
    logger.info("=" * 60)
    config["export"]["output_dir"] = str(export_dir)
    export_manager = ExportManager(model, config)
    export_results = export_manager.export()

    summary = {
        "model": model_name,
        "config": str(config_path),
        "device": str(device),
        "training_epochs": epochs,
        "best_metric": training_results.get("best_metric", 0),
        "best_epoch": training_results.get("best_epoch", -1),
        "test_metrics": {k: v for k, v in test_results.items()
                         if k not in ("predictions", "probabilities", "targets")},
        "training_time_seconds": elapsed,
        "exports": export_results,
    }

    summary_path = log_dir / "training_summary.json"
    with open(str(summary_path), "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    logger.info("")
    logger.info("=" * 60)
    logger.info("  TRAINING COMPLETE")
    logger.info("  Best %s: %.4f (epoch %d)",
                 config.get("callbacks", [{}])[0].get("params", {}).get("monitor", "val_accuracy"),
                 training_results.get("best_metric", 0),
                 training_results.get("best_epoch", -1) + 1)
    logger.info("  Summary: %s", summary_path)
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
