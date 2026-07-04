"""Inference engine for production-ready model deployment."""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset

from training.engine.base_engine import BaseEngine
from training.utils.logger import Logger


class InferenceEngine(BaseEngine):
    """Production inference engine supporting single, batch, and dataset inference."""

    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        device: Optional[torch.device] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        super().__init__(model, config, device, logger)
        self.model.eval()

    def run(self, *args, **kwargs) -> Any:
        raise NotImplementedError(
            "InferenceEngine.run() is not implemented. Use predict_single(), predict_batch(), or predict_dataset() instead."
        )

    def predict_single(self, image_tensor: torch.Tensor) -> Dict[str, Any]:
        self.model.eval()
        with torch.no_grad():
            image_tensor = image_tensor.unsqueeze(0).to(self.device)
            outputs = self.model(image_tensor)
            probabilities = torch.softmax(outputs, dim=1)
            predicted_class = torch.argmax(probabilities, dim=1).item()
            confidence = probabilities[0, predicted_class].item()

        return {
            "class_id": predicted_class,
            "confidence": confidence,
            "probabilities": probabilities[0].cpu().numpy().tolist(),
        }

    def predict_batch(self, batch_tensor: torch.Tensor) -> Dict[str, Any]:
        self.model.eval()
        with torch.no_grad():
            batch_tensor = batch_tensor.to(self.device)
            outputs = self.model(batch_tensor)
            probabilities = torch.softmax(outputs, dim=1)
            predicted_classes = torch.argmax(probabilities, dim=1)
            confidences = probabilities.gather(1, predicted_classes.unsqueeze(1)).squeeze()

        return {
            "class_ids": predicted_classes.cpu().numpy().tolist(),
            "confidences": confidences.cpu().numpy().tolist(),
            "probabilities": probabilities.cpu().numpy().tolist(),
        }

    def predict_dataset(
        self,
        dataset: Dataset,
        batch_size: int = 32,
        num_workers: int = 4,
    ) -> List[Dict[str, Any]]:
        loader = DataLoader(
            dataset,
            batch_size=batch_size,
            shuffle=False,
            num_workers=num_workers,
            pin_memory=True,
        )
        self.model.eval()
        all_results = []

        with torch.no_grad():
            for batch in loader:
                if isinstance(batch, (list, tuple)):
                    images = batch[0]
                else:
                    images = batch

                images = images.to(self.device, non_blocking=True)
                outputs = self.model(images)
                probabilities = torch.softmax(outputs, dim=1)
                predicted_classes = torch.argmax(probabilities, dim=1)
                confidences = probabilities.gather(1, predicted_classes.unsqueeze(1)).squeeze()

                for i in range(len(images)):
                    all_results.append({
                        "class_id": predicted_classes[i].item(),
                        "confidence": confidences[i].item()
                        if confidences.dim() == 0 else confidences[i].item(),
                    })

        return all_results

    def load_for_inference(self, model_path: Union[str, Path]) -> None:
        path = Path(model_path)
        if not path.exists():
            raise FileNotFoundError(f"Model not found: {path}")

        checkpoint = torch.load(str(path), map_location=self.device)
        if "model_state_dict" in checkpoint:
            self.model.load_state_dict(checkpoint["model_state_dict"])
        else:
            self.model.load_state_dict(checkpoint)

        self.model.eval()
        self.logger.info("Model loaded for inference: %s", path)
