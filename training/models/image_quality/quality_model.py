"""Image Quality Assessment Model (Model 2).

Stub architecture — framework ready for training when labeled data is available.
"""

from typing import Optional

import torch
import torch.nn as nn


class ImageQualityModel(nn.Module):
    """Image quality assessment model.

    Currently a structural placeholder with a configurable backbone.
    Ready for training once image quality labels are collected.
    """

    def __init__(
        self,
        backbone: str = "efficientnet_b0",
        pretrained: bool = True,
        dropout: float = 0.3,
    ) -> None:
        super().__init__()
        self.backbone_name = backbone

        import torchvision.models as tv_models

        weights = "DEFAULT" if pretrained else None
        model_fn = getattr(tv_models, backbone, None)
        if model_fn is None:
            raise ValueError(f"Unsupported backbone: {backbone}")

        self.backbone = model_fn(weights=weights)
        in_features = self._get_in_features()
        self.quality_head = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(in_features, 128),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout * 0.5),
            nn.Linear(128, 1),
            nn.Sigmoid(),
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
        return self.quality_head(x).squeeze(1)
