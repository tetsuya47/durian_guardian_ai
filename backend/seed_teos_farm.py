"""Seed script to ensure 'Nguyễn Văn Tèo' user and farm dataset exist in MongoDB as real data."""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from bson import ObjectId

from app.database.mongodb import MongoDBManager
from app.core.security import hash_password

logger = logging.getLogger(__name__)

async def seed_teos_farm() -> None:
    db = MongoDBManager.get_db()
    now = datetime.now(timezone.utc)

    # 1. Ensure user 'Nguyễn Văn Tèo' exists in users collection
    teo_user = await db["users"].find_one({
        "$or": [
            {"email": "teo@gmail.com"},
            {"full_name": "Nguyễn Văn Tèo"},
        ]
    })

    if not teo_user:
        count = await db["users"].count_documents({})
        user_code = f"USR{count + 1:04d}"
        teo_user_doc = {
            "user_code": user_code,
            "full_name": "Nguyễn Văn Tèo",
            "email": "teo@gmail.com",
            "phone": "0987654321",
            "password_hash": hash_password("123456"),
            "role": "user",
            "refresh_token": "",
            "created_at": now,
            "updated_at": now,
        }
        res = await db["users"].insert_one(teo_user_doc)
        teo_id = res.inserted_id
        logger.info("Created user Nguyễn Văn Tèo in MongoDB: %s", teo_id)
    else:
        teo_id = teo_user["_id"]
        logger.info("Found existing user Nguyễn Văn Tèo in MongoDB: %s", teo_id)

    # 2. Ensure Teo's farm exists in farms collection
    teo_farm = await db["farms"].find_one({
        "$or": [
            {"farm_code": "FRM-EAYONG-01"},
            {"owner_user_id": teo_id},
            {"owner_user_id": str(teo_id)},
            {"created_by": str(teo_id)},
        ]
    })

    boundary = [
      { "lat": 12.6860, "lng": 108.3135 },
      { "lat": 12.6868, "lng": 108.3168 },
      { "lat": 12.6835, "lng": 108.3175 },
      { "lat": 12.6828, "lng": 108.3140 },
    ]

    if not teo_farm:
        farm_doc = {
            "farm_code": "FRM-EAYONG-01",
            "farm_name": "Trang trại Sầu Riêng Sinh Thái Krông Pắc",
            "owner_name": "Nguyễn Văn Tèo",
            "owner_user_id": teo_id,
            "user_id": str(teo_id),
            "created_by": str(teo_id),
            "district": "Krông Pắc",
            "province": "Đắk Lắk",
            "location": "Xã Ea Yông, Huyện Krông Pắc, Đắk Lắk",
            "area_hectare": 3.5,
            "calculated_area_hectare": 3.5,
            "tree_count": 350,
            "boundary_points": boundary,
            "calculated_perimeter_meters": 815,
            "elevation_msl_meters": 525,
            "slope_gradient_percent": 8.2,
            "slope_aspect_heading": "Đông - Đông Nam",
            "soil_texture_type": "Đất đỏ Bazan nguyên sinh",
            "created_at": now,
            "updated_at": now,
        }
        res_farm = await db["farms"].insert_one(farm_doc)
        farm_id = res_farm.inserted_id
        logger.info("Created Nguyễn Văn Tèo's farm in MongoDB: %s", farm_id)
    else:
        farm_id = teo_farm["_id"]
        # Ensure owner link is set correctly
        await db["farms"].update_one(
            {"_id": farm_id},
            {
                "$set": {
                    "owner_user_id": teo_id,
                    "user_id": str(teo_id),
                    "owner_name": "Nguyễn Văn Tèo",
                    "boundary_points": boundary,
                    "area_hectare": 3.5,
                    "tree_count": 350,
                }
            }
        )
        logger.info("Updated Nguyễn Văn Tèo's farm link in MongoDB: %s", farm_id)

    # 3. Ensure zones exist for Teo's farm
    zone_a = await db["zones"].find_one({"farm_id": farm_id, "zone_name": "Khu A - Sầu Riêng Thái"})
    if not zone_a:
        await db["zones"].insert_one({
            "farm_id": farm_id,
            "zone_code": "Z-EAYONG-A",
            "zone_name": "Khu A - Sầu Riêng Thái",
            "area_ha": 2.0,
            "tree_count": 200,
            "created_at": now,
        })

    zone_b = await db["zones"].find_one({"farm_id": farm_id, "zone_name": "Khu B - Sầu Riêng Ri6"})
    if not zone_b:
        await db["zones"].insert_one({
            "farm_id": farm_id,
            "zone_code": "Z-EAYONG-B",
            "zone_name": "Khu B - Sầu Riêng Ri6",
            "area_ha": 1.5,
            "tree_count": 150,
            "created_at": now,
        })

    # 4. Ensure farm_performance document exists for Teo's farm
    perf = await db["farm_performance"].find_one({"farm_id": farm_id})
    if not perf:
        await db["farm_performance"].insert_one({
            "farm_id": farm_id,
            "farm_code": "FRM-EAYONG-01",
            "farm_name": "Trang trại Sầu Riêng Sinh Thái Krông Pắc",
            "owner_name": "Nguyễn Văn Tèo",
            "user_id": str(teo_id),
            "owner_user_id": teo_id,
            "province": "Đắk Lắk",
            "area_hectare": 3.5,
            "tree_count": 350,
            "yield_tons": 114.2,
            "yield_per_ha": 32.6,
            "growth_pct": 18.4,
            "revenue_vnd": 3426000000,
            "tier": "Rất cao",
            "created_at": now,
        })

    logger.info("Nguyễn Văn Tèo's farm seeding complete.")

if __name__ == "__main__":
    asyncio.run(seed_teos_farm())
