from __future__ import annotations

import asyncio
from datetime import datetime, timezone, timedelta
import random
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings
from app.utils.gis import calculate_terrain_analysis


async def seed_iot() -> None:
    client = AsyncIOMotorClient(settings.MONGODB_URL)
    
    # Target databases (seed both durian_guardian_ai_1 and durian_guardian_ai)
    db_names = [settings.MONGODB_DB_NAME, "durian_guardian_ai"]
    for db_name in set(db_names):
        db = client[db_name]

        # 1. Fetch existing farms and users
        farms = await db["farms"].find({}).to_list(length=100)
        users = await db["users"].find({}).to_list(length=100)
        if not farms:
            print(f"[{db_name}] No farms found to link active IoT devices.")
            continue

        print(f"[{db_name}] Found {len(farms)} farms. Clearing old IoT collections...")
        await db["iot_devices"].drop()
        await db["iot_orders"].drop()
        await db["iot_fault_reports"].drop()

        now = datetime.now(timezone.utc)
        iot_docs = []
        farm_iot_counters = {str(f["_id"]): {"total_devices": 0, "soil_sensors": 0, "weather_stations": 0, "gateway_hubs": 0, "smart_valves": 0} for f in farms}

        device_counter = 1

        # 2. Seed Active Devices for Each Farm
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

        # 3. Seed In-Stock Devices in Warehouse (Target: 58 in-stock devices)
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
            print(f"[{db_name}] Inserted {len(iot_docs)} IoT devices into `iot_devices` (Active: {active_count}, In_Stock: {len(iot_docs) - active_count}).")

        # 4. Seed iot_orders collection (15 realistic IoT orders)
        order_docs = []
        user_list = users if users else [{"_id": ObjectId(), "full_name": "Nguyễn Văn Tèo"}]
        order_statuses = ["Completed", "Approved", "Completed", "Pending", "Shipping"]

        for i, farm in enumerate(farms):
            user = user_list[i % len(user_list)]
            u_id = str(user.get("_id", ObjectId()))
            u_name = user.get("full_name") or user.get("fullname") or "Nguyễn Văn Tèo"
            f_id = str(farm["_id"])
            f_name = farm.get("farm_name", f"Trang trại Sầu Riêng #{i+1}")
            f_area = farm.get("area_hectare", 3.5)
            f_trees = farm.get("tree_count", 500)

            soil_qty = max(4, int(f_area / 0.5))
            weather_qty = max(1, int(f_area / 5.0))
            gw_qty = 2
            valve_qty = 2

            items = [
                {"device_type": "soil_sensor", "device_name": "Cảm biến độ ẩm & NPK đất DurianSense Pro", "quantity": soil_qty, "unit_price": 1200000.0},
                {"device_type": "weather_station", "device_name": "Trạm thời tiết vi khí hậu DGA-Weather 5G", "quantity": weather_qty, "unit_price": 8500000.0},
                {"device_type": "gateway_hub", "device_name": "Bộ trung tâm IoT Gateway Hub Edge AI", "quantity": gw_qty, "unit_price": 3500000.0},
                {"device_type": "smart_valve", "device_name": "Van tưới tự động thông minh DGA SmartValve", "quantity": valve_qty, "unit_price": 1800000.0},
            ]
            total_amt = sum(item["quantity"] * item["unit_price"] for item in items)
            st = order_statuses[i % len(order_statuses)]
            order_time = now - timedelta(days=random.randint(5, 60))

            order_docs.append({
                "order_code": f"ORD-{i+1:04d}",
                "user_id": u_id,
                "user_name": u_name,
                "farm_id": f_id,
                "farm_name": f_name,
                "area_hectare": f_area,
                "tree_count": f_trees,
                "items": items,
                "total_amount": total_amt,
                "status": st,
                "notes": "Đơn hàng tự động khuyến nghị theo quy mô vườn GIS",
                "admin_notes": "Đã phê duyệt bàn giao kỹ thuật lắp đặt tận vườn" if st != "Pending" else "Đang chờ Admin duyệt",
                "created_at": order_time,
                "updated_at": order_time,
            })

        if order_docs:
            await db["iot_orders"].insert_many(order_docs)
            print(f"[{db_name}] Inserted {len(order_docs)} IoT order records into `iot_orders`.")

        # 5. Seed iot_fault_reports collection (12 realistic fault/maintenance reports)
        fault_docs = []
        active_devices = [d for d in iot_docs if d.get("status") == "Active"]
        sample_issues = [
            "Cảm biến độ ẩm đất mất kết nối tín hiệu 4G quá 24 giờ",
            "Pin mặt trời trạm thời tiết bị giảm dung lượng sạc xuống dưới 15%",
            "Van tưới tự động không nhận lệnh đóng bù áp từ Gateway AI",
            "Nhiễu tín hiệu sóng LoRaWAN khu vực góc vườn phía Đông",
            "Đầu đo NPK đất bị bám bẩn cặn phân bón cần bảo dưỡng vệ sinh",
        ]
        fault_statuses = ["Resolved", "In_Progress", "Reported", "Resolved"]

        for i in range(min(12, len(active_devices))):
            dev = active_devices[i]
            user = user_list[i % len(user_list)]
            u_id = str(user.get("_id", ObjectId()))
            u_name = user.get("full_name") or user.get("fullname") or "Chủ vườn"
            st = fault_statuses[i % len(fault_statuses)]
            report_time = now - timedelta(days=random.randint(1, 30))

            fault_docs.append({
                "report_code": f"FLT-{i+1:04d}",
                "device_id": str(dev.get("_id", ObjectId())),
                "device_code": dev["device_code"],
                "device_name": dev["device_name"],
                "device_type": dev["device_type"],
                "farm_id": dev["farm_id"],
                "farm_name": dev["farm_name"],
                "user_id": u_id,
                "user_name": u_name,
                "issue_description": sample_issues[i % len(sample_issues)],
                "status": st,
                "technician_notes": "Đã cử kỹ thuật viên kiểm tra xử lý xong" if st == "Resolved" else "Đang cử nhân sự hỗ trợ",
                "created_at": report_time,
                "updated_at": report_time,
            })

        if fault_docs:
            await db["iot_fault_reports"].insert_many(fault_docs)
            print(f"[{db_name}] Inserted {len(fault_docs)} IoT fault report records into `iot_fault_reports`.")

        # 6. Update farms collection documents with iot_summary & 3D Terrain Analysis
        for farm in farms:
            fid = farm["_id"]
            fid_str = str(fid)
            summary = farm_iot_counters.get(fid_str, {
                "total_devices": 0, "soil_sensors": 0, "weather_stations": 0, "gateway_hubs": 0, "smart_valves": 0
            })
            b_pts = farm.get("boundary_points", [])
            c_lat = farm.get("gps_lat", 12.6667)
            c_lng = farm.get("gps_lng", 108.0500)
            terrain = calculate_terrain_analysis(b_pts, c_lat, c_lng)

            update_data = {
                "iot_summary": summary,
                "elevation_msl_meters": farm.get("elevation_msl_meters") or terrain["elevation_msl_meters"],
                "slope_gradient_percent": farm.get("slope_gradient_percent") or terrain["slope_gradient_percent"],
                "slope_aspect_heading": farm.get("slope_aspect_heading") or terrain["slope_aspect_heading"],
                "soil_texture_type": farm.get("soil_texture_type") or terrain["soil_texture_type"],
                "updated_at": now
            }

            await db["farms"].update_one(
                {"_id": fid},
                {"$set": update_data}
            )
        print(f"[{db_name}] Updated {len(farms)} farm documents with iot_summary and 3D Terrain Analysis.")


if __name__ == "__main__":
    asyncio.run(seed_iot())
