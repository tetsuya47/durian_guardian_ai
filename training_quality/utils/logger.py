import logging
import sys
from pathlib import Path
from typing import Optional


class Logger:
    _instances = {}

    @classmethod
    def get_logger(
        cls,
        name: str = "quality_model",
        level: str = "INFO",
        log_file: Optional[str] = None,
        format_str: Optional[str] = None,
    ) -> logging.Logger:
        key = (name, log_file)
        if key in cls._instances:
            return cls._instances[key]

        logger = logging.getLogger(name)
        logger.setLevel(getattr(logging, level.upper(), logging.INFO))
        logger.handlers.clear()

        fmt = format_str or "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
        formatter = logging.Formatter(fmt)

        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        if log_file:
            log_path = Path(log_file)
            log_path.parent.mkdir(parents=True, exist_ok=True)
            file_handler = logging.FileHandler(str(log_path), encoding="utf-8")
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)

        cls._instances[key] = logger
        return logger
