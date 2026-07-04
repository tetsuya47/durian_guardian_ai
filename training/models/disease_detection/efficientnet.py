"""Disease Detection Model (Model 1).

EfficientNet-B0 with transfer learning for durian leaf disease classification.
10 disease classes with configurable architecture.
"""

from typing import Optional

import torch
import torch.nn as nn

from training.utils.logger import Logger


class DiseaseDetectionModel(nn.Module):
    """Disease detection model with configurable backbone.

    Supports transfer learning with frozen backbone and fine-tuning.
    """

    def __init__(
        self,
        backbone: str = "efficientnet_b0",
        num_classes: int = 10,
        pretrained: bool = True,
        dropout: float = 0.3,
    ) -> None:
        super().__init__()
        self.backbone_name = backbone
        self.num_classes = num_classes

        import torchvision.models as tv_models

        weights = "DEFAULT" if pretrained else None
        model_fn = getattr(tv_models, backbone, None)
        if model_fn is None:
            raise ValueError(f"Unsupported backbone: {backbone}")

        self.backbone = model_fn(weights=weights)
        in_features = self._get_in_features()
        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(in_features, 512),
            nn.ReLU(inplace=True),
            nn.BatchNorm1d(512),
            nn.Dropout(dropout * 0.5),
            nn.Linear(512, num_classes),
        )

        Logger.get_logger("DiseaseDetectionModel").info(
            "Created %s with %d classes (pretrained=%s)", backbone, num_classes, pretrained
        )

    def _get_in_features(self) -> int:
        if hasattr(self.backbone, "classifier"):
            if isinstance(self.backbone.classifier, nn.Sequential):
                return self.backbone.classifier[-1].in_features
            return self.backbone.classifier.in_features
        if hasattr(self.backbone, "fc"):
            return self.backbone.fc.in_features
        if hasattr(self.backbone, "head"):
            if hasattr(self.backbone.head, "in_features"):
                return self.backbone.head.in_features
            return self.backbone.head.in_channels
        raise AttributeError("Cannot determine classifier in_features")

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.backbone(x)
        if hasattr(self.backbone, "global_pool") and self.backbone.global_pool is not None:
            x = self.backbone.global_pool(x)
        if x.dim() > 2:
            x = x.flatten(1)
        return self.classifier(x)

    def freeze_backbone(self) -> None:
        for param in self.backbone.parameters():
            param.requires_grad = False
        for param in self.classifier.parameters():
            param.requires_grad = True
        Logger.get_logger("DiseaseDetectionModel").info("Backbone frozen")

    def unfreeze_backbone(self) -> None:
        for param in self.backbone.parameters():
            param.requires_grad = True
        Logger.get_logger("DiseaseDetectionModel").info("Backbone unfrozen")
