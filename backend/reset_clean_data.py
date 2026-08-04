"""Reset script to clear 1,200 mock trees and mock diagnosis history from MongoDB.

Usage: python reset_clean_data.py
"""
from __future__ import annotations

import asyncio
from app.database.mongodb import MongoDBManager

async def reset_clean() -> None:
    db = MongoDBManager.get_db()

    # Clear 1200 trees, mock history, mock detections, mock inspections
    res_trees = await db["trees"].delete_many({})
    res_dh = await db["disease_history"].delete_many({})
    res_d = await db["diseases"].delete_many({})
    res_dr = await db["detection_results"].delete_many({})
    res_i = await db["inspections"].delete_many({})
    res_zones = await db["zones"].delete_many({})
    res_farms = await db["farms"].delete_many({})

    print("Cleared mock data:")
    print(f"  - trees: {res_trees.deleted_count} deleted")
    print(f"  - disease_history: {res_dh.deleted_count} deleted")
    print(f"  - diseases: {res_d.deleted_count} deleted")
    print(f"  - detection_results: {res_dr.deleted_count} deleted")
    print(f"  - inspections: {res_i.deleted_count} deleted")
    print(f"  - zones: {res_zones.deleted_count} deleted")
    print(f"  - farms: {res_farms.deleted_count} deleted")

    await MongoDBManager.close()

if __name__ == "__main__":
    asyncio.run(reset_clean())
