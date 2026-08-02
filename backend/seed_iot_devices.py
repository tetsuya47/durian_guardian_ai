from __future__ import annotations

import asyncio
from datetime import datetime, timezone, timedelta
import random
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings


async def seed_iot() -> None:
    client = AsyncIOMotorClient(settings.MONGODB_URL)
    
    # Target databases (seed both durian_guardian_ai_1 and durian_guardian_ai)
    db_names = [settings.MONGODB_DB_NAME, "durian_guardian_ai"]
    for db_name in set(db_names):
        db = client[db_name]

        # 1. Fetch existing farms
        farms = await db["farms"].find({}).to_list(length=100)
        if not farms:
            print(f"[{db_name}] No farms found to link active IoT devices.")
            continue

        print(f"[{db_name}] Found {len(farms)} farms. Clearing old iot_devices collection...")
        await db["iot_devices"].drop()

        now = datetime.now(timezone.utc)
        iot_docs = []
        farm_iot_counters = {str(f["_id"]): {"total_devices": 0, "soil_sensors": 0, "weather_stations": 0, "gateway_hubs": 0, "smart_valves": 0} for f in farms}

        device_counter = 1

        # 2. Seed Active Devices for Each Farm (Target: 142 total active devices across farms)
        for farm in farms:
            farm_id_str = str(farm["_id"])
            farm_name = farm.get("farm_name", "Trang trại")
            area = farm.get("area_hectare", 5.0)

            # Determine device counts per farm based on area
            soil_count = max(4, int(area / 0.5))
            weather_count = max(1, int(area / 5.0))
            gateway_count = 2
            valve_count = 2

            # Soil Sensors
            for _ in range(soil_count):
                iot_docs.append({
                    "device_code": f"IOT-SOIL-{device_counter:04d}",
                    "device_name": "Cảm biến độ ẩm & NPK đất DurianSense Pro",
                    "device_type": "soil_sensor",
                    "unit_price": 1200000.0,
                    "farm_id": farm_id_str,
                    "farm_name": farm_name,
                    "status": "Active",
                    "battery_level": random.randint(80, 100),
                    "last_signal": now - timedelta(minutes=random.randint(1, 60)),
                    "created_at": now - timedelta(days=random.randint(10, 90)),
                    "updated_at": now,
                })
                device_counter += 1
                farm_iot_counters[farm_id_str]["soil_sensors"] += 1
                farm_iot_counters[farm_id_str]["total_devices"] += 1

            # Weather Stations
            for _ in range(weather_count):
                iot_docs.append({
                    "device_code": f"IOT-WTH-{device_counter:04d}",
                    "device_name": "Trạm thời tiết vi khí hậu DGA-Weather 5G",
                    "device_type": "weather_station",
                    "unit_price": 8500000.0,
                    "farm_id": farm_id_str,
                    "farm_name": farm_name,
                    "status": "Active",
                    "battery_level": random.randint(90, 100),
                    "last_signal": now - timedelta(minutes=random.randint(1, 30)),
                    "created_at": now - timedelta(days=random.randint(10, 90)),
                    "updated_at": now,
                })
                device_counter += 1
                farm_iot_counters[farm_id_str]["weather_stations"] += 1
                farm_iot_counters[farm_id_str]["total_devices"] += 1

            # Gateway Hubs
            for _ in range(gateway_count):
                iot_docs.append({
                    "device_code": f"IOT-GW-{device_counter:04d}",
                    "device_name": "Bộ trung tâm IoT Gateway Hub Edge AI",
                    "device_type": "gateway_hub",
                    "unit_price": 3500000.0,
                    "farm_id": farm_id_str,
                    "farm_name": farm_name,
                    "status": "Active",
                    "battery_level": 100,
                    "last_signal": now - timedelta(minutes=random.randint(1, 15)),
                    "created_at": now - timedelta(days=random.randint(10, 90)),
                    "updated_at": now,
                })
                device_counter += 1
                farm_iot_counters[farm_id_str]["gateway_hubs"] += 1
                farm_iot_counters[farm_id_str]["total_devices"] += 1

            # Smart Valves
            for _ in range(valve_count):
                iot_docs.append({
                    "device_code": f"IOT-VALVE-{device_counter:04d}",
                    "device_name": "Van tưới tự động thông minh DGA SmartValve",
                    "device_type": "smart_valve",
                    "unit_price": 1800000.0,
                    "farm_id": farm_id_str,
                    "farm_name": farm_name,
                    "status": "Active",
                    "battery_level": random.randint(85, 100),
                    "last_signal": now - timedelta(minutes=random.randint(1, 45)),
                    "created_at": now - timedelta(days=random.randint(10, 90)),
                    "updated_at": now,
                })
                device_counter += 1
                farm_iot_counters[farm_id_str]["smart_valves"] += 1
                farm_iot_counters[farm_id_str]["total_devices"] += 1

        active_count = len(iot_docs)

        # 3. Seed In-Stock Devices in Warehouse (Target: 58 in-stock devices, making total 200)
        target_in_stock = 58
        for _ in range(target_in_stock):
            dtype = random.choice(["soil_sensor", "weather_station", "gateway_hub", "smart_valve"])
            dnames = {
                "soil_sensor": ("Cảm biến độ ẩm & NPK đất DurianSense Pro", 1200000.0),
                "weather_station": ("Trạm thời tiết vi khí hậu DGA-Weather 5G", 8500000.0),
                "gateway_hub": ("Bộ trung tâm IoT Gateway Hub Edge AI", 3500000.0),
                "smart_valve": ("Van tưới tự động thông minh DGA SmartValve", 1800000.0),
            }
            dname, price = dnames[dtype]
            prefix = {"soil_sensor": "SOIL", "weather_station": "WTH", "gateway_hub": "GW", "smart_valve": "VALVE"}[dtype]

            iot_docs.append({
                "device_code": f"IOT-{prefix}-{device_counter:04d}",
                "device_name": dname,
                "device_type": dtype,
                "unit_price": price,
                "farm_id": None,
                "farm_name": None,
                "status": "In_Stock",
                "battery_level": 100,
                "last_signal": None,
                "created_at": now,
                "updated_at": now,
            })
            device_counter += 1

        # Insert all iot_devices
        if iot_docs:
            await db["iot_devices"].insert_many(iot_docs)
            print(f"[{db_name}] Inserted {len(iot_docs)} IoT devices (Active: {active_count}, In_Stock: {len(iot_docs) - active_count}).")

        # 4. Update farms collection documents with iot_summary key-value dictionary
        for farm in farms:
            fid = farm["_id"]
            fid_str = str(fid)
            summary = farm_iot_counters.get(fid_str, {
                "total_devices": 0, "soil_sensors": 0, "weather_stations": 0, "gateway_hubs": 0, "smart_valves": 0
            })

            await db["farms"].update_one(
                {"_id": fid},
                {"$set": {"iot_summary": summary, "updated_at": now}}
            )
        print(f"[{db_name}] Updated {len(farms)} farm documents with iot_summary key-value properties.")


if __name__ == "__main__":
    asyncio.run(seed_iot())
