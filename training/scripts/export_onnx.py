"""ONNX export for trained disease detection model.

Usage:
    python training/scripts/export_onnx.py

Ensures model.pt, model.torchscript, and model.onnx all exist.
"""

import sys
from pathlib import Path

import torch

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.config_loader import ConfigLoader
from training.utils.logger import Logger
from training.models.registry import create_model_from_config
from training.engine.export_manager import ExportManager


logger = Logger.get_logger("export_onnx")


def main():
    config_path = PROJECT_ROOT / "training" / "configs" / "model1.yaml"
    if not config_path.exists():
        logger.error("Config not found: %s", config_path)
        return

    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    device_name = "cuda" if torch.cuda.is_available() else "cpu"
    device = torch.device(device_name)

    model_name = config.get("model", {}).get("name", "disease_detection")
    model = create_model_from_config(config)
    model = model.to(device)

    checkpoint_path = PROJECT_ROOT / "training" / "checkpoints" / model_name / "best_model.pt"
    if checkpoint_path.exists():
        state = torch.load(str(checkpoint_path), map_location=device)
        if "model_state_dict" in state:
            model.load_state_dict(state["model_state_dict"])
        else:
            model.load_state_dict(state)
        logger.info("Loaded checkpoint: %s", checkpoint_path)
    else:
        logger.warning("Checkpoint not found, using uninitialized model")

    config["export"]["output_dir"] = str(PROJECT_ROOT / "training" / "exports" / model_name)
    config["export"]["formats"] = ["pytorch", "torchscript", "onnx"]

    export_manager = ExportManager(model, config)
    results = export_manager.export()

    logger.info("")
    logger.info("=" * 60)
    logger.info("  EXPORT RESULTS")
    for fmt, path in results.items():
        status = "OK" if "FAILED" not in str(path) else "FAILED"
        logger.info("  %-15s: %s [%s]", fmt, path, status)
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
