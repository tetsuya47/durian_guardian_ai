"""Seed demo user, farm, trees, inspections, and detection results for competition demo mode.

Run: python seed_demo.py
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone, timedelta
from bson import ObjectId

from app.core.security import hash_password
from app.database.mongodb import MongoDBManager


async def seed() -> None:
    db = MongoDBManager.get_db()

    now = datetime.now(timezone.utc)

    # 1. Create or get Admin User
    user = await db["users"].find_one({"email": "bao@gmail.com"})
    if not user:
        count = await db["users"].count_documents({})
        user_code = f"USR{count + 1:04d}"
        user_id = ObjectId()
        user_doc = {
            "_id": user_id,
            "user_code": user_code,
            "full_name": "Bao Admin",
            "fullname": "Bao Admin",
            "email": "bao@gmail.com",
            "password_hash": hash_password("123456"),
            "role": "Admin",
            "created_at": now,
            "updated_at": now,
        }
        await db["users"].insert_one(user_doc)
        print(f"Created admin user bao@gmail.com with ID: {user_id}")
    else:
        user_id = user["_id"]
        await db["users"].update_one(
            {"_id": user_id},
            {"$set": {"password_hash": hash_password("123456"), "role": "Admin"}}
        )

    # 3. Create or get User teo@gmail.com
    teo = await db["users"].find_one({"email": "teo@gmail.com"})
    if not teo:
        count = await db["users"].count_documents({})
        teo_id = ObjectId()
        teo_doc = {
            "_id": teo_id,
            "user_code": f"USR{count + 1:04d}",
            "full_name": "Nguyễn Văn Tèo",
            "fullname": "Nguyễn Văn Tèo",
            "email": "teo@gmail.com",
            "password_hash": hash_password("123456"),
            "role": "Farm Owner",
            "created_at": now,
            "updated_at": now,
        }
        await db["users"].insert_one(teo_doc)
        print(f"Created user teo@gmail.com with ID: {teo_id}")
    else:
        teo_id = teo["_id"]
        await db["users"].update_one(
            {"_id": teo_id},
            {"$set": {"password_hash": hash_password("123456"), "role": "Farm Owner"}}
        )

    # 2. Check if farm exists for this user
    existing_farm = await db["farms"].find_one({"owner_id": user_id})
    if existing_farm:
        print("Demo farm data already exists. Skipping data seeding.")
        await MongoDBManager.close()
        return

    company_doc = await db["companies"].find_one({})
    company_id = company_doc["_id"] if company_doc else ObjectId()

    # 3. Create Demo Farm
    farm_id = ObjectId()
    await db["farms"].insert_one({
        "_id": farm_id,
        "farm_code": "FARM_DL01",
        "farm_name": "Nông Trại Sầu Riêng Đắk Lắk",
        "company_id": company_id,
        "owner_id": user_id,
        "created_by": user_id,
        "district": "Krông Pắc",
        "province": "Đắk Lắk",
        "area": 5.5,
        "tree_count": 10,
        "created_at": now,
        "updated_at": now,
    })
    print(f"Created demo farm: {farm_id}")

    # 4. Create Demo Zones
    zone_a_id = ObjectId()
    zone_b_id = ObjectId()
    await db["zones"].insert_many([
        {
            "_id": zone_a_id,
            "farm_id": farm_id,
            "zone_code": "ZONE_A",
            "zone_name": "Khu A - Monthong",
            "tree_count": 6,
            "created_at": now,
        },
        {
            "_id": zone_b_id,
            "farm_id": farm_id,
            "zone_code": "ZONE_B",
            "zone_name": "Khu B - Ri6",
            "tree_count": 4,
            "created_at": now,
        }
    ])

    # 5. Create 10 Demo Trees
    trees_data = [
        {"code": "SR-M01", "variety": "Monthong", "zone_id": zone_a_id, "status": "Khỏe mạnh"},
        {"code": "SR-M02", "variety": "Monthong", "zone_id": zone_a_id, "status": "Khỏe mạnh"},
        {"code": "SR-M03", "variety": "Monthong", "zone_id": zone_a_id, "status": "Khỏe mạnh"},
        {"code": "SR-M04", "variety": "Monthong", "zone_id": zone_a_id, "status": "Bị bệnh"},
        {"code": "SR-M05", "variety": "Monthong", "zone_id": zone_a_id, "status": "Bị bệnh"},
        {"code": "SR-M06", "variety": "Monthong", "zone_id": zone_a_id, "status": "Khỏe mạnh"},
        {"code": "SR-R01", "variety": "Ri6", "zone_id": zone_b_id, "status": "Khỏe mạnh"},
        {"code": "SR-R02", "variety": "Ri6", "zone_id": zone_b_id, "status": "Đang theo dõi"},
        {"code": "SR-R03", "variety": "Ri6", "zone_id": zone_b_id, "status": "Đang theo dõi"},
        {"code": "SR-R04", "variety": "Ri6", "zone_id": zone_b_id, "status": "Bị bệnh"},
    ]

    tree_ids = []
    for item in trees_data:
        t_id = ObjectId()
        tree_ids.append(t_id)
        await db["trees"].insert_one({
            "_id": t_id,
            "tree_code": item["code"],
            "farm_id": farm_id,
            "zone_id": item["zone_id"],
            "variety": item["variety"],
            "tree_age": 3,
            "status": item["status"],
            "health_status": item["status"],
            "planting_date": now - timedelta(days=365 * 3),
            "created_at": now,
        })

    # 6. Create Demo Inspections & Detections
    sample_records = [
        {"tree_code": "SR-M04", "tree_id": tree_ids[3], "disease": "Bệnh thối rễ Phytophthora", "severity": "Nặng", "conf": 0.94, "days_ago": 1},
        {"tree_code": "SR-R02", "tree_id": tree_ids[7], "disease": "Bệnh đốm lá Rhizoctonia", "severity": "Trung bình", "conf": 0.88, "days_ago": 2},
        {"tree_code": "SR-R04", "tree_id": tree_ids[9], "disease": "Bệnh thối rễ Phytophthora", "severity": "Nặng", "conf": 0.91, "days_ago": 3},
        {"tree_code": "SR-M01", "tree_id": tree_ids[0], "disease": "Không phát hiện bệnh (Khỏe mạnh)", "severity": "Nhẹ", "conf": 0.98, "days_ago": 4},
        {"tree_code": "SR-R01", "tree_id": tree_ids[6], "disease": "Không phát hiện bệnh (Khỏe mạnh)", "severity": "Nhẹ", "conf": 0.97, "days_ago": 5},
    ]

    for i, rec in enumerate(sample_records):
        rec_time = now - timedelta(days=rec["days_ago"])
        insp_id = ObjectId()
        await db["inspections"].insert_one({
            "_id": insp_id,
            "inspection_code": f"INSP-{i+1:04d}",
            "farm_id": farm_id,
            "tree_id": rec["tree_id"],
            "inspector_id": user_id,
            "created_by": user_id,
            "inspection_date": rec_time,
            "health_status": "Khỏe mạnh" if "Khỏe" in rec["disease"] else "Bị bệnh",
            "predicted_disease": rec["disease"],
            "confidence": rec["conf"],
            "status": "completed",
            "created_at": rec_time,
        })

        await db["detection_results"].insert_one({
            "_id": ObjectId(),
            "inspection_id": insp_id,
            "tree_id": rec["tree_id"],
            "disease_name": rec["disease"],
            "disease": rec["disease"],
            "confidence": rec["conf"],
            "severity": rec["severity"],
            "risk_score": 85.0 if rec["severity"] == "Nặng" else (45.0 if rec["severity"] == "Trung bình" else 10.0),
            "created_at": rec_time,
            "created_by": user_id,
        })

    print("Demo data seeded successfully with 1 Farm, 2 Zones, 10 Trees, and 5 Detection Records!")
    await MongoDBManager.close()


if __name__ == "__main__":
    asyncio.run(seed())

