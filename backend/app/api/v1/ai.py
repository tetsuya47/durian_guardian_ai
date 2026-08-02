from __future__ import annotations

import io
import logging
import os

from fastapi import APIRouter, Depends, File, Form, UploadFile
from motor.motor_asyncio import AsyncIOMotorDatabase
from PIL import Image

from app.ai.service import AIService
from app.core.dependencies import RoleChecker, get_current_user_id
from app.core.exceptions import BadRequestException
from app.core.response import success_response
from app.database.mongodb import get_database
from app.models import UserRole
from app.schemas.disease import DetectionResponse
from app.schemas.response_models import SuccessResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai", tags=["AI Detection"])

allow_all = RoleChecker([r.value for r in UserRole])

_ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".heic", ".heif"}


def _validate_image(contents: bytes, filename: str) -> None:
    """Input validation: reject empty, non-image, and corrupted uploads."""
    if not contents:
        raise BadRequestException("Tệp rỗng: Không có dữ liệu được tải lên")
    ext = os.path.splitext(filename or "")[1].lower()
    if ext and ext not in _ALLOWED_IMAGE_EXTENSIONS:
        try:
            with Image.open(io.BytesIO(contents)) as img:
                img.verify()
            return
        except Exception:
            raise BadRequestException(
                f"Định dạng tệp '{ext}' không hỗ trợ. "
                f"Các định dạng cho phép: {sorted(_ALLOWED_IMAGE_EXTENSIONS)}"
            )
    try:
        with Image.open(io.BytesIO(contents)) as img:
            img.verify()
    except Exception as exc:
        import cv2
        import numpy as np
        try:
            nparr = np.frombuffer(contents, np.uint8)
            decoded = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if decoded is None:
                raise BadRequestException("Tệp ảnh không hợp lệ hoặc bị hỏng") from exc
        except Exception:
            raise BadRequestException("Tệp ảnh không hợp lệ hoặc bị hỏng") from exc


@router.post("/detect", response_model=SuccessResponse[DetectionResponse])
async def detect_disease(
    tree_id: str = Form(...),
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    if not file.filename:
        raise BadRequestException("No file provided")
    contents = await file.read()
    _validate_image(contents, file.filename)
    service = AIService(db)
    result = await service.detect_disease(tree_id, contents, file.filename)
    logger.info("Detection completed for tree %s by user %s", tree_id, user_id)
    return success_response(
        data=result.model_dump(),
        message="Detection completed",
    )


@router.post("/image-quality", response_model=SuccessResponse[dict])
async def check_image_quality(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _=Depends(allow_all),
):
    if not file.filename:
        raise BadRequestException("No file provided")
    contents = await file.read()
    service = AIService(db)
    result = await service.check_image_quality(contents, file.filename)
    logger.info("Image quality check by user %s: %s", user_id, result)
    return success_response(
        data=result,
        message="Image quality checked",
    )
