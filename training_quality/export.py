"""Export trained Image Quality model to PyTorch, TorchScript, and ONNX formats.

Usage:
    python training_quality/export.py
    python training_quality/export.py --checkpoint training_quality/checkpoints/best_model.pt
"""

import argparse
import os
import sys
from pathlib import Path
from typing import Dict, Optional

import torch

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training_quality.utils.config_loader import ConfigLoader
from training_quality.utils.logger import Logger
from training_quality.models.quality_model import ImageQualityModel, create_quality_model

logger = Logger.get_logger("export")


def export_pytorch(model: torch.nn.Module, output_path: Path) -> Path:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), str(output_path))
    logger.info("PyTorch model saved: %s", output_path)
    return output_path


def export_torchscript(model: torch.nn.Module, output_path: Path, device: torch.device) -> Path:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    model.eval()
    dummy = torch.randn(1, 3, 224, 224).to(device)
    with torch.no_grad():
        traced = torch.jit.trace(model, dummy)
    traced.save(str(output_path))
    logger.info("TorchScript model saved: %s", output_path)
    return output_path


def export_onnx(
    model: torch.nn.Module,
    output_path: Path,
    device: torch.device,
    opset_version: int = 17,
    dynamic_batch: bool = True,
) -> Path:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    model.eval()
    dummy = torch.randn(1, 3, 224, 224).to(device)

    dynamic_axes = None
    if dynamic_batch:
        dynamic_axes = {
            "input": {0: "batch_size"},
            "output": {0: "batch_size"},
        }

    old_encoding = os.environ.pop("PYTHONIOENCODING", None)
    os.environ["PYTHONIOENCODING"] = "utf-8"
    try:
        torch.onnx.export(
            model,
            dummy,
            str(output_path),
            input_names=["input"],
            output_names=["output"],
            dynamic_axes=dynamic_axes,
            opset_version=opset_version,
            do_constant_folding=True,
        )
    finally:
        if old_encoding is None:
            os.environ.pop("PYTHONIOENCODING", None)
        else:
            os.environ["PYTHONIOENCODING"] = old_encoding
    logger.info("ONNX model saved: %s", output_path)
    return output_path


def export_all(config: Dict, checkpoint_path: Optional[str] = None) -> Dict[str, str]:
    device_name = "cuda" if torch.cuda.is_available() else "cpu"
    device = torch.device(device_name)
    logger.info("Device: %s", device)

    model_config = config.get("model", {})
    model = create_quality_model(
        num_classes=model_config.get("num_classes", 2),
        pretrained=False,
        freeze_backbone=False,
        dropout=model_config.get("dropout", 0.3),
    )

    if checkpoint_path is None:
        checkpoint_path = str(Path("training_quality/checkpoints/best_model.pt"))
    ckpt = torch.load(checkpoint_path, map_location=device)
    if "model_state_dict" in ckpt:
        model.load_state_dict(ckpt["model_state_dict"])
    else:
        model.load_state_dict(ckpt)
    model = model.to(device)
    model.eval()
    logger.info("Loaded checkpoint: %s", checkpoint_path)

    export_cfg = config.get("export", {})
    output_dir = Path(export_cfg.get("output_dir", "training_quality/exports"))
    output_dir.mkdir(parents=True, exist_ok=True)
    formats = export_cfg.get("formats", ["pytorch", "torchscript", "onnx"])
    opset = export_cfg.get("onnx_opset", 17)
    dynamic_batch = export_cfg.get("dynamic_batch", True)

    results = {}
    if "pytorch" in formats:
        path = export_pytorch(model, output_dir / "model.pt")
        results["pytorch"] = str(path)
    if "torchscript" in formats:
        path = export_torchscript(model, output_dir / "model.torchscript", device)
        results["torchscript"] = str(path)
    if "onnx" in formats:
        path = export_onnx(model, output_dir / "model.onnx", device, opset, dynamic_batch)
        results["onnx"] = str(path)

    logger.info("Export results: %s", results)
    return results


def main():
    parser = argparse.ArgumentParser(description="Export Image Quality Model")
    parser.add_argument("--config", type=str, default="training_quality/configs/model2.yaml")
    parser.add_argument("--checkpoint", type=str, default=None)
    args = parser.parse_args()

    config_path = PROJECT_ROOT / args.config
    config_loader = ConfigLoader(str(config_path))
    export_all(config_loader.config, args.checkpoint)


if __name__ == "__main__":
    main()
