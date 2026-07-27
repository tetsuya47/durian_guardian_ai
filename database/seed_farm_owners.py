#!/usr/bin/env python3
"""
Farm Owner Seed Script
======================

Durian Guardian AI - Seed Farm Owner accounts.

Creates Farm Owner user accounts and links them to farms.
Each farm gets exactly one Farm Owner.
This script is idempotent and safe to run multiple times.

Usage:
    python -m database.seed_farm_owners
"""

import logging
import sys
from datetime import datetime, timezone
from typing import List, Dict, Any

from bson import ObjectId
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

from database.config import settings

logger = logging.getLogger("durian_guardian.seed_farm_owners")


def hash_password(password: str) -> str:
    """Hash password using bcrypt via passlib."""
    from passlib.context import CryptContext
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    return pwd_context.hash(password)


FARM_OWNER_DATA = [
    {
        "full_name": "Nguyễn Văn An",
        "email": "nguyen.van.an@durianguardian.ai",
        "phone": "0901234001",
        "password": "123456",
    },
    {
        "full_name": "Trần Thị Bình",
        "email": "tran.thi.binh@durianguardian.ai",
        "phone": "0901234002",
        "password": "123456",
    },
    {
        "full_name": "Lê Hoàng Cường",
        "email": "le.hoang.cuong@durianguardian.ai",
        "phone": "0901234003",
        "password": "123456",
    },
    {
        "full_name": "Phạm Minh Đức",
        "email": "pham.minh.duc@durianguardian.ai",
        "phone": "0901234004",
        "password": "123456",
    },
    {
        "full_name": "Hoàng Thị Em",
        "email": "hoang.thi.em@durianguardian.ai",
        "phone": "0901234005",
        "password": "123456",
    },
    {
        "full_name": "Vũ Đức Phong",
        "email": "vu.duc.phong@durianguardian.ai",
        "phone": "0901234006",
        "password": "123456",
    },
    {
        "full_name": "Đặng Thị Giang",
        "email": "dang.thi.giang@durianguardian.ai",
        "phone": "0901234007",
        "password": "123456",
    },
    {
        "full_name": "Bùi Văn Hùng",
        "email": "bui.van.hung@durianguardian.ai",
        "phone": "0901234008",
        "password": "123456",
    },
    {
        "full_name": "Ngô Thị Khánh",
        "email": "ngo.thi.khanh@durianguardian.ai",
        "phone": "0901234009",
        "password": "123456",
    },
    {
        "full_name": "Đỗ Văn Long",
        "email": "do.van.long@durianguardian.ai",
        "phone": "0901234010",
        "password": "123456",
    },
]


def seed_farm_owners(db) -> Dict[str, int]:
    """
    Create Farm Owner users and link them to farms.

    Returns dict with counts: created, linked, skipped.
    """
    now = datetime.now(timezone.utc)
    created = 0
    linked = 0
    skipped = 0

    existing_fo_count = db.users.count_documents({"role": "Farm Owner"})
    if existing_fo_count >= len(FARM_OWNER_DATA):
        logger.info("Farm Owner users already exist (%d), skipping creation",
                     existing_fo_count)
        fo_users = list(db.users.find({"role": "Farm Owner"}))
    else:
        # Get next user_code number from existing codes
        import re
        max_num = 0
        for u in db.users.find({}, {"user_code": 1}):
            code = u.get("user_code", "")
            m = re.match(r"USR(\d+)", code)
            if m:
                max_num = max(max_num, int(m.group(1)))
        fo_users = []
        for i, fo_data in enumerate(FARM_OWNER_DATA):
            # Check if email already exists
            existing = db.users.find_one({"email": fo_data["email"]})
            if existing:
                logger.info("Farm Owner already exists: %s", fo_data["email"])
                fo_users.append(existing)
                continue

            user_code = f"USR{max_num + i + 1:04d}"
            user_doc = {
                "_id": ObjectId(),
                "user_code": user_code,
                "full_name": fo_data["full_name"],
                "email": fo_data["email"],
                "phone": fo_data["phone"],
                "password_hash": hash_password(fo_data["password"]),
                "role": "Farm Owner",
                "refresh_token": "",
                "created_at": now,
                "updated_at": now,
            }
            result = db.users.insert_one(user_doc)
            user_doc["_id"] = result.inserted_id
            fo_users.append(user_doc)
            created += 1
            logger.info("Created Farm Owner: %s (%s)", fo_data["full_name"], user_code)

    # Link farms to Farm Owners
    farms = list(db.farms.find({}).sort("farm_code", 1))
    for i, farm in enumerate(farms):
        fo_user = fo_users[i % len(fo_users)]
        db.farms.update_one(
            {"_id": farm["_id"]},
            {
                "$set": {
                    "owner_user_id": fo_user["_id"],
                    "owner": fo_user["full_name"],
                }
            },
        )
        linked += 1
        logger.info("Linked farm %s → owner %s",
                     farm.get("farm_code"), fo_user["full_name"])

    return {"created": created, "linked": linked, "skipped": skipped}


def main() -> None:
    """Main entry point for standalone execution."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    logger.info("=" * 60)
    logger.info("  DURIAN GUARDIAN AI - Farm Owner Seed")
    logger.info("=" * 60)

    try:
        client = MongoClient(
            settings.mongodb_uri_with_credentials,
            **settings.connection_kwargs,
        )
        client.admin.command("ping")
        db = client[settings.DATABASE_NAME]
        logger.info("Connected to MongoDB: %s", settings.DATABASE_NAME)
    except (ConnectionFailure, ServerSelectionTimeoutError) as exc:
        logger.critical("Cannot connect to MongoDB: %s", exc)
        sys.exit(1)

    try:
        result = seed_farm_owners(db)
        logger.info("")
        logger.info("Farm Owner seed completed:")
        logger.info("  Users created : %d", result["created"])
        logger.info("  Farms linked  : %d", result["linked"])
    except Exception as exc:
        logger.error("Farm Owner seed failed: %s", exc)
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        client.close()
        logger.info("MongoDB connection closed.")


if __name__ == "__main__":
    main()
