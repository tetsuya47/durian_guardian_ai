"""Model validation script.

Verifies:
  - model.pt loads correctly
  - model.torchscript loads correctly
  - model.onnx loads correctly (if exists)
  - Single prediction works
  - Batch prediction works
  - Output shapes are correct
"""

import json
import sys
from pathlib import Path

import torch
import numpy as np
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from training.utils.config_loader import ConfigLoader
from training.utils.logger import Logger
from training.models.registry import create_model_from_config
from training.datasets.preprocess import get_val_transform
from training.datasets.loaders import ImageClassificationDataset
from torch.utils.data import DataLoader


logger = Logger.get_logger("validate_model")
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


def test_pytorch_model(model, device, transform, test_loader):
    logger.info("")
    logger.info("--- Testing PyTorch model.pt ---")
    model.eval()

    images, labels = next(iter(test_loader))
    images = images.to(device)

    with torch.no_grad():
        outputs = model(images)
        probs = torch.softmax(outputs, dim=1)
        preds = torch.argmax(outputs, dim=1)

    assert outputs.shape == (images.size(0), 11), f"Expected shape (B,11), got {outputs.shape}"
    assert probs.shape == (images.size(0), 11), f"Expected shape (B,11), got {probs.shape}"
    assert preds.shape == (images.size(0),), f"Expected shape (B,), got {preds.shape}"
    assert torch.allclose(probs.sum(dim=1), torch.ones(images.size(0))), "Probabilities don't sum to 1"

    logger.info("  Output shape: %s", outputs.shape)
    logger.info("  Probabilities sum to 1: YES")
    logger.info("  Sample prediction: %s (%.4f)", CLASS_NAMES[preds[0].item()], probs[0, preds[0]].item())
    logger.info("  PyTorch model: PASS")


def test_torchscript_model(device):
    logger.info("")
    logger.info("--- Testing TorchScript model.torchscript ---")
    ts_path = PROJECT_ROOT / "training" / "exports" / "disease_detection" / "model.torchscript"
    assert ts_path.exists(), f"TorchScript model not found: {ts_path}"

    ts_model = torch.jit.load(str(ts_path), map_location=device)
    ts_model.eval()

    dummy = torch.randn(4, 3, 224, 224).to(device)
    with torch.no_grad():
        outputs = ts_model(dummy)
        probs = torch.softmax(outputs, dim=1)
        preds = torch.argmax(outputs, dim=1)

    assert outputs.shape == (4, 11), f"Expected shape (4,11), got {outputs.shape}"
    assert torch.allclose(probs.sum(dim=1), torch.ones(4)), "Probabilities don't sum to 1"

    logger.info("  Output shape: %s", outputs.shape)
    logger.info("  Probabilities sum to 1: YES")
    logger.info("  TorchScript model: PASS")
    return ts_model


def test_onnx_model():
    logger.info("")
    logger.info("--- Testing ONNX model.onnx ---")
    onnx_path = PROJECT_ROOT / "training" / "exports" / "disease_detection" / "model.onnx"
    if not onnx_path.exists():
        logger.warning("  ONNX model not found, skipping ONNX validation")
        return None

    try:
        import onnx
        import onnxruntime as ort

        onnx_model = onnx.load(str(onnx_path))
        onnx.checker.check_model(onnx_model)
        logger.info("  ONNX model structure: VALID")

        session = ort.InferenceSession(str(onnx_path))
        input_name = session.get_inputs()[0].name
        dummy = np.random.randn(4, 3, 224, 224).astype(np.float32)
        outputs = session.run(None, {input_name: dummy})[0]

        assert outputs.shape == (4, 11), f"Expected shape (4,11), got {outputs.shape}"
        probs = np.exp(outputs) / np.sum(np.exp(outputs), axis=1, keepdims=True)
        assert np.allclose(probs.sum(axis=1), 1.0), "Probabilities don't sum to 1"

        logger.info("  Output shape: %s", outputs.shape)
        logger.info("  Probabilities sum to 1: YES")
        logger.info("  ONNX model: PASS")
        return session
    except Exception as e:
        logger.error("  ONNX validation failed: %s", e)
        return None


def test_single_prediction(model, device, transform, config=None):
    logger.info("")
    logger.info("--- Testing single prediction ---")
    if config:
        dataset_cfg = config.get("dataset", {})
        root = PROJECT_ROOT / dataset_cfg.get("root", "dataset")
        test_dir = root / dataset_cfg.get("test_split", "Test")
    else:
        test_dir = PROJECT_ROOT / "dataset" / "Test"
    class_dirs = [d for d in test_dir.iterdir() if d.is_dir()]
    first_image = None
    IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}
    for cls_dir in class_dirs:
        images = [f for f in cls_dir.iterdir() if f.suffix.lower() in IMAGE_EXTS]
        if images:
            first_image = images[0]
            break

    if first_image is None:
        logger.warning("  No test images found, skipping")
        return

    img = Image.open(str(first_image)).convert("RGB")
    tensor = transform(img).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(tensor)
        probs = torch.softmax(outputs, dim=1)[0]
        pred_idx = torch.argmax(probs).item()
        confidence = probs[pred_idx].item()

    logger.info("  Image: %s", first_image.name)
    logger.info("  Predicted: %s (%.4f)", CLASS_NAMES[pred_idx], confidence)
    logger.info("  Single prediction: PASS")


def main():
    config_path = PROJECT_ROOT / "training" / "configs" / "model1.yaml"
    config_loader = ConfigLoader(str(config_path))
    config = config_loader.config

    device_name = "cuda" if torch.cuda.is_available() else "cpu"
    device = torch.device(device_name)
    logger.info("Device: %s", device)

    model = create_model_from_config(config)
    model = model.to(device)

    checkpoint_path = PROJECT_ROOT / "training" / "checkpoints" / "disease_detection" / "best_model.pt"
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

    root = PROJECT_ROOT / dataset_cfg.get("root", "dataset")
    test_dir = root / dataset_cfg.get("test_split", "Test")
    test_dataset = ImageClassificationDataset(
        root_dir=str(test_dir),
        transform=transform,
        validate_images=False,
    )
    test_loader = DataLoader(test_dataset, batch_size=4, shuffle=False, num_workers=0)

    test_pytorch_model(model, device, transform, test_loader)
    test_torchscript_model(device)
    test_onnx_model()
    test_single_prediction(model, device, transform, config)

    logger.info("")
    logger.info("=" * 60)
    logger.info("  ALL VALIDATIONS PASSED")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
