import json
from pathlib import Path
from typing import Any, Dict, List, Optional

import torch
import torch.nn as nn
from torch.utils.data import DataLoader

from training_quality.engine.base_engine import BaseEngine
from training_quality.utils.logger import Logger


class Evaluator(BaseEngine):
    def __init__(
        self,
        model: nn.Module,
        config: Dict[str, Any],
        loss_fn,
        test_loader: DataLoader,
        device: Optional[torch.device] = None,
        logger=None,
    ):
        super().__init__(model, config, device, logger)
        self.loss_fn = loss_fn
        self.test_loader = test_loader

    @torch.no_grad()
    def run(self) -> Dict[str, Any]:
        self.model.eval()
        total_loss = 0.0
        all_logits = []
        all_targets = []

        for images, labels in self.test_loader:
            images = images.to(self.device)
            labels = labels.to(self.device)
            outputs = self.model(images)
            loss = self.loss_fn(outputs, labels)
            total_loss += loss.item()
            all_logits.append(outputs.cpu())
            all_targets.append(labels.cpu())

        logits = torch.cat(all_logits, dim=0)
        targets = torch.cat(all_targets, dim=0)
        probs = torch.softmax(logits, dim=1)
        preds = torch.argmax(logits, dim=1)

        results = {
            "test_loss": total_loss / len(self.test_loader),
            "predictions": preds.numpy().tolist(),
            "targets": targets.numpy().tolist(),
            "probabilities": probs.numpy().tolist(),
        }

        self._compute_metrics(results)
        self._log_results(results)
        self._save_report(results)
        self._generate_model_info(results)

        return results

    def _compute_metrics(self, results: Dict[str, Any]):
        preds = torch.tensor(results["predictions"])
        targets = torch.tensor(results["targets"])
        probs = torch.tensor(results["probabilities"])
        total = targets.size(0)

        results["accuracy"] = (preds == targets).sum().item() / total
        results["num_samples"] = total

        from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
        targets_np = targets.numpy()
        preds_np = preds.numpy()
        probs_np = probs.numpy()

        cm = confusion_matrix(targets_np, preds_np)
        if cm.shape == (2, 2):
            tn, fp, fn, tp = cm.ravel()
            results["precision"] = float(tp / (tp + fp)) if (tp + fp) > 0 else 0.0
            results["recall"] = float(tp / (tp + fn)) if (tp + fn) > 0 else 0.0
            f1 = 2 * results["precision"] * results["recall"] / (results["precision"] + results["recall"]) if (results["precision"] + results["recall"]) > 0 else 0.0
            results["f1_score"] = f1
            results["specificity"] = float(tn / (tn + fp)) if (tn + fp) > 0 else 0.0
        else:
            results["precision"] = 0.0
            results["recall"] = 0.0
            results["f1_score"] = 0.0

        try:
            results["roc_auc"] = float(roc_auc_score(targets_np, probs_np[:, 1]))
        except Exception:
            results["roc_auc"] = 0.0

        report = classification_report(targets_np, preds_np, output_dict=True, zero_division=0)
        results["classification_report"] = report
        results["confusion_matrix"] = cm.tolist()

    def _log_results(self, results: Dict[str, Any]):
        self.logger.info("")
        self.logger.info("=" * 60)
        self.logger.info("  TEST EVALUATION RESULTS")
        self.logger.info("=" * 60)
        self.logger.info("  Test Loss:      %.4f", results.get("test_loss", 0))
        self.logger.info("  Accuracy:       %.4f", results.get("accuracy", 0))
        self.logger.info("  Precision:      %.4f", results.get("precision", 0))
        self.logger.info("  Recall:         %.4f", results.get("recall", 0))
        self.logger.info("  F1-Score:       %.4f", results.get("f1_score", 0))
        self.logger.info("  ROC-AUC:        %.4f", results.get("roc_auc", 0))
        self.logger.info("  Samples:        %d", results.get("num_samples", 0))
        self.logger.info("=" * 60)

    def _save_report(self, results: Dict[str, Any]):
        report_dir = Path("training_quality/reports")
        report_dir.mkdir(parents=True, exist_ok=True)

        report_data = {k: v for k, v in results.items() if k not in ("predictions", "probabilities")}
        report_path = report_dir / "evaluation_report.json"
        with open(str(report_path), "w", encoding="utf-8") as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        self.logger.info("Report saved: %s", report_path)

        from sklearn.metrics import classification_report
        report_str = classification_report(
            results["targets"], results["predictions"],
            target_names=["Good", "Bad"], zero_division=0,
        )
        txt_path = report_dir / "classification_report.txt"
        with open(str(txt_path), "w", encoding="utf-8") as f:
            f.write(report_str)
        self.logger.info("Classification report saved: %s", txt_path)

    def _generate_model_info(self, results: Dict[str, Any]):
        report_dir = Path("training_quality/reports")
        report_dir.mkdir(parents=True, exist_ok=True)

        import platform
        total_params = sum(p.numel() for p in self.model.parameters())
        trainable_params = sum(p.numel() for p in self.model.parameters() if p.requires_grad)
        param_size = sum(p.numel() * p.element_size() for p in self.model.parameters())
        buffer_size = sum(b.numel() * b.element_size() for b in self.model.buffers())
        model_size_mb = (param_size + buffer_size) / (1024 * 1024)

        info = {
            "model_name": self.config.get("model", {}).get("name", "image_quality"),
            "architecture": self.config.get("model", {}).get("architecture", "mobilenet_v3_small"),
            "num_classes": self.config.get("model", {}).get("num_classes", 2),
            "class_names": ["Good", "Bad"],
            "parameters": {
                "total": total_params,
                "trainable": trainable_params,
                "frozen": total_params - trainable_params,
            },
            "model_size_mb": round(model_size_mb, 2),
            "test_metrics": {
                "accuracy": results.get("accuracy", 0),
                "precision": results.get("precision", 0),
                "recall": results.get("recall", 0),
                "f1_score": results.get("f1_score", 0),
                "roc_auc": results.get("roc_auc", 0),
            },
            "framework": {
                "pytorch": torch.__version__,
                "python": platform.python_version(),
            },
        }
        info_path = report_dir / "model_info.json"
        with open(str(info_path), "w", encoding="utf-8") as f:
            json.dump(info, f, indent=2, ensure_ascii=False)
        self.logger.info("Model info saved: %s", info_path)
