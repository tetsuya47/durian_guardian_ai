"""Script to clear self-created diagnosis and disease history records from MongoDB."""
from __future__ import annotations

import asyncio
from app.database.mongodb import MongoDBManager

async def clear_history() -> None:
    db = MongoDBManager.get_db()

    res_dh = await db["disease_history"].delete_many({})
    res_d = await db["diseases"].delete_many({})
    res_dr = await db["detection_results"].delete_many({})
    res_i = await db["inspections"].delete_many({})

    print(f"Cleared history records:")
    print(f"  - disease_history: {res_dh.deleted_count} deleted")
    print(f"  - diseases: {res_d.deleted_count} deleted")
    print(f"  - detection_results: {res_dr.deleted_count} deleted")
    print(f"  - inspections: {res_i.deleted_count} deleted")

    await MongoDBManager.close()

if __name__ == "__main__":
    asyncio.run(clear_history())
