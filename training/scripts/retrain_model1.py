"""
Retrain Model 1 from scratch on cleaned dataset.
50 epochs, EfficientNet-B0, AdamW, CosineAnnealingLR, mixed precision.
"""
import sys, json, yaml
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

import torch
from training.engine.trainer import Trainer
from training.models.efficientnet import EfficientNetClassifier
from training.data.dataset import create_dataloaders
from training.losses import get_loss_function
from training.optimizers import get_optimizer
from training.schedulers import get_scheduler
from training.callbacks import get_callbacks
from training.utils.logger import Logger

logger = Logger.get_logger("retrain")

def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info(f"Device: {device}")

    # Load config
    config_path = PROJECT_ROOT / "training" / "configs" / "model1.yaml"
    with open(config_path) as f:
        config = yaml.safe_load(f)
    logger.info(f"Config loaded: {config_path.name}")

    # Override: force full fine-tuning (unfreeze backbone for cleaned dataset)
    config["model"]["freeze_backbone"] = False

    # Model
    model = EfficientNetClassifier(
        model_name=config["model"]["architecture"],
        num_classes=config["model"]["num_classes"],
        pretrained=config["model"]["pretrained"],
        freeze_backbone=config["model"]["freeze_backbone"],
        dropout=config["model"]["dropout"],
    )
    model = model.to(device)
    logger.info(f"Model: {config['model']['architecture']} (freeze_backbone={config['model']['freeze_backbone']})")

    # Data
    train_loader, val_loader, test_loader = create_dataloaders(config)
    logger.info(f"Train: {len(train_loader.dataset)}, Val: {len(val_loader.dataset)}, Test: {len(test_loader.dataset)}")

    # Loss
    criterion = get_loss_function(
        config["loss"]["name"],
        **config["loss"].get("params", {}),
    )

    # Optimizer
    optimizer = get_optimizer(
        model,
        config["optimizer"]["name"],
        **config["optimizer"].get("params", {}),
    )

    # Scheduler
    scheduler_config = config["scheduler"]
    scheduler = get_scheduler(
        optimizer,
        scheduler_config["name"],
        T_max=scheduler_config["params"]["T_max"],
        eta_min=scheduler_config["params"]["eta_min"],
        warmup_epochs=scheduler_config.get("warmup_epochs", 0),
        warmup_start_lr=scheduler_config.get("warmup_start_lr", None),
    )

    # Callbacks
    callbacks = get_callbacks(config.get("callbacks", []))
    logger.info(f"Callbacks: {[c.__class__.__name__ for c in callbacks]}")

    # Trainer
    trainer = Trainer(
        model=model,
        train_loader=train_loader,
        val_loader=val_loader,
        test_loader=test_loader,
        criterion=criterion,
        optimizer=optimizer,
        scheduler=scheduler,
        callbacks=callbacks,
        config=config,
        device=device,
    )

    # Train from scratch
    logger.info("Starting training from scratch...")
    history = trainer.train(num_epochs=config["training"]["epochs"])
    logger.info("Training complete.")

    # Evaluate on test set
    logger.info("Evaluating on test set...")
    test_metrics = trainer.evaluate(split="test")
    logger.info(f"Test metrics: {json.dumps(test_metrics, indent=2)}")

    # Export
    logger.info("Exporting model...")
    export_dir = PROJECT_ROOT / config["export"]["output_dir"]
    export_dir.mkdir(parents=True, exist_ok=True)

    # PyTorch
    torch.save(model.state_dict(), export_dir / "model1_final.pt")
    logger.info(f"Exported: {export_dir / 'model1_final.pt'}")

    # TorchScript
    model.eval()
    example_input = torch.randn(1, 3, 224, 224).to(device)
    with torch.no_grad():
        traced = torch.jit.trace(model, example_input)
    traced.save(str(export_dir / "model1_traced.pt"))
    logger.info(f"Exported: {export_dir / 'model1_traced.pt'}")

    # ONNX
    try:
        torch.onnx.export(
            model,
            example_input,
            str(export_dir / "model1.onnx"),
            input_names=["input"],
            output_names=["output"],
            dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
            opset_version=17,
        )
        logger.info(f"Exported: {export_dir / 'model1.onnx'}")
    except Exception as e:
        logger.warning(f"ONNX export failed: {e}")

    # Save final metrics
    metrics_path = PROJECT_ROOT / "training" / "reports" / "model1_final_metrics.json"
    with open(metrics_path, "w") as f:
        json.dump(test_metrics, f, indent=2)
    logger.info(f"Metrics saved: {metrics_path}")

    # Save training history
    history_path = PROJECT_ROOT / "training" / "reports" / "model1_training_history.json"
    with open(history_path, "w") as f:
        json.dump(history, f, indent=2)
    logger.info(f"History saved: {history_path}")

    logger.info("=== RETRAIN COMPLETE ===")
    return test_metrics

if __name__ == "__main__":
    main()
