"""Optimizer factory with dynamic parameter grouping."""

import logging
from typing import Any, Dict, List, Optional

import torch
import torch.nn as nn

from training.utils.model_utils import get_parameter_groups


OPTIMIZER_REGISTRY = {
    "Adam": torch.optim.Adam,
    "AdamW": torch.optim.AdamW,
    "SGD": torch.optim.SGD,
    "RMSprop": torch.optim.RMSprop,
    "Adamax": torch.optim.Adamax,
    "NAdam": torch.optim.NAdam,
    "RAdam": torch.optim.RAdam,
}


LOG_TYPES = {
    "lr", "weight_decay", "eps", "momentum", "dampening",
    "alpha", "betas", "rho",
}


def _log_param_types(opt_params: dict, logger: logging.Logger) -> None:
    for key, value in opt_params.items():
        logger.info("  %s: type=%s value=%r", key, type(value).__name__, value)
    if "betas" in opt_params:
        betas = opt_params["betas"]
        if isinstance(betas, (list, tuple)):
            for i, b in enumerate(betas):
                logger.info("  betas[%d]: type=%s value=%r", i, type(b).__name__, b)


def create_optimizer(
    model: nn.Module,
    config: Dict[str, Any],
) -> torch.optim.Optimizer:
    logger = logging.getLogger("OptimizerFactory")

    opt_config = config.get("optimizer", {})
    opt_name = opt_config.get("name", "AdamW")
    opt_params = opt_config.get("params", {})

    if opt_name not in OPTIMIZER_REGISTRY:
        raise ValueError(
            f"Unknown optimizer: '{opt_name}'. Available: {list(OPTIMIZER_REGISTRY.keys())}"
        )

    lr = opt_params.pop("lr", 1e-3)
    weight_decay = opt_params.pop("weight_decay", 0.01)

    logger.info("=== Optimizer params type dump ===")
    logger.info("  lr:          type=%s value=%r", type(lr).__name__, lr)
    logger.info("  weight_decay: type=%s value=%r", type(weight_decay).__name__, weight_decay)
    logger.info("  opt_name:    %s", opt_name)
    _log_param_types(opt_params, logger)
    logger.info("================================")

    param_groups = get_parameter_groups(model, lr, weight_decay)
    opt_class = OPTIMIZER_REGISTRY[opt_name]
    return opt_class(param_groups, lr=lr, weight_decay=weight_decay, **opt_params)
