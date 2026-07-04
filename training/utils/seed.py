"""Reproducibility utilities for deterministic training."""

import random
import os

import numpy as np


def seed_everything(seed: int = 42, deterministic: bool = True, benchmark: bool = False) -> None:
    """Set random seeds for reproducibility across all libraries.

    Args:
        seed: Random seed value.
        deterministic: Enable deterministic operations (may reduce performance).
        benchmark: Enable cuDNN benchmark mode (may affect determinism).
    """
    random.seed(seed)
    np.random.seed(seed)

    try:
        import torch

        torch.manual_seed(seed)
        torch.cuda.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)

        if deterministic:
            torch.backends.cudnn.deterministic = True
            torch.backends.cudnn.benchmark = benchmark
            try:
                torch.use_deterministic_algorithms(True, warn_only=True)
            except AttributeError:
                pass
        else:
            torch.backends.cudnn.deterministic = False
            torch.backends.cudnn.benchmark = benchmark

        os.environ["PYTHONHASHSEED"] = str(seed)
        os.environ["CUBLAS_WORKSPACE_CONFIG"] = ":4096:8"

    except ImportError:
        pass

    try:
        import tensorflow as tf

        tf.random.set_seed(seed)
    except ImportError:
        pass

    os.environ["PYTHONHASHSEED"] = str(seed)
