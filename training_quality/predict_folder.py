"""Batch quality prediction for a folder of images.

Usage:
    python training_quality/predict_folder.py path/to/image/folder
"""

import csv
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
SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def load_model():
    config_path = PROJECT_ROOT / "training_quality" / "configs" / "model2.yaml"
    config_loader = ConfigLoader(str(config_path))
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


def predict_folder(folder_path: str, output_dir: str = None):
    model, device, transform = load_model()

    folder = Path(folder_path)
    if not folder.is_dir():
        print(f"Error: Not a directory: {folder_path}")
        sys.exit(1)

    image_files = sorted([
        f for f in folder.iterdir()
        if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
    ])
    if not image_files:
        print(f"No supported images found in {folder_path}")
        sys.exit(1)

    print(f"Found {len(image_files)} images in {folder_path}")
    results = []

    for img_file in image_files:
        img = Image.open(str(img_file)).convert("RGB")
        tensor = transform(img).unsqueeze(0).to(device)

        with torch.no_grad():
            outputs = model(tensor)
            probabilities = torch.softmax(outputs, dim=1)[0]
            predicted_idx = torch.argmax(probabilities).item()
            confidence = probabilities[predicted_idx].item()

        result = {
            "filename": img_file.name,
            "predicted_quality": CLASS_NAMES[predicted_idx],
            "class_id": predicted_idx,
            "confidence": round(confidence, 4),
        }
        results.append(result)
        print(f"  {img_file.name:50s} -> {CLASS_NAMES[predicted_idx]:6s} ({confidence:.4f})")

    if output_dir is None:
        output_dir = str(folder)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    csv_path = output_path / "quality_prediction.csv"
    with open(str(csv_path), "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["filename", "predicted_quality", "class_id", "confidence"])
        for r in results:
            writer.writerow([r["filename"], r["predicted_quality"], r["class_id"], r["confidence"]])
    print(f"\nSaved: {csv_path}")

    json_path = output_path / "quality_prediction.json"
    with open(str(json_path), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"Saved: {json_path}")

    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: python training_quality/predict_folder.py <folder_path> [output_dir]")
        sys.exit(1)

    folder_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None
    predict_folder(folder_path, output_dir)


if __name__ == "__main__":
    main()
