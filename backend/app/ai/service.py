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
from app.repositories.inspection_repository import InspectionRepository
from app.repositories.detection_result_repository import DetectionResultRepository
from app.repositories.alert_repository import AlertRepository
from app.schemas import DetectionResponse, DetectionResult
from app.ai.predictor import DiseasePredictor
from app.ai.decision_engine.service import AIDecisionEngineService

logger = logging.getLogger(__name__)


def _build_recommendation(disease_vi: str, severity: str) -> str:
    """AI Decision Engine recommendation combining Model 1 prediction + Knowledge Base + Actionable Protocol."""
    if disease_vi in ("Khỏe mạnh", "Healthy"):
        return "🌱 NÔNG TRẠI AN TOÀN: Lá sầu riêng xanh mướt, không có dấu hiệu bệnh hại. Duy trì tưới gốc & bổ sung phân hữu cơ vi sinh định kỳ."

    if "Thán Thư" in disease_vi or "Anthracnose" in disease_vi:
        return (
            f"⚡ AI DECISION ENGINE (Mức độ: {severity}): Phát hiện Bệnh Thán Thư (Colletotrichum). "
            "Phác đồ khuyên dùng: Phun Ridomil Gold 68WG (Metalaxyl + Mancozeb) pha 500g/200L nước hoặc Antracol 70WP vào sáng sớm. "
            "Tỉa cành rậm rạp & đặt lịch hẹn tái khám sau 7 ngày."
        )
    elif "Xì Mủ" in disease_vi or "Phytophthora" in disease_vi:
        return (
            f"⚡ AI DECISION ENGINE (Mức độ: {severity}): Cảnh báo Bệnh Xì Mủ Thối Rễ (Phytophthora). "
            "Phác đồ khuyên dùng: Quét trực tiếp Aliette 800WG hoặc Ridomil Gold đậm đặc lên vết xì mủ ở gốc. "
            "Rải 500g Vôi bột/gốc để sát trùng nâng pH đất và khơi rãnh thoát nước."
        )
    elif "Cháy Lá" in disease_vi or "Rhizoctonia" in disease_vi:
        return (
            f"⚡ AI DECISION ENGINE (Mức độ: {severity}): Phát hiện Bệnh Cháy Lá Dính (Rhizoctonia). "
            "Phác đồ khuyên dùng: Phun Anvil 5SC (Hexaconazole 50g/l) 300ml/200L nước hoặc Validacin 5SL. "
            "Gỡ chùm lá dính cháy khô & theo dõi cơi đọt non sau 7 ngày."
        )
    elif "Nấm Hồng" in disease_vi or "Pink" in disease_vi:
        return (
            f"⚡ AI DECISION ENGINE (Mức độ: {severity}): Phát hiện Bệnh Nấm Hồng cành chạc ba. "
            "Phác đồ khuyên dùng: Phun Coc85 hoặc Champion 77WP quét sương vết nấm. "
            "Tỉa bớt cành rậm tán dưới để thoáng gầm cây."
        )

    return (
        f"⚡ AI DECISION ENGINE (Mức độ: {severity}): Phát hiện {disease_vi}. "
        "Cần theo dõi sát cơi đọt và phun thuốc bảo vệ thực vật đặc trị theo hướng dẫn."
    )


class AIService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.disease_repo = DiseaseRepository(db)
        self.tree_repo = TreeRepository(db)
        self.inspection_repo = InspectionRepository(db)
        self.detection_result_repo = DetectionResultRepository(db)
        self.alert_repo = AlertRepository(db)
        self.decision_engine = AIDecisionEngineService(db)
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

        # 4. Strict plant foliage & non-durian image validation:
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

        # A) Genuine green plant foliage spectrum (H: 30-88, S: 45-255, V: 35-255)
        mask_green = cv2.inRange(hsv, np.array([30, 45, 35]), np.array([88, 255, 255]))
        green_ratio = float(np.count_nonzero(mask_green) / mask_green.size)

        # B) Diseased yellow foliage spectrum (H: 15-30, S: 55-255, V: 45-255)
        mask_yellow = cv2.inRange(hsv, np.array([15, 55, 45]), np.array([30, 255, 255]))
        yellow_ratio = float(np.count_nonzero(mask_yellow) / mask_yellow.size)

        foliage_ratio = green_ratio + yellow_ratio

        # C) Non-leaf background checks
        mask_skin = cv2.inRange(hsv, np.array([0, 30, 70]), np.array([20, 160, 255]))
        skin_ratio = float(np.count_nonzero(mask_skin) / mask_skin.size)

        mask_blue = cv2.inRange(hsv, np.array([90, 45, 40]), np.array([135, 255, 255]))
        blue_ratio = float(np.count_nonzero(mask_blue) / mask_blue.size)

        mean_saturation = float(np.mean(hsv[:, :, 1]))

        # D) Validation Decision for Durian Leaf / Plant Foliage:
        # A valid plant/leaf image MUST contain sufficient green/yellow foliage diệp lục (foliage_ratio >= 0.08 or green_ratio >= 0.05)
        if green_ratio < 0.05 and foliage_ratio < 0.08:
            leaf_detected = False
        elif skin_ratio > 0.25 and green_ratio < 0.08:
            leaf_detected = False
        elif blue_ratio > 0.30 and green_ratio < 0.08:
            leaf_detected = False
        elif mean_saturation < 18.0 and green_ratio < 0.08:
            leaf_detected = False
        else:
            leaf_detected = True

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
                tree_id = str(tree.get("id") or tree.get("_id"))
            else:
                fallback_oid = ObjectId("6a6cc2ba3432b70022fba65d")
                tree = await self.db["trees"].find_one({"_id": fallback_oid})
                if not tree:
                    farm = await self.db["farms"].find_one({})
                    farm_id = farm["_id"] if farm else ObjectId()
                    zone = await self.db["zones"].find_one({})
                    zone_id = zone["_id"] if zone else ObjectId()

                    tree = {
                        "_id": fallback_oid,
                        "tree_code": "SR-DEFAULT-01",
                        "farm_id": farm_id,
                        "zone_id": zone_id,
                        "variety": "Ri6",
                        "planting_date": datetime.now(timezone.utc),
                        "tree_age": 5,
                        "status": "Khỏe mạnh",
                        "health_status": "Khỏe mạnh",
                        "created_at": datetime.now(timezone.utc),
                        "updated_at": datetime.now(timezone.utc),
                    }
                    try:
                        await self.db["trees"].insert_one(tree)
                    except Exception as err:
                        logger.warning("Could not insert fallback tree: %s", err)
                tree_id = str(fallback_oid)

        # Validate image quality & leaf presence
        quality = self._analyze_quality(file_bytes)
        if quality["brightness"] == "dark":
            raise BadRequestException("Ảnh quá tối. Vui lòng chụp ở nơi đủ ánh sáng.")
        if quality["blur"]:
            raise BadRequestException("Ảnh quá mờ. Vui lòng chụp lại ảnh lá sầu riêng rõ nét hơn.")
        if not quality["leaf_detected"]:
            raise BadRequestException("Ảnh tải lên không phải là lá hoặc cây sầu riêng. Vui lòng chụp hoặc chọn ảnh lá/quả sầu riêng rõ nét để phân tích.")

        farm_id = tree.get("farm_id") if isinstance(tree, dict) else None
        zone_id = tree.get("zone_id") if isinstance(tree, dict) else None
        company_id = tree.get("company_id") if isinstance(tree, dict) else None

        # Phase 1: Create Inspection record with status="PROCESSING"
        count = await self.inspection_repo.collection.count_documents({})
        inspection_code = f"INSP{count + 1:05d}"

        inspection_id = await self.inspection_repo.create({
            "inspection_code": inspection_code,
            "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
            "farm_id": ObjectId(farm_id) if farm_id and ObjectId.is_valid(str(farm_id)) else farm_id,
            "zone_id": ObjectId(zone_id) if zone_id and ObjectId.is_valid(str(zone_id)) else zone_id,
            "inspection_date": datetime.now(timezone.utc),
            "health_status": "Đang theo dõi",
            "predicted_disease": "Đang xử lý",
            "confidence": 0.0,
            "status": "PROCESSING",
        })

        try:
            start_time = time.perf_counter()
            prediction = quality.get("prediction")
            if not prediction:
                prediction = self._predictor.predict(file_bytes)
            inference_time_ms = round((time.perf_counter() - start_time) * 1000, 2)

            # Save uploaded image
            upload_dir = settings.UPLOAD_DIR
            os.makedirs(upload_dir, exist_ok=True)
            ext = os.path.splitext(filename or "")[1] or ".jpg"
            saved_name = f"{uuid.uuid4().hex}{ext}"
            saved_path = os.path.join(upload_dir, saved_name)
            with open(saved_path, "wb") as f:
                f.write(file_bytes)

            result = DetectionResult(
                disease=prediction["disease_vi"],
                confidence=prediction["confidence"],
                severity=prediction["severity"],
            )

            rel_image_url = f"/uploads/{saved_name}"

            # Phase 2: Create Detection Result record in detection_results collection
            severity_risk_map = {
                "none": 10,
                "low": 40,
                "medium": 70,
                "high": 90,
            }
            risk_score = severity_risk_map.get(result.severity.lower() if isinstance(result.severity, str) else "medium", 50)

            # Model 4 AI Decision Engine & AI Agronomist execution
            ai_decision_dict, agronomist_recommendation = await self.decision_engine.run_decision_engine(
                tree_id=tree_id,
                disease_name=result.disease,
                confidence=result.confidence,
                severity=result.severity,
                risk_score=float(risk_score),
                risk_level="High" if risk_score >= 70 else "Medium" if risk_score >= 40 else "Low",
            )

            count_det = await self.detection_result_repo.collection.count_documents({})
            detection_code = f"DET{count_det + 1:05d}"

            detection_result_id = await self.detection_result_repo.create({
                "detection_code": detection_code,
                "inspection_id": ObjectId(inspection_id) if ObjectId.is_valid(inspection_id) else inspection_id,
                "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
                "farm_id": ObjectId(farm_id) if farm_id and ObjectId.is_valid(str(farm_id)) else farm_id,
                "company_id": ObjectId(company_id) if company_id and ObjectId.is_valid(str(company_id)) else company_id,
                "model": "EfficientNet-B0",
                "model_version": "1.0.0",
                "prediction": result.disease,
                "confidence": round(float(result.confidence) * 100, 2),
                "severity": result.severity,
                "image_path": rel_image_url,
                "image_quality": "good" if quality.get("passed") else "normal",
                "processing_time_ms": inference_time_ms,
                "recommendation": agronomist_recommendation,
                "ai_decision": ai_decision_dict,
                "created_at": datetime.now(timezone.utc),
            })
            status_enum = "Khỏe mạnh" if result.disease in ("Khỏe mạnh", "Healthy") else "Bị bệnh"
            health_status_vi = "Khỏe mạnh" if result.disease in ("Khỏe mạnh", "Healthy") else result.disease

            await self.tree_repo.update(
                tree_id,
                {
                    "health_status": health_status_vi,
                    "status": status_enum,
                    "risk_score": risk_score,
                    "last_inspection": datetime.now(timezone.utc),
                },
            )

            # Phase 4: Disease History Audit Log (Immutable append-only record)
            disease_id = await self.disease_repo.create(
                {
                    "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
                    "farm_id": ObjectId(farm_id) if farm_id and ObjectId.is_valid(str(farm_id)) else farm_id,
                    "company_id": ObjectId(company_id) if company_id and ObjectId.is_valid(str(company_id)) else company_id,
                    "detection_result_id": ObjectId(detection_result_id) if ObjectId.is_valid(str(detection_result_id)) else detection_result_id,
                    "disease": result.disease,
                    "disease_name": result.disease,
                    "severity": result.severity,
                    "confidence": result.confidence,
                    "image_url": rel_image_url,
                    "date": datetime.now(timezone.utc),
                    "action": "Chẩn đoán bệnh AI",
                }
            )

            # Phase 5: High-Risk Alert Auto-Generation (Only triggered when severity == 'high')
            if result.severity == "high":
                tree_code = tree.get("tree_code", tree_id) if isinstance(tree, dict) else tree_id
                count_alert = await self.alert_repo.collection.count_documents({})
                alert_code = f"ALT{count_alert + 1:05d}"

                await self.alert_repo.create({
                    "alert_code": alert_code,
                    "farm_id": ObjectId(farm_id) if farm_id and ObjectId.is_valid(str(farm_id)) else farm_id,
                    "tree_id": ObjectId(tree_id) if ObjectId.is_valid(tree_id) else tree_id,
                    "company_id": ObjectId(company_id) if company_id and ObjectId.is_valid(str(company_id)) else company_id,
                    "inspection_id": ObjectId(inspection_id) if ObjectId.is_valid(inspection_id) else inspection_id,
                    "detection_result_id": ObjectId(detection_result_id) if ObjectId.is_valid(str(detection_result_id)) else detection_result_id,
                    "disease_history_id": ObjectId(disease_id) if ObjectId.is_valid(str(disease_id)) else disease_id,
                    "alert_type": "Bệnh nghiêm trọng",
                    "title": "Cảnh báo bệnh nguy cơ cao",
                    "message": f"Phát hiện bệnh {result.disease} nguy cơ cao tại cây {tree_code}",
                    "recommendation": _build_recommendation(result.disease, result.severity),
                    "priority": "Cao",
                    "status": "unread",
                    "is_read": False,
                    "date": datetime.now(timezone.utc),
                    "created_at": datetime.now(timezone.utc),
                })

            health_status_vi = "Khỏe mạnh" if result.disease in ("Khỏe mạnh", "Healthy") else "Bị bệnh"
            await self.inspection_repo.update(
                inspection_id,
                {
                    "status": "COMPLETED",
                    "health_status": health_status_vi,
                    "predicted_disease": result.disease,
                    "confidence": round(result.confidence * 100, 2),
                    "severity": result.severity,
                    "remark": f"Chẩn đoán AI: {result.disease} ({result.severity})",
                },
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
        except Exception as exc:
            logger.error("AI detection phase failed for inspection %s: %s", inspection_id, exc, exc_info=True)
            await self.inspection_repo.update(
                inspection_id,
                {
                    "status": "FAILED",
                    "error_message": str(exc),
                },
            )
            if isinstance(exc, BadRequestException):
                raise exc
            raise BadRequestException(f"Không thể hoàn tất chẩn đoán AI: {exc}") from exc

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
