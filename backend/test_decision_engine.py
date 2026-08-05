"""Test script for Model 4 AI Decision Engine (AI Agronomist).

Run: python test_decision_engine.py
"""

from __future__ import annotations
import asyncio
import json
import sys

sys.stdout.reconfigure(encoding="utf-8")
from app.database.mongodb import MongoDBManager
from app.ai.decision_engine.service import AIDecisionEngineService


async def test_decision_engine() -> None:
    db = MongoDBManager.get_db()
    service = AIDecisionEngineService(db)

    print("\n--- TEST SCENARIO 1: Disease = Anthracnose, Rain Tomorrow = True, Sprayed 5 days ago ---")
    tree_id = "6a6cc2ba3432b70022fba65d"
    weather_rainy = {"rain_tomorrow": True, "rain_today": False, "humidity": 88.0}

    rec_dict, agronomist_text = await service.run_decision_engine(
        tree_id=tree_id,
        disease_name="Anthracnose",
        confidence=0.92,
        severity="Medium",
        risk_score=82.0,
        risk_level="High",
        weather_info=weather_rainy,
    )

    print("\n[STRUCTURED OUTPUT]:")
    print(json.dumps(rec_dict, indent=2, ensure_ascii=False))

    print("\n[AI AGRONOMIST TEXT]:")
    print(agronomist_text)

    print("\n--- TEST SCENARIO 2: Disease = Healthy ---")
    rec_healthy, agronomist_healthy = await service.run_decision_engine(
        tree_id=tree_id,
        disease_name="Healthy",
        confidence=0.98,
        severity="Low",
        risk_score=10.0,
        risk_level="Low",
    )

    print("\n[HEALTHY OUTPUT]:")
    print(agronomist_healthy)


if __name__ == "__main__":
    asyncio.run(test_decision_engine())
