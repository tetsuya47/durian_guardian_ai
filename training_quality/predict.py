"""Single-image quality prediction.

Usage:
    python training_quality/predict.py path/to/image.jpg
"""

import json
import sys
from pathlib import Path

import torch
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training_quality.utils.config_loader import ConfigLoader
from training_quality.models.quality_model import create_quality_model
from training_quality.dataset.quality_dataset import get_val_transform

CLASS_NAMES = ["Good", "Bad"]


def load_model(config_path: str = None):
    if config_path is None:
        config_path = str(PROJECT_ROOT / "training_quality" / "configs" / "model2.yaml")
    config_loader = ConfigLoader(config_path)
    config = config_loader.config

    device_name = "cuda" if torch.cuda.is_available() else "cpu"
    device = torch.device(device_name)

    model_config = config.get("model", {})
    model = create_quality_model(
        num_classes=model_config.get("num_classes", 2),
        pretrained=False,
        freeze_backbone=False,
        dropout=model_config.get("dropout", 0.3),
    )
    model = model.to(device)
    model.eval()

    checkpoint_path = PROJECT_ROOT / "training_quality" / "checkpoints" / "best_model.pt"
    if checkpoint_path.exists():
        state = torch.load(str(checkpoint_path), map_location=device)
        if "model_state_dict" in state:
            model.load_state_dict(state["model_state_dict"])
        else:
            model.load_state_dict(state)

    dataset_cfg = config.get("dataset", {})
    target_size = tuple(dataset_cfg.get("target_size", [224, 224]))
    mean = tuple(dataset_cfg.get("mean", [0.485, 0.456, 0.406]))
    std = tuple(dataset_cfg.get("std", [0.229, 0.224, 0.225]))
    transform = get_val_transform(target_size, mean, std)

    return model, device, transform


def predict(image_path: str) -> dict:
    model, device, transform = load_model()

    img = Image.open(image_path).convert("RGB")
    tensor = transform(img).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(tensor)
        probabilities = torch.softmax(outputs, dim=1)[0]
        predicted_idx = torch.argmax(probabilities).item()
        confidence = probabilities[predicted_idx].item()

    result = {
        "predicted_quality": CLASS_NAMES[predicted_idx],
        "class_id": predicted_idx,
        "confidence": round(confidence, 4),
        "probabilities": {
            "Good": round(probabilities[0].item(), 4),
            "Bad": round(probabilities[1].item(), 4),
        },
    }
    return result


def main():
    if len(sys.argv) < 2:
        print("Usage: python training_quality/predict.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    if not Path(image_path).exists():
        print(f"Error: File not found: {image_path}")
        sys.exit(1)

    result = predict(image_path)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
