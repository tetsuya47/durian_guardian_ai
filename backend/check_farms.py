import asyncio
import json
from app.database.mongodb import MongoDBManager

def clean_doc(d):
    res = {}
    for k, v in d.items():
        res[k] = str(v)
    return res

async def main():
    db = MongoDBManager.get_db()
    
    print("=== FARM ACTIVITIES ===")
    activities = await db["farm_activities"].find({}).to_list(10)
    print(f"Total farm_activities: {len(activities)}")
    for a in activities:
        print(clean_doc(a))

    print("\n=== FARM LOGS ===")
    logs = await db["farm_logs"].find({}).to_list(10)
    print(f"Total farm_logs: {len(logs)}")
    for l in logs:
        print(clean_doc(l))

    print("\n=== IOT ORDERS ===")
    if "iot_orders" in await db.list_collection_names():
        orders = await db["iot_orders"].find({}).to_list(10)
        print(f"Total iot_orders: {len(orders)}")
        for o in orders:
            print(clean_doc(o))
    else:
        print("No iot_orders collection")

if __name__ == "__main__":
    asyncio.run(main())
