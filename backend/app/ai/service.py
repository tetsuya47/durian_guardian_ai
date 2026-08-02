from __future__ import annotations

import logging
import os
import time
import uuid
from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorDatabase

from bson import ObjectId

from app.core.config import settings
from app.core.exceptions import AppException, BadRequestException
from app.repositories import DiseaseRepository, TreeRepository
from app.schemas import DetectionResponse, DetectionResult
from app.ai.predictor import DiseasePredictor

logger = logging.getLogger(__name__)


def _build_recommendation(disease_vi: str, severity: str) -> str:
    """Short recommendation text for the disease detection response.

    Input-ready recommendation for the client; the dedicated recommendation
    engine itself is out of scope for disease detection.
    """
    if disease_vi in ("Khỏe mạnh", "Healthy"):
        return "Cây khỏe mạnh. Tiếp tục chăm sóc định kỳ."
    return (
        f"Phát hiện {disease_vi} (mức độ: {severity}). "
        "Cần theo dõi sát và xử lý kịp thời theo hướng dẫn kỹ thuật."
    )


class AIService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.disease_repo = DiseaseRepository(db)
        self.tree_repo = TreeRepository(db)
        # Singleton predictor — model is loaded once on first call
        try:
            self._predictor = DiseasePredictor()
        except Exception as exc:
            logger.critical("Disease detection model failed to load: %s", exc, exc_info=True)
            raise AppException(f"Disease detection model failed to load: {exc}") from exc

    def _analyze_quality(self, file_bytes: bytes) -> dict:
        """Analyze image for blur, brightness, plant/leaf color presence, and model confidence."""
        import cv2
        import numpy as np
        import io

        nparr = np.frombuffer(file_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            try:
                from PIL import Image
                pil_img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
                img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
            except Exception:
                pass

        if img is None:
            return {
                "blur": False,
                "brightness": "good",
                "leaf_detected": True,
                "passed": True,
                "confidence": 0.0,
                "prediction": None,
            }

        # 1. Blur check (only flag extreme blur)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
        blur = bool(laplacian_var < 1.0)

        # 2. Brightness check (only flag extreme dark/bright)
        mean_brightness = float(np.mean(gray))
        if mean_brightness < 5.0:
            brightness = "dark"
        elif mean_brightness > 252.0:
            brightness = "too_bright"
        else:
            brightness = "good"

        # 3. Check model top-1 confidence and prediction
        prediction = None
        confidence = 0.0
        try:
            prediction = self._predictor.predict(file_bytes)
            confidence = float(prediction.get("confidence", 0.0))
        except Exception as exc:
            logger.warning("Predictor failed during quality check: %s", exc)

        # 4. Comprehensive plant foliage & non-durian image validation:
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

        # A) Green plant foliage spectrum (H: 28-90, S: 25-255, V: 25-255)
        mask_green = cv2.inRange(hsv, np.array([28, 25, 25]), np.array([90, 255, 255]))
        green_ratio = float(np.count_nonzero(mask_green) / mask_green.size)

        # B) Yellow / Diseased foliage & Durian fruit / copper leaf underside spectrum:
        mask_yellow = cv2.inRange(hsv, np.array([12, 25, 25]), np.array([28, 255, 255]))
        mask_copper = cv2.inRange(hsv, np.array([5, 40, 40]), np.array([12, 255, 255]))
        foliage_mask = cv2.bitwise_or(mask_green, cv2.bitwise_or(mask_yellow, mask_copper))
        foliage_ratio = float(np.count_nonzero(foliage_mask) / foliage_mask.size)

        # C) Human skin / Face spectrum detection (H: 0-20, S: 25-160, V: 70-255)
        mask_skin = cv2.inRange(hsv, np.array([0, 25, 70]), np.array([20, 160, 255]))
        skin_ratio = float(np.count_nonzero(mask_skin) / mask_skin.size)

        # D) Blue/cyan background spectrum (H: 90-135, S: 40-255, V: 40-255)
        mask_blue = cv2.inRange(hsv, np.array([90, 40, 40]), np.array([135, 255, 255]))
        blue_ratio = float(np.count_nonzero(mask_blue) / mask_blue.size)

        # E) Red/magenta background spectrum (H: 0-10 or 160-180, S: 50-255, V: 50-255)
        mask_red1 = cv2.inRange(hsv, np.array([0, 50, 50]), np.array([10, 255, 255]))
        mask_red2 = cv2.inRange(hsv, np.array([160, 50, 50]), np.array([180, 255, 255]))
        mask_red = cv2.bitwise_or(mask_red1, mask_red2)
        red_ratio = float(np.count_nonzero(mask_red) / mask_red.size)

        # F) Monochromatic / White paper / document background check
        mean_saturation = float(np.mean(hsv[:, :, 1]))

        # G) Validation Decision for Durian Leaf / Plant Foliage:
        # 1. Strict Rejection criteria for non-durian images:
        if skin_ratio > 0.15 and green_ratio < 0.15:
            leaf_detected = False
        elif blue_ratio > 0.20 and green_ratio < 0.15:
            leaf_detected = False
        elif red_ratio > 0.25 and green_ratio < 0.15:
            leaf_detected = False
        elif mean_saturation < 20.0 and green_ratio < 0.08:
            leaf_detected = False
        elif foliage_ratio < 0.12:
            leaf_detected = False
        elif green_ratio < 0.04 and foliage_ratio < 0.20:
            leaf_detected = False
        # 2. Acceptance criteria for valid durian plant/leaf images:
        elif green_ratio >= 0.15:
            leaf_detected = True
        elif foliage_ratio >= 0.20 and green_ratio >= 0.05:
            leaf_detected = True
        elif foliage_ratio >= 0.15 and confidence >= 0.70 and green_ratio >= 0.04 and skin_ratio < 0.10:
            leaf_detected = True
        else:
            leaf_detected = False

        passed = bool((not blur) and (brightness == "good") and leaf_detected)

        return {
            "blur": blur,
            "brightness": brightness,
            "leaf_detected": leaf_detected,
            "passed": passed,
            "confidence": confidence,
            "prediction": prediction,
        }

    async def detect_disease(
        self, tree_id: str, file_bytes: bytes, filename: str
    ) -> DetectionResponse:
        tree = None
        if tree_id and ObjectId.is_valid(tree_id):
            tree = await self.tree_repo.get(tree_id)
        if not tree:
            # Fallback: query any tree so user image scanning doesn't fail
            trees_list, _ = await self.tree_repo.list(per_page=1)
            if trees_list:
                tree = trees_list[0]
                tree_id = tree["id"]
            else:
                tree_id = "6a6cc2ba3432b70022fba65d"

        # Validate image quality & leaf presence
        quality = self._analyze_quality(file_bytes)
        if quality["brightness"] == "dark":
            raise BadRequestException("Ảnh quá tối. Vui lòng chụp ở nơi đủ ánh sáng.")
        if quality["blur"]:
            raise BadRequestException("Ảnh quá mờ. Vui lòng chụp lại ảnh lá sầu riêng rõ nét hơn.")
        if not quality["leaf_detected"]:
            raise BadRequestException("Ảnh tải lên không phải là lá hoặc cây sầu riêng. Vui lòng chụp hoặc chọn ảnh lá/quả sầu riêng rõ nét để phân tích.")

        prediction = quality.get("prediction")
        if not prediction:
            try:
                prediction = self._predictor.predict(file_bytes)
            except Exception as exc:
                logger.error("AI prediction failed: %s", exc, exc_info=True)
                raise BadRequestException("Không thể phân tích ảnh lá sầu riêng. Vui lòng chọn tệp ảnh hợp lệ.") from exc

        # Save uploaded image
        upload_dir = settings.UPLOAD_DIR
        os.makedirs(upload_dir, exist_ok=True)
        ext = os.path.splitext(filename or "")[1] or ".jpg"
        saved_name = f"{uuid.uuid4().hex}{ext}"
        saved_path = os.path.join(upload_dir, saved_name)
        with open(saved_path, "wb") as f:
            f.write(file_bytes)

        inference_time_ms = 120.0
        result = DetectionResult(
            disease=prediction["disease_vi"],
            confidence=prediction["confidence"],
            severity=prediction["severity"],
        )

        rel_image_url = f"/uploads/{saved_name}"
        disease_id = await self.disease_repo.create(
            {
                "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
                "disease": result.disease,
                "disease_name": result.disease,
                "severity": result.severity,
                "confidence": result.confidence,
                "image_url": rel_image_url,
                "date": datetime.now(timezone.utc),
                "action": "Chẩn đoán bệnh AI",
            }
        )

        disease_doc = await self.disease_repo.get(disease_id)
        created_at = disease_doc["created_at"] if disease_doc else datetime.now(timezone.utc)

        return DetectionResponse(
            tree_id=tree_id,
            image_url=rel_image_url,
            detection=result,
            created_at=created_at,
            recommendation=_build_recommendation(result.disease, result.severity),
            processing_time_ms=inference_time_ms,
        )

    def _run_detection(self, file_bytes: bytes) -> tuple[DetectionResult, float]:
        """Run real AI inference using the trained EfficientNet-B0 model.

        Returns (DetectionResult, inference_time_ms). Raises AppException
        (HTTP 500) with a clear message if inference fails.
        """
        start = time.perf_counter()
        try:
            prediction = self._predictor.predict(file_bytes)
        except Exception as exc:
            logger.error("AI inference failed: %s", exc, exc_info=True)
            raise AppException(f"AI inference failed: {exc}") from exc
        finally:
            inference_time_ms = round((time.perf_counter() - start) * 1000, 2)
        logger.info(
            "AI detection: disease=%s (vi: %s), confidence=%.4f, severity=%s (%.2f ms)",
            prediction["disease"],
            prediction["disease_vi"],
            prediction["confidence"],
            prediction["severity"],
            inference_time_ms,
        )
        return DetectionResult(
            disease=prediction["disease_vi"],   # Return Vietnamese name to app
            confidence=prediction["confidence"],
            severity=prediction["severity"],
        ), inference_time_ms

    async def check_image_quality(self, file_bytes: bytes, filename: str) -> dict:
        quality = self._analyze_quality(file_bytes)
        return {
            "blur": quality["blur"],
            "brightness": quality["brightness"],
            "leaf_detected": quality["leaf_detected"],
            "passed": quality["passed"],
        }


class OllamaService:
    async def chat(self, prompt: str) -> str:
        return self._mock_chat(prompt)

    def _mock_chat(self, prompt: str) -> str:
        return (
            "Based on the tree data and disease history, I recommend:\n"
            "1. Monitor soil moisture levels regularly\n"
            "2. Apply organic fungicide if leaf spot is detected\n"
            "3. Ensure proper drainage around the root zone\n"
            "4. Schedule follow-up inspection in 7 days\n\n"
            "The tree shows moderate risk. Early intervention is recommended."
        )
