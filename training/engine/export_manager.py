"""Model export manager supporting PyTorch, TorchScript, and ONNX formats."""

from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import torch
import torch.nn as nn

from training.utils.logger import Logger


class ExportManager:
    """Exports trained models to deployment formats.

    Supported formats:
    - PyTorch (.pt / .pth)
    - TorchScript (.torchscript)
    - ONNX (.onnx)
    """

    def __init__(self, model: nn.Module, config: Dict[str, Any]) -> None:
        self.model = model
        self.config = config
        self.logger = Logger.get_logger("ExportManager")
        export_cfg = config.get("export", {})
        self.output_dir = Path(export_cfg.get("output_dir", "training/exports"))
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def export(self, formats: Optional[List[str]] = None) -> Dict[str, str]:
        if formats is None:
            export_cfg = self.config.get("export", {})
            formats = export_cfg.get("formats", ["pytorch"])

        results = {}
        for fmt in formats:
            try:
                if fmt == "pytorch":
                    results[fmt] = self._export_pytorch()
                elif fmt == "torchscript":
                    results[fmt] = self._export_torchscript()
                elif fmt == "onnx":
                    results[fmt] = self._export_onnx()
                else:
                    self.logger.warning("Unsupported export format: %s", fmt)
            except Exception as exc:
                self.logger.error("Export '%s' failed: %s", fmt, exc)
                results[fmt] = f"FAILED: {exc}"

        self.logger.info("Export results: %s", results)
        return results

    def _export_pytorch(self) -> str:
        path = self.output_dir / "model.pt"
        torch.save(
            {
                "model_state_dict": self.model.state_dict(),
                "config": self.config,
            },
            str(path),
        )
        self.logger.info("PyTorch model saved: %s", path)
        return str(path)

    def _export_torchscript(self) -> str:
        self.model.eval()
        example_input = self._get_example_input()
        traced_model = torch.jit.trace(self.model, example_input)
        path = self.output_dir / "model.torchscript"
        traced_model.save(str(path))
        self.logger.info("TorchScript model saved: %s", path)
        return str(path)

    def _export_onnx(self) -> str:
        import onnx  # noqa

        self.model.eval()
        example_input = self._get_example_input()
        export_cfg = self.config.get("export", {})
        dynamic_batch = export_cfg.get("dynamic_batch", True)
        onnx_opset = export_cfg.get("onnx_opset", 17)

        dynamic_axes = None
        if dynamic_batch:
            dynamic_axes = {"input": {0: "batch_size"}, "output": {0: "batch_size"}}

        path = self.output_dir / "model.onnx"
        torch.onnx.export(
            self.model,
            example_input,
            str(path),
            input_names=["input"],
            output_names=["output"],
            dynamic_axes=dynamic_axes,
            opset_version=onnx_opset,
            do_constant_folding=True,
        )
        self.logger.info("ONNX model saved: %s", path)
        return str(path)

    def _get_example_input(self) -> torch.Tensor:
        input_size = self.config.get("dataset", {}).get("target_size", [224, 224])
        return torch.randn(1, 3, input_size[0], input_size[1])
