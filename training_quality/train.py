"""Main training entry point for Model 2: Image Quality Assessment.

Usage:
    python training_quality/train.py
    python training_quality/train.py --config training_quality/configs/model2.yaml
    python training_quality/train.py --generate-only
    python training_quality/train.py --resume training_quality/checkpoints/last_model.pt
"""

import argparse
import json
import sys
import time
from pathlib import Path

import torch

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training_quality.utils.config_loader import ConfigLoader
from training_quality.utils.logger import Logger
from training_quality.models.quality_model import create_quality_model, count_parameters
from training_quality.dataset.quality_generator import generate_dataset_from_config
from training_quality.dataset.quality_dataset import create_dataloaders
from training_quality.engine.trainer import Trainer
from training_quality.engine.evaluator import Evaluator
from training_quality.export import export_all

logger = Logger.get_logger("train")


def parse_args():
    parser = argparse.ArgumentParser(description="Train Image Quality Assessment Model")
    parser.add_argument("--config", type=str, default="training_quality/configs/model2.yaml")
    parser.add_argument("--generate-only", action="store_true", help="Only generate dataset, do not train")
    parser.add_argument("--resume", type=str, default=None,
                        help="Resume from checkpoint (default: auto-detect last checkpoint)")
    return parser.parse_args()


def find_latest_checkpoint() -> Path:
    ckpt_dir = Path("training_quality/checkpoints")
    if not ckpt_dir.exists():
        return None
    candidates = ["last_model.pt", "best_model.pt"]
    for name in candidates:
        p = ckpt_dir / name
        if p.exists():
            return p
    return None


def load_checkpoint(path: str) -> dict:
    logger.info("Loading checkpoint: %s", path)
    ckpt = torch.load(path, map_location="cpu", weights_only=False)
    logger.info("  Checkpoint epoch: %d  (saved epoch %d)",
                ckpt.get("epoch", 0), ckpt.get("epoch", 0))
    logger.info("  Best metric: %.4f at epoch %d",
                ckpt.get("best_metric", 0), ckpt.get("best_epoch", -1) + 1)
    return ckpt


def build_optimizer(model, config):
    opt_config = config.get("optimizer", {})
    opt_name = opt_config.get("name", "AdamW")
    opt_params = opt_config.get("params", {})
    lr = opt_params.get("lr", 0.001)
    weight_decay = opt_params.get("weight_decay", 0.01)
    betas = tuple(opt_params.get("betas", [0.9, 0.999]))
    eps = opt_params.get("eps", 1e-8)

    logger.info("=== Optimizer params type dump ===")
    logger.info("  lr:          type=%s value=%r", type(lr).__name__, lr)
    logger.info("  weight_decay: type=%s value=%r", type(weight_decay).__name__, weight_decay)
    logger.info("  eps:         type=%s value=%r", type(eps).__name__, eps)
    logger.info("  betas:       type=%s value=%r", type(betas).__name__, betas)
    if isinstance(betas, (list, tuple)):
        for i, b in enumerate(betas):
            logger.info("    betas[%d]: type=%s value=%r", i, type(b).__name__, b)
    for k, v in opt_params.items():
        if k not in ("lr", "weight_decay", "eps", "betas"):
            logger.info("  %s: type=%s value=%r", k, type(v).__name__, v)
    logger.info("================================")

    OptimizerClass = getattr(torch.optim, opt_name, torch.optim.AdamW)
    optimizer = OptimizerClass(model.parameters(), lr=lr, weight_decay=weight_decay, betas=betas, eps=eps)
    return optimizer


def build_scheduler(optimizer, config):
    sched_config = config.get("scheduler", {})
    sched_name = sched_config.get("name")
    if not sched_name or sched_name.lower() == "none":
        return None
    sched_params = sched_config.get("params", {}).copy()
    sched_params["T_max"] = sched_params.get("T_max", config.get("training", {}).get("epochs", 30))

    logger.info("=== Scheduler params type dump ===")
    logger.info("  name: %s", sched_name)
    for k, v in sched_params.items():
        logger.info("  %s: type=%s value=%r", k, type(v).__name__, v)
    warmup_epochs = sched_config.get("warmup_epochs", 0)
    logger.info("  warmup_epochs: type=%s value=%r", type(warmup_epochs).__name__, warmup_epochs)
    logger.info("================================")

    SchedulerClass = getattr(torch.optim.lr_scheduler, sched_name, None)
    if SchedulerClass:
        return SchedulerClass(optimizer, **sched_params)
    return None


def main():
    args = parse_args()
    config_path = PROJECT_ROOT / args.config
    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    log_config = config.get("logging", {})
    logger_inst = Logger.get_logger(
        "train",
        level=log_config.get("level", "INFO"),
        log_file=log_config.get("file"),
    )

    seed = config.get("training", {}).get("seed", 42)
    torch.manual_seed(seed)

    logger_inst.info("=" * 60)
    logger_inst.info("  MODEL 2: IMAGE QUALITY ASSESSMENT")
    logger_inst.info("  Config: %s", config_path)
    logger_inst.info("=" * 60)

    # --- Determine resume mode ---
    resume_path = args.resume
    auto_resume = False
    if resume_path is None:
        found = find_latest_checkpoint()
        if found is not None:
            logger_inst.info("Auto-detected checkpoint: %s", found)
            resume_path = str(found)
            auto_resume = True
    do_resume = resume_path is not None

    # --- Step 1: Dataset (skip if resuming, dataset should already exist) ---
    dataset_root = Path(config.get("dataset", {}).get("root", "training_quality/dataset_quality"))
    if not dataset_root.is_absolute():
        dataset_root = PROJECT_ROOT / dataset_root
    dataset_exists = dataset_root.exists() and any(dataset_root.iterdir())

    if do_resume and dataset_exists and auto_resume:
        logger_inst.info("Step 1: Dataset already exists at %s, skipping generation", dataset_root)
        stats = {"note": "dataset already exists, skipped generation"}
    else:
        logger_inst.info("Step 1: Generating quality dataset...")
        stats = generate_dataset_from_config(config)
        logger_inst.info("Dataset generated: %s", json.dumps(stats, indent=2))

    if args.generate_only:
        logger_inst.info("--generate-only flag set. Training skipped.")
        return

    # --- Step 2: Create model ---
    logger_inst.info("Step 2: Creating model...")
    model_config = config.get("model", {})
    model = create_quality_model(
        num_classes=model_config.get("num_classes", 2),
        pretrained=model_config.get("pretrained", True),
        freeze_backbone=model_config.get("freeze_backbone", False),
        dropout=model_config.get("dropout", 0.3),
    )
    param_counts = count_parameters(model)
    logger_inst.info("Model: MobileNetV3 Small | Total params: %d | Trainable: %d",
                     param_counts["total"], param_counts["trainable"])

    # --- Step 3: Dataloaders ---
    logger_inst.info("Step 3: Creating dataloaders...")
    train_loader, val_loader, test_loader, test_dataset = create_dataloaders(config)

    # --- Step 4: Loss, optimizer, scheduler ---
    logger_inst.info("Step 4: Creating loss, optimizer, scheduler...")
    loss_fn = torch.nn.CrossEntropyLoss()

    if do_resume:
        # --- RESUME PATH ---
        ckpt = load_checkpoint(resume_path)
        ckpt_epoch = ckpt.get("epoch", 0)  # saved as epoch+1 (1-indexed)
        ckpt_best_metric = ckpt.get("best_metric", 0.0)
        ckpt_best_epoch = ckpt.get("best_epoch", -1)
        ckpt_global_step = ckpt.get("global_step", 0)

        # Model already created above, load state
        model.load_state_dict(ckpt["model_state_dict"])
        logger_inst.info("  Model state restored.")

        # Create optimizer from scratch then load state
        optimizer = build_optimizer(model, config)
        optimizer.load_state_dict(ckpt["optimizer_state_dict"])
        logger_inst.info("  Optimizer state restored (epoch %d/%d lr=%.6f).",
                         ckpt_epoch, config.get("training", {}).get("epochs", 30),
                         optimizer.param_groups[0]["lr"])

        # Create scheduler from scratch then load state
        scheduler = build_scheduler(optimizer, config)

        if scheduler is not None and "scheduler_state_dict" in ckpt:
            try:
                scheduler.load_state_dict(ckpt["scheduler_state_dict"])
                logger_inst.info("  Scheduler state restored.")
            except Exception as e:
                logger_inst.warning("  Could not restore scheduler state: %s", e)

        # Scaler state
        trainer_kwargs = dict(
            model=model,
            config=config,
            optimizer=optimizer,
            loss_fn=loss_fn,
            train_loader=train_loader,
            val_loader=val_loader,
            scheduler=scheduler,
            start_epoch=ckpt_epoch,  # resume from this epoch (0-indexed loop)
            best_metric=ckpt_best_metric,
            best_epoch=ckpt_best_epoch,
            global_step=ckpt_global_step,
        )
        logger_inst.info("Resuming training from epoch %d / %d",
                         ckpt_epoch + 1, config.get("training", {}).get("epochs", 30))
    else:
        # --- FRESH TRAIN PATH ---
        optimizer = build_optimizer(model, config)
        scheduler = build_scheduler(optimizer, config)
        trainer_kwargs = dict(
            model=model,
            config=config,
            optimizer=optimizer,
            loss_fn=loss_fn,
            train_loader=train_loader,
            val_loader=val_loader,
            scheduler=scheduler,
        )

    # --- Step 5: Train ---
    logger_inst.info("Step 5: Training...")
    trainer = Trainer(**trainer_kwargs)

    # Restore scaler state if resuming
    if do_resume and "scaler_state_dict" in ckpt:
        try:
            trainer.scaler.load_state_dict(ckpt["scaler_state_dict"])
        except Exception as e:
            logger_inst.warning("  Could not restore scaler state: %s", e)

    train_results = trainer.train()

    # --- Step 6: Evaluate on test set ---
    logger_inst.info("Step 6: Evaluating on test set...")
    evaluator = Evaluator(
        model=model,
        config=config,
        loss_fn=loss_fn,
        test_loader=test_loader,
    )
    test_results = evaluator.run()

    # --- Step 7: Export ---
    logger_inst.info("Step 7: Exporting models...")
    export_results = export_all(config)

    # --- Step 8: Save summary ---
    logger_inst.info("Step 8: Saving training summary...")
    summary = {
        "model": "image_quality",
        "config": str(config_path),
        "device": str(trainer.device),
        "training_epochs": config.get("training", {}).get("epochs", 30),
        "best_metric": train_results.get("best_metric", 0),
        "best_epoch": train_results.get("best_epoch", 0),
        "test_metrics": {
            "accuracy": test_results.get("accuracy", 0),
            "precision": test_results.get("precision", 0),
            "recall": test_results.get("recall", 0),
            "f1_score": test_results.get("f1_score", 0),
            "roc_auc": test_results.get("roc_auc", 0),
        },
        "training_time_seconds": train_results.get("total_time", 0),
        "exports": export_results,
        "dataset_stats": stats,
        "parameters": param_counts,
    }

    summary_path = Path("training_quality/logs/training_summary.json")
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    with open(str(summary_path), "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)
    logger_inst.info("Training summary saved: %s", summary_path)

    logger_inst.info("")
    logger_inst.info("=" * 60)
    logger_inst.info("  MODEL 2 TRAINING COMPLETE")
    logger_inst.info("=" * 60)


if __name__ == "__main__":
    main()
