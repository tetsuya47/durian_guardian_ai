"""Clear all mock history entries so history only contains real user scans."""
from __future__ import annotations

import asyncio
from app.database.mongodb import MongoDBManager

async def clear_history() -> None:
    db = MongoDBManager.get_db()
    
    await db["disease_history"].delete_many({})
    await db["diseases"].delete_many({})
    await db["detection_results"].delete_many({})
    await db["inspections"].delete_many({})
    
    print("Successfully cleared all mock history entries!")
    await MongoDBManager.close()

if __name__ == "__main__":
    asyncio.run(clear_history())
