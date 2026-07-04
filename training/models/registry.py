"""Model Factory — centralized model registry with dynamic model creation.

Supports pluggable architectures: EfficientNet, ResNet, DenseNet,
ConvNeXt, MobileNet, Vision Transformer, and custom models.
"""

from typing import Any, Dict, Optional

import torch
import torch.nn as nn

from training.utils.logger import Logger


class ModelFactory:
    """Factory for creating model instances from config.

    Usage:
        model = ModelFactory.create("efficientnet_b0", num_classes=10, pretrained=True)
    """

    _registry: Dict[str, Any] = {}

    @classmethod
    def register(cls, name: str) -> callable:
        """Decorator to register a model builder function."""
        def wrapper(builder_fn):
            cls._registry[name] = builder_fn
            return builder_fn
        return wrapper

    @classmethod
    def create(
        cls,
        architecture: str,
        num_classes: int,
        pretrained: bool = True,
        freeze_backbone: bool = False,
        dropout: float = 0.3,
        **kwargs,
    ) -> nn.Module:
        model = cls._create_pytorch_model(
            architecture, num_classes, pretrained, dropout, **kwargs
        )

        if freeze_backbone and pretrained:
            cls._freeze_backbone(model, architecture)

        param_count = sum(p.numel() for p in model.parameters() if p.requires_grad)
        total_params = sum(p.numel() for p in model.parameters())
        Logger.get_logger("ModelFactory").info(
            "Created %s | trainable: %d / total: %d params",
            architecture, param_count, total_params,
        )
        return model

    @classmethod
    def _create_pytorch_model(
        cls, architecture: str, num_classes: int,
        pretrained: bool, dropout: float, **kwargs,
    ) -> nn.Module:
        try:
            import torchvision.models as tv_models
        except ImportError:
            raise ImportError("torchvision required for model creation")

        model_fn = getattr(tv_models, architecture, None)
        if model_fn:
            try:
                if pretrained:
                    model = model_fn(weights="DEFAULT")
                else:
                    model = model_fn(weights=None)
            except TypeError:
                if pretrained:
                    model = model_fn(pretrained=True)
                else:
                    model = model_fn()
            return cls._adapt_classifier(model, architecture, num_classes, dropout)

        if architecture in cls._registry:
            return cls._registry[architecture](num_classes, pretrained, dropout, **kwargs)

        raise ValueError(
            f"Unknown architecture: '{architecture}'. "
            f"Available: {list(tv_models.__dict__.keys())[:50]} "
            f"or register custom with @ModelFactory.register()"
        )

    @classmethod
    def _adapt_classifier(
        cls, model: nn.Module, architecture: str, num_classes: int, dropout: float
    ) -> nn.Module:
        in_features = None
        if hasattr(model, "classifier"):
            if isinstance(model.classifier, nn.Sequential):
                last_layer = model.classifier[-1]
                if hasattr(last_layer, "in_features"):
                    in_features = last_layer.in_features
                model.classifier[-1] = nn.Linear(in_features, num_classes)
            elif isinstance(model.classifier, nn.Linear):
                in_features = model.classifier.in_features
                model.classifier = nn.Linear(in_features, num_classes)
        elif hasattr(model, "fc"):
            in_features = model.fc.in_features
            model.fc = nn.Sequential(
                nn.Dropout(dropout),
                nn.Linear(in_features, num_classes),
            )
        elif hasattr(model, "head"):
            if hasattr(model.head, "in_features"):
                in_features = model.head.in_features
            elif hasattr(model.head, "in_channels"):
                in_features = model.head.in_channels
            model.head = nn.Linear(in_features, num_classes)
        elif hasattr(model, "heads"):
            in_features = model.heads.in_features
            model.heads = nn.Linear(in_features, num_classes)
        else:
            raise AttributeError(
                f"Cannot adapt classifier for {architecture}: "
                f"unknown classifier attribute"
            )
        return model

    @classmethod
    def _freeze_backbone(cls, model: nn.Module, architecture: str) -> None:
        classifier_names = ["classifier", "fc", "head", "heads"]
        for name, param in model.named_parameters():
            is_classifier = any(c in name for c in classifier_names)
            param.requires_grad = is_classifier

    @classmethod
    def list_available(cls) -> list:
        try:
            import torchvision.models as tv_models
            tv_models_list = [
                name for name in dir(tv_models)
                if callable(getattr(tv_models, name))
                and not name.startswith("_")
            ]
        except ImportError:
            tv_models_list = []
        return tv_models_list + list(cls._registry.keys())


def create_model_from_config(config: Dict[str, Any]) -> nn.Module:
    model_config = config.get("model", {})
    return ModelFactory.create(
        architecture=model_config.get("architecture", "efficientnet_b0"),
        num_classes=model_config.get("num_classes", 10),
        pretrained=model_config.get("pretrained", True),
        freeze_backbone=model_config.get("freeze_backbone", False),
        dropout=model_config.get("dropout", 0.3),
    )
