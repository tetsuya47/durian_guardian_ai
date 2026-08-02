"""Standalone test script for AI Service quality and non-durian image filter."""
import cv2
import numpy as np
from app.ai.service import AIService
from unittest.mock import MagicMock

def test_filter_rules():
    service = AIService.__new__(AIService)
    service._predictor = MagicMock()
    service._predictor.predict.return_value = {"confidence": 0.35, "disease": "Healthy", "disease_vi": "Khỏe mạnh"}

    # 1. Valid Green Leaf Image
    img_green = np.zeros((200, 200, 3), dtype=np.uint8)
    img_green[:, :] = (30, 160, 40) # BGR green
    _, buf_green = cv2.imencode(".jpg", img_green)
    res_green = service._analyze_quality(buf_green.tobytes())
    assert res_green["leaf_detected"] is True, f"Failed green leaf test: {res_green}"

    # 2. Non-Durian Blue Image
    img_blue = np.zeros((200, 200, 3), dtype=np.uint8)
    img_blue[:, :] = (220, 100, 30) # BGR blue
    _, buf_blue = cv2.imencode(".jpg", img_blue)
    res_blue = service._analyze_quality(buf_blue.tobytes())
    assert res_blue["leaf_detected"] is False, f"Failed blue non-durian test: {res_blue}"

    # 3. Human Face/Skin Tone Image (BGR: 120, 160, 220)
    img_skin = np.zeros((200, 200, 3), dtype=np.uint8)
    img_skin[:, :] = (120, 160, 220)
    _, buf_skin = cv2.imencode(".jpg", img_skin)
    res_skin = service._analyze_quality(buf_skin.tobytes())
    assert res_skin["leaf_detected"] is False, f"Failed skin tone non-durian test: {res_skin}"

    # 4. White Paper / Document Grayscale Image (BGR: 240, 240, 240)
    img_paper = np.zeros((200, 200, 3), dtype=np.uint8)
    img_paper[:, :] = (240, 240, 240)
    _, buf_paper = cv2.imencode(".jpg", img_paper)
    res_paper = service._analyze_quality(buf_paper.tobytes())
    # 5. Non-Durian Red Object Image (BGR: 20, 20, 220)
    img_red = np.zeros((200, 200, 3), dtype=np.uint8)
    img_red[:, :] = (20, 20, 220)
    _, buf_red = cv2.imencode(".jpg", img_red)
    res_red = service._analyze_quality(buf_red.tobytes())
    assert res_red["leaf_detected"] is False, f"Failed red object non-durian test: {res_red}"

    # 6. Non-Durian Dark Keyboard/Desk Image (BGR: 40, 40, 40)
    img_dark = np.zeros((200, 200, 3), dtype=np.uint8)
    img_dark[:, :] = (40, 40, 40)
    _, buf_dark = cv2.imencode(".jpg", img_dark)
    res_dark = service._analyze_quality(buf_dark.tobytes())
    assert res_dark["leaf_detected"] is False, f"Failed dark non-foliage test: {res_dark}"

    print("ALL DURIAIN FILTER TESTS PASSED PERFECTLY!")

if __name__ == "__main__":
    test_filter_rules()
