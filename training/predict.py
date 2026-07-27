"""Single-image prediction for trained disease detection model.

Usage:
    python training/predict.py path/to/image.jpg

Output:
    {
        "predicted_class": "anthracnose_disease",
        "confidence": 0.97,
        "top5": [...]
    }
"""

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

# Vietnamese disease name mapping (matches database seed/diseases.json)
DISEASE_NAME_VI = {
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

    return model, device, transform, config


def predict(image_path: str) -> dict:
    model, device, transform, config = load_model()

    img = Image.open(image_path).convert("RGB")
    tensor = transform(img).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(tensor)
        probabilities = torch.softmax(outputs, dim=1)[0]
        predicted_idx = torch.argmax(probabilities).item()
        confidence = probabilities[predicted_idx].item()

    top5_indices = torch.topk(probabilities, 5).indices.tolist()
    top5 = [
        {
            "class": CLASS_NAMES[i],
            "class_vi": DISEASE_NAME_VI.get(CLASS_NAMES[i], CLASS_NAMES[i]),
            "confidence": round(probabilities[i].item(), 4),
        }
        for i in top5_indices
    ]

    result = {
        "predicted_class": CLASS_NAMES[predicted_idx],
        "predicted_class_vi": DISEASE_NAME_VI.get(CLASS_NAMES[predicted_idx], CLASS_NAMES[predicted_idx]),
        "class_id": predicted_idx,
        "confidence": round(confidence, 4),
        "top5": top5,
    }
    return result


def main():
    if len(sys.argv) < 2:
        print("Usage: python training/predict.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    if not Path(image_path).exists():
        print(f"Error: File not found: {image_path}")
        sys.exit(1)

    result = predict(image_path)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
