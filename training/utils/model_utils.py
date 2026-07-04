"""Model utility functions for parameter management and device handling."""

from typing import Iterator, Tuple, Union

import torch
import torch.nn as nn


def count_parameters(model: nn.Module, trainable_only: bool = True) -> int:
    """Count model parameters.

    Args:
        model: PyTorch model.
        trainable_only: Count only trainable parameters.

    Returns:
        Total parameter count.
    """
    if trainable_only:
        return sum(p.numel() for p in model.parameters() if p.requires_grad)
    return sum(p.numel() for p in model.parameters())


def count_parameters_by_layer(model: nn.Module) -> Iterator[Tuple[str, int]]:
    """Yield (layer_name, parameter_count) for each named parameter."""
    for name, param in model.named_parameters():
        yield name, param.numel()


def get_device() -> torch.device:
    """Get the best available device (CUDA, MPS, or CPU)."""
    if torch.cuda.is_available():
        return torch.device("cuda")
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def freeze_model(model: nn.Module) -> None:
    """Freeze all model parameters.

    Args:
        model: PyTorch model to freeze.
    """
    for param in model.parameters():
        param.requires_grad = False


def unfreeze_model(model: nn.Module) -> None:
    """Unfreeze all model parameters.

    Args:
        model: PyTorch model to unfreeze.
    """
    for param in model.parameters():
        param.requires_grad = True


def freeze_layers_except(model: nn.Module, layer_names: list) -> None:
    """Freeze all layers except those specified.

    Args:
        model: PyTorch model.
        layer_names: List of layer name substrings to keep trainable.
    """
    for name, param in model.named_parameters():
        param.requires_grad = any(layer in name for layer in layer_names)


def get_parameter_groups(
    model: nn.Module,
    base_lr: float,
    weight_decay: float = 0.01,
    skip_decay: tuple = ("bias", "LayerNorm.weight", "layer_norm.weight"),
) -> list:
    """Group parameters for optimizer with different weight decay.

    Args:
        model: PyTorch model.
        base_lr: Base learning rate.
        weight_decay: Weight decay value.
        skip_decay: Parameter names to exclude from weight decay.

    Returns:
        List of parameter group dicts.
    """
    decay = []
    no_decay = []
    for name, param in model.named_parameters():
        if not param.requires_grad:
            continue
        if any(skip in name for skip in skip_decay):
            no_decay.append(param)
        else:
            decay.append(param)

    groups = [
        {"params": decay, "lr": base_lr, "weight_decay": weight_decay},
        {"params": no_decay, "lr": base_lr, "weight_decay": 0.0},
    ]
    return groups


def get_model_size(model: nn.Module) -> Tuple[float, str]:
    """Estimate model size in memory.

    Args:
        model: PyTorch model.

    Returns:
        Tuple of (size, unit).
    """
    param_size = sum(p.numel() * p.element_size() for p in model.parameters())
    buffer_size = sum(b.numel() * b.element_size() for b in model.buffers())
    total = param_size + buffer_size

    for unit in ["B", "KB", "MB", "GB"]:
        if total < 1024:
            return float(total), unit
        total /= 1024
    return float(total), "TB"
