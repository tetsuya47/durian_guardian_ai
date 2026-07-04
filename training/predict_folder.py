"""Batch prediction for trained disease detection model.

Usage:
    python training/predict_folder.py path/to/image/folder

Output:
    prediction.csv
    prediction.json
"""

import csv
import json
import sys
from pathlib import Path

import torch
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.config_loader import ConfigLoader
from training.models.registry import create_model_from_config
from training.datasets.preprocess import get_val_transform


CLASS_NAMES = [
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

SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def load_model():
    config_path = PROJECT_ROOT / "training" / "configs" / "model1.yaml"
    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    device_name = "cuda" if torch.cuda.is_available() else "cpu"
    device = torch.device(device_name)

    model = create_model_from_config(config)
    model = model.to(device)
    model.eval()

    checkpoint_path = PROJECT_ROOT / "training" / "checkpoints" / "disease_detection" / "best_model.pt"
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

        top5_indices = torch.topk(probabilities, min(5, len(CLASS_NAMES))).indices.tolist()
        top5 = [
            {"class": CLASS_NAMES[i], "confidence": round(probabilities[i].item(), 4)}
            for i in top5_indices
        ]

        result = {
            "filename": img_file.name,
            "predicted_class": CLASS_NAMES[predicted_idx],
            "class_id": predicted_idx,
            "confidence": round(confidence, 4),
            "top5": top5,
        }
        results.append(result)
        print(f"  {img_file.name:50s} -> {CLASS_NAMES[predicted_idx]:30s} ({confidence:.4f})")

    if output_dir is None:
        output_dir = str(folder)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    csv_path = output_path / "prediction.csv"
    with open(str(csv_path), "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["filename", "predicted_class", "class_id", "confidence", "top5"])
        for r in results:
            top5_str = "; ".join([f"{t['class']}({t['confidence']})" for t in r["top5"]])
            writer.writerow([r["filename"], r["predicted_class"], r["class_id"], r["confidence"], top5_str])
    print(f"\nSaved: {csv_path}")

    json_path = output_path / "prediction.json"
    with open(str(json_path), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"Saved: {json_path}")

    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: python training/predict_folder.py <folder_path> [output_dir]")
        sys.exit(1)

    folder_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None
    predict_folder(folder_path, output_dir)


if __name__ == "__main__":
    main()
