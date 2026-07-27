"""GradCAM visualization for model interpretability.

Shows which regions of the leaf image the model focuses on for its decision.

Usage:
    python training/gradcam.py path/to/image.jpg
    python training/gradcam.py path/to/image.jpg --output custom_output.png --target-layer features.6

Output:
    heatmap.png        - Raw heatmap
    overlay.png        - Heatmap overlaid on original image
"""

import argparse
import sys
from pathlib import Path

import torch
import torch.nn.functional as F
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


class GradCAM:
    """GradCAM for visualizing model attention regions."""

    def __init__(self, model: torch.nn.Module, target_layer: str):
        self.model = model
        self.model.eval()
        self.gradients = None
        self.activations = None
        self._register_hooks(target_layer)

    def _register_hooks(self, target_layer: str):
        target_module = self._find_layer(target_layer)
        if target_module is None:
            available = self._list_layers()
            raise ValueError(
                f"Layer '{target_layer}' not found. Available layers:\n"
                + "\n".join(available[:20])
            )

        target_module.register_forward_hook(self._forward_hook)
        target_module.register_full_backward_hook(self._backward_hook)

    def _find_layer(self, name: str):
        parts = name.split(".")
        module = self.model
        for part in parts:
            if part.isdigit():
                module = module[int(part)]
            elif hasattr(module, part):
                module = getattr(module, part)
            else:
                return None
        return module

    def _list_layers(self):
        layers = []
        for name, _ in self.model.named_modules():
            layers.append(name)
        return layers

    def _forward_hook(self, module, input, output):
        self.activations = output.detach()

    def _backward_hook(self, module, grad_input, grad_output):
        self.gradients = grad_output[0].detach()

    def generate(self, input_tensor: torch.Tensor, class_idx: int = None) -> torch.Tensor:
        output = self.model(input_tensor)
        if class_idx is None:
            class_idx = torch.argmax(output, dim=1).item()

        self.model.zero_grad()
        class_loss = output[0, class_idx]
        class_loss.backward()

        weights = self.gradients.mean(dim=(2, 3), keepdim=True)
        cam = (weights * self.activations).sum(dim=1, keepdim=True)
        cam = F.relu(cam)
        cam = F.interpolate(cam, size=input_tensor.shape[2:], mode="bilinear", align_corners=False)
        cam = cam.squeeze()

        cam_min, cam_max = cam.min(), cam.max()
        if cam_max > cam_min:
            cam = (cam - cam_min) / (cam_max - cam_min)
        return cam.cpu(), class_idx


def main():
    parser = argparse.ArgumentParser(description="GradCAM for Durian Disease Detection")
    parser.add_argument("image", type=str, help="Path to input image")
    parser.add_argument("--output", type=str, default=None, help="Output directory")
    parser.add_argument("--target-layer", type=str, default="features.6",
                        help="Target layer for GradCAM (default: features.6)")
    parser.add_argument("--alpha", type=float, default=0.5, help="Overlay opacity (default: 0.5)")
    args = parser.parse_args()

    img_path = Path(args.image)
    if not img_path.exists():
        print(f"Error: File not found: {args.image}")
        sys.exit(1)

    if args.output:
        output_dir = Path(args.output)
    else:
        output_dir = img_path.parent
    output_dir.mkdir(parents=True, exist_ok=True)

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

    pil_img = Image.open(str(img_path)).convert("RGB")
    input_tensor = transform(pil_img).unsqueeze(0).to(device)

    with torch.no_grad():
        output = model(input_tensor)
        probs = torch.softmax(output, dim=1)
        predicted_idx = torch.argmax(output, dim=1).item()
        confidence = probs[0, predicted_idx].item()

    print(f"\nImage: {img_path.name}")
    disease_vi = DISEASE_NAME_VI.get(CLASS_NAMES[predicted_idx], CLASS_NAMES[predicted_idx])
    print(f"Predicted: {CLASS_NAMES[predicted_idx]} / {disease_vi} ({confidence:.4f})")

    gradcam = GradCAM(model, args.target_layer)
    cam, class_idx = gradcam.generate(input_tensor, class_idx=predicted_idx)

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        import numpy as np

        mean_np = np.array(mean)
        std_np = np.array(std)
        img_np = input_tensor[0].cpu().numpy().transpose(1, 2, 0)
        img_np = img_np * std_np + mean_np
        img_np = np.clip(img_np, 0, 1)

        from matplotlib import cm as cm_module
        heatmap = cm_module.jet(cam.numpy())[:, :, :3]

        fig, axes = plt.subplots(1, 3, figsize=(18, 6))

        axes[0].imshow(img_np)
        axes[0].set_title("Original Image", fontsize=14)
        axes[0].axis("off")

        disease_vi = DISEASE_NAME_VI.get(CLASS_NAMES[class_idx], CLASS_NAMES[class_idx])
        axes[1].imshow(cam.numpy(), cmap="jet", interpolation="bilinear")
        axes[1].set_title(f"GradCAM Heatmap\n{disease_vi} ({confidence:.2f})", fontsize=14)
        axes[1].axis("off")

        overlay = (1 - args.alpha) * img_np + args.alpha * heatmap
        overlay = np.clip(overlay, 0, 1)
        axes[2].imshow(overlay)
        axes[2].set_title("Overlay", fontsize=14)
        axes[2].axis("off")

        plt.tight_layout()
        overlay_path = output_dir / "overlay.png"
        plt.savefig(str(overlay_path), dpi=150, bbox_inches="tight")
        plt.close()
        print(f"Saved: {overlay_path}")

        plt.figure(figsize=(8, 6))
        plt.imshow(cam.numpy(), cmap="jet", interpolation="bilinear")
        plt.colorbar(label="Activation")
        plt.title(f"GradCAM Heatmap - {DISEASE_NAME_VI.get(CLASS_NAMES[class_idx], CLASS_NAMES[class_idx])}", fontsize=14)
        plt.axis("off")
        heatmap_path = output_dir / "heatmap.png"
        plt.savefig(str(heatmap_path), dpi=150, bbox_inches="tight")
        plt.close()
        print(f"Saved: {heatmap_path}")

    except ImportError:
        print("matplotlib not available. Saving raw heatmap tensor.")
        torch.save(cam, str(output_dir / "heatmap.pt"))
        print(f"Saved: {output_dir / 'heatmap.pt'}")


if __name__ == "__main__":
    main()
