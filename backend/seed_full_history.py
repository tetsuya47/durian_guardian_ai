"""Seed comprehensive diagnosis history records for trees in MongoDB."""
from __future__ import annotations

import asyncio
import os
import shutil
from datetime import datetime, timezone, timedelta
from bson import ObjectId

from app.database.mongodb import MongoDBManager

async def seed_history() -> None:
    db = MongoDBManager.get_db()
    now = datetime.now(timezone.utc)

    # 1. Copy sample images to uploads directory
    uploads_dir = os.path.join(os.path.dirname(__file__), "uploads")
    os.makedirs(uploads_dir, exist_ok=True)

    artifacts_dir = r"C:\Users\Chinh\.gemini\antigravity-ide\brain\017f9b3b-40d1-411d-944b-0bb0de40868d"
    leaf_healthy_src = os.path.join(artifacts_dir, "durian_leaf_healthy_1785552801752.png")
    leaf_spot_src = os.path.join(artifacts_dir, "durian_leaf_spot_1785552815045.png")

    target_healthy = os.path.join(uploads_dir, "demo_leaf_healthy.png")
    target_spot = os.path.join(uploads_dir, "demo_leaf_spot.png")

    if os.path.exists(leaf_healthy_src):
        shutil.copy(leaf_healthy_src, target_healthy)
        print("Copied demo_leaf_healthy.png to uploads")

    if os.path.exists(leaf_spot_src):
        shutil.copy(leaf_spot_src, target_spot)
        print("Copied demo_leaf_spot.png to uploads")

    # 2. Get all trees in DB
    trees = await db["trees"].find().to_list(length=200)
    if not trees:
        print("No trees found in database! Run seed_many_trees.py first.")
        await MongoDBManager.close()
        return

    print(f"Found {len(trees)} trees in database.")

    # Clear old history records
    await db["disease_history"].delete_many({})
    await db["diseases"].delete_many({})
    await db["detection_results"].delete_many({})

    # 3. Create history logs for the first 30 trees + fallback tree
    fallback_oid = ObjectId("6a6cc2ba3432b70022fba65d")
    sample_tree_ids = [t["_id"] for t in trees[:30]] + [fallback_oid]

    diseases_pool = [
        {"name": "Không phát hiện bệnh hại", "severity": "Khỏe mạnh", "conf": 0.96, "img": "/uploads/demo_leaf_healthy.png", "risk": 15.0},
        {"name": "Bệnh đốm lá Rhizoctonia", "severity": "Nhẹ", "conf": 0.88, "img": "/uploads/demo_leaf_spot.png", "risk": 45.0},
        {"name": "Bệnh thối rễ Phytophthora", "severity": "Nặng", "conf": 0.94, "img": "/uploads/demo_leaf_spot.png", "risk": 90.0},
        {"name": "Bệnh xì mủ thân Phytophthora", "severity": "Trung bình", "conf": 0.91, "img": "/uploads/demo_leaf_spot.png", "risk": 75.0},
        {"name": "Sâu đục quả", "severity": "Nhẹ", "conf": 0.85, "img": "/uploads/demo_leaf_spot.png", "risk": 35.0},
    ]

    history_docs = []
    detection_docs = []

    doc_index = 0
    for tree_oid in sample_tree_ids:
        # Create 2-3 historical diagnosis entries per tree
        for delta_days in [0, 3, 7, 14]:
            disease_item = diseases_pool[doc_index % len(diseases_pool)]
            doc_time = now - timedelta(days=delta_days, hours=doc_index % 12)

            rec_id = ObjectId()
            h_doc = {
                "_id": rec_id,
                "tree_id": tree_oid,
                "disease": disease_item["name"],
                "disease_name": disease_item["name"],
                "severity": disease_item["severity"],
                "confidence": disease_item["conf"],
                "image_url": disease_item["img"],
                "risk_score": disease_item["risk"],
                "date": doc_time,
                "action": "Chẩn đoán bệnh AI",
                "created_at": doc_time,
                "updated_at": doc_time,
            }
            history_docs.append(h_doc)

            d_doc = {
                "_id": ObjectId(),
                "inspection_id": rec_id,
                "tree_id": tree_oid,
                "model": "EfficientNet-B0",
                "prediction": disease_item["name"],
                "disease": disease_item["name"],
                "disease_name": disease_item["name"],
                "severity": disease_item["severity"],
                "confidence": disease_item["conf"],
                "image_url": disease_item["img"],
                "created_at": doc_time,
            }
            detection_docs.append(d_doc)

            doc_index += 1

    await db["disease_history"].insert_many(history_docs)
    await db["detection_results"].insert_many(detection_docs)

    print(f"Successfully seeded {len(history_docs)} diagnosis history records for trees!")
    await MongoDBManager.close()

if __name__ == "__main__":
    asyncio.run(seed_history())
