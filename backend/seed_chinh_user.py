"""Seed script to ensure 'chinh@gmail.com' is the ONLY user with active IoT & Farm data.
All other accounts (e.g. teo@gmail.com, bao@gmail.com, or new signups) have no IoT/farm data until activated.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from bson import ObjectId

from app.database.mongodb import MongoDBManager
from app.core.security import hash_password

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def seed_chinh_user() -> None:
    db = MongoDBManager.get_db()
    now = datetime.now(timezone.utc)

    # 1. Ensure user 'chinh@gmail.com' exists in users collection
    chinh_user = await db["users"].find_one({"email": "chinh@gmail.com"})

    if not chinh_user:
        count = await db["users"].count_documents({})
        user_code = f"USR{count + 1:04d}"
        chinh_user_doc = {
            "user_code": user_code,
            "full_name": "Nguyễn Văn Chinh",
            "email": "chinh@gmail.com",
            "phone": "0912345678",
            "password_hash": hash_password("123456"),
            "role": "Farm Owner",
            "refresh_token": "",
            "created_at": now,
            "updated_at": now,
        }
        res = await db["users"].insert_one(chinh_user_doc)
        chinh_id = res.inserted_id
        logger.info("Created user Nguyễn Văn Chinh in MongoDB: %s", chinh_id)
    else:
        chinh_id = chinh_user["_id"]
        # Ensure password is 123456
        await db["users"].update_one(
            {"_id": chinh_id},
            {
                "$set": {
                    "password_hash": hash_password("123456"),
                    "full_name": "Nguyễn Văn Chinh",
                    "role": "Farm Owner",
                }
            }
        )
        logger.info("Found and updated existing user Nguyễn Văn Chinh in MongoDB: %s", chinh_id)

    str_chinh_id = str(chinh_id)

    # 2. Attach ALL farms to chinh@gmail.com
    farms = await db["farms"].find({}).to_list(length=100)
    for farm in farms:
        await db["farms"].update_one(
            {"_id": farm["_id"]},
            {
                "$set": {
                    "owner_user_id": chinh_id,
                    "user_id": str_chinh_id,
                    "owner_id": str_chinh_id,
                    "created_by": str_chinh_id,
                    "owner_name": "Nguyễn Văn Chinh",
                }
            }
        )
    logger.info("Re-assigned %d farms to chinh@gmail.com", len(farms))

    # 3. Attach ALL iot_devices to chinh@gmail.com
    devices = await db["iot_devices"].find({}).to_list(length=100)
    for dev in devices:
        await db["iot_devices"].update_one(
            {"_id": dev["_id"]},
            {
                "$set": {
                    "user_id": str_chinh_id,
                    "owner_user_id": chinh_id,
                }
            }
        )
    logger.info("Re-assigned %d IoT devices to chinh@gmail.com", len(devices))

    # 4. Attach ALL trees to chinh@gmail.com
    trees_updated = await db["trees"].update_many(
        {},
        {"$set": {"user_id": str_chinh_id, "owner_id": str_chinh_id}}
    )
    logger.info("Re-assigned %d trees to chinh@gmail.com", trees_updated.modified_count)

    # 5. Attach farm_performance, inspections, detection_results, disease_history to chinh@gmail.com
    await db["farm_performance"].update_many({}, {"$set": {"owner_user_id": chinh_id, "user_id": str_chinh_id, "owner_name": "Nguyễn Văn Chinh"}})
    await db["detection_results"].update_many({}, {"$set": {"user_id": str_chinh_id}})
    await db["disease_history"].update_many({}, {"$set": {"user_id": str_chinh_id}})
    await db["inspections"].update_many({}, {"$set": {"user_id": str_chinh_id}})
    await db["farm_activities"].update_many({}, {"$set": {"user_id": str_chinh_id}})

    logger.info("Complete: chinh@gmail.com is now the exclusive owner of IoT & Farm data!")

if __name__ == "__main__":
    asyncio.run(seed_chinh_user())
