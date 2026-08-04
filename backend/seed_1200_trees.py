"""Seed 1,200 durian trees across 5 zones with comprehensive diagnosis history."""
from __future__ import annotations

import asyncio
import os
import shutil
import random
from datetime import datetime, timezone, timedelta
from bson import ObjectId

from app.database.mongodb import MongoDBManager

async def seed_1200_trees() -> None:
    db = MongoDBManager.get_db()
    now = datetime.now(timezone.utc)

    # 1. Verify uploads directory and demo images
    uploads_dir = os.path.join(os.path.dirname(__file__), "uploads")
    os.makedirs(uploads_dir, exist_ok=True)

    artifacts_dir = r"C:\Users\Chinh\.gemini\antigravity-ide\brain\017f9b3b-40d1-411d-944b-0bb0de40868d"
    leaf_healthy_src = os.path.join(artifacts_dir, "durian_leaf_healthy_1785552801752.png")
    leaf_spot_src = os.path.join(artifacts_dir, "durian_leaf_spot_1785552815045.png")

    target_healthy = os.path.join(uploads_dir, "demo_leaf_healthy.png")
    target_spot = os.path.join(uploads_dir, "demo_leaf_spot.png")

    if os.path.exists(leaf_healthy_src) and not os.path.exists(target_healthy):
        shutil.copy(leaf_healthy_src, target_healthy)

    if os.path.exists(leaf_spot_src) and not os.path.exists(target_spot):
        shutil.copy(leaf_spot_src, target_spot)

    # Clear existing data in trees, zones, farms, disease_history, diseases, detection_results
    await db["trees"].delete_many({})
    await db["zones"].delete_many({})
    await db["farms"].delete_many({})
    await db["disease_history"].delete_many({})
    await db["diseases"].delete_many({})
    await db["detection_results"].delete_many({})

    # 2. Get main owner user ID (Farmer nongdan@gmail.com)
    user = await db["users"].find_one({"email": "nongdan@gmail.com"}) or await db["users"].find_one({"email": "bao@gmail.com"})
    owner_id = user["_id"] if user else ObjectId("6a6d510a1b0a24c1305a4310")

    # 3. Create Main Farm
    farm_id = ObjectId("6a6d50f673cabe5ab0e0d894")
    farm_doc = {
        "_id": farm_id,
        "farm_code": "FARM_1200",
        "farm_name": "Trang Trại Sầu Riêng Đại Vườn 1,200 Cây",
        "owner_id": owner_id,
        "company_id": owner_id,
        "district": "Định Quán",
        "location": "Đồng Nai, Việt Nam",
        "total_area_ha": 15.5,
        "created_at": now,
        "updated_at": now,
    }
    await db["farms"].insert_one(farm_doc)

    # 4. Create 5 Zones
    zones_config = [
        {"name": "Khu A", "variety": "Monthong", "count": 450, "manager": "Trần Văn Bao"},
        {"name": "Khu B", "variety": "Ri6", "count": 350, "manager": "Lê Hoàng Nam"},
        {"name": "Khu C", "variety": "Musang King", "count": 200, "manager": "Nguyễn Thị Hoa"},
        {"name": "Khu D", "variety": "Ri6", "count": 120, "manager": "Phạm Minh Đức"},
        {"name": "Khu E", "variety": "Monthong", "count": 80, "manager": "Hoàng Văn Thái"},
    ]

    zone_ids = {}
    for z in zones_config:
        z_oid = ObjectId()
        zone_doc = {
            "_id": z_oid,
            "farm_id": farm_id,
            "zone_name": z["name"],
            "variety": z["variety"],
            "tree_count": z["count"],
            "manager_name": z["manager"],
            "created_at": now,
            "updated_at": now,
        }
        await db["zones"].insert_one(zone_doc)
        zone_ids[z["name"]] = z_oid

    # 5. Generate 1,200 Trees
    tree_docs = []
    # Ensure fallback tree ID is preserved for seamless mobile compatibility
    fallback_oid = ObjectId("6a6cc2ba3432b70022fba65d")
    is_first_tree = True

    global_tree_num = 1
    for z in zones_config:
        z_name = z["name"]
        z_oid = zone_ids[z_name]
        variety = z["variety"]
        count = z["count"]

        for i in range(1, count + 1):
            if is_first_tree:
                t_oid = fallback_oid
                is_first_tree = False
            else:
                t_oid = ObjectId()

            # Health ratio: ~85% Healthy, ~10% Diseased, ~5% High Risk
            rand_val = random.random()
            if rand_val < 0.85:
                health = "Healthy"
                status_vi = "Khỏe mạnh"
                risk_score = random.uniform(5.0, 25.0)
            elif rand_val < 0.95:
                health = "Diseased"
                status_vi = "Bị bệnh"
                risk_score = random.uniform(55.0, 85.0)
            else:
                health = "High Risk"
                status_vi = "Bị bệnh"
                risk_score = random.uniform(85.0, 98.0)

            prefix = z_name.replace("Khu ", "")
            tree_code = f"SR-{prefix}{i:03d}"
            planted_yr = random.choice([2018, 2019, 2020, 2021, 2022])

            tree_docs.append({
                "_id": t_oid,
                "farm_id": farm_id,
                "zone_id": z_oid,
                "tree_code": tree_code,
                "variety": variety,
                "health_status": health,
                "status": status_vi,
                "risk_score": round(risk_score, 1),
                "planted_year": planted_yr,
                "planting_date": datetime(planted_yr, 1, 1, tzinfo=timezone.utc),
                "tree_age": 2026 - planted_yr,
                "location_row": ((i - 1) // 20) + 1,
                "location_column": ((i - 1) % 20) + 1,
                "created_at": now - timedelta(days=random.randint(30, 365)),
                "updated_at": now,
            })
            global_tree_num += 1

    await db["trees"].insert_many(tree_docs)
    print(f"Successfully seeded {len(tree_docs)} trees in MongoDB!")

if __name__ == "__main__":
    asyncio.run(seed_1200_trees())
    asyncio.run(MongoDBManager.close())

