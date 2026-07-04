"""Standalone model export script.

Usage:
    python training/export.py --config training/configs/model1.yaml
    python training/export.py --config training/configs/model1.yaml --formats pytorch onnx
"""

import argparse
import sys
from pathlib import Path
from typing import List, Optional

import torch

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.config_loader import ConfigLoader
from training.utils.logger import Logger
from training.models.registry import create_model_from_config
from training.engine.export_manager import ExportManager


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Model Export",
    )
    parser.add_argument("--config", type=str, required=True,
                        help="Path to YAML config")
    parser.add_argument("--checkpoint", type=str, default=None,
                        help="Path to checkpoint")
    parser.add_argument("--formats", type=str, nargs="+",
                        choices=["pytorch", "torchscript", "onnx", "all"],
                        default=None,
                        help="Export formats")
    parser.add_argument("--output-dir", type=str, default=None,
                        help="Override output directory")
    parser.add_argument("--device", type=str, default=None,
                        help="Override device")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    config_path = PROJECT_ROOT / args.config
    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    logger = Logger.get_logger("export")

    model_name = config.get("model", {}).get("name", "model")
    device_name = args.device or ("cuda" if torch.cuda.is_available() else "cpu")
    device = torch.device(device_name)

    model = create_model_from_config(config)
    model = model.to(device)

    checkpoint_path = args.checkpoint
    if checkpoint_path is None:
        checkpoint_path = str(PROJECT_ROOT / "training" / "checkpoints" / model_name / "best_model.pt")

    if Path(checkpoint_path).exists():
        checkpoint = torch.load(str(checkpoint_path), map_location=device)
        if "model_state_dict" in checkpoint:
            model.load_state_dict(checkpoint["model_state_dict"])
        else:
            model.load_state_dict(checkpoint)
        logger.info("Loaded checkpoint: %s", checkpoint_path)
    else:
        logger.warning("Checkpoint not found: %s", checkpoint_path)

    if args.output_dir:
        config["export"]["output_dir"] = args.output_dir

    if args.formats:
        if "all" in args.formats:
            config["export"]["formats"] = ["pytorch", "torchscript", "onnx"]
        else:
            config["export"]["formats"] = args.formats

    export_manager = ExportManager(model, config)
    results = export_manager.export()

    logger.info("")
    logger.info("Export results:")
    for fmt, path in results.items():
        status = "✓" if "FAILED" not in str(path) else "✗"
        logger.info("  %s %s: %s", status, fmt, path)


if __name__ == "__main__":
    main()
