"""Verify Model 4 prediction on 20 real MongoDB records."""

import sys; from pathlib import Path; sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
import json
import random
import numpy as np
import pandas as pd
from pymongo import MongoClient
from datetime import datetime

from training.utils.logger import Logger
from database.config import settings
from training_recommendation.predict import load_artifacts, predict

SEASON_MAP = {1: "Khô", 2: "Khô", 3: "Khô", 4: "Khô",
              5: "Mưa", 6: "Mưa", 7: "Mưa", 8: "Mưa",
              9: "Mưa", 10: "Mưa", 11: "Mưa", 12: "Khô"}

logger = Logger.get_logger("Model4Verify")

model, regressors, preprocessor, metadata = load_artifacts()
logger.info("Model 4 artifacts loaded")

client = MongoClient(settings.mongodb_uri_with_credentials, **settings.connection_kwargs)
db = client[settings.DATABASE_NAME]
logger.info("Connected to MongoDB: %s", settings.DATABASE_NAME)

inspections = list(db.inspections.aggregate([{"$sample": {"size": 20}}]))
logger.info("Sampled %d inspections", len(inspections))

tree_ids = [str(i["tree_id"]) for i in inspections if "tree_id" in i]
farm_ids = [str(i["farm_id"]) for i in inspections if "farm_id" in i]

tree_lookup = {}
for doc in db.trees.find({}, {"_id": 1, "tree_code": 1, "tree_age": 1, "farm_id": 1, "variety": 1}):
    tree_lookup[str(doc["_id"])] = doc

farm_lookup = {}
for doc in db.farms.find({}, {"_id": 1, "area_hectare": 1, "tree_count": 1}):
    farm_lookup[str(doc["_id"])] = doc

insp_codes = [i["inspection_code"] for i in inspections]
detection_map = {}
for doc in db.detection_results.find({"inspection_id": {"$in": [i["_id"] for i in inspections]}},
                                      {"inspection_id": 1, "prediction": 1, "confidence": 1}):
    detection_map[str(doc["inspection_id"])] = doc

disease_history_map = {}
for doc in db.disease_history.find({"tree_id": {"$in": [i["tree_id"] for i in inspections if "tree_id" in i]}},
                                    {"tree_id": 1, "disease": 1, "date": 1}):
    tid = str(doc["tree_id"])
    if tid not in disease_history_map:
        disease_history_map[tid] = []
    disease_history_map[tid].append(doc)

alert_map = {}
for doc in db.alerts.find({"tree_id": {"$in": [i["tree_id"] for i in inspections if "tree_id" in i]}},
                           {"tree_id": 1, "alert_type": 1, "priority": 1, "date": 1}):
    tid = str(doc["tree_id"])
    if tid not in alert_map:
        alert_map[tid] = []
    alert_map[tid].append(doc)

PRIORITY_MAP = {0: "Thấp", 1: "Trung bình", 2: "Cao", 3: "Rất cao"}
ACTION_MAP = {
    0: "Tiếp tục theo dõi định kỳ",
    1: "Theo dõi và kiểm tra lại sau 14 ngày",
    2: "Lên lịch điều trị trong 7 ngày",
    3: "Cần điều trị ngay - Cần can thiệp khẩn cấp",
}

results = []
errors = 0
for i, insp in enumerate(inspections):
    try:
        tree_id = str(insp.get("tree_id", ""))
        farm_id = str(insp.get("farm_id", ""))
        insp_id = str(insp.get("_id", ""))

        tree = tree_lookup.get(tree_id, {})
        farm = farm_lookup.get(farm_id, {})
        detection = detection_map.get(insp_id, {})

        hist_records = disease_history_map.get(tree_id, [])
        alert_records = alert_map.get(tree_id, [])

        inspection_date = insp.get("inspection_date", datetime.now())
        if isinstance(inspection_date, str):
            inspection_date = datetime.fromisoformat(inspection_date)

        hist_count = len(hist_records)
        hist_oldest = None
        if hist_records:
            dates = [r["date"] for r in hist_records if "date" in r]
            if dates:
                hist_oldest = max(dates)

        last_treatment_days = None
        if hist_oldest is not None:
            if isinstance(hist_oldest, datetime):
                last_treatment_days = (inspection_date - hist_oldest).days
            else:
                last_treatment_days = (inspection_date - datetime.fromisoformat(str(hist_oldest))).days

        alert_count = len(alert_records)
        alert_type = "None"
        alert_priority = "None"
        if alert_records:
            atypes = [r.get("alert_type", "None") for r in alert_records]
            alert_type = max(set(atypes), key=atypes.count)
            aprios = [r.get("priority", "None") for r in alert_records]
            alert_priority = max(set(aprios), key=aprios.count)

        features = {
            "temperature": float(insp.get("temperature", 0)),
            "humidity": float(insp.get("humidity", 0)),
            "rainfall": float(insp.get("rainfall", 0)),
            "tree_age": int(tree.get("tree_age", 0)),
            "area_hectare": float(farm.get("area_hectare", 0)),
            "confidence": float(insp.get("confidence", 0)),
            "detection_confidence": float(detection.get("confidence", 0) if detection else 0),
            "disease_history_count": hist_count,
            "last_treatment_days": last_treatment_days if last_treatment_days is not None else 999,
            "alert_count": alert_count,
            "days_since_last_inspection": 60,
            "historical_disease_count": hist_count,
            "historical_disease_frequency": hist_count / max(tree.get("tree_age", 1), 1),
            "density_per_hectare": float(farm.get("tree_count", 0)) / max(float(farm.get("area_hectare", 1)), 0.1),
            "priority_score": 0.0,
            "health_status": str(insp.get("health_status", "Khỏe mạnh")),
            "predicted_disease": str(insp.get("predicted_disease", "Khỏe mạnh")),
            "detection_prediction": str(detection.get("prediction", "Khỏe mạnh") if detection else "Khỏe mạnh"),
            "alert_type": alert_type,
            "alert_priority": alert_priority,
            "season": SEASON_MAP.get(inspection_date.month, "Khô"),
            "risk_level": "Thấp",
        }

        result = predict(features, model, regressors, preprocessor)

        assert result["priority"] in PRIORITY_MAP.values(), f"Invalid priority: {result['priority']}"
        assert 0 <= result["priority_code"] <= 3, f"Invalid priority_code: {result['priority_code']}"
        assert result["recommended_action"] in ACTION_MAP.values(), f"Invalid action: {result['recommended_action']}"
        assert 0.0 <= result["urgency_score"] <= 1.0, f"Invalid urgency: {result['urgency_score']}"
        assert 0.0 <= result["estimated_loss_pct"] <= 100.0, f"Invalid loss: {result['estimated_loss_pct']}"
        assert 1 <= result["next_check_days"] <= 30, f"Invalid check days: {result['next_check_days']}"

        result["inspection_code"] = insp.get("inspection_code", f"UNKNOWN_{i}")
        result["tree_code"] = tree.get("tree_code", "UNKNOWN")
        result["health_status"] = features["health_status"]
        result["predicted_disease"] = features["predicted_disease"]
        results.append(result)

        logger.info("[%d/%d] %s | %s → %s (urg=%.3f, loss=%.1f%%, check=%dd)",
                    i + 1, len(inspections),
                    result["inspection_code"], result["health_status"],
                    result["priority"], result["urgency_score"],
                    result["estimated_loss_pct"], result["next_check_days"])

    except Exception as e:
        errors += 1
        logger.error("Error processing inspection %s: %s", insp.get("inspection_code", "?"), e)

client.close()

print("\n" + "=" * 60)
print(f"  VERIFICATION COMPLETE")
print(f"  Total: {len(inspections)}, Success: {len(results)}, Errors: {errors}")
print("=" * 60)
print(f"\n{'Code':<12} {'Status':<12} {'Priority':<10} {'Urgency':<8} {'Loss':<8} {'Check':<6}")
print("-" * 60)
for r in results:
    print(f"{r['inspection_code']:<12} {r['health_status']:<12} {r['priority']:<10} "
          f"{r['urgency_score']:<8.3f} {r['estimated_loss_pct']:<8.1f} {r['next_check_days']:<6}")

print("\nPriority distribution:")
priority_counts = {}
for r in results:
    priority_counts[r["priority"]] = priority_counts.get(r["priority"], 0) + 1
for p, c in sorted(priority_counts.items()):
    print(f"  {p}: {c}")

logger.info("Verification %s", "PASSED" if errors == 0 else f"FAILED with {errors} errors")
