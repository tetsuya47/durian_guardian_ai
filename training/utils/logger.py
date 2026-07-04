"""Centralized logging module with file and console output."""

import logging
import sys
from pathlib import Path
from typing import Optional


class Logger:
    """Factory for creating configured loggers with consistent formatting."""

    _instances: dict = {}

    @classmethod
    def get_logger(
        cls,
        name: str = "durian_guardian",
        level: str = "INFO",
        log_file: Optional[str] = None,
        format_string: Optional[str] = None,
    ) -> logging.Logger:
        cache_key = f"{name}:{log_file}"
        if cache_key in cls._instances:
            return cls._instances[cache_key]

        logger = logging.getLogger(name)
        logger.setLevel(getattr(logging, level.upper(), logging.INFO))
        logger.handlers.clear()

        formatter = logging.Formatter(
            format_string or "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(getattr(logging, level.upper(), logging.INFO))
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        if log_file:
            log_path = Path(log_file)
            log_path.parent.mkdir(parents=True, exist_ok=True)
            file_handler = logging.FileHandler(
                str(log_path), mode="a", encoding="utf-8"
            )
            file_handler.setLevel(getattr(logging, level.upper(), logging.INFO))
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)

        logger.propagate = False
        cls._instances[cache_key] = logger
        return logger

    @classmethod
    def clear(cls) -> None:
        cls._instances.clear()
