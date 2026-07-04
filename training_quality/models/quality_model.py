import torch
import torch.nn as nn
import torchvision
from typing import Optional


class ImageQualityModel(nn.Module):
    def __init__(
        self,
        num_classes: int = 2,
        pretrained: bool = True,
        dropout: float = 0.3,
    ):
        super().__init__()
        self.backbone = torchvision.models.mobilenet_v3_small(pretrained=pretrained)
        in_features = self.backbone.classifier[0].in_features
        self.backbone.classifier = nn.Sequential(
            nn.Linear(in_features, 256),
            nn.Hardswish(),
            nn.Dropout(dropout),
            nn.Linear(256, num_classes),
        )
        self._num_classes = num_classes

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.backbone(x)


def create_quality_model(
    num_classes: int = 2,
    pretrained: bool = True,
    freeze_backbone: bool = False,
    dropout: float = 0.3,
) -> ImageQualityModel:
    model = ImageQualityModel(
        num_classes=num_classes,
        pretrained=pretrained,
        dropout=dropout,
    )
    if freeze_backbone and pretrained:
        for name, param in model.backbone.features.named_parameters():
            param.requires_grad = False
    return model


def count_parameters(model: nn.Module) -> dict:
    total = sum(p.numel() for p in model.parameters())
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    return {"total": total, "trainable": trainable, "frozen": total - trainable}
