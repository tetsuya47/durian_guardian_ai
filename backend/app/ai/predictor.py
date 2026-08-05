"""Disease detection predictor using trained EfficientNet-B0 model.

Standalone predictor - does NOT depend on training module.
Replicates the same architecture used in training/models/registry.py
(ModelFactory._adapt_classifier for EfficientNet-B0).
"""
from __future__ import annotations

import io
import logging
import threading
from pathlib import Path
from typing import Optional

import torch
import torch.nn as nn
import torchvision.models as tv_models
import torchvision.transforms as T
from PIL import Image

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────────────────────

CLASS_NAMES: list[str] = [
    "anthracnose_disease",
    "canker_disease",
    "fruit_rot",
    "Healthy",
    "mealybug_infestation",
    "pink_disease",
    "sooty_mold",
    "stem_blight",
    "stem_cracking_ gummosis",
    "thrips_disease",
    "yellow_leaf",
]

DISEASE_NAME_VI: dict[str, str] = {
    "anthracnose_disease": "Thán thư",
    "canker_disease": "Sẹo thân",
    "fruit_rot": "Thối quả",
    "Healthy": "Khỏe mạnh",
    "mealybug_infestation": "Rệp sáp",
    "pink_disease": "Bệnh hồng thân",
    "sooty_mold": "Nấm bồ hóng",
    "stem_blight": "Cháy thân",
    "stem_cracking_ gummosis": "Nứt thân chảy nhựa",
    "thrips_disease": "Bọ trĩ",
    "yellow_leaf": "Vàng lá",
}

# Severity mapping based on disease type and confidence level
_SEVERITY_MAP: dict[str, str] = {
    "Healthy": "none",
    "mealybug_infestation": "low",
    "thrips_disease": "low",
    "sooty_mold": "low",
    "yellow_leaf": "medium",
    "anthracnose_disease": "medium",
    "pink_disease": "medium",
    "canker_disease": "high",
    "fruit_rot": "high",
    "stem_blight": "high",
    "stem_cracking_ gummosis": "high",
}

import os

# Path to trained checkpoint with flexible multi-path resolution
def _get_checkpoint_path() -> Path:
    env_path = os.getenv("DISEASE_MODEL_PATH")
    if env_path and Path(env_path).exists():
        return Path(env_path)

    # 1. Local path inside backend (recommended for Render)
    local_path = Path(__file__).resolve().parent / "best_model.pt"
    if local_path.exists():
        return local_path

    # 2. Standard path relative to repo root
    repo_path = (
        Path(__file__).resolve().parent.parent.parent.parent
        / "training"
        / "checkpoints"
        / "disease_detection"
        / "best_model.pt"
    )
    if repo_path.exists():
        return repo_path

    # 3. Secondary path inside backend or export dir
    export_path = (
        Path(__file__).resolve().parent.parent.parent.parent
        / "training"
        / "exports"
        / "disease_detection"
        / "model.pt"
    )
    if export_path.exists():
        return export_path

    return local_path

_CHECKPOINT_PATH = _get_checkpoint_path()

# ImageNet normalization stats (same used during training)
_IMAGENET_MEAN = (0.485, 0.456, 0.406)
_IMAGENET_STD = (0.229, 0.224, 0.225)

NUM_CLASSES = 11


# ──────────────────────────────────────────────────────────────
# Model builder — mirrors ModelFactory._adapt_classifier
# ──────────────────────────────────────────────────────────────

def _build_model() -> nn.Module:
    """Create EfficientNet-B0 with 11-class classifier head."""
    model = tv_models.efficientnet_b0(weights=None)
    # Replace final Linear layer: (1280→1000) → (1280→11)
    # EfficientNet-B0 classifier = Sequential(Dropout(0.2), Linear(1280, 1000))
    in_features: int = model.classifier[-1].in_features  # 1280
    model.classifier[-1] = nn.Linear(in_features, NUM_CLASSES)
    return model


# ──────────────────────────────────────────────────────────────
# Val transform — mirrors get_val_transform() in training
# ──────────────────────────────────────────────────────────────

def _build_transform() -> T.Compose:
    return T.Compose([
        T.Resize((224, 224)),
        T.ToTensor(),
        T.Normalize(mean=_IMAGENET_MEAN, std=_IMAGENET_STD),
    ])


# ──────────────────────────────────────────────────────────────
# DiseasePredictor (singleton, thread-safe)
# ──────────────────────────────────────────────────────────────

class DiseasePredictor:
    """Thread-safe singleton predictor for durian leaf disease detection.

    Loads EfficientNet-B0 checkpoint once and reuses across requests.
    Raises RuntimeError if the checkpoint is missing or cannot be loaded.
    """

    _instance: Optional["DiseasePredictor"] = None
    _lock = threading.Lock()

    def __new__(cls) -> "DiseasePredictor":
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    instance = super().__new__(cls)
                    instance._initialized = False
                    cls._instance = instance
        return cls._instance

    def __init__(self) -> None:
        if self._initialized:
            return
        with self._lock:
            if self._initialized:
                return
            self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            self._model = self._load_model()
            self._transform = _build_transform()
            self._initialized = True
            logger.info(
                "DiseasePredictor initialized on %s | checkpoint=%s",
                self._device,
                _CHECKPOINT_PATH,
            )

    def _load_model(self) -> nn.Module:
        model = _build_model()
        if not _CHECKPOINT_PATH.exists():
            raise RuntimeError(
                f"Disease detection checkpoint not found at {_CHECKPOINT_PATH}"
            )
        try:
            state = torch.load(
                str(_CHECKPOINT_PATH),
                map_location=self._device,
                weights_only=False,
            )
            # Checkpoint may wrap weights under 'model_state_dict'
            if isinstance(state, dict) and "model_state_dict" in state:
                state = state["model_state_dict"]
            model.load_state_dict(state, strict=True)
            logger.info("Loaded checkpoint from %s", _CHECKPOINT_PATH)
        except Exception as exc:
            raise RuntimeError(
                f"Failed to load disease detection checkpoint: {exc}"
            ) from exc
        model = model.to(self._device)
        model.eval()
        return model

    # ── Public API ──────────────────────────────────────────

    def predict(self, image_bytes: bytes) -> dict:
        """Run inference on raw image bytes.

        Returns:
            {
                "disease":       str,   # English class name
                "disease_vi":    str,   # Vietnamese name
                "confidence":    float, # 0.0 – 1.0
                "severity":      str,   # none | low | medium | high
                "top5":          list[dict],
            }
        """
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        tensor = self._transform(img).unsqueeze(0).to(self._device)

        with torch.no_grad():
            logits = self._model(tensor)
            probs = torch.softmax(logits, dim=1)[0]
            pred_idx = int(torch.argmax(probs).item())
            confidence = float(probs[pred_idx].item())

        top5_indices = torch.topk(probs, min(5, NUM_CLASSES)).indices.tolist()
        top5 = [
            {
                "class": CLASS_NAMES[i],
                "class_vi": DISEASE_NAME_VI.get(CLASS_NAMES[i], CLASS_NAMES[i]),
                "confidence": round(float(probs[i].item()), 4),
            }
            for i in top5_indices
        ]

        disease = CLASS_NAMES[pred_idx]
        base_severity = _SEVERITY_MAP.get(disease, "medium")

        # Escalate severity for diseased plants with high confidence
        if disease != "Healthy" and base_severity in ("low", "medium") and confidence >= 0.85:
            severity_levels = ["none", "low", "medium", "high"]
            idx = severity_levels.index(base_severity)
            base_severity = severity_levels[min(idx + 1, len(severity_levels) - 1)]

        return {
            "disease": disease,
            "disease_vi": DISEASE_NAME_VI.get(disease, disease),
            "confidence": round(confidence, 4),
            "severity": base_severity,
            "top5": top5,
        }
